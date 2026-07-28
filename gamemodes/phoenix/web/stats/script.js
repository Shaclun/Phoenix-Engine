(function () {
	const root = document.getElementById("page-stats");
	if (!root) return;

	const I18n = window.PhoenixI18n;
	const weaponOrder = ["oneHand", "twoHand", "bow", "crossbow"];
	let lastSnapshot = null;
	let lastBestiary = null;
	let lastProfessions = [];
	let bestiaryRenderConfig = {};
	let activeTab = "stats";
	let featureFlags = {};
	const featureDefaults = {
		"progression.leveling": true,
		"progression.statsSpending": true,
		"progression.learnPoints": true,
		"progression.dailyLp": false,
		"progression.weaponExperience": true,
		"progression.magicExperience": true,
		"player.stamina": true,
		"bestiary.enabled": true,
		"professions.enabled": true
	};

	function featureEnabled(path) {
		const parts = path.split(".");
		let value = featureFlags;
		for (let i = 0; i < parts.length; i += 1) {
			if (!value || typeof value !== "object" || !Object.prototype.hasOwnProperty.call(value, parts[i])) return featureDefaults[path] !== false;
			value = value[parts[i]];
		}
		return value !== false;
	}

	function tabEnabled(tab) {
		if (tab === "stats") return featureEnabled("progression.leveling") || featureEnabled("progression.statsSpending") || featureEnabled("progression.dailyLp");
		if (tab === "bestiary") return featureEnabled("bestiary.enabled");
		if (tab === "professions") return featureEnabled("professions.enabled");
		return false;
	}

	function availableTabs() {
		return ["stats", "bestiary", "professions"].filter(tabEnabled);
	}

	function statsPageVisible() {
		return window.phoenixApp && phoenixApp.current() === "stats";
	}

	function applyFeatureFlags(payload) {
		featureFlags = payload && payload.settings && payload.settings.flags && typeof payload.settings.flags === "object" ? payload.settings.flags : {};
		root.querySelectorAll(".stats-tab").forEach(function (node) { node.hidden = !tabEnabled(node.dataset.tab); });
		root.querySelectorAll(".stats-rank").forEach(function (node) { node.hidden = !featureEnabled("progression.leveling"); });
		root.querySelectorAll(".stats-block--attributes").forEach(function (node) { node.hidden = !featureEnabled("progression.statsSpending"); });
		root.querySelectorAll(".stats-block--development").forEach(function (node) { node.hidden = !featureEnabled("progression.dailyLp"); });
		root.querySelectorAll(".stats-chip--points").forEach(function (node) { node.hidden = !featureEnabled("progression.learnPoints"); });
		root.querySelectorAll(".stats-block--weapons").forEach(function (node) { node.hidden = !featureEnabled("progression.weaponExperience"); });
		root.querySelectorAll(".stats-block--magic").forEach(function (node) { node.hidden = !featureEnabled("progression.magicExperience"); });
		const staminaRow = els.stamina && els.stamina.closest(".attribute-row");
		if (staminaRow) staminaRow.hidden = !featureEnabled("player.stamina");
		const tabs = availableTabs();
		if (!tabs.length) {
			if (statsPageVisible()) {
				PhoenixBridge.send("phoenix:stats:close", null);
				phoenixApp.hide();
			}
			return;
		}
		if (!tabEnabled(activeTab)) switchTab(tabs[0], !statsPageVisible());
		else switchTab(activeTab, true);
		if (lastSnapshot && tabEnabled("stats")) applySnapshot(lastSnapshot);
		if (lastBestiary && tabEnabled("bestiary")) applyBestiary(lastBestiary);
		if (tabEnabled("professions")) applyProfessions({ entries: lastProfessions });
	}

	function t(key, fallback) {
		if (!I18n || typeof I18n.t !== "function") return fallback || key;
		const value = I18n.t(key);
		return value === key && fallback ? fallback : value;
	}

	function fmt(key, value, fallback) {
		return t(key, fallback).replace("{0}", value);
	}
	function escapeHtml(value) {
		return String(value == null ? "" : value).replace(/[&<>"']/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]; });
	}

	root.innerHTML =
		'<div class="stats-panel">' +
			'<header class="stats-toolbar">' +
				'<div class="stats-brand">' +
					'<span class="stats-brand__eyebrow" data-t="stats.card">Karta postaci</span>' +
					'<strong class="stats-brand__title" data-t="stats.progressTitle">Rozwój postaci</strong>' +
				'</div>' +
				'<nav class="stats-tabs" data-role="tabs" aria-label="character sections">' +
					'<button type="button" class="stats-tab is-active" data-tab="stats" data-t="stats.tabs.stats">Statystyki</button>' +
					'<button type="button" class="stats-tab" data-tab="bestiary" data-t="stats.tabs.bestiary">Bestiariusz</button>' +
					'<button type="button" class="stats-tab" data-tab="professions" data-t="stats.tabs.professions">Rzemiosła</button>' +
				'</nav>' +
				'<button type="button" class="stats-panel__close" data-action="close" title="ESC" aria-label="close">×</button>' +
			'</header>' +
			'<main class="stats-content">' +
				'<div class="stats-tabview" data-tab="stats">' +
					'<div class="stats-dashboard">' +
						'<section class="stats-pane stats-pane--identity">' +
							'<header class="stats-pane__head"><div><span data-t="stats.card">Karta postaci</span><h1 data-t="stats.progressTitle">Rozwój postaci</h1></div><small data-t="stats.section.teachers"></small></header>' +
							'<div class="stats-rank">' +
								'<div class="stats-level"><span data-t="stats.levelShort">Poziom</span><strong data-role="level">1</strong></div>' +
								'<div class="stats-exp">' +
									'<div class="stats-exp__top"><span data-t="stats.exp">Doświadczenie</span><strong data-role="exp-left">0</strong></div>' +
									'<div class="stats-exp__track"><i data-role="bar-exp"></i></div>' +
									'<div class="stats-exp__bottom"><span data-role="text-exp">0 / 0</span><span data-role="exp-percent">0%</span></div>' +
								'</div>' +
							'</div>' +
							'<div class="stats-summary">' +
								'<div class="stats-chip stats-chip--points"><span data-t="stats.learnPoints"></span><strong data-role="learnPoints">0</strong></div>' +
								'<div class="stats-chip stats-chip--gold"><span data-t="stats.gold"></span><strong data-role="gold">0</strong></div>' +
								'<div class="stats-chip stats-chip--health"><span data-t="stats.hp"></span><strong><b data-role="hp">0</b><em>/</em><b data-role="hpMax">0</b></strong></div>' +
								'<div class="stats-chip stats-chip--mana"><span data-t="stats.mana"></span><strong><b data-role="mana">0</b><em>/</em><b data-role="manaMax">0</b></strong></div>' +
							'</div>' +
							'<div class="stats-block stats-block--development" data-role="development"><div class="stats-block__head"><h2 data-t="development.title"></h2><span data-role="development-next"></span></div><div class="development-meta" data-role="development-meta"></div><div class="development-grid" data-role="development-skills"></div></div>' +
							'<div class="stats-block stats-block--attributes">' +
								'<div class="stats-block__head"><h2 data-t="stats.section.attributes"></h2><span data-t="stats.section.teachers"></span></div>' +
								'<div class="attribute-list">' +
									'<div class="attribute-row"><span data-t="stats.attr.strength"></span><strong data-role="strength">10</strong></div>' +
									'<div class="attribute-row"><span data-t="stats.attr.dexterity"></span><strong data-role="dexterity">10</strong></div>' +
									'<div class="attribute-row"><span data-t="stats.attr.stamina"></span><strong><b data-role="stamina">0</b><em>/</em><b data-role="staminaMax">0</b></strong></div>' +
								'</div>' +
							'</div>' +
						'</section>' +
						'<section class="stats-pane stats-pane--training">' +
							'<header class="stats-pane__head"><div><span data-t="stats.section.combatTraining"></span><h1 data-t="stats.section.weapons"></h1></div></header>' +
							'<div class="stats-block stats-block--weapons">' +
								'<div class="stats-block__head"><h2 data-t="stats.section.weapons"></h2><span data-t="stats.section.combatTraining"></span></div>' +
								'<div class="weapon-grid" data-role="weapons"></div>' +
							'</div>' +
							'<div class="stats-block stats-block--magic">' +
								'<div class="stats-block__head"><h2 data-t="stats.section.magic">Magia</h2><span data-t="stats.section.magicHint">Wbijanie poprzez czary</span></div>' +
								'<article class="weapon-card weapon-card--magic">' +
									'<div class="weapon-card__top"><span data-t="stats.magic.level">Poziom magii</span><strong data-role="magicLevel">0</strong></div>' +
									'<div class="weapon-card__meta"><span data-role="magicCircle"></span><span data-role="magicXpText">0 / 0</span></div>' +
									'<div class="weapon-card__track"><i data-role="magicXpFill" style="width:0%"></i></div>' +
								'</article>' +
							'</div>' +
						'</section>' +
					'</div>' +
					'<footer class="stats-panel__foot"><span class="stats-panel__error" data-role="error"></span></footer>' +
				'</div>' +
				'<div class="stats-tabview" data-tab="bestiary" hidden>' +
					'<header class="stats-view-head">' +
						'<div class="stats-view-head__copy"><span class="stats-kicker" data-t="bestiary.kicker">Księga łowcy</span><h1 data-t="bestiary.title">Bestiariusz</h1><p data-t="bestiary.sub">Wpisy pojawiają się po pokonaniu istoty.</p></div>' +
						'<div class="bestiary-summary"><div class="stats-chip"><span data-t="bestiary.species">Gatunki</span><strong data-role="bestiary-species">0</strong></div><div class="stats-chip"><span data-t="bestiary.totalKills">Zabójstwa</span><strong data-role="bestiary-total">0</strong></div></div>' +
					'</header>' +
					'<section class="bestiary-grid" data-role="bestiary-grid"><div class="bestiary-empty" data-role="bestiary-empty" data-t="bestiary.empty">Twój bestiariusz jest pusty. Pokonaj wroga, aby dodać wpis.</div></section>' +
				'</div>' +
				'<div class="stats-tabview" data-tab="professions" hidden>' +
					'<header class="stats-view-head"><div class="stats-view-head__copy"><span class="stats-kicker" data-t="professions.kicker">Droga rzemieślnika</span><h1 data-t="professions.title">Rzemiosła</h1><p data-t="professions.sub">Rozwijaj profesje wykonując przypisane czynności.</p></div></header>' +
					'<section class="profession-grid" data-role="profession-grid"><div class="bestiary-empty" data-t="professions.empty">Brak aktywnych profesji.</div></section>' +
				'</div>' +
			'</main>' +
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
		magicLevel: root.querySelector("[data-role='magicLevel']"),
		magicCircle: root.querySelector("[data-role='magicCircle']"),
		magicXpText: root.querySelector("[data-role='magicXpText']"),
		magicXpFill: root.querySelector("[data-role='magicXpFill']"),
		development: root.querySelector("[data-role='development']"),
		developmentNext: root.querySelector("[data-role='development-next']"),
		developmentMeta: root.querySelector("[data-role='development-meta']"),
		developmentSkills: root.querySelector("[data-role='development-skills']"),
		tabs: root.querySelectorAll("[data-tab]"),
		bestiaryGrid: root.querySelector("[data-role='bestiary-grid']"),
		bestiaryEmpty: root.querySelector("[data-role='bestiary-empty']"),
		bestiarySpecies: root.querySelector("[data-role='bestiary-species']"),
		bestiaryTotal: root.querySelector("[data-role='bestiary-total']"),
		professionGrid: root.querySelector("[data-role='profession-grid']")
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

	function renderDevelopment(data) {
		if (!els.development || !els.developmentSkills) return;
		const enabled = !!(data && data.enabled && featureEnabled("progression.dailyLp"));
		els.development.hidden = !enabled;
		if (!enabled) { els.developmentSkills.innerHTML = ""; return; }
		const reset = data.nextGrantAt ? new Date(data.nextGrantAt * 1000).toLocaleString(I18n && I18n.getLang ? I18n.getLang() : "pl") : "—";
		setText(els.developmentNext, t("development.nextGrant", "Następny grant: {0}").replace("{0}", reset));
		setText(els.developmentMeta, t("development.meta", "Dziennie: {0} LP · bank: {1}/{2}").replace("{0}", data.dailyGrant || 0).replace("{1}", data.balance || 0).replace("{2}", data.accumulationCap || 0));
		const order = ["strength", "dexterity", "hpMax", "manaMax", "staminaMax", "oneHand", "twoHand", "bow", "crossbow", "magicLevel"];
		const labels = { strength: "stats.attr.strength", dexterity: "stats.attr.dexterity", hpMax: "stats.attr.hpMax", manaMax: "stats.attr.manaMax", staminaMax: "stats.attr.staminaMax", oneHand: "stats.weapon.oneHand", twoHand: "stats.weapon.twoHand", bow: "stats.weapon.bow", crossbow: "stats.weapon.crossbow", magicLevel: "stats.magic.level" };
		els.developmentSkills.innerHTML = order.map(function (key) {
			const skill = data.skills && data.skills[key];
			if (!skill || !skill.enabled) return "";
			const disabled = !skill.available || skill.maxPurchase <= 0;
			const detail = skill.current + " / " + skill.cap + " · +" + skill.unit + " · " + skill.cost + " LP";
			const batch = (skill.batchAmount || 0) > 1 ? '<button type="button" data-action="develop" data-skill="' + escapeHtml(key) + '" data-amount="' + skill.batchAmount + '" title="' + escapeHtml(skill.batchCost + ' LP') + '">+' + (skill.batchAmount * skill.unit) + '</button>' : '';
			return '<div class="development-skill"><span><b>' + escapeHtml(t(labels[key] || key, key)) + '</b><small>' + escapeHtml(detail) + '</small></span><div class="development-skill__actions"><button type="button" data-action="develop" data-skill="' + escapeHtml(key) + '" data-amount="1"' + (disabled ? ' disabled' : '') + '>+' + skill.unit + '</button>' + batch + '</div></div>';
		}).join("");
	}

	function applySnapshot(d) {
		if (!d || !tabEnabled("stats")) return;
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
		renderDevelopment(d.development || null);
		renderWeapons(d);
		renderMagic(d);
	}

	function renderMagic(d) {
		if (!els.magicLevel) return;
		const lv = (d.magicLevel | 0) || 0;
		const xp = (d.magicXp | 0) || 0;
		const next = (d.magicXpNext | 0) || 0;
		const capped = next <= 0;
		const circle = lv >= 60 ? 6 : Math.max(0, Math.floor(lv / 10));
		setText(els.magicLevel, lv);
		if (els.magicCircle) {
			let label = circle <= 0 ? t("stats.magic.noCircle", "Krąg 0 / 6") : t("stats.magic.circle", "Krąg {0} / 6").replace("{0}", String(circle));
			if (lv >= 60) label = t("stats.magic.maxCircle", "Krąg 6 / 6 (MAX)");
			els.magicCircle.textContent = label;
		}
		if (els.magicXpText) els.magicXpText.textContent = capped ? t("stats.weaponState.max", "MAX") : (xp + " / " + next);
		if (els.magicXpFill) els.magicXpFill.style.width = (capped ? 100 : clampPct(xp, next)) + "%";
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
		const instance = String(entry.instance || "");
		const label = String(npcDisplayLabel(instance, entry.name) || "");
		const sub = instance && instance !== label ? instance : "";
		const npcVisual = window.PhoenixNpcVisuals ? PhoenixNpcVisuals.get(instance) : "";
		const visual = String(npcVisual || entry.visual || "").replace(/\.(MDM|MDL|3DS|MMB|MDS)$/i, function (m) { return m.toUpperCase(); });
		const renderable = visual && /\.(MDM|MRM|MDL|MMB)$/i.test(visual) ? visual : "";
		const killed = Math.max(0, entry.killed | 0);
		const first = formatDate(entry.firstKilledAt);
		const last = formatDate(entry.lastKilledAt);
		const cfg = bestiaryRenderConfig[String(instance).toUpperCase()] || {};
		function finite(value, fallback) {
			const number = Number(value);
			return Number.isFinite(number) ? number : fallback;
		}
		const rotX = finite(cfg.rotX, 0.158);
		const rotY = finite(cfg.rotY, -0.853);
		const rotZ = finite(cfg.rotZ, 0);
		const scaleValue = finite(cfg.scaleValue, 1.5);
		const lightIntensity = finite(cfg.lightIntensity, 2.3);
		return '<article class="bestiary-card">' +
			'<div class="bestiary-card__visual">' +
				(renderable
					? '<gothic-render width="160" height="200" rot-x="' + rotX + '" rot-y="' + rotY + '" rot-z="' + rotZ + '" scale="' + scaleValue + '" light-intensity="' + lightIntensity + '" visual="' + escapeHtml(renderable) + '"></gothic-render>'
					: '<div class="bestiary-card__visual-fallback">' + escapeHtml(label ? label.charAt(0) : "?") + '</div>') +
			'</div>' +
			'<div class="bestiary-card__body">' +
				'<h3 class="bestiary-card__name">' + escapeHtml(label) + '</h3>' +
				(sub ? '<div class="bestiary-card__sub">' + escapeHtml(sub) + '</div>' : "") +
				'<div class="bestiary-card__stat"><span data-t="bestiary.kills">Zabójstwa</span><strong>' + killed + '</strong></div>' +
				'<div class="bestiary-card__dates">' +
					'<span><em data-t="bestiary.first">Pierwszy</em>' + escapeHtml(first) + '</span>' +
					'<span><em data-t="bestiary.last">Ostatni</em>' + escapeHtml(last) + '</span>' +
				'</div>' +
			'</div>' +
		'</article>';
	}

	function applyBestiary(payload) {
		if (!tabEnabled("bestiary")) return;
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

	function applyProfessions(payload) {
		if (!tabEnabled("professions")) return;
		lastProfessions = payload && Array.isArray(payload.entries) ? payload.entries.slice() : [];
		if (!els.professionGrid) return;
		if (!lastProfessions.length) {
			els.professionGrid.innerHTML = '<div class="bestiary-empty">' + escapeHtml(t("professions.empty", "Brak aktywnych profesji.")) + '</div>';
			return;
		}
		const lang = I18n && typeof I18n.getLang === "function" ? I18n.getLang() : "pl";
		const suffix = { pl: "Pl", en: "En", de: "De", ru: "Ru" }[lang] || "Pl";
		els.professionGrid.innerHTML = lastProfessions.map(function (entry) {
			const pct = Math.max(0, Math.min(100, entry.progressPct | 0));
			const capped = (entry.xpNext | 0) <= 0;
			const name = entry["name" + suffix] || entry.namePl || entry.name || entry.code || "?";
			const description = entry["description" + suffix] || entry.descriptionPl || entry.description || "";
			return '<article class="profession-card"><div class="profession-card__head"><div><small>' + escapeHtml(entry.code || '') + '</small><h3>' + escapeHtml(name) + '</h3></div><strong>T' + (entry.tier | 0) + '</strong></div>' +
				'<p>' + escapeHtml(description) + '</p><div class="profession-card__meta"><span>' + escapeHtml(t("professions.level", "Poziom")) + ' ' + (entry.level | 0) + '</span><span>' + (capped ? 'MAX' : ((entry.xp | 0) + ' / ' + (entry.xpNext | 0) + ' XP')) + '</span></div>' +
				'<div class="profession-card__track"><i style="width:' + (capped ? 100 : pct) + '%"></i></div></article>';
		}).join('');
	}

	function switchTab(tab, skipRequest) {
		if (!tabEnabled(tab)) return;
		activeTab = tab;
		root.querySelectorAll(".stats-tab").forEach(function (btn) {
			btn.classList.toggle("is-active", btn.dataset.tab === tab);
		});
		root.querySelectorAll(".stats-tabview").forEach(function (view) {
			if (view.dataset.tab === tab) view.removeAttribute("hidden");
			else view.setAttribute("hidden", "");
		});
		if (!skipRequest && tab === "bestiary") PhoenixBridge.send("phoenix:bestiary:request", null);
		if (!skipRequest && tab === "professions") PhoenixBridge.send("phoenix:profession:request", null);
	}

	root.addEventListener("click", function (ev) {
		const closeTarget = ev.target.closest("[data-action='close']");
		if (closeTarget) { PhoenixBridge.send("phoenix:stats:close", null); return; }
		const developTarget = ev.target.closest("[data-action='develop']");
		if (developTarget && developTarget.dataset.skill && !developTarget.disabled) {
			developTarget.disabled = true;
			PhoenixBridge.send("phoenix:stats:spend", { stat: developTarget.dataset.skill, amount: Math.max(1, parseInt(developTarget.dataset.amount, 10) || 1), requestId: "stats:" + Date.now() + ":" + Math.floor(Math.random() * 1000000) });
			return;
		}
		const tabTarget = ev.target.closest(".stats-tab");
		if (tabTarget && tabTarget.dataset.tab) { switchTab(tabTarget.dataset.tab); }
	});

	PhoenixBridge.on("phoenix:stats:snapshot", function (payload) { if (tabEnabled("stats")) applySnapshot(payload); });
	PhoenixBridge.on("phoenix:stats:result", function (payload) { if (tabEnabled("stats")) applyResult(payload); });
	PhoenixBridge.on("phoenix:bestiary:snapshot", function (payload) { if (tabEnabled("bestiary")) applyBestiary(payload); });
	PhoenixBridge.on("phoenix:profession:snapshot", function (payload) { if (tabEnabled("professions")) applyProfessions(payload); });
	PhoenixBridge.on("phoenix:features:snapshot", applyFeatureFlags);
	PhoenixBridge.on("phoenix:bestiary:renderConfig", function (payload) {
		if (!tabEnabled("bestiary")) return;
		const entries = payload && Array.isArray(payload.entries) ? payload.entries : [];
		bestiaryRenderConfig = {};
		entries.forEach(function (e) {
			if (!e || !e.instance) return;
			bestiaryRenderConfig[String(e.instance).toUpperCase()] = e;
		});
		if (lastBestiary && activeTab === "bestiary") applyBestiary(lastBestiary);
	});

	const page = {
		onShow: function () {
			const tabs = availableTabs();
			if (!tabs.length) { PhoenixBridge.send("phoenix:stats:close", null); if (window.phoenixApp) phoenixApp.hide(); return; }
			if (!tabEnabled(activeTab)) activeTab = tabs[0];
			switchTab(activeTab, true);
			if (tabEnabled("stats")) PhoenixBridge.send("phoenix:stats:request", null);
			if (tabEnabled("professions")) PhoenixBridge.send("phoenix:profession:request", null);
			if (activeTab === "bestiary" && tabEnabled("bestiary")) PhoenixBridge.send("phoenix:bestiary:request", null);
			if (I18n) I18n.applyDom(root);
			applyFeatureFlags({ settings: { flags: featureFlags } });
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
		applyProfessions({ entries: lastProfessions });
	});
	if (window.phoenixApp) window.phoenixApp.register("stats", page);
})();
