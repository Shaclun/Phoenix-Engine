(function () {
	const root = document.getElementById("page-teacher");
	if (!root) return;
	const I18n = window.PhoenixI18n;
	const skillLabels = {
		strength: "stats.attr.strength",
		dexterity: "stats.attr.dexterity",
		hpMax: "stats.attr.hpMax",
		manaMax: "stats.attr.manaMax",
		oneHand: "stats.weapon.oneHand",
		twoHand: "stats.weapon.twoHand",
		bow: "stats.weapon.bow",
		crossbow: "stats.weapon.crossbow"
	};
	const lineKeys = {
		player: ["npc.dialog.line.player.1", "npc.dialog.line.player.2", "npc.dialog.line.player.3"],
		npc: ["npc.dialog.line.npc.1", "npc.dialog.line.npc.2", "npc.dialog.line.npc.3"]
	};
	let state = { mode: "dialog", npcName: "", items: [], playerItems: [], playerGold: 0 };
	let dialogStage = { active: false, index: 0, stages: [], data: null };
	let merchantModal = null;
	let lastMerchantPick = { key: "", at: 0 };
	const ITEM_RENDER = { rotX: "1.584", rotY: "-1.662", rotZ: "-0.488", scale: "1.40", light: "2.85" };
	const MESH_QUEUE_CONCURRENCY = 1;
	const MESH_QUEUE_TIMEOUT_MS = 1500;
	const MESH_QUEUE_GAP_MS = 25;
	const MESH_RETRY_INTERVAL_MS = 1500;
	let merchantMeshRetryTimer = null;
	const merchantMeshQueue = {
		pending: [], active: 0, gen: 0,
		reset: function () { this.gen += 1; this.pending.length = 0; },
		schedule: function (cell, visual) {
			if (!cell || !visual) return;
			if (cell.dataset.meshVisual === visual && cell.querySelector("gothic-render")) return;
			this.pending.push({ gen: this.gen, cell: cell, visual: visual });
			this.tick();
		},
		tick: function () {
			while (this.active < MESH_QUEUE_CONCURRENCY && this.pending.length) {
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
				setTimeout(function () { self.tick(); }, MESH_QUEUE_GAP_MS);
				return;
			}
			const fallback = task.cell.querySelector(".merchant-item__fallback");
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
			task.cell.dataset.meshVisual = task.visual;
			task.cell.dataset.meshLoaded = "0";
			let done = false;
			const finish = function (ok) {
				if (done) return;
				done = true;
				clearTimeout(watchdog);
				try { obs.disconnect(); } catch (e) {}
				if (ok) {
					if (fallback) {
						fallback.classList.remove("is-loading");
						fallback.classList.add("is-loaded");
					}
					task.cell.dataset.meshLoaded = "1";
				} else {
					el.dataset.meshStuck = "1";
				}
				self.active -= 1;
				setTimeout(function () { self.tick(); }, MESH_QUEUE_GAP_MS);
			};
			const obs = new MutationObserver(function () {
				if (el.querySelector("canvas")) finish(true);
				else if (el.childElementCount === 0) finish(false);
			});
			obs.observe(el, { childList: true });
			const watchdog = setTimeout(function () { finish(false); }, MESH_QUEUE_TIMEOUT_MS);
			el.setAttribute("visual", task.visual);
		}
	};
	function startMerchantMeshRetrySweeps() {
		if (merchantMeshRetryTimer) return;
		merchantMeshRetryTimer = setInterval(function () {
			if (!root || root.style.display === "none") return;
			root.querySelectorAll(".merchant-item__fallback.is-loading").forEach(function (fallback) {
				const cell = fallback.parentElement;
				if (!cell || cell.dataset.meshLoaded === "1") return;
				if (cell.querySelector("gothic-render canvas")) {
					fallback.classList.remove("is-loading");
					fallback.classList.add("is-loaded");
					cell.dataset.meshLoaded = "1";
					return;
				}
				const visual = cell.dataset.visual || "";
				if (!visual) return;
				const old = cell.querySelector("gothic-render[data-mesh-stuck='1']");
				if (old) { try { old.remove(); } catch (e) {} }
				merchantMeshQueue.schedule(cell, visual);
			});
		}, MESH_RETRY_INTERVAL_MS);
	}
	function stopMerchantMeshRetrySweeps() {
		if (merchantMeshRetryTimer) { clearInterval(merchantMeshRetryTimer); merchantMeshRetryTimer = null; }
	}
	function lang() { return (I18n && I18n.getLang && I18n.getLang()) || "pl"; }
	function t(key, fallback) {
		if (!I18n || typeof I18n.t !== "function") return fallback || key;
		const value = I18n.t(key);
		return value === key && fallback ? fallback : value;
	}
	function line(group) { return t(pick(lineKeys[group] || []), ""); }
	function itemName(instance) { return I18n && I18n.tItem ? I18n.tItem(instance, "name", instance) : instance; }
	function esc(value) { return String(value == null ? "" : value).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c])); }
	function pick(list) { return list[Math.floor(Math.random() * list.length)] || ""; }
	function isWeaponSkill(skill) { return skill === "oneHand" || skill === "twoHand" || skill === "bow" || skill === "crossbow"; }
	function parseWeaponProgress(raw) {
		const out = {};
		if (!raw) return out;
		String(raw).split(",").forEach(function (part) {
			const p = part.split("|");
			if (p.length < 5) return;
			out[p[0]] = { level: +(p[1] || 0), cap: +(p[4] || 30) };
		});
		return out;
	}
	function teacherCost(skill, d, progress) {
		if (!isWeaponSkill(skill)) return d.cost;
		const item = progress[skill] || { level: 0, cap: 30 };
		if (item.cap >= 100) return t("stats.weaponState.max", "MAX");
		if (item.level < item.cap) return item.level + "/" + item.cap;
		return (item.cap === 30 ? 30 : 60) + " " + t("stats.learnPoints.short", "PN");
	}
	function parseMerchantItems(raw, player) {
		if (!raw) return [];
		return String(raw).split(",").map(function (part) {
			const fields = part.split("|");
			if (player) return { id: +(fields[0] || 0), instance: fields[1] || "", amount: +(fields[2] || 0), value: +(fields[3] || 0), visual: fields[4] || "", category: +(fields[5] || 0), slot: +(fields[6] || 0), quality: +(fields[7] || 2), upgrade: +(fields[8] || 0) };
			return { instance: fields[0] || "", amount: +(fields[1] || 0), value: +(fields[2] || 0), visual: fields[3] || "", category: +(fields[4] || 0), slot: +(fields[5] || 0) };
		}).filter(function (it) { return it.instance && it.amount > 0; });
	}
	function shell(titleKey) {
		root.innerHTML = '<div class="teacher-panel"><header class="teacher-panel__head"><button type="button" class="phoenix-exit-btn" data-action="close" title="ESC" aria-label="close">x</button><h1 class="teacher-panel__title" data-t="' + titleKey + '"></h1><p class="teacher-panel__subtitle" data-role="npcName"></p></header><section class="teacher-panel__body" data-role="body"></section><footer class="teacher-panel__foot"><span class="teacher-panel__error" data-role="error"></span></footer></div>';
		if (I18n) I18n.applyDom(root);
		const name = root.querySelector("[data-role='npcName']");
		if (name) name.textContent = state.npcName || "";
	}
	function emitStage() {
		if (!dialogStage.active || !dialogStage.stages[dialogStage.index]) return;
		try { PhoenixBridge.send("phoenix:npc:dialogStage", { speaker: dialogStage.stages[dialogStage.index].speaker }); } catch (e) {}
	}
	function renderDialogStage() {
		if (!dialogStage.active) return;
		const stage = dialogStage.stages[dialogStage.index];
		const showOptions = !stage;
		let html = '<div class="npc-cinematic-dialog"><button type="button" class="phoenix-exit-btn npc-cinematic-dialog__close" data-action="close" title="ESC" aria-label="close">x</button><section class="npc-cinematic-dialog__speech">';
		if (showOptions) {
			html += '<span class="npc-cinematic-dialog__name">' + esc(state.npcName || "") + '</span><p data-t="npc.dialog.choose"></p>';
		} else {
			html += '<span class="npc-cinematic-dialog__name">' + esc(stage.speaker === "player" ? t("character.hero", "Ty") : (state.npcName || "")) + '</span><p>' + esc(stage.text) + '</p><small>' + esc(t("npc.dialog.nextHint", "Space / LPM")) + '</small>';
		}
		html += '</section><section class="npc-cinematic-dialog__options' + (showOptions ? ' is-visible' : '') + '">';
		if (showOptions) {
			const data = dialogStage.data || {};
			if (data.hasMerchant) html += '<button type="button" class="teacher-row" data-action="merchant"><span data-t="npc.dialog.trade"></span></button>';
			if (data.hasTeacher) html += '<button type="button" class="teacher-row" data-action="teacher"><span data-t="npc.dialog.learn"></span></button>';
			html += '<button type="button" class="teacher-row teacher-row--muted" data-action="close"><span data-t="npc.dialog.leave"></span></button>';
		}
		html += '</section></div>';
		root.innerHTML = html;
		if (I18n) I18n.applyDom(root);
		if (!showOptions) emitStage();
	}
	function advanceDialog() {
		if (!dialogStage.active) return false;
		if (!dialogStage.stages[dialogStage.index]) return false;
		dialogStage.index += 1;
		renderDialogStage();
		return true;
	}
	function renderDialog(data) {
		state = { mode: "dialog", npcName: data.npcName || "", items: [], playerItems: [], playerGold: 0 };
		dialogStage = { active: true, index: 0, data: data, stages: [
			{ speaker: "player", text: line("player") },
			{ speaker: "npc", text: line("npc") }
		] };
		renderDialogStage();
	}
	function renderTeacher(d) {
		dialogStage.active = false;
		state.mode = "teacher";
		state.npcName = d.npcName || state.npcName;
		shell("teacher.title");
		const skills = (d.skills || "").split(",").map(s => s.trim()).filter(Boolean);
		const progress = parseWeaponProgress(d.weaponProgress || "");
		let html = '<section class="teacher-panel__info"><span>' + esc(t("teacher.cost", "Koszt")) + ': <strong>' + d.cost + '</strong></span><span>' + esc(t("stats.gold", "Zloto")) + ': <strong>' + d.playerGold + '</strong></span><span>' + esc(t("stats.learnPoints", "PN")) + ': <strong>' + d.playerLearnPoints + '</strong></span></section><section class="teacher-panel__list">';
		html += skills.map(function (skill) { return '<button type="button" class="teacher-row" data-action="train" data-skill="' + esc(skill) + '"><span>' + esc(t(skillLabels[skill] || skill, skill)) + '</span><span class="teacher-row__cost">' + esc(teacherCost(skill, d, progress)) + '</span></button>'; }).join("");
		html += '</section><button type="button" class="teacher-row teacher-row--muted" data-action="back"><span data-t="npc.dialog.back"></span></button>';
		root.querySelector("[data-role='body']").innerHTML = html;
		if (I18n) I18n.applyDom(root);
	}
	function renderMerchantVisual(item) {
		const cls = item.visual ? "merchant-item__fallback is-loading" : "merchant-item__fallback";
		return '<div class="' + cls + '"><span>' + esc(itemName(item.instance).slice(0, 14)) + '</span></div>';
	}

	function merchantCell(item, mode, index) {
		const price = mode === "buy" ? item.value : Math.floor(item.value * 0.3);
		return '<div role="button" tabindex="0" class="merchant-item" data-action="merchant-pick" data-mode="' + mode + '" data-index="' + index + '" data-visual="' + esc(item.visual || "") + '">' +
			'<span class="merchant-item__amount">x' + item.amount + '</span>' +
			renderMerchantVisual(item) +
			'<span class="merchant-item__name">' + esc(itemName(item.instance)) + '</span>' +
			'<span class="merchant-item__price">' + price + ' ' + esc(t("inv.unit.gold", "zl")) + '</span>' +
		'</div>';
	}

	function merchantGrid(items, mode, emptyKey) {
		let html = '<div class="merchant-grid">';
		if (items.length) html += items.map(function (item, index) { return merchantCell(item, mode, index); }).join("");
		else html += '<div class="teacher-empty" data-t="' + emptyKey + '"></div>';
		return html + '</div>';
	}

	function renderMerchant(d) {
		merchantMeshQueue.reset();
		dialogStage.active = false;
		state.mode = "merchant";
		state.npcName = d.npcName || state.npcName;
		state.items = parseMerchantItems(d.items, false);
		state.playerItems = parseMerchantItems(d.playerItems, true);
		state.playerGold = d.playerGold || 0;
		let html = '<div class="merchant-screen">';
		html += '<section class="merchant-panel merchant-panel--npc"><header class="merchant-panel__head"><h2>' + esc(state.npcName || t("merchant.title", "Handlarz")) + '</h2><span data-t="merchant.buy"></span></header>' + merchantGrid(state.items, "buy", "merchant.empty") + '</section>';
		html += '<section class="merchant-panel merchant-panel--player"><header class="merchant-panel__head"><button type="button" class="phoenix-exit-btn" data-action="close" title="ESC" aria-label="close">x</button><h2 data-t="merchant.sell"></h2><span>' + esc(t("stats.gold", "Zloto")) + ': <strong>' + state.playerGold + '</strong> / ' + esc(t("merchant.sellRate", "Skup")) + ': <strong>30%</strong></span></header>' + merchantGrid(state.playerItems, "sell", "merchant.noItems") + '<button type="button" class="teacher-row teacher-row--muted merchant-panel__back" data-action="back"><span data-t="npc.dialog.back"></span></button></section>';
		html += '<div class="merchant-modal" data-role="merchant-modal"></div></div>';
		root.innerHTML = html;
		if (I18n) I18n.applyDom(root);
		scheduleMerchantMeshes();
		startMerchantMeshRetrySweeps();
	}

	function scheduleMerchantMeshes() {
		root.querySelectorAll(".merchant-item[data-visual]").forEach(function (cell) {
			const visual = cell.dataset.visual || "";
			if (!visual) return;
			merchantMeshQueue.schedule(cell, visual);
		});
	}

	function money(value) { return value + " " + t("inv.unit.gold", "zl"); }

	function tradeModalData() {
		if (!merchantModal) return null;
		const mode = merchantModal.dataset.mode || "";
		const index = +(merchantModal.dataset.index || 0);
		const item = mode === "buy" ? state.items[index] : state.playerItems[index];
		if (!item) return null;
		const max = Math.max(1, item.amount || 1);
		let amount = Math.max(1, +(merchantModal.querySelector("[data-role='merchant-amount']") || {}).value || 1);
		if (amount > max) amount = max;
		const single = mode === "buy" ? item.value : Math.floor(item.value * 0.3);
		const total = single * amount;
		return { mode: mode, index: index, item: item, amount: amount, single: single, total: total };
	}

	function renderMerchantModalBody() {
		const data = tradeModalData();
		if (!data || !merchantModal) return;
		const input = merchantModal.querySelector("[data-role='merchant-amount']");
		if (input && +input.value !== data.amount) input.value = data.amount;
		const total = merchantModal.querySelector("[data-role='merchant-total']");
		if (total) total.textContent = money(data.total);
		const single = merchantModal.querySelector("[data-role='merchant-single']");
		if (single) single.textContent = money(data.single);
		const button = merchantModal.querySelector("[data-action='merchant-confirm']");
		if (button) {
			button.textContent = data.mode === "buy" ? t("merchant.buy", "Kup") : t("merchant.sell", "Sprzedaj");
			button.disabled = data.mode === "buy" && data.total > state.playerGold;
		}
		const gold = merchantModal.querySelector("[data-role='merchant-gold-check']");
		if (gold) gold.textContent = data.mode === "buy" && data.total > state.playerGold ? t("merchant.error.noGold", "Za malo zlota") : "";
	}

	function openMerchantModal(target) {
		if (!target) return;
		const mode = target.dataset.mode;
		const index = +(target.dataset.index || 0);
		const item = mode === "buy" ? state.items[index] : state.playerItems[index];
		if (!item) return;
		merchantModal = root.querySelector("[data-role='merchant-modal']");
		if (!merchantModal) return;
		merchantModal.dataset.mode = mode;
		merchantModal.dataset.index = index;
		const action = mode === "buy" ? t("merchant.buy", "Kup") : t("merchant.sell", "Sprzedaj");
		merchantModal.innerHTML = '<div class="merchant-modal__box"><button type="button" class="phoenix-exit-btn merchant-modal__close" data-action="merchant-close" title="ESC" aria-label="close">x</button><div class="merchant-modal__eyebrow">' + esc(action) + '</div><div class="merchant-modal__name">' + esc(itemName(item.instance)) + '</div><div class="merchant-modal__meta">' + esc(item.instance) + '</div><label class="merchant-modal__label">' + esc(t("admin.items.amount", "Ilosc")) + '</label><input class="merchant-modal__amount" type="number" min="1" max="' + Math.max(1, item.amount || 1) + '" value="1" data-role="merchant-amount"><div class="merchant-modal__prices"><span>' + esc(t("merchant.priceOne", "Sztuka")) + ': <strong data-role="merchant-single"></strong></span><span>' + esc(t("merchant.total", "Razem")) + ': <strong data-role="merchant-total"></strong></span></div><div class="merchant-modal__error" data-role="merchant-gold-check"></div><div class="merchant-modal__actions"><button type="button" class="teacher-row teacher-row--muted" data-action="merchant-close"><span>' + esc(t("npc.dialog.back", "Wroc")) + '</span></button><button type="button" class="teacher-row" data-action="merchant-confirm"><span>' + esc(action) + '</span></button></div></div>';
		merchantModal.classList.add("is-visible");
		renderMerchantModalBody();
		const input = merchantModal.querySelector("[data-role='merchant-amount']");
		if (input) { input.focus(); input.select(); }
	}

	function handleMerchantPick(target) {
		if (!target) return;
		const key = (target.dataset.mode || "") + ":" + (target.dataset.index || "");
		const now = Date.now();
		if (lastMerchantPick.key === key && now - lastMerchantPick.at <= 450) {
			lastMerchantPick.key = "";
			lastMerchantPick.at = 0;
			openMerchantModal(target);
			return;
		}
		lastMerchantPick.key = key;
		lastMerchantPick.at = now;
	}

	function closeMerchantModal() {
		if (merchantModal) merchantModal.classList.remove("is-visible");
	}

	function commitMerchant() {
		const data = tradeModalData();
		if (!data) return;
		const mode = data.mode;
		const item = data.item;
		const amount = data.amount;
		if (mode === "buy" && data.total > state.playerGold) return;
		if (mode === "buy") PhoenixBridge.send("phoenix:merchant:trade", { mode: "buy", instance: item.instance, amount: amount });
		else PhoenixBridge.send("phoenix:merchant:trade", { mode: "sell", itemId: item.id, amount: amount });
		closeMerchantModal();
	}

	function result(eventName, payload) {
		const error = root.querySelector("[data-role='error']");
		if (!error || !payload) return;
		if (payload.success) error.textContent = t(eventName + ".success", "OK");
		else error.textContent = t(eventName + ".error." + (payload.error || "internal"), payload.error || "error");
	}
	root.addEventListener("click", function (event) {
		const target = event.target.closest("[data-action]");
		if (!target && advanceDialog()) return;
		if (!target) return;
		const action = target.dataset.action;
		if (action === "close") PhoenixBridge.send("phoenix:teacher:close", null);
		else if (action === "teacher" || action === "merchant" || action === "back") PhoenixBridge.send("phoenix:npc:dialogAction", { action: action === "back" ? "root" : action });
		else if (action === "train") PhoenixBridge.send("phoenix:teacher:train", { skill: target.dataset.skill });
		else if (action === "merchant-close") closeMerchantModal();
		else if (action === "merchant-confirm") commitMerchant();
		else if (action === "merchant-pick") handleMerchantPick(target);
	});
	root.addEventListener("dblclick", function (event) {
		const target = event.target.closest("[data-action='merchant-pick']");
		if (target) { lastMerchantPick.key = ""; lastMerchantPick.at = 0; openMerchantModal(target); }
	});
	root.addEventListener("input", function (event) {
		if (event.target.closest("[data-role='merchant-amount']")) renderMerchantModalBody();
	});
	root.addEventListener("keydown", function (event) {
		if (event.key === "Enter" && event.target.closest("[data-role='merchant-amount']")) {
			event.preventDefault();
			commitMerchant();
		}
		if (event.key === "Escape" && merchantModal && merchantModal.classList.contains("is-visible")) {
			event.preventDefault();
			closeMerchantModal();
		}
	});
	document.addEventListener("keydown", function (event) {
		if (event.code !== "Space" && event.key !== " ") return;
		if (advanceDialog()) {
			event.preventDefault();
			event.stopPropagation();
		}
	});
	PhoenixBridge.on("phoenix:npc:dialog", renderDialog);
	PhoenixBridge.on("phoenix:teacher:dialog", renderTeacher);
	PhoenixBridge.on("phoenix:teacher:result", function (payload) { result("teacher", payload); });
	PhoenixBridge.on("phoenix:merchant:dialog", renderMerchant);
	PhoenixBridge.on("phoenix:merchant:result", function (payload) { result("merchant", payload); });
	if (window.phoenixApp) window.phoenixApp.register("teacher", {
		onShow: function () { if (window.PhoenixHud && window.PhoenixHud.setBlocked) window.PhoenixHud.setBlocked(true); },
		onHide: function () { stopMerchantMeshRetrySweeps(); merchantMeshQueue.reset(); if (window.PhoenixHud && window.PhoenixHud.setBlocked) window.PhoenixHud.setBlocked(false); }
	});
})();
