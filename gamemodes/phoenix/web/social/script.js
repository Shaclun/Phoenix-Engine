(function () {
	const root = document.getElementById("page-social");
	if (!root) return;

	let inventory = { gold: 0, items: [] };
	let social = { friends: [], party: [] };
	let interaction = null;
	let trade = null;
	let invite = null;
	let view = "social";
	let confirmOpen = false;
	let amountPicker = null;
	const ITEM_RENDER = { rotX: "1.584", rotY: "-1.662", rotZ: "-0.488", scale: "1.40", light: "2.85" };
	const PLAYER_RENDER = { rotX: "-0.022", rotY: "0.58", rotZ: "1.584", scale: "1.60", light: "1.75" };
	const VISUAL_BY_INSTANCE = { ITMI_GOLD: "ITMI_GOLD.MRM", ITRW_ARROW: "ITRW_ARROW.MRM", ITRW_BOLT: "ITRW_BOLT.MRM" };
	const meshQueue = {
		pending: [], active: 0, gen: 0,
		reset: function () { this.gen += 1; this.pending.length = 0; },
		schedule: function (cell, visual) {
			if (!cell || !visual) return;
			this.pending.push({ gen: this.gen, cell: cell, visual: visual });
			this.tick();
		},
		tick: function () {
			while (this.active < 1 && this.pending.length) {
				const task = this.pending.shift();
				if (task.gen !== this.gen) continue;
				this.run(task);
			}
		},
		run: function (task) {
			const self = this;
			self.active += 1;
			if (!task.cell || !task.cell.isConnected || task.gen !== self.gen) {
				self.active -= 1;
				setTimeout(function () { self.tick(); }, 25);
				return;
			}
			const fallback = task.cell.querySelector(".social-item__fallback");
			task.cell.querySelectorAll("gothic-render").forEach(function (old) { try { old.remove(); } catch (e) {} });
			const el = document.createElement("gothic-render");
			el.setAttribute("width", "112");
			el.setAttribute("height", "112");
			el.setAttribute("rot-x", ITEM_RENDER.rotX);
			el.setAttribute("rot-y", ITEM_RENDER.rotY);
			el.setAttribute("rot-z", ITEM_RENDER.rotZ);
			el.setAttribute("scale", ITEM_RENDER.scale);
			el.setAttribute("light-intensity", ITEM_RENDER.light);
			el.style.position = "absolute";
			el.style.inset = "0";
			el.style.zIndex = "1";
			task.cell.appendChild(el);
			let done = false;
			const finish = function (ok) {
				if (done) return;
				done = true;
				clearTimeout(watchdog);
				try { obs.disconnect(); } catch (e) {}
				if (ok && fallback) fallback.classList.add("is-loaded");
				if (!ok) try { el.remove(); } catch (e2) {}
				self.active -= 1;
				setTimeout(function () { self.tick(); }, 25);
			};
			const obs = new MutationObserver(function () {
				if (el.querySelector("canvas")) finish(true);
				else if (el.childElementCount === 0) finish(false);
			});
			obs.observe(el, { childList: true });
			const watchdog = setTimeout(function () { finish(false); }, 1500);
			el.setAttribute("visual", task.visual);
		}
	};

	function esc(value) {
		return String(value == null ? "" : value).replace(/[&<>\"]/g, function (ch) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[ch];
		});
	}

	function t(key, fallback) {
		try {
			if (window.PhoenixI18n && PhoenixI18n.t) {
				const value = PhoenixI18n.t(key);
				return value === key && fallback ? fallback : value;
			}
		} catch (e) {}
		return fallback || key;
	}
	function tItem(instance, suffix, fallback) {
		try { return window.PhoenixI18n && PhoenixI18n.tItem ? PhoenixI18n.tItem(instance, suffix, fallback) : (fallback || instance || ""); } catch (e) {}
		return fallback || instance || "";
	}
	function num(value) { return parseInt(value, 10) || 0; }
	function send(channel, payload) { if (window.PhoenixBridge) PhoenixBridge.send(channel, payload || {}); }
	function itemName(item) { return tItem(item.instance || item.instanceId, "name", item.name || item.displayName || item.instance || item.instanceId || t("social.item", "Przedmiot")); }
	function ownOfferItem(id) {
		if (!trade || !trade.ownOffer || !trade.ownOffer.items) return null;
		return trade.ownOffer.items.find(function (entry) { return num(entry.itemId) === num(id); }) || null;
	}
	function findInventoryItem(id) {
		return (inventory.items || []).find(function (entry) { return num(entry.id) === num(id); }) || null;
	}
	function offerSummary(offer) {
		const items = offer && offer.items ? offer.items : [];
		const parts = items.map(function (entry) { return itemName(entry) + " x" + num(entry.amount); });
		const gold = num(offer && offer.gold);
		if (gold > 0) parts.push(gold + " " + t("inv.unit.gold", "zl"));
		return parts.length ? parts.join(", ") : t("social.trade.nothing", "nic");
	}
	function itemVisual(item) {
		if (item && item.visual) return String(item.visual);
		const inst = item && (item.instance || item.instanceId) ? String(item.instance || item.instanceId).toUpperCase() : "";
		return VISUAL_BY_INSTANCE[inst] || "";
	}
	function itemVisualHtml(item) {
		const visual = itemVisual(item);
		return '<div class="social-item__render" data-visual="' + esc(visual) + '"><div class="social-item__fallback' + (visual ? ' is-loading' : '') + '"></div></div>';
	}

	function playerPortraitHtml(player) {
		const head = String(player && player.headModel || "").trim();
		const initial = String(player && player.name || "?").slice(0, 1).toUpperCase();
		return '<div class="social-interaction-card__sigil social-player-portrait" data-head="' + esc(head) + '" data-face="' + num(player && player.face) + '"><span>' + esc(initial || "?") + '</span></div>';
	}

	function personPortraitHtml(player) {
		const head = String(player && player.headModel || "").trim();
		const initial = String(player && player.name || "?").slice(0, 1).toUpperCase();
		return '<div class="social-person__portrait social-player-portrait" data-head="' + esc(head) + '" data-face="' + num(player && player.face) + '"><span>' + esc(initial || "?") + '</span></div>';
	}

	function itemCard(item) {
		const offered = ownOfferItem(item.id);
		const amount = num(item.amount || 1);
		return '<button type="button" class="social-item" data-action="offer-item" data-id="' + num(item.id) + '">' +
			itemVisualHtml(item) + '<span class="social-item__name">' + esc(itemName(item)) + '</span><b class="social-item__amount">x' + amount + '</b>' + (offered ? '<em class="social-item__badge">' + esc(t("social.trade.inOffer", "w ofercie")) + ' x' + num(offered.amount) + '</em>' : '') + '</button>';
	}
	function renderAmountModal() {
		if (!amountPicker || !amountPicker.item) return "";
		const item = amountPicker.item;
		const isGold = amountPicker.mode === "gold";
		const max = Math.max(1, num(item.amount || inventory.gold || 1));
		const current = isGold ? num(trade && trade.ownOffer && trade.ownOffer.gold) : num((ownOfferItem(item.id) || {}).amount || 1);
		const value = Math.max(1, Math.min(max, current || 1));
		return '<div class="social-confirm social-amount"><div class="social-confirm__box social-amount__box"><h3>' + esc(t("social.amount.title", "Wybierz ilosc")) + '</h3><p>' + esc(itemName(item)) + '</p><label class="social-amount__input"><span>' + esc(t("social.amount.label", "Ilosc")) + '</span><input type="number" min="0" max="' + max + '" value="' + value + '" data-role="amount-value"></label><small>' + esc(t("social.amount.max", "Maksymalnie")) + ': ' + max + '</small><footer><button type="button" data-action="amount-close">' + esc(t("social.action.cancel", "Anuluj")) + '</button><button type="button" class="social-primary" data-action="amount-confirm">' + esc(t("social.action.confirm", "Potwierdz")) + '</button></footer></div></div>';
	}

	function offerList(offer, own) {
		const items = offer && offer.items ? offer.items : [];
		const body = items.length ? items.map(function (entry) {
			const action = own ? ' data-action="remove-offer" data-id="' + num(entry.itemId) + '"' : '';
			return '<button type="button" class="social-item social-item--offer"' + action + '>' + itemVisualHtml(entry) + '<span class="social-item__name">' + esc(itemName(entry)) + '</span><b class="social-item__amount">x' + num(entry.amount) + '</b></button>';
		}).join("") : '<p class="social-empty">' + esc(t("social.trade.noItems", "Brak przedmiotow.")) + '</p>';
		return '<div class="social-offer-list social-items">' + body + '</div><div class="social-gold-line">' + esc(t("stats.gold", "Zloto")) + ': <strong>' + num(offer && offer.gold) + '</strong></div>';
	}
	function renderConfirmModal() {
		if (!confirmOpen || !trade) return "";
		return '<div class="social-confirm"><div class="social-confirm__box"><h3>' + esc(t("social.confirm.title", "Potwierdz wymiane")) + '</h3><p>' + esc(t("social.confirm.text", "Czy chcesz wymienic:")) + '</p><div class="social-confirm__swap"><span>' + esc(t("social.confirm.youGive", "Oddajesz")) + '</span><strong>' + esc(offerSummary(trade.ownOffer)) + '</strong><span>' + esc(t("social.confirm.youGet", "Otrzymujesz")) + '</span><strong>' + esc(offerSummary(trade.otherOffer)) + '</strong></div><footer><button type="button" data-action="confirm-close">' + esc(t("social.action.back", "Wroc")) + '</button><button type="button" class="social-primary" data-action="confirm-trade">' + esc(t("social.action.confirm", "Potwierdz")) + '</button></footer></div></div>';
	}

	function renderTrade() {
		if (!trade) return "";
		const ownAccepted = trade.ownOffer && trade.ownOffer.accepted;
		const otherAccepted = trade.otherOffer && trade.otherOffer.accepted;
		const otherName = trade.other && trade.other.name ? trade.other.name : t("social.player", "Gracz");
		return '<section class="social-trade merchant-screen">' +
			'<header class="social-screen-head social-trade__head"><div><span>' + esc(t("social.trade.kicker", "Bezpieczna wymiana")) + '</span><h1>' + esc(t("social.trade.title", "Handel")) + '</h1></div><p>' + esc(t("social.trade.with", "Wymiana z")) + ' <strong>' + esc(otherName) + '</strong></p></header>' +
			'<section class="social-offer social-offer--other merchant-panel"><header class="merchant-panel__head"><div><span>' + esc(t("social.trade.otherOffer", "Oferta gracza")) + '</span><h2>' + esc(otherName) + '</h2></div><em class="social-status' + (otherAccepted ? ' is-ready' : '') + '">' + esc(otherAccepted ? t("social.trade.accepted", "Zaakceptowano") : t("social.trade.waiting", "Czeka")) + '</em></header>' + offerList(trade.otherOffer, false) + '</section>' +
			'<section class="social-offer merchant-panel"><header class="merchant-panel__head"><div><span>' + esc(t("social.trade.yourOffer", "Twoja oferta")) + '</span><h2>' + esc(t("character.hero", "Ty")) + '</h2></div><em class="social-status' + (ownAccepted ? ' is-ready' : '') + '">' + esc(ownAccepted ? t("social.trade.accepted", "Zaakceptowano") : t("social.trade.canChange", "Edytowalna")) + '</em></header>' + offerList(trade.ownOffer, true) + '<label class="social-gold-input"><span>' + esc(t("stats.gold", "Złoto")) + '</span><input type="number" min="0" max="' + num(inventory.gold) + '" value="' + num(trade.ownOffer && trade.ownOffer.gold) + '" data-role="trade-gold"></label><footer><button type="button" class="social-primary" data-action="accept-trade">' + esc(t("social.action.accept", "Akceptuj")) + '</button><button type="button" data-action="cancel-trade">' + esc(t("social.action.cancel", "Anuluj")) + '</button></footer></section>' +
			'<aside class="social-inventory merchant-panel"><header class="merchant-panel__head"><div><span>' + esc(t("inv.bag", "Plecak")) + '</span><h2>' + esc(t("social.trade.chooseItems", "Wybierz przedmioty")) + '</h2></div><strong>' + num(inventory.gold) + ' ' + esc(t("inv.unit.gold", "zł")) + '</strong></header><div class="social-items">' + (inventory.items || []).filter(function (it) { return !it.equipped; }).map(itemCard).join("") + '</div></aside>' +
		'</section>' + renderConfirmModal() + renderAmountModal();
	}

	function renderFriendList() {
		const friends = social.friends || [];
		if (!friends.length) return '<p class="social-empty">' + esc(t("social.friendsEmpty", "Brak znajomych.")) + '</p>';
		return friends.map(function (friend) {
			const online = num(friend.playerId) >= 0;
			return '<article class="social-person' + (online ? ' is-online' : '') + '">' + personPortraitHtml(friend) + '<div class="social-person__identity"><b>' + esc(friend.name || t("social.player", "Gracz")) + '</b><small><i></i>' + esc(online ? t("social.online", "online") : t("social.offline", "offline")) + '</small></div><div class="social-row-actions">' + (online ? '<button type="button" data-action="dm-open" data-target="' + num(friend.playerId) + '" data-name="' + esc(friend.name || "") + '">' + esc(t("social.action.dm", "Wiadomość")) + '</button><button type="button" data-action="party-invite" data-target="' + num(friend.playerId) + '">' + esc(t("social.action.party", "Party")) + '</button>' : '') + '</div></article>';
		}).join("");
	}

	function renderInvite() {
		if (!invite || !invite.from) return "";
		return '<section class="social-invite"><div><span>' + esc(t("social.party.invitation", "Zaproszenie do drużyny")) + '</span><strong>' + esc(invite.from.name || t("social.player", "Gracz")) + '</strong></div><div class="social-row-actions"><button type="button" class="social-primary" data-action="party-accept" data-invite="' + num(invite.inviteId) + '">' + esc(t("social.action.join", "Dołącz")) + '</button><button type="button" data-action="party-decline" data-invite="' + num(invite.inviteId) + '">' + esc(t("social.action.decline", "Odrzuć")) + '</button></div></section>';
	}

	function renderPartyPanel() {
		const members = social.party || [];
		const selfId = num(social.self && social.self.playerId);
		const leaderId = num(social.partyLeaderId);
		const isLeader = members.length > 0 && selfId === leaderId;
		const maxMembers = num(social.partyMaxMembers) || 4;
		const body = members.length ? members.map(function (member) {
			const memberId = num(member.playerId);
			const transfer = member.testPlayerNpc ? '' : '<button type="button" data-action="party-transfer" data-target="' + memberId + '">' + esc(t("social.party.transfer", "Lider")) + '</button>';
			const controls = isLeader && memberId !== selfId ? transfer + '<button type="button" class="is-danger" data-action="party-kick" data-target="' + memberId + '">' + esc(t("social.party.kick", "Usuń")) + '</button>' : '';
			return '<article class="social-party-member' + (member.isLeader ? ' is-leader' : '') + (member.testPlayerNpc ? ' is-test-player' : '') + '">' + personPortraitHtml(member) + '<div><b>' + esc(member.name || t("social.player", "Gracz")) + '</b><small>' + (member.isLeader ? '◆ ' : '') + esc(t("stats.levelShort", "Lv")) + ' ' + num(member.level) + (memberId === selfId ? ' · ' + esc(t("character.hero", "Ty")) : '') + '</small></div><div class="social-row-actions">' + controls + '</div></article>';
		}).join("") : '<p class="social-empty">' + esc(t("social.party.empty", "Nie jesteś w drużynie.")) + '</p>';
		return '<div class="social-column social-column--party"><header><div><span>' + esc(t("social.party.title", "Drużyna")) + '</span><small>' + esc(t("social.party.sharedExp", "Współdzielony EXP w zasięgu")) + '</small></div><strong>' + members.length + ' / ' + maxMembers + '</strong></header><div class="social-list">' + body + '</div>' + (members.length ? '<footer><button type="button" data-action="party-leave">' + esc(t("social.party.leave", "Opuść drużynę")) + '</button></footer>' : '') + '</div>';
	}

	function renderSocialHome() {
		const players = social.players || [];
		return '<section class="social-panel social-panel--home">' + renderInvite() +
			'<header class="social-screen-head"><div><span>' + esc(t("social.kicker", "Kontakty i drużyna")) + '</span><h1>' + esc(t("social.title", "Kompania")) + '</h1></div><p>' + esc(t("social.subtitle", "Znajomi, pobliscy bohaterowie i wspólna wyprawa.")) + '</p></header>' +
			'<div class="social-column social-column--friends"><header><div><span>' + esc(t("social.friends", "Znajomi")) + '</span><small>' + esc(t("social.friendsHint", "Twoje stałe kontakty")) + '</small></div><strong>' + (social.friends || []).length + '</strong></header><div class="social-list">' + renderFriendList() + '</div></div>' +
			renderPartyPanel() +
			'<div class="social-column social-column--players"><header><div><span>' + esc(t("social.playersOnline", "Gracze online")) + '</span><small>' + esc(t("social.playersHint", "Zaproś do wspólnej gry")) + '</small></div><strong>' + players.length + '</strong></header><div class="social-list">' + (players.length ? players.map(function (player) {
				return '<article class="social-person">' + personPortraitHtml(player) + '<div class="social-person__identity"><b>' + esc(player.name) + '</b><small>' + esc(player.near ? t("social.party.inRange", "w zasięgu party") : t("social.party.outRange", "poza zasięgiem party")) + '</small></div><div class="social-row-actions"><button type="button" data-action="friend-add" data-target="' + num(player.playerId) + '">' + esc(t("social.action.addFriend", "Dodaj")) + '</button><button type="button" data-action="dm-open" data-target="' + num(player.playerId) + '" data-name="' + esc(player.name) + '">' + esc(t("social.action.dm", "Wiadomość")) + '</button><button type="button" class="social-primary" data-action="party-invite" data-target="' + num(player.playerId) + '">' + esc(t("social.action.party", "Party")) + '</button></div></article>';
			}).join("") : '<p class="social-empty">' + esc(t("social.playersEmpty", "Brak innych graczy online.")) + '</p>') + '</div></div>' +
		'</section>';
	}

	function renderPanel() {
		const target = interaction && interaction.target ? interaction.target : null;
		if (view !== "interaction" || !target) return renderSocialHome();
		return '<section class="social-panel social-panel--npc">' + renderInvite() + '<article class="social-interaction-card"><span class="social-interaction-card__kicker">' + esc(t("social.selected", "Wybrany gracz")) + '</span>' + playerPortraitHtml(target) + '<h2>' + esc(target.name) + '</h2>' + (target.testPlayerNpc ? '<small>' + esc(t("social.testNpc", "NPC testowy gracza")) + '</small>' : '<small>' + esc(t("social.interactionHint", "Wybierz sposób interakcji")) + '</small>') + '<div class="social-actions"><button type="button" class="social-primary" data-action="trade-start" data-target="' + num(target.playerId) + '">' + esc(t("social.action.trade", "Handel")) + '</button><button type="button" data-action="friend-add" data-target="' + num(target.playerId) + '">' + esc(t("social.action.addFriend", "Dodaj znajomego")) + '</button><button type="button" data-action="dm-open" data-target="' + num(target.playerId) + '" data-name="' + esc(target.name) + '">' + esc(t("social.action.dm", "Prywatna wiadomość")) + '</button><button type="button" data-action="party-invite" data-target="' + num(target.playerId) + '">' + esc(t("social.action.party", "Zaproś do party")) + '</button></div></article></section>';
	}

	function schedulePlayerPortraits() {
		root.querySelectorAll(".social-player-portrait[data-head]").forEach(function (cell) {
			const head = String(cell.dataset.head || "").trim();
			if (!head) return;
			const render = document.createElement("gothic-render");
			render.setAttribute("width", "96");
			render.setAttribute("height", "96");
			render.setAttribute("rot-x", PLAYER_RENDER.rotX);
			render.setAttribute("rot-y", PLAYER_RENDER.rotY);
			render.setAttribute("rot-z", PLAYER_RENDER.rotZ);
			render.setAttribute("scale", PLAYER_RENDER.scale);
			render.setAttribute("light-intensity", PLAYER_RENDER.light);
			render.setAttribute("head-tex-index", String(num(cell.dataset.face)));
			render.setAttribute("visual", head.toUpperCase().endsWith(".MMB") ? head : head + ".MMB");
			cell.appendChild(render);
		});
	}

	function scheduleMeshes() {
		root.querySelectorAll(".social-item__render[data-visual]").forEach(function (cell) {
			const visual = cell.dataset.visual || "";
			if (visual) meshQueue.schedule(cell, visual);
		});
		schedulePlayerPortraits();
	}

	function render() {
		meshQueue.reset();
		const compact = !trade && view === "interaction" && interaction && interaction.target;
		root.innerHTML = '<div class="social-shell' + (compact ? ' social-shell--compact' : '') + '"><button type="button" class="phoenix-exit-btn social-close" data-action="close" aria-label="close">x</button>' + (trade ? renderTrade() : renderPanel()) + '</div>';
		scheduleMeshes();
	}

	root.addEventListener("click", function (event) {
		const button = event.target.closest("button");
		if (!button) return;
		const action = button.dataset.action;
		const targetId = num(button.dataset.target);
		if (action === "close") send("phoenix:social:close", {});
		if (action === "trade-start") send("phoenix:social:tradeStart", { targetId: targetId });
		if (action === "friend-add") send("phoenix:social:friendAdd", { targetId: targetId });
		if (action === "party-invite") send("phoenix:social:partyInvite", { targetId: targetId });
		if (action === "party-accept") { send("phoenix:social:partyAccept", { inviteId: num(button.dataset.invite) }); invite = null; }
		if (action === "party-decline") { send("phoenix:social:partyDecline", { inviteId: num(button.dataset.invite) }); invite = null; }
		if (action === "party-leave") send("phoenix:social:partyLeave", {});
		if (action === "party-kick") send("phoenix:social:partyKick", { targetId: targetId });
		if (action === "party-transfer") send("phoenix:social:partyTransfer", { targetId: targetId });
		if (action === "accept-trade") { confirmOpen = true; render(); return; }
		if (action === "confirm-close") { confirmOpen = false; render(); return; }
		if (action === "confirm-trade") { confirmOpen = false; send("phoenix:social:tradeAccept", {}); }
		if (action === "cancel-trade") send("phoenix:social:tradeCancel", {});
		if (action === "offer-item") {
			const item = findInventoryItem(button.dataset.id);
			if (!item) return;
			const instance = String(item.instance || item.instanceId || "").toUpperCase();
			if (instance === "ITMI_GOLD") amountPicker = { mode: "gold", item: item };
			else if (num(item.amount) > 1) amountPicker = { mode: "item", item: item };
			else send("phoenix:social:tradeItem", { itemId: num(item.id), amount: 1 });
			render();
			return;
		}
		if (action === "remove-offer") send("phoenix:social:tradeItem", { itemId: num(button.dataset.id), amount: 0 });
		if (action === "amount-close") { amountPicker = null; render(); return; }
		if (action === "amount-confirm") {
			const input = root.querySelector("[data-role='amount-value']");
			const amount = input ? num(input.value) : 0;
			if (amountPicker && amountPicker.mode === "gold") send("phoenix:social:tradeGold", { gold: amount });
			else if (amountPicker && amountPicker.item) send("phoenix:social:tradeItem", { itemId: num(amountPicker.item.id), amount: amount });
			amountPicker = null;
			render();
			return;
		}
		if (action === "dm-open") {
			if (window.PhoenixBridge) PhoenixBridge.emit("phoenix:chat:dmOpen", { playerId: targetId, name: button.dataset.name || "Gracz" });
			send("phoenix:social:close", {});
		}
		render();
	});

	root.addEventListener("change", function (event) {
		if (event.target && event.target.dataset.role === "trade-gold") send("phoenix:social:tradeGold", { gold: num(event.target.value) });
	});

	if (window.PhoenixBridge) {
		PhoenixBridge.on("phoenix:social:mode", function (payload) {
			view = payload && payload.mode ? String(payload.mode) : "social";
			if (view === "social") { interaction = null; trade = null; confirmOpen = false; }
			render();
		});
		PhoenixBridge.on("phoenix:item:inventory", function (payload) { inventory = payload || inventory; render(); });
		PhoenixBridge.on("phoenix:social:state", function (payload) { social = payload || social; render(); });
		PhoenixBridge.on("phoenix:social:interaction", function (payload) { view = "interaction"; interaction = payload || null; trade = null; render(); });
		PhoenixBridge.on("phoenix:social:trade", function (payload) { view = "trade"; trade = payload || null; confirmOpen = false; amountPicker = null; render(); });
		PhoenixBridge.on("phoenix:social:tradeClosed", function () { trade = null; confirmOpen = false; amountPicker = null; view = "social"; render(); });
		PhoenixBridge.on("phoenix:social:partyInvite", function (payload) { invite = payload || null; render(); });
		PhoenixBridge.on("phoenix:social:partyInviteClosed", function () { invite = null; render(); });
	}

	if (window.phoenixApp) {
		window.phoenixApp.register("social", {
			onShow: function () { if (view !== "interaction" && view !== "trade") view = "social"; send("phoenix:social:request", {}); render(); },
			onHide: function () {}
		});
	}
	if (window.PhoenixI18n && PhoenixI18n.onChange) PhoenixI18n.onChange(render);

	render();
})();
