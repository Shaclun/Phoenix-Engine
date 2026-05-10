(function () {
	const root = document.getElementById("page-house");
	if (!root) return;

	let state = { mode: "panel", houseId: 0, maxExtendWeeks: 12, weeklyRentGold: 0, rentPaidUntil: 0, playerGold: 0 };
	let tickTimer = null;

	function esc(value) {
		return String(value == null ? "" : value).replace(/[&<>"]/g, function (ch) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[ch];
		});
	}

	function number(value) { return parseInt(value, 10) || 0; }

	function t(key) {
		if (window.PhoenixI18n && typeof PhoenixI18n.t === "function") return PhoenixI18n.t(key);
		return key;
	}

	function gold(amount) { return number(amount) + " " + t("house.time.gold"); }

	function timeLeft(until) {
		if (!number(until)) return t("house.time.lifetime");
		const left = Math.max(0, number(until) - Math.floor(Date.now() / 1000));
		const days = Math.floor(left / 86400);
		const hours = Math.floor((left % 86400) / 3600);
		const minutes = Math.floor((left % 3600) / 60);
		if (left <= 0) return t("house.time.expired");
		if (days > 0) return days + " " + t("house.time.unitDays") + " " + hours + " " + t("house.time.unitHours");
		if (hours > 0) return hours + " " + t("house.time.unitHours") + " " + minutes + " " + t("house.time.unitMinutes");
		return minutes + " " + t("house.time.unitMinutes");
	}

	function close() { PhoenixBridge.send("phoenix:house:close", null); }

	const successKeys = {
		bought: "house.result.success.bought",
		rentExtended: "house.result.success.rentExtended",
		guestAdded: "house.result.success.guestAdded",
		requestSent: "house.result.success.requestSent",
		requestAccepted: "house.result.success.requestAccepted",
		requestDenied: "house.result.success.requestDenied",
		guestRemoved: "house.result.success.guestRemoved",
		ownerAccess: "house.result.success.ownerAccess",
		guestAccess: "house.result.success.guestAccess",
		houseSold: "house.result.success.houseSold",
		houseLeft: "house.result.success.houseLeft"
	};
	const errorKeys = {
		freeHouse: "house.result.error.freeHouse",
		targetNotFound: "house.result.error.targetNotFound",
		targetOwner: "house.result.error.targetOwner",
		alreadyGuest: "house.result.error.alreadyGuest",
		notFriend: "house.result.error.notFriend",
		noRequest: "house.result.error.noRequest",
		notGuest: "house.result.error.notGuest",
		ownerOffline: "house.result.error.ownerOffline",
		noGold: "house.result.error.noGold",
		owned: "house.result.error.owned",
		tooFar: "house.result.error.tooFar",
		maxRent: "house.result.error.maxRent",
		noHouse: "house.result.error.noHouse",
		priceInvalid: "house.result.error.priceInvalid",
		buyerOffline: "house.result.error.buyerOffline",
		buyerNoGold: "house.result.error.buyerNoGold",
		buyerNotFriend: "house.result.error.buyerNotFriend",
		cantSellOwn: "house.result.error.cantSellOwn"
	};

	function resultText(data) {
		const error = data && data.error ? data.error : "";
		const success = data && data.success;
		if (success && successKeys[error]) return t(successKeys[error]);
		if (errorKeys[error]) return t(errorKeys[error]);
		return success ? t("house.result.success.default") : t("house.result.error.default");
	}

	function parseAccountList(text) {
		const out = [];
		if (!text) return out;
		const parts = String(text).split(";");
		for (let i = 0; i < parts.length; i += 1) {
			const chunk = parts[i];
			if (!chunk) continue;
			const sep = chunk.indexOf("|");
			if (sep < 0) continue;
			const id = parseInt(chunk.slice(0, sep), 10) || 0;
			const name = chunk.slice(sep + 1);
			if (id > 0) out.push({ accountId: id, name: name || (t("house.account.fallback") + id) });
		}
		return out;
	}

	function notifyResult(data) {
		if (!data || data.error === "open" || data.error === "panel") return;
		if (!data.error) return;
		if (data.error === "noHouse" && data.mode === "panel") return;
		if (window.PhoenixNotify) PhoenixNotify.notify(data.success ? "success" : "error", t("house.notify.title"), resultText(data), 3600);
	}

	function renderShell(inner) {
		root.innerHTML = '<div class="house-panel">' +
			'<button type="button" class="phoenix-exit-btn house-panel__close" data-action="close" title="ESC" aria-label="close">x</button>' + inner + '</div>';
	}

	function renderEntry(data) {
		const owned = number(data.ownerId) > 0;
		const expired = owned && number(data.rentPaidUntil) > 0 && number(data.rentPaidUntil) < Math.floor(Date.now() / 1000);
		const total = number(data.priceGold) + number(data.weeklyRentGold);
		const access = data.access || "";
		const hasAccess = !!data.canEnter || access === "owner" || access === "guest" || access === "admin";
		const ownerLabel = data.ownerName && String(data.ownerName).length > 0 ? String(data.ownerName) : (t("house.account.fallback") + number(data.ownerId));
		const accessLine = access === "owner" ? t("house.entry.ownerYou") : (access === "guest" ? t("house.entry.guestYou") : t("house.entry.adminYou"));
		renderShell(
			'<header class="house-head"><span class="house-kicker">' + t("house.entry.kicker") + '</span><h1>' + esc(data.name || t("house.notify.title")) + '</h1></header>' +
			'<section class="house-entry">' +
				(owned ? '<p class="house-muted house-owner">' + t("house.entry.owner") + ': <strong>' + esc(ownerLabel) + '</strong></p>' : '') +
				(hasAccess ?
					'<p class="house-muted">' + accessLine + '</p>' +
					(expired ? '<p class="house-warning">' + t("house.entry.expired.guest") + '</p>' : '') +
					'<button type="button" class="house-btn house-btn--primary" data-action="close">' + t("house.action.close") + '</button>' : owned ?
					(expired ? '<p class="house-warning">' + t("house.entry.expired.locked") + '</p>' : '') +
					'<button type="button" class="house-btn house-btn--primary" data-action="request-access">' + t("house.entry.requestAccess") + '</button>' :
					'<div class="house-price"><span>' + t("house.entry.startCost") + '</span><strong>' + gold(total) + '</strong></div>' +
					'<div class="house-grid house-grid--two"><div><span>' + t("house.entry.priceLabel") + '</span><b>' + number(data.priceGold) + '</b></div><div><span>' + t("house.entry.weeklyLabel") + '</span><b>' + number(data.weeklyRentGold) + '</b></div></div>' +
					'<button type="button" class="house-btn house-btn--primary" data-action="rent">' + t("house.entry.rent") + '</button>') +
				(hasAccess ? '' : '<button type="button" class="house-btn" data-action="close">' + t("house.action.close") + '</button>') +
			'</section>'
		);
	}

	function renderInviteSection(friends, guestsLabel) {
		const options = friends.length > 0
			? friends.map(function (f) { return '<option value="' + f.accountId + '">' + esc(f.name) + '</option>'; }).join("")
			: '<option value="">' + esc(t("house.panel.invite.empty")) + '</option>';
		const disabled = friends.length === 0 ? ' disabled' : '';
		return '<section class="house-section"><h2>' + t("house.panel.invite.title") + '</h2>' +
			'<div class="house-invite"><select data-role="invite-target"' + disabled + '>' + options + '</select>' +
			'<button type="button" class="house-btn" data-action="invite"' + disabled + '>' + t("house.panel.invite.btn") + '</button></div>' +
			'<p class="house-muted">' + t("house.panel.invite.note") + '</p>' +
			'<p class="house-guests">' + t("house.panel.invite.guests") + ': ' + esc(guestsLabel || t("house.panel.invite.noGuests")) + '</p>' +
			'</section>';
	}

	function renderRequestsSection(requests) {
		if (!requests || requests.length === 0) {
			return '<section class="house-section"><h2>' + t("house.panel.requests.title") + '</h2><p class="house-muted">' + t("house.panel.requests.empty") + '</p></section>';
		}
		const rows = requests.map(function (r) {
			return '<li class="house-request"><span>' + esc(r.name) + '</span>' +
				'<button type="button" class="house-btn house-btn--primary" data-action="accept" data-target="' + r.accountId + '">' + t("house.panel.requests.accept") + '</button>' +
				'<button type="button" class="house-btn" data-action="deny" data-target="' + r.accountId + '">' + t("house.panel.requests.deny") + '</button>' +
				'</li>';
		}).join("");
		return '<section class="house-section"><h2>' + t("house.panel.requests.title") + '</h2><ul class="house-list">' + rows + '</ul></section>';
	}

	function renderGuestsSection(guests) {
		if (!guests || guests.length === 0) {
			return '<section class="house-section"><h2>' + t("house.panel.guests.title") + '</h2><p class="house-muted">' + t("house.panel.guests.empty") + '</p></section>';
		}
		const rows = guests.map(function (g) {
			return '<li class="house-guest"><span>' + esc(g.name) + '</span>' +
				'<button type="button" class="house-btn house-btn--danger" data-action="kick" data-target="' + g.accountId + '">' + t("house.panel.guests.kick") + '</button>' +
				'</li>';
		}).join("");
		return '<section class="house-section"><h2>' + t("house.panel.guests.title") + '</h2><ul class="house-list">' + rows + '</ul></section>';
	}

	function renderSellSection(friends) {
		const options = friends.length > 0
			? friends.map(function (f) { return '<option value="' + f.accountId + '">' + esc(f.name) + '</option>'; }).join("")
			: '<option value="">' + esc(t("house.panel.invite.empty")) + '</option>';
		const disabled = friends.length === 0 ? ' disabled' : '';
		return '<section class="house-section"><h2>' + t("house.panel.sell.title") + '</h2>' +
			'<div class="house-rent-row">' +
				'<input type="number" min="0" step="1" value="0" data-role="sell-price" placeholder="' + esc(t("house.panel.sell.priceLabel")) + '">' +
				'<select data-role="sell-buyer"' + disabled + '>' + options + '</select>' +
				'<button type="button" class="house-btn house-btn--primary" data-action="sell"' + disabled + '>' + t("house.panel.sell.btn") + '</button>' +
			'</div>' +
			'<p class="house-muted">' + t("house.panel.sell.note") + '</p>' +
			'</section>';
	}

	function renderLeaveSection() {
		return '<section class="house-section"><h2>' + t("house.panel.leave.title") + '</h2>' +
			'<p class="house-muted">' + t("house.panel.leave.note") + '</p>' +
			'<button type="button" class="house-btn house-btn--danger" data-action="leave">' + t("house.panel.leave.btn") + '</button>' +
			'</section>';
	}

	function renderPanel(data) {
		state = Object.assign({}, state, data || {}, { mode: "panel" });
		if (!data || !data.houseId || data.error === "noHouse") {
			renderShell('<header class="house-head"><span class="house-kicker">' + t("house.panel.kicker") + '</span><h1>' + t("house.panel.noHouse.title") + '</h1></header><p class="house-muted">' + t("house.panel.noHouse.text") + '</p><button type="button" class="house-btn" data-action="close">' + t("house.action.close") + '</button>');
			return;
		}
		const maxWeeks = Math.max(1, Math.min(12, number(data.maxExtendWeeks || 12)));
		const weekly = number(data.weeklyRentGold);
		const rentSection = weekly > 0
			? '<section class="house-section"><h2>' + t("house.panel.rent.title") + '</h2><div class="house-rent-row"><input type="range" min="1" max="' + maxWeeks + '" value="1" data-role="weeks"><strong><span data-role="weeks-text">1</span> ' + t("house.panel.rent.weekUnit") + '</strong><span data-role="cost">' + gold(weekly) + '</span><button type="button" class="house-btn house-btn--primary" data-action="extend">' + t("house.panel.rent.btn") + '</button></div><p class="house-muted">' + t("house.panel.rent.maxNote") + '</p></section>'
			: '<section class="house-section"><h2>' + t("house.panel.rent.lifetime.title") + '</h2><p class="house-muted">' + t("house.panel.rent.lifetime.text") + '</p></section>';
		const friends = parseAccountList(data.friends);
		const requests = parseAccountList(data.requests);
		const guestsList = parseAccountList(data.guestsData);
		renderShell(
			'<header class="house-head"><span class="house-kicker">' + t("house.panel.kicker") + '</span><h1>' + esc(data.name || t("house.notify.title")) + '</h1></header>' +
			'<section class="house-grid house-grid--three">' +
				'<div><span>' + t("house.panel.timeLeft") + '</span><b data-role="time-left">' + timeLeft(data.rentPaidUntil) + '</b></div>' +
				'<div><span>' + t("house.panel.weekly") + '</span><b>' + weekly + '</b></div>' +
				'<div><span>' + t("house.panel.gold") + '</span><b data-role="gold">' + number(data.playerGold) + '</b></div>' +
			'</section>' +
			rentSection +
			renderRequestsSection(requests) +
			renderInviteSection(friends, data.guests) +
			renderGuestsSection(guestsList) +
			renderSellSection(friends) +
			renderLeaveSection() +
			'<p class="house-status" data-role="status">' + (data.error && data.error !== "panel" ? esc(resultText(data)) : '') + '</p>'
		);
		bindRange();
	}

	function bindRange() {
		const range = root.querySelector("[data-role='weeks']");
		if (!range) return;
		function sync() {
			const weeks = number(range.value) || 1;
			const weekly = number(state.weeklyRentGold);
			const text = root.querySelector("[data-role='weeks-text']");
			const cost = root.querySelector("[data-role='cost']");
			if (text) text.textContent = weeks;
			if (cost) cost.textContent = gold(weeks * weekly);
		}
		range.addEventListener("input", sync);
		sync();
	}

	function applyResult(data) {
		if (!data) return;
		notifyResult(data);
		if (data.mode === "panel") { renderPanel(data); return; }
		const status = root.querySelector("[data-role='status']");
		if (status) status.textContent = resultText(data);
		if (data.success && (data.error === "bought" || data.error === "rentExtended" || data.error === "houseSold" || data.error === "houseLeft")) close();
	}

	root.addEventListener("click", function (ev) {
		const target = ev.target.closest("[data-action]");
		if (!target) return;
		const action = target.dataset.action;
		if (action === "close") close();
		if (action === "rent") PhoenixBridge.send("phoenix:house:rent", { houseId: state.houseId });
		if (action === "request-access") PhoenixBridge.send("phoenix:house:requestAccess", { houseId: state.houseId });
		if (action === "extend") {
			const weeks = number((root.querySelector("[data-role='weeks']") || {}).value || 1);
			PhoenixBridge.send("phoenix:house:extend", { houseId: state.houseId, weeks: weeks });
		}
		if (action === "invite") {
			const input = root.querySelector("[data-role='invite-target']");
			const value = input ? input.value : "";
			if (!value) return;
			PhoenixBridge.send("phoenix:house:invite", { houseId: state.houseId, target: value });
		}
		if (action === "accept") PhoenixBridge.send("phoenix:house:accept", { houseId: state.houseId, target: target.dataset.target || "" });
		if (action === "deny") PhoenixBridge.send("phoenix:house:deny", { houseId: state.houseId, target: target.dataset.target || "" });
		if (action === "kick") PhoenixBridge.send("phoenix:house:kick", { houseId: state.houseId, target: target.dataset.target || "" });
		if (action === "sell") {
			const priceInput = root.querySelector("[data-role='sell-price']");
			const buyerInput = root.querySelector("[data-role='sell-buyer']");
			const price = number(priceInput ? priceInput.value : 0);
			const buyer = buyerInput ? buyerInput.value : "";
			if (!buyer) return;
			PhoenixBridge.send("phoenix:house:sell", { houseId: state.houseId, target: buyer, price: price });
		}
		if (action === "leave") PhoenixBridge.send("phoenix:house:leave", { houseId: state.houseId });
	});

	PhoenixBridge.on("phoenix:house:entry", function (data) { state = Object.assign({}, state, data || {}, { mode: "entry" }); renderEntry(state); });
	PhoenixBridge.on("phoenix:house:panel", function (data) { notifyResult(data); renderPanel(data); });
	PhoenixBridge.on("phoenix:house:result", applyResult);

	if (window.PhoenixI18n && typeof PhoenixI18n.onChange === "function") {
		PhoenixI18n.onChange(function () {
			if (!root.innerHTML) return;
			if (state.mode === "panel") renderPanel(state);
			else if (state.mode === "entry") renderEntry(state);
		});
	}

	const page = {
		onShow: function () {
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") window.PhoenixHud.setBlocked(true);
			if (!root.innerHTML) PhoenixBridge.send("phoenix:house:panelRequest", null);
			clearInterval(tickTimer);
			tickTimer = setInterval(function () {
				const el = root.querySelector("[data-role='time-left']");
				if (el) el.textContent = timeLeft(state.rentPaidUntil);
			}, 1000);
		},
		onHide: function () {
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") window.PhoenixHud.setBlocked(false);
			clearInterval(tickTimer);
			tickTimer = null;
		}
	};
	if (window.phoenixApp) window.phoenixApp.register("house", page);
})();
