(function () {
	const root = document.getElementById("page-stats");
	if (!root) return;

	const I18n = window.PhoenixI18n;
	const weaponOrder = ["oneHand", "twoHand", "bow", "crossbow"];
	let lastSnapshot = null;

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
		weapons: root.querySelector("[data-role='weapons']")
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

	root.addEventListener("click", function (ev) {
		const target = ev.target.closest("[data-action]");
		if (!target) return;
		if (target.dataset.action === "close") PhoenixBridge.send("phoenix:stats:close", null);
	});

	PhoenixBridge.on("phoenix:stats:snapshot", applySnapshot);
	PhoenixBridge.on("phoenix:stats:result", applyResult);

	const page = {
		onShow: function () {
			PhoenixBridge.send("phoenix:stats:request", null);
			if (I18n) I18n.applyDom(root);
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") window.PhoenixHud.setBlocked(true);
		},
		onHide: function () {
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") window.PhoenixHud.setBlocked(false);
		}
	};
	if (I18n && typeof I18n.onChange === "function") I18n.onChange(function () { if (I18n) I18n.applyDom(root); if (lastSnapshot) applySnapshot(lastSnapshot); });
	if (window.phoenixApp) window.phoenixApp.register("stats", page);
})();