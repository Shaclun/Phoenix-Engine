(function () {
	const HOTBAR_SLOTS = 8;
	const STORAGE_KEY = "phoenix:hotbar:v1";
	const HOTBAR_RENDER = { rotX: "1.584", rotY: "-1.662", rotZ: "-0.488", scale: "1.35", light: "2.6" };

	const state = {
		visible: false,
		hotbar: new Array(HOTBAR_SLOTS).fill(null),
		items: [],
		level: 1,
		expNext: 500
	};

	let nodes = null;
	let targetNodes = null;
	let knockdownNodes = null;
	let herbNodes = null;
	let weaponNodes = null;
	let knockdownInterval = null;
	let herbTimer = null;
	let herbRunId = 0;
	let weaponHideTimer = null;

	function t(key, fallback) {
		if (!window.PhoenixI18n || typeof PhoenixI18n.t !== "function") return fallback || key;
		const value = PhoenixI18n.t(key);
		return value === key && fallback ? fallback : value;
	}

	function countdownText(seconds) {
		return t("player.knockdown.respawnCountdown", "Respawn choice in {0}s").replace("{0}", '<span data-role="seconds">' + String(seconds) + '</span>');
	}

	function fmt(cur, max) { return Math.max(0, cur | 0) + " / " + Math.max(0, max | 0); }

	function pct(cur, max) {
		max = max | 0;
		if (max <= 0) return 0;
		const v = Math.max(0, Math.min(1, cur / max));
		return Math.round(v * 1000) / 10;
	}

	function buildHud() {
		if (nodes) return nodes;
		const root = document.createElement("div");
		root.className = "phoenix-hud";
		root.id = "phoenix-hud";
		root.innerHTML =
			'<div class="phoenix-hud__name" data-role="name">—</div>' +
			'<div class="phoenix-hud__level" data-role="level">Lv 1</div>' +
			'<div class="phoenix-hud__bars">' +
				'<div class="phoenix-hud__bar phoenix-hud__bar--hp"><div class="phoenix-hud__bar-fill" data-role="hpFill"></div><div class="phoenix-hud__bar-label" data-role="hpLabel">0 / 0</div></div>' +
				'<div class="phoenix-hud__bar phoenix-hud__bar--mana"><div class="phoenix-hud__bar-fill" data-role="manaFill"></div><div class="phoenix-hud__bar-label" data-role="manaLabel">0 / 0</div></div>' +
				'<div class="phoenix-hud__bar phoenix-hud__bar--stamina"><div class="phoenix-hud__bar-fill" data-role="stamFill"></div><div class="phoenix-hud__bar-label" data-role="stamLabel">0 / 0</div></div>' +
			'</div>' +
			'<div class="phoenix-hud__exp"><div class="phoenix-hud__exp-fill" data-role="expFill"></div></div>' +
			'<div class="phoenix-hud__hotbar" data-role="hotbar"></div>';
		document.body.appendChild(root);

		const hotbar = root.querySelector('[data-role="hotbar"]');
		for (let i = 0; i < HOTBAR_SLOTS; i++) {
			const slot = document.createElement("div");
			slot.className = "phoenix-hud__slot";
			slot.dataset.slot = String(i);
			slot.innerHTML =
				'<span class="phoenix-hud__slot-key">' + (i + 1) + '</span>' +
				'<div class="phoenix-hud__slot-icon" data-role="icon"></div>' +
				'<span class="phoenix-hud__slot-count" data-role="count"></span>' +
				'<span class="phoenix-hud__slot-name" data-role="name"></span>';
			slot.addEventListener("dragover", function (e) {
				if (e.dataTransfer && (e.dataTransfer.types || []).indexOf("text/phoenix-item") !== -1) {
					e.preventDefault();
					slot.classList.add("is-dragover");
				}
			});
			slot.addEventListener("dragleave", function () { slot.classList.remove("is-dragover"); });
			slot.addEventListener("drop", function (e) {
				slot.classList.remove("is-dragover");
				if (!e.dataTransfer) return;
				const raw = e.dataTransfer.getData("text/phoenix-item");
				if (!raw) return;
				e.preventDefault();
				try {
					const data = JSON.parse(raw);
					assignSlot(i, data);
				} catch (err) {}
			});
			slot.addEventListener("contextmenu", function (e) {
				e.preventDefault();
				clearSlot(i);
			});
			slot.addEventListener("click", function () { useSlot(i); });
			hotbar.appendChild(slot);
		}

		nodes = {
			root: root,
			name: root.querySelector('[data-role="name"]'),
			level: root.querySelector('[data-role="level"]'),
			hpFill: root.querySelector('[data-role="hpFill"]'),
			hpLabel: root.querySelector('[data-role="hpLabel"]'),
			manaFill: root.querySelector('[data-role="manaFill"]'),
			manaLabel: root.querySelector('[data-role="manaLabel"]'),
			stamFill: root.querySelector('[data-role="stamFill"]'),
			stamLabel: root.querySelector('[data-role="stamLabel"]'),
			expFill: root.querySelector('[data-role="expFill"]'),
			hotbar: hotbar
		};
		return nodes;
	}

	function buildTargetHud() {
		if (targetNodes) return targetNodes;
		const root = document.createElement("div");
		root.className = "phoenix-target-hud";
		root.id = "phoenix-target-hud";
		root.innerHTML =
			'<div class="phoenix-target-hud__name" data-role="name">—</div>' +
			'<div class="phoenix-target-hud__level" data-role="level">Lv 1</div>' +
			'<div class="phoenix-target-hud__bar phoenix-target-hud__bar--hp"><div class="phoenix-target-hud__bar-fill" data-role="hpFill"></div></div>' +
			'<div class="phoenix-target-hud__bar phoenix-target-hud__bar--mana"><div class="phoenix-target-hud__bar-fill" data-role="manaFill"></div></div>';
		document.body.appendChild(root);
		targetNodes = {
			root: root,
			name: root.querySelector('[data-role="name"]'),
			level: root.querySelector('[data-role="level"]'),
			hpFill: root.querySelector('[data-role="hpFill"]'),
			manaFill: root.querySelector('[data-role="manaFill"]')
		};
		return targetNodes;
	}

	function buildKnockdown() {
		if (knockdownNodes) return knockdownNodes;
		const root = document.createElement("div");
		root.className = "phoenix-knockdown";
		root.id = "phoenix-knockdown";
		root.innerHTML =
			'<div class="phoenix-knockdown__inner">' +
				'<div class="phoenix-knockdown__title">' + t("player.knockdown.title", "Unconscious") + '</div>' +
				'<div class="phoenix-knockdown__sub" data-role="sub">' + countdownText(10) + '</div>' +
				'<div class="phoenix-knockdown__choices" data-role="choices">' +
					'<button type="button" class="phoenix-knockdown__btn" data-mode="here">' + t("player.knockdown.respawnHere", "Respawn here") + '</button>' +
					'<button type="button" class="phoenix-knockdown__btn phoenix-knockdown__btn--primary" data-mode="spawn">' + t("player.knockdown.respawnSpawn", "Respawn at spawn") + '</button>' +
				'</div>' +
			'</div>';
		document.body.appendChild(root);
		root.querySelectorAll("[data-mode]").forEach(function (button) {
			button.addEventListener("click", function () {
				if (button.disabled) return;
				root.querySelectorAll("[data-mode]").forEach(function (item) { item.disabled = true; });
				if (window.PhoenixBridge) PhoenixBridge.send("phoenix:player:respawnChoice", { mode: button.dataset.mode || "here" });
			});
		});
		knockdownNodes = {
			root: root,
			seconds: root.querySelector('[data-role="seconds"]'),
			sub: root.querySelector('[data-role="sub"]'),
			choices: root.querySelector('[data-role="choices"]')
		};
		return knockdownNodes;
	}

	function buildHerbProgress() {
		if (herbNodes) return herbNodes;
		const root = document.createElement("div");
		root.className = "phoenix-herb-progress";
		root.innerHTML =
			'<div class="phoenix-herb-progress__label" data-role="label"></div>' +
			'<div class="phoenix-herb-progress__bar"><div class="phoenix-herb-progress__fill" data-role="fill"></div></div>' +
			'<div class="phoenix-herb-progress__state" data-role="state"></div>';
		document.body.appendChild(root);
		herbNodes = {
			root: root,
			label: root.querySelector('[data-role="label"]'),
			fill: root.querySelector('[data-role="fill"]'),
			state: root.querySelector('[data-role="state"]')
		};
		return herbNodes;
	}

	function buildWeaponProgress() {
		if (weaponNodes) return weaponNodes;
		const root = document.createElement("div");
		root.className = "phoenix-weapon-progress";
		root.innerHTML =
			'<div class="phoenix-weapon-progress__top">' +
				'<span class="phoenix-weapon-progress__name" data-role="name"></span>' +
				'<strong class="phoenix-weapon-progress__level" data-role="level"></strong>' +
			'</div>' +
			'<div class="phoenix-weapon-progress__bar"><div class="phoenix-weapon-progress__fill" data-role="fill"></div></div>' +
			'<div class="phoenix-weapon-progress__meta"><span data-role="xp"></span><span data-role="cap"></span></div>';
		document.body.appendChild(root);
		weaponNodes = {
			root: root,
			name: root.querySelector('[data-role="name"]'),
			level: root.querySelector('[data-role="level"]'),
			fill: root.querySelector('[data-role="fill"]'),
			xp: root.querySelector('[data-role="xp"]'),
			cap: root.querySelector('[data-role="cap"]')
		};
		return weaponNodes;
	}

	function weaponXpToNext(level) {
		const value = Math.max(0, parseInt(level, 10) || 0);
		if (value >= 100) return 0;
		return 20 + value * value * 3;
	}

	function parseWeaponProgress(raw) {
		const out = {};
		["oneHand", "twoHand", "bow", "crossbow"].forEach(function (key) {
			out[key] = { level: 0, xp: 0, xpNext: 20, cap: 30 };
		});
		if (!raw) return out;
		String(raw).split(",").forEach(function (part) {
			const bits = part.split("|");
			if (bits.length < 5 || !out[bits[0]]) return;
			const level = parseInt(bits[1], 10) || 0;
			const cap = parseInt(bits[4], 10) || 30;
			let xpNext = parseInt(bits[3], 10) || 0;
			if (xpNext <= 0 && level < cap) xpNext = weaponXpToNext(level);
			out[bits[0]] = { level: level, xp: parseInt(bits[2], 10) || 0, xpNext: xpNext, cap: cap };
		});
		return out;
	}

	function applyWeapon(payload) {
		buildWeaponProgress();
		if (!payload || !payload.active || blocked) {
			weaponNodes.root.classList.remove("is-notify", "is-updated");
			weaponNodes.root.classList.add("is-hiding");
			if (weaponHideTimer) clearTimeout(weaponHideTimer);
			weaponHideTimer = setTimeout(function () {
				if (!weaponNodes) return;
				weaponNodes.root.classList.remove("is-visible", "is-hiding", "is-capped");
			}, 360);
			return;
		}
		if (weaponHideTimer) { clearTimeout(weaponHideTimer); weaponHideTimer = null; }
		const key = payload.key || "";
		const progress = parseWeaponProgress(payload.weaponProgress || "");
		const item = progress[key] || { level: 0, xp: 0, xpNext: 20, cap: 30 };
		const capped = item.level >= item.cap;
		const percent = capped ? 100 : pct(item.xp, item.xpNext || weaponXpToNext(item.level));
		weaponNodes.name.textContent = payload.label || key;
		weaponNodes.level.textContent = "Lv " + item.level;
		weaponNodes.fill.style.width = percent + "%";
		weaponNodes.xp.textContent = capped ? t("stats.weaponState.capShort", "cap") : item.xp + " / " + (item.xpNext || weaponXpToNext(item.level));
		weaponNodes.cap.textContent = item.cap >= 100 ? t("stats.weaponState.max", "MAX") : t("stats.weaponState.capShort", "cap") + " " + item.cap;
		weaponNodes.root.classList.toggle("is-capped", capped && item.cap < 100);
		weaponNodes.root.classList.remove("is-hiding");
		weaponNodes.root.classList.add("is-visible");
		if (payload.changed) {
			weaponNodes.root.classList.remove("is-notify");
			void weaponNodes.root.offsetWidth;
			weaponNodes.root.classList.add("is-notify");
		}
		if (payload.updated) {
			weaponNodes.root.classList.remove("is-updated");
			void weaponNodes.root.offsetWidth;
			weaponNodes.root.classList.add("is-updated");
		}
	}

	function applySnapshot(payload) {
		buildHud();
		state.level = payload.level | 0;
		state.expNext = payload.experienceNext | 0;
		state.weaponProgress = payload.weaponProgress || "";
		nodes.name.textContent = payload.name || "—";
		nodes.level.textContent = "Lv " + (payload.level | 0);
		nodes.hpFill.style.width = pct(payload.hp, payload.hpMax) + "%";
		nodes.hpLabel.textContent = fmt(payload.hp, payload.hpMax);
		nodes.manaFill.style.width = pct(payload.mana, payload.manaMax) + "%";
		nodes.manaLabel.textContent = fmt(payload.mana, payload.manaMax);
		nodes.stamFill.style.width = pct(payload.stamina, payload.staminaMax) + "%";
		nodes.stamLabel.textContent = fmt(payload.stamina, payload.staminaMax);
		const expCur = payload.experience | 0;
		const expCap = (payload.experienceNext | 0) || 1;
		nodes.expFill.style.width = pct(expCur, expCap) + "%";
		show();
	}

	function applyTarget(payload) {
		buildTargetHud();
		if (!payload || blocked) {
			targetNodes.root.classList.remove("is-visible");
			return;
		}
		targetNodes.name.textContent = payload.name || "?";
		targetNodes.level.textContent = "Lv " + (payload.level | 0);
		targetNodes.hpFill.style.width = pct(payload.hp, payload.hpMax) + "%";
		const manaMax = payload.manaMax | 0;
		if (manaMax > 0) {
			targetNodes.manaFill.parentElement.style.display = "";
			targetNodes.manaFill.style.width = pct(payload.mana, payload.manaMax) + "%";
		} else {
			targetNodes.manaFill.parentElement.style.display = "none";
		}
		targetNodes.root.classList.add("is-visible");
	}

	function show() {
		buildHud();
		state.visible = true;
		nodes.root.classList.add("is-visible");
		renderHotbar();
	}

	function hide() {
		state.visible = false;
		if (nodes) nodes.root.classList.remove("is-visible");
		if (targetNodes) targetNodes.root.classList.remove("is-visible");
		if (weaponNodes) weaponNodes.root.classList.remove("is-visible", "is-hiding", "is-notify", "is-updated");
		if (knockdownNodes) knockdownNodes.root.classList.remove("is-visible");
		if (herbNodes) herbNodes.root.classList.remove("is-visible");
		if (knockdownInterval) { clearInterval(knockdownInterval); knockdownInterval = null; }
		if (herbTimer) { clearInterval(herbTimer); herbTimer = null; }
	}

	function loadHotbar() {
		try {
			const raw = localStorage.getItem(STORAGE_KEY);
			if (raw) {
				const data = JSON.parse(raw);
				if (Array.isArray(data) && data.length === HOTBAR_SLOTS) {
					state.hotbar = data;
				}
			}
		} catch (e) {}
	}
	function persistHotbar() {
		try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state.hotbar)); } catch (e) {}
	}

	function assignSlot(idx, data) {
		state.hotbar[idx] = { instance: data.instance || "", name: data.name || "", icon: data.icon || "", visual: data.visual || "", category: data.category || 0, onUse: !!data.onUse };
		persistHotbar();
		renderHotbar();
	}
	function clearSlot(idx) {
		state.hotbar[idx] = null;
		persistHotbar();
		renderHotbar();
	}
	function useSlot(idx) {
		const entry = state.hotbar[idx];
		if (!entry || !entry.instance) return;
		PhoenixBridge.send("phoenix:hotbar:use", { slot: idx, instance: entry.instance });
	}

	function hotbarItemFor(entry) {
		let best = null;
		state.items.forEach(function (it) {
			if (!entry || it.instance !== entry.instance) return;
			if (!best) best = it;
			else if (it.equipped) best = it;
		});
		return best;
	}

	function renderHotbarMesh(icon, entry, item) {
		icon.innerHTML = "";
		icon.style.backgroundImage = "";
		const visual = (item && item.visual) || entry.visual || "";
		if (!visual) {
			icon.style.backgroundImage = entry.icon ? "url('" + entry.icon + "')" : "";
			return;
		}
		const fallback = document.createElement("span");
		fallback.className = "phoenix-hud__slot-fallback";
		fallback.textContent = ((item && item.name) || entry.name || entry.instance || "?").slice(0, 2);
		icon.appendChild(fallback);
		const el = document.createElement("gothic-render");
		el.setAttribute("width", "96");
		el.setAttribute("height", "96");
		el.setAttribute("rot-x", HOTBAR_RENDER.rotX);
		el.setAttribute("rot-y", HOTBAR_RENDER.rotY);
		el.setAttribute("rot-z", HOTBAR_RENDER.rotZ);
		el.setAttribute("scale", HOTBAR_RENDER.scale);
		el.setAttribute("light-intensity", HOTBAR_RENDER.light);
		el.setAttribute("visual", visual);
		icon.appendChild(el);
	}

	function renderHotbar() {
		if (!nodes) return;
		const slots = nodes.hotbar.children;
		for (let i = 0; i < HOTBAR_SLOTS; i++) {
			const slot = slots[i];
			const entry = state.hotbar[i];
			const icon = slot.querySelector('[data-role="icon"]');
			const name = slot.querySelector('[data-role="name"]');
			const count = slot.querySelector('[data-role="count"]');
			if (!entry) {
				icon.innerHTML = "";
				icon.style.backgroundImage = "";
				name.textContent = "";
				count.textContent = "";
				continue;
			}
			const item = hotbarItemFor(entry);
			let label = entry.name || entry.instance;
			let qty = 0;
			state.items.forEach(function (it) {
				if (it.instance === entry.instance) qty += (it.amount | 0) || 1;
			});
			if (window.PhoenixI18n && entry.instance) {
				label = window.PhoenixI18n.tItem(entry.instance, "name", label);
			}
			name.textContent = label;
			count.textContent = qty > 1 ? String(qty) : "";
			renderHotbarMesh(icon, entry, item);
		}
	}

	function onKey(e) {
		if (!state.visible) return;
		if (e.target && (e.target.tagName === "INPUT" || e.target.tagName === "TEXTAREA")) return;
		const k = e.key;
		if (k >= "1" && k <= "8") {
			useSlot(parseInt(k, 10) - 1);
		}
	}

	function onInventoryUpdate(payload) {
		if (payload && Array.isArray(payload.items)) {
			state.items = payload.items;
			renderHotbar();
		}
	}

	function onKnockedDown(payload) {
		buildKnockdown();
		const total = (payload && payload.secondsRemaining) ? payload.secondsRemaining | 0 : 10;
		let left = total;
		knockdownNodes.seconds.textContent = String(left);
		knockdownNodes.sub.innerHTML = countdownText(left);
		knockdownNodes.seconds = knockdownNodes.sub.querySelector('[data-role="seconds"]');
		knockdownNodes.choices.classList.remove("is-ready");
		knockdownNodes.root.querySelectorAll("[data-mode]").forEach(function (button) { button.disabled = true; });
		knockdownNodes.root.classList.add("is-visible");
		if (knockdownInterval) clearInterval(knockdownInterval);
		knockdownInterval = setInterval(function () {
			left -= 1;
			if (left <= 0) {
				clearInterval(knockdownInterval);
				knockdownInterval = null;
				knockdownNodes.sub.textContent = t("player.knockdown.chooseLocation", "Choose respawn location");
				knockdownNodes.choices.classList.add("is-ready");
				knockdownNodes.root.querySelectorAll("[data-mode]").forEach(function (button) { button.disabled = false; });
				return;
			}
			knockdownNodes.seconds.textContent = String(left);
		}, 1000);
	}

	function onRevived() {
		if (knockdownInterval) { clearInterval(knockdownInterval); knockdownInterval = null; }
		if (knockdownNodes) knockdownNodes.root.classList.remove("is-visible");
	}

	function onHerbStart(payload) {
		buildHerbProgress();
		herbRunId += 1;
		const runId = herbRunId;
		const total = Math.max(1, (payload && payload.gatherMs) ? payload.gatherMs | 0 : 10000);
		const started = Date.now();
		herbNodes.root.classList.remove("is-cancelled", "is-error", "is-success");
		herbNodes.label.textContent = (payload && payload.label) ? payload.label : tr("herb.defaultLabel");
		herbNodes.state.textContent = tr("herb.progress.gathering");
		herbNodes.fill.style.width = "0%";
		herbNodes.root.classList.add("is-visible");
		if (herbTimer) clearInterval(herbTimer);
		let timerId = null;
		timerId = setInterval(function () {
			if (runId !== herbRunId) {
				clearInterval(timerId);
				if (herbTimer === timerId) herbTimer = null;
				return;
			}
			const pct = Math.max(0, Math.min(1, (Date.now() - started) / total));
			herbNodes.fill.style.width = Math.round(pct * 1000) / 10 + "%";
			if (pct >= 1) {
				clearInterval(timerId);
				if (herbTimer === timerId) herbTimer = null;
			}
		}, 50);
		herbTimer = timerId;
	}

	function onHerbResult(payload) {
		buildHerbProgress();
		herbRunId += 1;
		const runId = herbRunId;
		if (herbTimer) { clearInterval(herbTimer); herbTimer = null; }
		const ok = !!(payload && payload.success);
		const error = payload && payload.error ? String(payload.error) : "failed";
		herbNodes.root.classList.remove("is-cancelled", "is-error", "is-success");
		herbNodes.root.classList.add(ok ? "is-success" : (error === "cancelled" || error === "moved" ? "is-cancelled" : "is-error"));
		if (ok) herbNodes.fill.style.width = "100%";
		else if (error !== "cancelled" && error !== "moved") herbNodes.fill.style.width = "0%";
		if (ok) herbNodes.state.textContent = tr("herb.progress.success");
		else if (error === "cooldown") herbNodes.state.textContent = tr("herb.progress.cooldown");
		else if (error === "moved") herbNodes.state.textContent = tr("herb.progress.moved");
		else if (error === "cancelled") herbNodes.state.textContent = tr("herb.progress.cancelled");
		else herbNodes.state.textContent = tr("herb.progress.failed");
		notifyHerb(payload, ok, error);
		setTimeout(function () { if (herbNodes && runId === herbRunId) herbNodes.root.classList.remove("is-visible"); }, 1600);
	}

	function tr(key) {
		return window.PhoenixI18n ? PhoenixI18n.t(key) : key;
	}

	function notifyHerb(payload, ok, error) {
		if (!window.PhoenixNotify) return;
		const label = payload && payload.label ? payload.label : tr("herb.defaultLabel");
		if (ok) { PhoenixNotify.notify("success", tr("herb.notify.success.title"), label, 3500); return; }
		if (error === "cooldown") {
			const seconds = payload && payload.cooldownSec ? payload.cooldownSec | 0 : 0;
			PhoenixNotify.notify("warn", tr("herb.notify.cooldown.title"), tr("herb.notify.cooldown.text").replace("{seconds}", String(seconds)), 3500);
			return;
		}
		if (error === "cancelled") { PhoenixNotify.notify("warn", tr("herb.notify.cancelled.title"), tr("herb.notify.cancelled.text"), 2500); return; }
		if (error === "moved") { PhoenixNotify.notify("warn", tr("herb.notify.moved.title"), tr("herb.notify.moved.text"), 3000); return; }
		PhoenixNotify.notify("error", tr("herb.notify.failed.title"), label, 3500);
	}

	loadHotbar();

	document.addEventListener("keydown", onKey, true);

	if (window.PhoenixBridge) {
		PhoenixBridge.on("phoenix:hud:snapshot", applySnapshot);
		PhoenixBridge.on("phoenix:hud:weapon", applyWeapon);
		PhoenixBridge.on("phoenix:hud:target", applyTarget);
		PhoenixBridge.on("phoenix:hud:target:clear", function () { applyTarget(null); });
		PhoenixBridge.on("phoenix:player:knockedDown", onKnockedDown);
		PhoenixBridge.on("phoenix:player:revived", onRevived);
		PhoenixBridge.on("phoenix:herb:start", onHerbStart);
		PhoenixBridge.on("phoenix:herb:result", onHerbResult);
		PhoenixBridge.on("phoenix:inventory:update", onInventoryUpdate);
		PhoenixBridge.on("phoenix:item:inventory", onInventoryUpdate);
		PhoenixBridge.on("phoenix:hud:hide", hide);
		PhoenixBridge.on("phoenix:hud:show", show);
	}

	let blocked = false;
	function setBlocked(value) {
		blocked = !!value;
		const hud = document.querySelector(".phoenix-hud");
		if (hud) hud.classList.toggle("is-blocked", blocked);
		const target = document.querySelector(".phoenix-target-hud");
		if (target) target.classList.toggle("is-blocked", blocked);
		const weapon = document.querySelector(".phoenix-weapon-progress");
		if (weapon) weapon.classList.toggle("is-blocked", blocked);
	}

	window.PhoenixHud = {
		show: show, hide: hide,
		applySnapshot: applySnapshot,
		applyTarget: applyTarget,
		applyWeapon: applyWeapon,
		assignSlot: assignSlot,
		clearSlot: clearSlot,
		getSlots: function () { return state.hotbar.slice(); },
		slotOf: function (instance) {
			for (let i = 0; i < HOTBAR_SLOTS; i++) if (state.hotbar[i] && state.hotbar[i].instance === instance) return i;
			return -1;
		},
		setBlocked: setBlocked
	};
})();
