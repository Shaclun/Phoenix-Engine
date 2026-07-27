(function () {
	const HOTBAR_SLOTS = 8;
	const STORAGE_KEY = "phoenix:hotbar:v1";
	const HOTBAR_RENDER = { rotX: "1.584", rotY: "-1.662", rotZ: "-0.488", scale: "1.35", light: "2.6" };
	const hotbarRenderConfig = {};
	function hotbarRenderFor(instance) {
		if (!instance) return HOTBAR_RENDER;
		const cfg = hotbarRenderConfig[String(instance).toUpperCase()];
		if (!cfg) return HOTBAR_RENDER;
		return {
			rotX: String(cfg.rotX),
			rotY: String(cfg.rotY),
			rotZ: String(cfg.rotZ),
			scale: String(cfg.scaleValue),
			light: String(cfg.lightIntensity)
		};
	}

	const state = {
		visible: false,
		hotbar: new Array(HOTBAR_SLOTS).fill(null),
		items: [],
		level: 1,
		expNext: 500
	};

	const els = {};
	let targetNodes = null;
	let partyNodes = null;
	let knockdownNodes = null;
	let herbNodes = null;
	let weaponNodes = null;
	let knockdownInterval = null;
	let herbTimer = null;
	let herbRunId = 0;
	let weaponHideTimer = null;
	let blocked = false;
	let layoutState = null;
	let featureFlags = {};
	const featureDefaults = {
		"progression.leveling": true,
		"progression.magicExperience": true,
		"progression.weaponExperience": true,
		"hud.levelExperience": true,
		"hud.magicExperience": true,
		"hud.weaponExperience": true,
		"player.hotbar": true,
		"player.stamina": true,
		"player.targetHud": true,
		"player.knockdown": true,
		"herbs.enabled": true,
		"minimap.enabled": true,
		"worldclock.enabled": true,
		"weather.enabled": true,
		"social.party": true
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

	function levelHudEnabled() { return featureEnabled("progression.leveling") && featureEnabled("hud.levelExperience"); }
	function magicHudEnabled() { return featureEnabled("progression.magicExperience") && featureEnabled("hud.magicExperience"); }
	function weaponHudEnabled() { return featureEnabled("progression.weaponExperience") && featureEnabled("hud.weaponExperience"); }
	function featureAllowsHudId(id) {
		if (id === "level" || id === "exp") return levelHudEnabled();
		if (id === "magicxp") return magicHudEnabled();
		if (id === "hotbar") return featureEnabled("player.hotbar");
		if (id === "stamina") return featureEnabled("player.stamina");
		if (id === "target") return featureEnabled("player.targetHud");
		if (id === "minimap") return featureEnabled("minimap.enabled");
		if (id === "worldclock") return featureEnabled("worldclock.enabled");
		return true;
	}

	function t(key, fallback) {
		if (!window.PhoenixI18n || typeof PhoenixI18n.t !== "function") return fallback || key;
		const value = PhoenixI18n.t(key);
		return value === key && fallback ? fallback : value;
	}

	function countdownText(seconds) {
		return t("player.knockdown.respawnCountdown", "Respawn choice in {0}s").replace("{0}", '<span data-role="seconds">' + String(seconds) + '</span>');
	}

	function fmt(cur, max) { return Math.max(0, cur | 0) + " / " + Math.max(0, max | 0); }

	function setFill(node, percent) {
		if (!node) return;
		const v = Math.max(0, Math.min(100, percent || 0));
		node.style.setProperty("--fill-pct", v + "%");
	}

	function pct(cur, max) {
		max = max | 0;
		if (max <= 0) return 0;
		const v = Math.max(0, Math.min(1, cur / max));
		return Math.round(v * 1000) / 10;
	}

	function makeElement(id, className, html) {
		let node = document.getElementById("phoenix-hud-" + id);
		if (node) return node;
		node = document.createElement("div");
		node.className = "phoenix-hud-el " + className;
		node.id = "phoenix-hud-" + id;
		node.dataset.hudId = id;
		if (html) node.innerHTML = html;
		document.body.appendChild(node);
		return node;
	}

	function buildHud() {
		if (els.portrait) return;

		els.portrait = makeElement("portrait", "phoenix-hud-portrait",
			'<div class="phoenix-hud-portrait__frame"></div>' +
			'<div class="phoenix-hud-portrait__inner" data-role="portrait"></div>'
		);

		els.name = makeElement("name", "phoenix-hud-name",
			'<span data-role="name">—</span>'
		);

		els.level = makeElement("level", "phoenix-hud-level",
			'<span data-role="level">Lv 1</span>'
		);

		els.hp = makeElement("hp", "phoenix-hud-bar phoenix-hud-bar--hp",
			'<div class="phoenix-hud-bar__fill" data-role="hpFill"></div>' +
			'<div class="phoenix-hud-bar__label" data-role="hpLabel">0 / 0</div>'
		);

		els.mana = makeElement("mana", "phoenix-hud-bar phoenix-hud-bar--mana",
			'<div class="phoenix-hud-bar__fill" data-role="manaFill"></div>' +
			'<div class="phoenix-hud-bar__label" data-role="manaLabel">0 / 0</div>'
		);

		els.stamina = makeElement("stamina", "phoenix-hud-bar phoenix-hud-bar--stamina",
			'<div class="phoenix-hud-bar__fill" data-role="stamFill"></div>' +
			'<div class="phoenix-hud-bar__label" data-role="stamLabel">0 / 0</div>'
		);

		els.exp = makeElement("exp", "phoenix-hud-xp",
			'<div class="phoenix-hud-xp__fill" data-role="expFill"></div>' +
			'<span class="phoenix-hud-xp__label" data-role="expLabel">0 / 0</span>'
		);

		els.magicxp = makeElement("magicxp", "phoenix-hud-xp phoenix-hud-xp--magic",
			'<div class="phoenix-hud-xp__fill" data-role="magicFill"></div>' +
			'<span class="phoenix-hud-xp__label" data-role="magicLabel">M 0</span>'
		);

		els.hotbar = makeElement("hotbar", "phoenix-hud-hotbar", "");

		for (let i = 0; i < HOTBAR_SLOTS; i++) {
			const slot = document.createElement("div");
			slot.className = "phoenix-hud-hotbar__slot";
			slot.dataset.slot = String(i);
			slot.innerHTML =
				'<span class="phoenix-hud-hotbar__key">' + (i + 1) + '</span>' +
				'<div class="phoenix-hud-hotbar__icon" data-role="icon"></div>' +
				'<span class="phoenix-hud-hotbar__count" data-role="count"></span>' +
				'<span class="phoenix-hud-hotbar__name" data-role="name"></span>';
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
			els.hotbar.appendChild(slot);
		}

		els.refs = {
			portraitInner: els.portrait.querySelector('[data-role="portrait"]'),
			name: els.name.querySelector('[data-role="name"]'),
			level: els.level.querySelector('[data-role="level"]'),
			hpFill: els.hp.querySelector('[data-role="hpFill"]'),
			hpLabel: els.hp.querySelector('[data-role="hpLabel"]'),
			manaFill: els.mana.querySelector('[data-role="manaFill"]'),
			manaLabel: els.mana.querySelector('[data-role="manaLabel"]'),
			stamFill: els.stamina.querySelector('[data-role="stamFill"]'),
			stamLabel: els.stamina.querySelector('[data-role="stamLabel"]'),
			expFill: els.exp.querySelector('[data-role="expFill"]'),
			expLabel: els.exp.querySelector('[data-role="expLabel"]'),
			magicFill: els.magicxp.querySelector('[data-role="magicFill"]'),
			magicLabel: els.magicxp.querySelector('[data-role="magicLabel"]')
		};
	}

	const portraitState = { headModel: "", bodyModel: "", bodyTexIndex: 0, face: 0, current: "" };
	const portraitConfig = { rotX: -0.022, rotY: 0.58, rotZ: 1.584, scale: 1.60, light: 1.75 };

	function applyPortraitConfig(raw) {
		if (raw == null) return;
		const text = String(raw || "").trim();
		if (!text) return;
		let obj = null;
		try { obj = JSON.parse(text); } catch (e) { obj = null; }
		if (!obj) return;
		if (typeof obj.rotX === "number") portraitConfig.rotX = obj.rotX;
		if (typeof obj.rotY === "number") portraitConfig.rotY = obj.rotY;
		if (typeof obj.rotZ === "number") portraitConfig.rotZ = obj.rotZ;
		if (typeof obj.scale === "number") portraitConfig.scale = obj.scale;
		if (typeof obj.light === "number") portraitConfig.light = obj.light;
		portraitState.current = "";
		try { renderPortrait(portraitState.headModel, portraitState.bodyModel, portraitState.bodyTexIndex, portraitState.face); } catch (e2) {}
	}

	function renderPortrait(headModel, bodyModel, bodyTexIndex, face) {
		buildHud();
		if (!els.refs || !els.refs.portraitInner) return;
		const head = String(headModel || "").trim();
		const body = String(bodyModel || "").trim();
		const bodyTex = (bodyTexIndex | 0) || 0;
		const faceTex = (face | 0) || 0;
		portraitState.headModel = head;
		portraitState.bodyModel = body;
		portraitState.bodyTexIndex = bodyTex;
		portraitState.face = faceTex;
		const target = els.refs.portraitInner;
		
		if (!head) {
			if (portraitState.current !== "") {
				target.innerHTML = '<span class="phoenix-hud-portrait__fallback">?</span>';
				portraitState.current = "";
			}
			return;
		}
		const visual = head.toUpperCase().endsWith(".MMB") ? head : head + ".MMB";
		const sig = visual + "|" + faceTex + "|" + portraitConfig.rotX + "|" + portraitConfig.rotY + "|" + portraitConfig.rotZ + "|" + portraitConfig.scale + "|" + portraitConfig.light;
		if (portraitState.current === sig) return;
		portraitState.current = sig;
		target.innerHTML = "";
		const fallback = document.createElement("span");
		fallback.className = "phoenix-hud-portrait__fallback";
		fallback.textContent = "…";
		target.appendChild(fallback);
		const el = document.createElement("gothic-render");
		el.setAttribute("width", "100");
		el.setAttribute("height", "100");
		el.setAttribute("rot-x", String(portraitConfig.rotX));
		el.setAttribute("rot-y", String(portraitConfig.rotY));
		el.setAttribute("rot-z", String(portraitConfig.rotZ));
		el.setAttribute("scale", String(portraitConfig.scale));
		el.setAttribute("light-intensity", String(portraitConfig.light));
		el.setAttribute("head-tex-index", String(faceTex));
		el.setAttribute("visual", visual);
		target.appendChild(el);
	}

	function buildPartyHud() {
		if (partyNodes) return partyNodes;
		const root = document.createElement("div");
		root.className = "phoenix-party-hud";
		root.id = "phoenix-party-hud";
		document.body.appendChild(root);
		partyNodes = { root: root, signature: "" };
		return partyNodes;
	}

	function applyPartySnapshot(payload) {
		state.partySnapshot = payload;
		const nodes = buildPartyHud();
		const members = featureEnabled("social.party") && payload && Array.isArray(payload.members) ? payload.members.slice(0, 3) : [];
		const signature = JSON.stringify(members) + "|" + (levelHudEnabled() ? "1" : "0");
		if (nodes.signature === signature) return;
		nodes.signature = signature;
		nodes.root.innerHTML = "";
		members.forEach(function (member) {
			const card = document.createElement("article");
			card.className = "phoenix-party-member" + (member.isLeader ? " is-leader" : "") + (member.testPlayerNpc ? " is-test-player" : "");
			card.innerHTML =
				'<div class="phoenix-party-member__portrait">' +
					'<div class="phoenix-party-member__portrait-frame"></div>' +
					'<div class="phoenix-party-member__portrait-inner"><span>?</span></div>' +
				'</div>' +
				'<div class="phoenix-party-member__body">' +
					'<div class="phoenix-party-member__head"><strong></strong><em></em></div>' +
					'<div class="phoenix-party-member__bar phoenix-party-member__bar--hp"><i></i><span></span></div>' +
					'<div class="phoenix-party-member__bar phoenix-party-member__bar--mana"><i></i><span></span></div>' +
				'</div>';
			card.querySelector("strong").textContent = member.name || "—";
			const partyLevel = card.querySelector("em");
			partyLevel.textContent = levelHudEnabled() ? (member.isLeader ? "◆ " : "") + t("stats.levelShort", "Lv") + " " + (member.level | 0) : "";
			partyLevel.style.display = levelHudEnabled() ? "" : "none";
			const bars = card.querySelectorAll(".phoenix-party-member__bar");
			bars[0].querySelector("i").style.width = pct(member.hp, member.hpMax) + "%";
			bars[0].querySelector("span").textContent = fmt(member.hp, member.hpMax);
			bars[1].querySelector("i").style.width = pct(member.mana, member.manaMax) + "%";
			bars[1].querySelector("span").textContent = fmt(member.mana, member.manaMax);
			const head = String(member.headModel || "").trim();
			if (head) {
				const portrait = card.querySelector(".phoenix-party-member__portrait-inner");
				const render = document.createElement("gothic-render");
				render.setAttribute("width", "72");
				render.setAttribute("height", "72");
				render.setAttribute("rot-x", String(portraitConfig.rotX));
				render.setAttribute("rot-y", String(portraitConfig.rotY));
				render.setAttribute("rot-z", String(portraitConfig.rotZ));
				render.setAttribute("scale", String(portraitConfig.scale));
				render.setAttribute("light-intensity", String(portraitConfig.light));
				render.setAttribute("head-tex-index", String(member.face | 0));
				render.setAttribute("visual", head.toUpperCase().endsWith(".MMB") ? head : head + ".MMB");
				portrait.appendChild(render);
			}
			nodes.root.appendChild(card);
		});
		nodes.root.classList.toggle("is-visible", state.visible && members.length > 0 && !blocked);
	}

	function buildTargetHud() {
		if (targetNodes) return targetNodes;
		const root = document.createElement("div");
		root.className = "phoenix-target-hud";
		root.id = "phoenix-target-hud";
		root.dataset.hudId = "target";
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
		if (!weaponHudEnabled()) payload = null;
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
		const weaponLabelKeys = {
			oneHand: "stats.weapon.oneHand",
			twoHand: "stats.weapon.twoHand",
			bow: "stats.weapon.bow",
			crossbow: "stats.weapon.crossbow"
		};
		const weaponLabelKey = weaponLabelKeys[key];
		weaponNodes.name.textContent = weaponLabelKey ? t(weaponLabelKey, payload.label || key) : (payload.label || key);
		weaponNodes.level.textContent = t("stats.levelShort", "Lv") + " " + item.level;
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
		const r = els.refs;
		r.name.textContent = payload.name || "—";
		r.level.textContent = t("stats.levelShort", "Lv") + " " + (payload.level | 0);
		setFill(r.hpFill, pct(payload.hp, payload.hpMax));
		r.hpLabel.textContent = fmt(payload.hp, payload.hpMax);
		setFill(r.manaFill, pct(payload.mana, payload.manaMax));
		r.manaLabel.textContent = fmt(payload.mana, payload.manaMax);
		setFill(r.stamFill, pct(payload.stamina, payload.staminaMax));
		r.stamLabel.textContent = fmt(payload.stamina, payload.staminaMax);
		const expCur = payload.experience | 0;
		const expCap = (payload.experienceNext | 0) || 1;
		setFill(r.expFill, pct(expCur, expCap));
		r.expLabel.textContent = expCur + " / " + expCap;
		const magicLv = payload.magicLevel | 0;
		const magicXp = payload.magicXp | 0;
		const magicNext = (payload.magicXpNext | 0);
		const magicCapped = magicNext <= 0;
		const magicPctV = magicCapped ? 100 : pct(magicXp, magicNext);
		setFill(r.magicFill, magicPctV);
		r.magicLabel.textContent = "M " + magicLv + (magicCapped ? "  ·  MAX" : "  ·  " + magicXp + " / " + magicNext);
		try { renderPortrait(payload.headModel, payload.bodyModel, payload.bodyTexIndex, payload.face); } catch (ePt) {}
		try { applyLayoutNow(); } catch (eLn) {}
		show();
	}

	function applyTarget(payload) {
		state.targetSnapshot = payload;
		buildTargetHud();
		if (!payload || blocked || !featureEnabled("player.targetHud")) {
			targetNodes.root.classList.remove("is-visible");
			return;
		}
		targetNodes.name.textContent = payload.name || "?";
		targetNodes.level.textContent = levelHudEnabled() ? t("stats.levelShort", "Lv") + " " + (payload.level | 0) : "";
		targetNodes.level.style.display = levelHudEnabled() ? "" : "none";
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

	function applyFeatureVisibility() {
		buildHud();
		Object.keys(els).forEach(function (key) {
			if (key === "refs") return;
			const node = els[key];
			if (!node || !node.classList) return;
			const allowed = featureAllowsHudId(key);
			node.classList.toggle("is-visible", state.visible && allowed);
			if (!allowed) node.style.display = "none";
			else if (!layoutState || !layoutState[key] || layoutState[key].visible !== false) node.style.display = "";
		});
		if (worldClockNodes) worldClockNodes.root.classList.toggle("is-visible", state.visible && featureEnabled("worldclock.enabled"));
		if (targetNodes && !featureEnabled("player.targetHud")) targetNodes.root.classList.remove("is-visible");
		if (partyNodes) partyNodes.root.classList.toggle("is-visible", state.visible && featureEnabled("social.party") && partyNodes.root.children.length > 0 && !blocked);
		if (!weaponHudEnabled() && weaponNodes) weaponNodes.root.classList.remove("is-visible", "is-hiding", "is-notify", "is-updated");
		if (!featureEnabled("player.knockdown") && knockdownNodes) knockdownNodes.root.classList.remove("is-visible");
		if (!featureEnabled("herbs.enabled") && herbNodes) herbNodes.root.classList.remove("is-visible");
		if (window.PhoenixMinimap) {
			if (typeof window.PhoenixMinimap.setFeatureEnabled === "function") window.PhoenixMinimap.setFeatureEnabled(featureEnabled("minimap.enabled"));
			window.PhoenixMinimap.setVisible(state.visible && featureEnabled("minimap.enabled"));
		}
		try { applyLayoutNow(); } catch (e) {}
	}

	function applyFeatureFlags(payload) {
		featureFlags = payload && payload.settings && payload.settings.flags && typeof payload.settings.flags === "object" ? payload.settings.flags : {};
		if (!featureEnabled("player.hotbar")) rootHotbarPickerClose();
		if (!featureEnabled("herbs.enabled")) { herbRunId += 1; if (herbTimer) { clearInterval(herbTimer); herbTimer = null; } }
		if (!featureEnabled("player.knockdown") && knockdownInterval) { clearInterval(knockdownInterval); knockdownInterval = null; }
		if (state.partySnapshot) applyPartySnapshot(state.partySnapshot);
		if (state.targetSnapshot) applyTarget(state.targetSnapshot);
		applyFeatureVisibility();
		if (worldClockNodes) renderWorldClock();
	}

	function rootHotbarPickerClose() {
		document.querySelectorAll(".invui-hotbar-picker").forEach(function (node) { node.remove(); });
	}

	function show() {
		buildHud();
		state.visible = true;
		applyFeatureVisibility();
		if (featureEnabled("player.hotbar")) renderHotbar();
	}

	function hide() {
		state.visible = false;
		Object.keys(els).forEach(function (k) {
			if (k === "refs") return;
			if (els[k] && els[k].classList) els[k].classList.remove("is-visible");
		});
		if (targetNodes) targetNodes.root.classList.remove("is-visible");
		if (partyNodes) partyNodes.root.classList.remove("is-visible");
		if (weaponNodes) weaponNodes.root.classList.remove("is-visible", "is-hiding", "is-notify", "is-updated");
		if (knockdownNodes) knockdownNodes.root.classList.remove("is-visible");
		if (herbNodes) herbNodes.root.classList.remove("is-visible");
		if (worldClockNodes) worldClockNodes.root.classList.remove("is-visible");
		if (window.PhoenixMinimap) window.PhoenixMinimap.setVisible(false);
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
		try { PhoenixBridge.send("phoenix:hotbar:save", { data: JSON.stringify(state.hotbar) }); } catch (e) {}
	}

	function applyHotbarSnapshot(payload) {
		if (!payload || !payload.data) return;
		try {
			const data = JSON.parse(payload.data);
			if (Array.isArray(data) && data.length === HOTBAR_SLOTS) {
				state.hotbar = data;
				try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state.hotbar)); } catch (e) {}
				renderHotbar();
			}
		} catch (e) {}
	}

	function assignSlot(idx, data) {
		if (!featureEnabled("player.hotbar")) return;
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
		if (!featureEnabled("player.hotbar")) return;
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
		fallback.className = "phoenix-hud-hotbar__fallback";
		fallback.textContent = ((item && item.name) || entry.name || entry.instance || "?").slice(0, 2);
		icon.appendChild(fallback);
		const el = document.createElement("gothic-render");
		el.setAttribute("width", "96");
		el.setAttribute("height", "96");
		const hcfg = hotbarRenderFor(entry.instance || (item && item.instance));
		el.setAttribute("rot-x", hcfg.rotX);
		el.setAttribute("rot-y", hcfg.rotY);
		el.setAttribute("rot-z", hcfg.rotZ);
		el.setAttribute("scale", hcfg.scale);
		el.setAttribute("light-intensity", hcfg.light);
		el.setAttribute("visual", visual);
		icon.appendChild(el);
	}

	function renderHotbar() {
		if (!els.hotbar) return;
		const slots = els.hotbar.children;
		for (let i = 0; i < HOTBAR_SLOTS; i++) {
			const slot = slots[i];
			if (!slot) continue;
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
	}

	function onInventoryUpdate(payload) {
		if (payload && Array.isArray(payload.items)) {
			state.items = payload.items;
			renderHotbar();
		}
	}

	function onKnockedDown(payload) {
		if (!featureEnabled("player.knockdown")) return;
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
		if (!featureEnabled("herbs.enabled")) return;
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
		if (!featureEnabled("herbs.enabled")) return;
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

	let worldClockNodes = null;
	let worldClockState = { weather: "clear" };
	let worldClockTicker = null;

	function buildWorldClock() {
		if (worldClockNodes) return worldClockNodes;
		const root = document.createElement("div");
		root.className = "phoenix-worldclock";
		root.id = "phoenix-worldclock";
		root.dataset.hudId = "worldclock";
		root.innerHTML =
			'<span class="phoenix-worldclock__time" data-role="time">00:00</span>' +
			'<span class="phoenix-worldclock__sep" data-role="weather">·</span>' +
			'<span class="phoenix-worldclock__icon" data-role="weather">☀</span>' +
			'<span class="phoenix-worldclock__label" data-role="weather">Clear</span>';
		const host = document.getElementById("phoenix-minimap-meta");
		(host || document.body).appendChild(root);
		worldClockNodes = {
			root: root,
			time: root.querySelector('[data-role="time"]'),
			icon: root.querySelector(".phoenix-worldclock__icon"),
			label: root.querySelector(".phoenix-worldclock__label"),
			weather: root.querySelectorAll('[data-role="weather"]')
		};
		if (!worldClockTicker) worldClockTicker = setInterval(renderWorldClock, 1000);
		return worldClockNodes;
	}

	function weatherMeta(kind) {
		switch (kind) {
			case "rain": return { icon: "🌧", label: t("hud.weather.rain", "Deszcz"), cls: "is-rain" };
			case "snow": return { icon: "❄", label: t("hud.weather.snow", "Śnieg"), cls: "is-snow" };
			case "storm": return { icon: "⛈", label: t("hud.weather.storm", "Burza"), cls: "is-storm" };
			case "stop": return { icon: "☁", label: t("hud.weather.cloudy", "Pochmurno"), cls: "is-clear" };
			case "clear":
			default: return { icon: "☀", label: t("hud.weather.clear", "Pogodnie"), cls: "is-clear" };
		}
	}

	function applyWorldClock(payload) {
		if (!featureEnabled("worldclock.enabled")) {
			if (worldClockNodes) worldClockNodes.root.classList.remove("is-visible");
			return;
		}
		buildWorldClock();
		if (payload && payload.weather) worldClockState.weather = String(payload.weather);
		renderWorldClock();
	}

	function renderWorldClock() {
		if (!worldClockNodes) return;
		const now = new Date();
		const hour = now.getHours();
		const minute = now.getMinutes();
		const hh = hour < 10 ? "0" + hour : String(hour);
		const mm = minute < 10 ? "0" + minute : String(minute);
		worldClockNodes.time.textContent = hh + ":" + mm;
		const weatherEnabled = featureEnabled("weather.enabled");
		worldClockNodes.weather.forEach(function (node) { node.style.display = weatherEnabled ? "" : "none"; });
		worldClockNodes.root.classList.remove("is-clear", "is-rain", "is-snow", "is-storm");
		if (weatherEnabled) {
			const meta = weatherMeta(worldClockState.weather);
			worldClockNodes.icon.textContent = meta.icon;
			worldClockNodes.label.textContent = meta.label;
			worldClockNodes.root.classList.add(meta.cls);
		}
		const night = hour >= 21 || hour < 6;
		worldClockNodes.root.classList.toggle("is-night", night);
		if (state.visible && featureEnabled("worldclock.enabled")) worldClockNodes.root.classList.add("is-visible");
		else worldClockNodes.root.classList.remove("is-visible");
	}

	function notifyHerb(payload, ok, error) {
		if (!window.PhoenixNotify) return;
		const label = payload && payload.label ? payload.label : tr("herb.defaultLabel");
		if (ok) {
			const amount = payload && payload.amount ? payload.amount | 0 : 1;
			const xp = payload && payload.xp ? payload.xp | 0 : 0;
			let text = label + (amount > 1 ? " ×" + amount : "");
			if (xp > 0) text += " · +" + xp + " XP";
			if (payload && payload.hunting) PhoenixNotify.notify("success", tr("hunting.notify.success.title"), text, 3500);
			else PhoenixNotify.notify("success", tr("herb.notify.success.title"), text, 3500); return;
		}
		if (error === "noStamina") { PhoenixNotify.notify("error", tr("herb.notify.noStamina.title"), tr("herb.notify.noStamina.text"), 3000); return; }
		if (error === "busy") { PhoenixNotify.notify("warn", tr("herb.notify.cancelled.title"), tr("crafting.error.busy"), 3000); return; }
		if (error === "lowProfessionTier" || error === "professionUnavailable") { PhoenixNotify.notify("error", tr("herb.notify.lowTier.title"), tr("herb.notify.lowTier.text"), 3000); return; }
		if (error === "grantFailed") { PhoenixNotify.notify("error", tr("herb.notify.failed.title"), tr("herb.notify.grantFailed.text"), 3500); return; }
		if (error === "cooldown") {
			const seconds = payload && payload.cooldownSec ? payload.cooldownSec | 0 : 0;
			PhoenixNotify.notify("warn", tr("herb.notify.cooldown.title"), tr("herb.notify.cooldown.text").replace("{seconds}", String(seconds)), 3500);
			return;
		}
		if (error === "cancelled") { PhoenixNotify.notify("warn", tr("herb.notify.cancelled.title"), tr("herb.notify.cancelled.text"), 2500); return; }
		if (error === "moved") { PhoenixNotify.notify("warn", tr("herb.notify.moved.title"), tr("herb.notify.moved.text"), 3000); return; }
		PhoenixNotify.notify("error", tr("herb.notify.failed.title"), label, 3500);
	}


	function getElementNodeById(id) {
		if (id === "minimap") return document.getElementById("phoenix-minimap");
		if (id === "worldclock") return worldClockNodes ? worldClockNodes.root : document.getElementById("phoenix-worldclock");
		if (id === "chat") return document.getElementById("phoenix-chat");
		if (id === "target") return targetNodes ? targetNodes.root : document.getElementById("phoenix-target-hud");
		return document.getElementById("phoenix-hud-" + id);
	}

	function applyLayoutNow() {
		if (!layoutState) return;
		Object.keys(layoutState).forEach(function (id) {
			const cfg = layoutState[id];
			if (!cfg) return;
			const node = getElementNodeById(id);
			if (!node) return;
			applyElementLayout(node, cfg, id);
		});
	}

	function applyElementLayout(node, cfg, id) {
		if (!featureAllowsHudId(id)) {
			node.style.display = "none";
			return;
		}
		if (cfg.visible === false) {
			node.style.display = "none";
			return;
		}
		node.style.display = "";

		const x = (typeof cfg.x === "number") ? cfg.x : 0;
		const y = (typeof cfg.y === "number") ? cfg.y : 0;
		const scale = (typeof cfg.scale === "number") ? cfg.scale : 1;

		node.style.right = "";
		node.style.bottom = "";
		node.style.left = x + "%";
		node.style.top = y + "%";
		node.style.transformOrigin = "0 0";
		node.style.transform = "scale(" + scale + ")";

		const orientation = (cfg.orientation === "vertical") ? "vertical" : "horizontal";
		node.classList.toggle("phoenix-hud-vertical", orientation === "vertical");
		node.classList.toggle("phoenix-hud-horizontal", orientation === "horizontal");
	}

	function applyLayout(layout) {
		if (!layout) return;
		layoutState = layout;
		buildHud();
		try { buildWorldClock(); } catch (eW) {}
		try { applyLayoutNow(); } catch (e) {}
	}

	loadHotbar();

	document.addEventListener("keydown", onKey, true);

	if (window.PhoenixBridge) {
		PhoenixBridge.on("phoenix:hud:snapshot", applySnapshot);
		PhoenixBridge.on("phoenix:social:partySnapshot", applyPartySnapshot);
		PhoenixBridge.on("phoenix:hud:weapon", applyWeapon);
		PhoenixBridge.on("phoenix:hud:target", applyTarget);
		PhoenixBridge.on("phoenix:hud:target:clear", function () { applyTarget(null); });
		PhoenixBridge.on("phoenix:player:knockedDown", onKnockedDown);
		PhoenixBridge.on("phoenix:player:revived", onRevived);
		PhoenixBridge.on("phoenix:herb:start", onHerbStart);
		PhoenixBridge.on("phoenix:herb:result", onHerbResult);
		PhoenixBridge.on("phoenix:inventory:update", onInventoryUpdate);
		PhoenixBridge.on("phoenix:item:inventory", onInventoryUpdate);
		PhoenixBridge.on("phoenix:hotbar:snapshot", applyHotbarSnapshot);
		PhoenixBridge.on("phoenix:item:renderConfig", function (payload) {
			if (!payload) return;
			Object.keys(hotbarRenderConfig).forEach(function (k) { delete hotbarRenderConfig[k]; });
			(payload.entries || []).forEach(function (e) {
				if (!e || !e.instance) return;
				hotbarRenderConfig[String(e.instance).toUpperCase()] = e;
			});
			try { renderHotbar(); } catch (e2) {}
		});
		PhoenixBridge.on("phoenix:hud:hide", hide);
		PhoenixBridge.on("phoenix:hud:show", show);
		PhoenixBridge.on("phoenix:chat:show", function () {
			setTimeout(function () { try { applyLayoutNow(); } catch (e) {} }, 50);
		});
		PhoenixBridge.on("phoenix:hud:portraitConfig", function (payload) {
			if (!payload) return;
			applyPortraitConfig(payload.data || "");
		});
		PhoenixBridge.on("phoenix:uisettings:snapshot", function (payload) {
			if (!payload || !payload.data) return;
			try {
				const obj = JSON.parse(payload.data);
				if (obj && obj.hud) applyLayout(obj.hud);
			} catch (e) {}
		});
		PhoenixBridge.on("phoenix:worldclock:update", applyWorldClock);
		PhoenixBridge.on("phoenix:features:snapshot", applyFeatureFlags);
	}

	function setBlocked(value) {
		blocked = !!value;
		const target = document.querySelector(".phoenix-target-hud");
		if (target) target.classList.toggle("is-blocked", blocked);
		const partyHud = document.querySelector(".phoenix-party-hud");
		if (partyHud) {
			partyHud.classList.toggle("is-blocked", blocked);
			partyHud.classList.toggle("is-visible", !blocked && state.visible && partyHud.children.length > 0);
		}
		const weapon = document.querySelector(".phoenix-weapon-progress");
		if (weapon) weapon.classList.toggle("is-blocked", blocked);
		const questTracker = document.querySelector(".quest-tracker");
		if (questTracker) questTracker.classList.toggle("is-blocked", blocked);
		const worldClock = document.querySelector(".phoenix-worldclock");
		if (worldClock) worldClock.classList.toggle("is-blocked", blocked);
		const minimap = document.querySelector(".phoenix-minimap");
		if (minimap) minimap.classList.toggle("is-blocked", blocked);
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
		setBlocked: setBlocked,
		applyHotbarSnapshot: applyHotbarSnapshot,
		applyLayout: applyLayout,
		getElement: getElementNodeById
	};
})();
