(function () {
	const root = document.getElementById("page-stats");
	if (!root) return;

	const I18n = window.PhoenixI18n;
	const weaponOrder = ["oneHand", "twoHand", "bow", "crossbow"];
	let lastSnapshot = null;
	let lastBestiary = null;
	let activeTab = "stats";

	function t(key, fallback) {
		if (!I18n || typeof I18n.t !== "function") return fallback || key;
		const value = I18n.t(key);
		return value === key && fallback ? fallback : value;
	}

	function fmt(key, value, fallback) {
		return t(key, fallback).replace("{0}", value);
	}

	root.innerHTML =
		'<div class="stats-panel stats-panel--modern">' +
			'<button type="button" class="phoenix-exit-btn stats-panel__close" data-action="close" title="ESC" aria-label="close">x</button>' +
			'<nav class="stats-tabs" data-role="tabs">' +
				'<button type="button" class="stats-tab is-active" data-tab="stats" data-t="stats.tabs.stats">Statystyki</button>' +
				'<button type="button" class="stats-tab" data-tab="bestiary" data-t="stats.tabs.bestiary">Bestiariusz</button>' +
			'</nav>' +
			'<div class="stats-tabview" data-tab="stats">' +
				'<header class="stats-hero">' +
					'<div class="stats-hero__main">' +
						'<span class="stats-kicker" data-t="stats.card"></span>' +
						'<h1 data-t="stats.progressTitle"></h1>' +
						'<div class="stats-level"><strong data-role="level">1</strong><span data-t="stats.levelShort"></span></div>' +
					'</div>' +
					'<div class="stats-exp">' +
						'<div class="stats-exp__top"><span data-t="stats.exp"></span><strong data-role="exp-left">0</strong></div>' +
						'<div class="stats-exp__track"><i data-role="bar-exp"></i></div>' +
						'<div class="stats-exp__bottom"><span data-role="text-exp">0 / 0</span><span data-role="exp-percent">0%</span></div>' +
					'</div>' +
				'</header>' +
				'<section class="stats-summary">' +
					'<div class="stats-chip"><span data-t="stats.learnPoints"></span><strong data-role="learnPoints">0</strong></div>' +
					'<div class="stats-chip"><span data-t="stats.gold"></span><strong data-role="gold">0</strong></div>' +
					'<div class="stats-chip"><span data-t="stats.hp"></span><strong><b data-role="hp">0</b>/<b data-role="hpMax">0</b></strong></div>' +
					'<div class="stats-chip"><span data-t="stats.mana"></span><strong><b data-role="mana">0</b>/<b data-role="manaMax">0</b></strong></div>' +
				'</section>' +
				'<section class="stats-grid">' +
					'<aside class="stats-block stats-block--attributes">' +
						'<div class="stats-block__head"><h2 data-t="stats.section.attributes"></h2><span data-t="stats.section.teachers"></span></div>' +
						'<div class="attribute-list">' +
							'<div class="attribute-row"><span data-t="stats.attr.strength"></span><strong data-role="strength">10</strong></div>' +
							'<div class="attribute-row"><span data-t="stats.attr.dexterity"></span><strong data-role="dexterity">10</strong></div>' +
							'<div class="attribute-row"><span data-t="stats.attr.stamina"></span><strong><b data-role="stamina">0</b>/<b data-role="staminaMax">0</b></strong></div>' +
						'</div>' +
					'</aside>' +
					'<aside class="stats-block stats-block--weapons">' +
						'<div class="stats-block__head"><h2 data-t="stats.section.weapons"></h2><span data-t="stats.section.combatTraining"></span></div>' +
						'<div class="weapon-grid" data-role="weapons"></div>' +
					'</aside>' +
				'</section>' +
				'<footer class="stats-panel__foot"><span class="stats-panel__error" data-role="error"></span></footer>' +
			'</div>' +
			'<div class="stats-tabview" data-tab="bestiary" hidden>' +
				'<header class="bestiary-hero">' +
					'<div class="bestiary-hero__main">' +
						'<span class="stats-kicker" data-t="bestiary.kicker">Księga łowcy</span>' +
						'<h1 data-t="bestiary.title">Bestiariusz</h1>' +
						'<p class="bestiary-sub" data-t="bestiary.sub">Wpisy pojawiają się po pokonaniu istoty.</p>' +
					'</div>' +
					'<div class="bestiary-summary">' +
						'<div class="stats-chip"><span data-t="bestiary.species">Gatunki</span><strong data-role="bestiary-species">0</strong></div>' +
						'<div class="stats-chip"><span data-t="bestiary.totalKills">Zabójstwa</span><strong data-role="bestiary-total">0</strong></div>' +
					'</div>' +
				'</header>' +
				'<section class="bestiary-grid" data-role="bestiary-grid">' +
					'<div class="bestiary-empty" data-role="bestiary-empty" data-t="bestiary.empty">Twój bestiariusz jest pusty. Pokonaj wroga, aby dodać wpis.</div>' +
				'</section>' +
			'</div>' +
		'</div>';
	if (I18n) I18n.applyDom(root);

	const els = {
		level: root.querySelector("[data-role='level']"),
		barExp: root.querySelector("[data-role='bar-exp']"),
		textExp: root.querySelector("[data-role='text-exp']"),
		expLeft: root.querySelector("[data-role='exp-left']"),
		expPercent: root.querySelector("[data-role='exp-percent']"),
		learnPoints: root.querySelector("[data-role='learnPoints']"),
		gold: root.querySelector("[data-role='gold']"),
		error: root.querySelector("[data-role='error']"),
		hp: root.querySelector("[data-role='hp']"),
		hpMax: root.querySelector("[data-role='hpMax']"),
		mana: root.querySelector("[data-role='mana']"),
		manaMax: root.querySelector("[data-role='manaMax']"),
		stamina: root.querySelector("[data-role='stamina']"),
		staminaMax: root.querySelector("[data-role='staminaMax']"),
		strength: root.querySelector("[data-role='strength']"),
		dexterity: root.querySelector("[data-role='dexterity']"),
		weapons: root.querySelector("[data-role='weapons']"),
		tabs: root.querySelectorAll("[data-tab]"),
		bestiaryGrid: root.querySelector("[data-role='bestiary-grid']"),
		bestiaryEmpty: root.querySelector("[data-role='bestiary-empty']"),
		bestiarySpecies: root.querySelector("[data-role='bestiary-species']"),
		bestiaryTotal: root.querySelector("[data-role='bestiary-total']")
	};

	function setText(el, val) { if (el) el.textContent = String(val); }

	function clampPct(current, next) {
		if (!next || next <= 0) return 100;
		return Math.max(0, Math.min(100, Math.round((current / next) * 100)));
	}

	function weaponXpToNext(level) {
		const lv = Math.max(0, parseInt(level, 10) || 0);
		if (lv >= 100) return 0;
		return 20 + lv * lv * 3;
	}

	function parseWeapons(raw, snapshot) {
		const out = {};
		weaponOrder.forEach(function (key) {
			const level = snapshot && snapshot[key] ? parseInt(snapshot[key], 10) || 0 : 0;
			out[key] = { level: level, xp: 0, xpNext: weaponXpToNext(level), cap: level >= 60 ? 100 : (level >= 30 ? 60 : 30) };
		});
		if (!raw) return out;
		raw.split(",").forEach(function (part) {
			const p = part.split("|");
			if (p.length < 5 || !out[p[0]]) return;
			const level = parseInt(p[1], 10) || 0;
			let xpNext = parseInt(p[3], 10) || 0;
			const cap = parseInt(p[4], 10) || 30;
			if (xpNext <= 0 && level < cap) xpNext = weaponXpToNext(level);
			out[p[0]] = {
				level: level,
				xp: parseInt(p[2], 10) || 0,
				xpNext: xpNext,
				cap: cap
			};
		});
		return out;
	}

	function weaponState(item) {
		if (item.cap >= 100 && item.level >= 100) return t("stats.weaponState.max", "MAX");
		if (item.level >= item.cap) return t("stats.weaponState.needsTeacher", "Needs teacher");
		return fmt("stats.weaponState.limit", item.cap, "Limit {0}");
	}

	function weaponCard(key, item) {
		const pct = item.level >= item.cap ? 100 : clampPct(item.xp, item.xpNext);
		const xpText = item.level >= item.cap ? t("stats.weaponState.capShort", "cap") : item.xp + " / " + item.xpNext;
		const locked = item.level >= item.cap && item.cap < 100 ? " weapon-card--locked" : "";
		return '<article class="weapon-card' + locked + '">' +
			'<div class="weapon-card__top"><span>' + t("stats.weapon." + key, key) + '</span><strong>' + item.level + '</strong></div>' +
			'<div class="weapon-card__meta"><span>' + weaponState(item) + '</span><span>' + xpText + '</span></div>' +
			'<div class="weapon-card__track"><i style="width:' + pct + '%"></i></div>' +
		'</article>';
	}

	function renderWeapons(snapshot) {
		const weapons = parseWeapons(snapshot.weaponProgress, snapshot);
		els.weapons.innerHTML = weaponOrder.map(function (key) { return weaponCard(key, weapons[key]); }).join("");
	}

	function applySnapshot(d) {
		if (!d) return;
		lastSnapshot = d;
		const cur = d.experience || 0;
		const next = d.experienceNext || 1;
		const pct = clampPct(cur, next);
		const left = Math.max(0, next - cur);
		if (els.barExp) els.barExp.style.width = pct + "%";
		setText(els.level, d.level || 1);
		setText(els.textExp, cur + " / " + next);
		setText(els.expLeft, fmt("stats.expLeft", left, "{0} to next level"));
		setText(els.expPercent, pct + "%");
		setText(els.learnPoints, d.learnPoints || 0);
		setText(els.gold, d.gold || 0);
		setText(els.hp, d.hp || 0);
		setText(els.hpMax, d.hpMax || 0);
		setText(els.mana, d.mana || 0);
		setText(els.manaMax, d.manaMax || 0);
		setText(els.stamina, d.stamina || 0);
		setText(els.staminaMax, d.staminaMax || 0);
		setText(els.strength, d.strength || 0);
		setText(els.dexterity, d.dexterity || 0);
		setText(els.error, "");
		renderWeapons(d);
	}

	function applyResult(r) {
		if (!r) return;
		setText(els.error, !r.success && r.error ? t("stats.error." + r.error, r.error) : "");
	}

	function npcDisplayLabel(instance, name) {
		const custom = (name || "").trim();
		if (custom && custom.toUpperCase() !== String(instance || "").toUpperCase()) return custom;
		if (window.PhoenixI18n && instance) {
			const direct = PhoenixI18n.t(instance);
			if (direct && direct !== instance) return direct;
		}
		return instance || t("bestiary.unknown", "Nieznany");
	}

	function formatDate(ts) {
		if (!ts || ts <= 0) return "—";
		try {
			const d = new Date(ts * 1000);
			const pad = function (v) { return v < 10 ? "0" + v : String(v); };
			return pad(d.getDate()) + "." + pad(d.getMonth() + 1) + "." + d.getFullYear() + " " + pad(d.getHours()) + ":" + pad(d.getMinutes());
		} catch (e) { return "—"; }
	}

	function bestiaryCard(entry) {
		const instance = entry.instance || "";
		const label = npcDisplayLabel(instance, entry.name);
		const sub = instance && instance !== label ? instance : "";
		const npcVisual = window.PhoenixNpcVisuals ? PhoenixNpcVisuals.get(instance) : "";
		const visual = npcVisual || (entry.visual || "").replace(/\.(MDM|MDL|3DS|MMB|MDS)$/i, function (m) { return m.toUpperCase(); });
		const renderable = visual && /\.(MDM|MRM|MDL|MMB)$/i.test(visual) ? visual : "";
		const killed = entry.killed | 0;
		const first = formatDate(entry.firstKilledAt);
		const last = formatDate(entry.lastKilledAt);
		return '<article class="bestiary-card">' +
			'<div class="bestiary-card__visual">' +
				(renderable
					? '<gothic-render width="160" height="200" rot-x="1.57" rot-y="-1.57" rot-z="0" scale="0.9" light-intensity="2.2" visual="' + renderable + '"></gothic-render>'
					: '<div class="bestiary-card__visual-fallback">' + (label ? label.charAt(0) : "?") + '</div>') +
			'</div>' +
			'<div class="bestiary-card__body">' +
				'<h3 class="bestiary-card__name">' + label + '</h3>' +
				(sub ? '<div class="bestiary-card__sub">' + sub + '</div>' : "") +
				'<div class="bestiary-card__stat"><span data-t="bestiary.kills">Zabójstwa</span><strong>' + killed + '</strong></div>' +
				'<div class="bestiary-card__dates">' +
					'<span><em data-t="bestiary.first">Pierwszy</em>' + first + '</span>' +
					'<span><em data-t="bestiary.last">Ostatni</em>' + last + '</span>' +
				'</div>' +
			'</div>' +
		'</article>';
	}

	function applyBestiary(payload) {
		lastBestiary = payload;
		const entries = payload && Array.isArray(payload.entries) ? payload.entries : [];
		let totalKills = 0;
		entries.forEach(function (e) { totalKills += e.killed | 0; });
		setText(els.bestiarySpecies, entries.length);
		setText(els.bestiaryTotal, totalKills);
		if (entries.length === 0) {
			if (els.bestiaryEmpty) els.bestiaryEmpty.removeAttribute("hidden");
			els.bestiaryGrid.innerHTML = '<div class="bestiary-empty" data-t="bestiary.empty">' + t("bestiary.empty", "Twój bestiariusz jest pusty. Pokonaj wroga, aby dodać wpis.") + '</div>';
			return;
		}
		if (els.bestiaryEmpty) els.bestiaryEmpty.setAttribute("hidden", "");
		els.bestiaryGrid.innerHTML = entries.map(bestiaryCard).join("");
		if (I18n) I18n.applyDom(els.bestiaryGrid);
	}

	function switchTab(tab) {
		activeTab = tab;
		root.querySelectorAll(".stats-tab").forEach(function (btn) {
			btn.classList.toggle("is-active", btn.dataset.tab === tab);
		});
		root.querySelectorAll(".stats-tabview").forEach(function (view) {
			if (view.dataset.tab === tab) view.removeAttribute("hidden");
			else view.setAttribute("hidden", "");
		});
		if (tab === "bestiary") PhoenixBridge.send("phoenix:bestiary:request", null);
	}

	root.addEventListener("click", function (ev) {
		const closeTarget = ev.target.closest("[data-action='close']");
		if (closeTarget) { PhoenixBridge.send("phoenix:stats:close", null); return; }
		const tabTarget = ev.target.closest(".stats-tab");
		if (tabTarget && tabTarget.dataset.tab) { switchTab(tabTarget.dataset.tab); }
	});

	PhoenixBridge.on("phoenix:stats:snapshot", applySnapshot);
	PhoenixBridge.on("phoenix:stats:result", applyResult);
	PhoenixBridge.on("phoenix:bestiary:snapshot", applyBestiary);

	const page = {
		onShow: function () {
			PhoenixBridge.send("phoenix:stats:request", null);
			if (activeTab === "bestiary") PhoenixBridge.send("phoenix:bestiary:request", null);
			if (I18n) I18n.applyDom(root);
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") window.PhoenixHud.setBlocked(true);
		},
		onHide: function () {
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") window.PhoenixHud.setBlocked(false);
		}
	};
	if (I18n && typeof I18n.onChange === "function") I18n.onChange(function () {
		if (I18n) I18n.applyDom(root);
		if (lastSnapshot) applySnapshot(lastSnapshot);
		if (lastBestiary) applyBestiary(lastBestiary);
	});
	if (window.phoenixApp) window.phoenixApp.register("stats", page);
})();
