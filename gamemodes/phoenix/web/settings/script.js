(function () {
	"use strict";

	function t(key, fallback) {
		try { return (window.PhoenixI18n && window.PhoenixI18n.t) ? window.PhoenixI18n.t(key) : (fallback != null ? fallback : key); }
		catch (e) { return fallback != null ? fallback : key; }
	}

	const ELEMENTS = [
		{ id: "portrait",   labelKey: "settings.hud.portrait",   fallback: "Portret",         x: 1.0,  y: 1.5,  orientable: false },
		{ id: "level",      labelKey: "settings.hud.level",      fallback: "Poziom",          x: 6.4,  y: 1.9,  orientable: false },
		{ id: "name",       labelKey: "settings.hud.name",       fallback: "Nick",            x: 6.4,  y: 3.5,  orientable: false },
		{ id: "hp",         labelKey: "settings.hud.hp",         fallback: "Pasek HP",        x: 6.2,  y: 6.1,  orientable: true },
		{ id: "mana",       labelKey: "settings.hud.mana",       fallback: "Pasek many",      x: 6.2,  y: 7.6,  orientable: true },
		{ id: "stamina",    labelKey: "settings.hud.stamina",    fallback: "Pasek staminy",   x: 6.2,  y: 9.2,  orientable: true },
		{ id: "exp",        labelKey: "settings.hud.exp",        fallback: "Pasek EXP",       x: 39.0, y: 91.0, orientable: true },
		{ id: "magicxp",    labelKey: "settings.hud.magicxp",    fallback: "Pasek M-EXP",     x: 39.0, y: 93.6, orientable: true },
		{ id: "hotbar",     labelKey: "settings.hud.hotbar",     fallback: "Hotbar",          x: 39.0, y: 95.5, orientable: true },
		{ id: "worldclock", labelKey: "settings.hud.worldclock", fallback: "Zegar + pogoda",  x: 90.0, y: 1.5,  orientable: false },
		{ id: "chat",       labelKey: "settings.hud.chat",       fallback: "Czat",            x: 1.0,  y: 87.0, orientable: false }
	];

	function buildDefaults() {
		const out = {};
		ELEMENTS.forEach(function (el) {
			out[el.id] = { x: el.x, y: el.y, scale: 1.0, visible: true, orientation: "horizontal" };
		});
		return out;
	}

	const DEFAULT_SETTINGS = { hud: buildDefaults() };

	let state = JSON.parse(JSON.stringify(DEFAULT_SETTINGS));
	let activeTab = "hud";
	let editMode = false;
	let collapsed = false;
	let dragging = null;
	let resizing = null;
	let root = null;

	function deepMerge(target, src) {
		if (!src || typeof src !== "object") return target;
		Object.keys(src).forEach(function (k) {
			if (src[k] && typeof src[k] === "object" && !Array.isArray(src[k])) {
				if (!target[k] || typeof target[k] !== "object") target[k] = {};
				deepMerge(target[k], src[k]);
			} else {
				target[k] = src[k];
			}
		});
		return target;
	}

	function applyToHud() {
		if (!window.PhoenixHud || typeof window.PhoenixHud.applyLayout !== "function") {
			setTimeout(applyToHud, 100);
			return;
		}
		window.PhoenixHud.applyLayout(state.hud);
	}

	function loadFromString(raw) {
		if (!raw) return;
		try {
			const parsed = JSON.parse(raw);
			state = JSON.parse(JSON.stringify(DEFAULT_SETTINGS));
			deepMerge(state, parsed);
			applyToHud();
		} catch (e) {}
	}

	function persist() {
		try {
			const json = JSON.stringify(state);
			PhoenixBridge.send("phoenix:uisettings:save", { data: json });
			localStorage.setItem("phoenix:uisettings:v1", json);
		} catch (e) {}
	}

	function getElementNode(id) {
		if (window.PhoenixHud && typeof window.PhoenixHud.getElement === "function") {
			return window.PhoenixHud.getElement(id);
		}
		return null;
	}

	function setEditMode(on) {
		editMode = !!on;
		document.body.classList.toggle("phoenix-settings-editmode", editMode);
		ELEMENTS.forEach(function (el) {
			const node = getElementNode(el.id);
			if (!node) return;
			if (editMode) {
				attachEditOverlay(node, el);
			} else {
				detachEditOverlay(node);
			}
		});
		const btn = root && root.querySelector("[data-act='editmode']");
		if (btn) btn.textContent = editMode ? t("settings.editmode.exit", "WYJDŹ Z TRYBU EDYCJI") : t("settings.editmode.enter", "TRYB EDYCJI");
	}

	function toggleCollapsed() {
		collapsed = !collapsed;
		if (!root) return;
		root.classList.toggle("is-collapsed", collapsed);
		const btn = root.querySelector("[data-role='collapse']");
		if (btn) {
			btn.textContent = collapsed ? "›" : "‹";
			btn.title = t(collapsed ? "settings.expand" : "settings.collapse", collapsed ? "Rozwiń" : "Zwiń");
		}
	}

	function attachEditOverlay(node, el) {
		if (node.dataset.editAttached === "1") return;
		node.dataset.editAttached = "1";
		node.classList.add("phoenix-edit-target");
		node.dataset.editId = el.id;
		const cs = getComputedStyle(node);
		if (cs.position === "static") node.style.position = "fixed";

		const overlay = document.createElement("div");
		overlay.className = "phoenix-edit-overlay";
		overlay.dataset.editId = el.id;
		overlay.innerHTML =
			'<div class="phoenix-edit-overlay__label">' + t(el.labelKey, el.fallback) + '</div>' +
			'<div class="phoenix-edit-overlay__handle phoenix-edit-overlay__handle--resize" data-handle="resize" title="Skala">⤡</div>';
		node.appendChild(overlay);

		overlay.addEventListener("mousedown", function (e) {
			if (e.target.dataset && e.target.dataset.handle === "resize") {
				e.preventDefault();
				e.stopPropagation();
				startResize(el, e);
				return;
			}
			e.preventDefault();
			e.stopPropagation();
			startDrag(el, e);
		});
	}

	function detachEditOverlay(node) {
		if (!node) return;
		node.classList.remove("phoenix-edit-target");
		const overlays = node.querySelectorAll(".phoenix-edit-overlay");
		overlays.forEach(function (ov) { try { ov.remove(); } catch (e) {} });
		delete node.dataset.editAttached;
		delete node.dataset.editId;
	}

	function startDrag(el, e) {
		const node = getElementNode(el.id);
		if (!node) return;
		const rect = node.getBoundingClientRect();
		dragging = {
			el: el,
			node: node,
			startX: e.clientX,
			startY: e.clientY,
			startLeft: rect.left,
			startTop: rect.top
		};
		document.body.classList.add("phoenix-settings-dragging");
	}

	function startResize(el, e) {
		const node = getElementNode(el.id);
		if (!node) return;
		resizing = {
			el: el,
			node: node,
			startX: e.clientX,
			startY: e.clientY,
			startScale: state.hud[el.id].scale || 1
		};
		document.body.classList.add("phoenix-settings-dragging");
	}

	function onWindowMouseMove(e) {
		if (dragging) {
			const dx = e.clientX - dragging.startX;
			const dy = e.clientY - dragging.startY;
			const vw = window.innerWidth || 1;
			const vh = window.innerHeight || 1;
			const newLeft = Math.max(0, Math.min(vw - 1, dragging.startLeft + dx));
			const newTop = Math.max(0, Math.min(vh - 1, dragging.startTop + dy));
			state.hud[dragging.el.id].x = Math.round((newLeft / vw) * 1000) / 10;
			state.hud[dragging.el.id].y = Math.round((newTop / vh) * 1000) / 10;
			applyToHud();
			updateInputs();
		}
		if (resizing) {
			const dx = e.clientX - resizing.startX;
			const dy = e.clientY - resizing.startY;
			const delta = Math.max(dx, dy);
			const newScale = Math.max(0.5, Math.min(2.0, resizing.startScale + delta / 200));
			state.hud[resizing.el.id].scale = Math.round(newScale * 100) / 100;
			applyToHud();
			updateInputs();
		}
	}

	function onWindowMouseUp() {
		if (dragging || resizing) {
			persist();
		}
		dragging = null;
		resizing = null;
		document.body.classList.remove("phoenix-settings-dragging");
	}

	window.addEventListener("mousemove", onWindowMouseMove);
	window.addEventListener("mouseup", onWindowMouseUp);

	function updateInputs() {
		if (!root) return;
		ELEMENTS.forEach(function (el) {
			const cfg = state.hud[el.id];
			if (!cfg) return;
			["x", "y", "scale"].forEach(function (key) {
				const inp = root.querySelector("[data-elcfg='" + el.id + "'][data-key='" + key + "']");
				if (inp && inp !== document.activeElement) {
					inp.value = String(cfg[key]);
					const val = root.querySelector("[data-elval='" + el.id + "'][data-key='" + key + "']");
					if (val) val.textContent = (key === "scale") ? Number(cfg[key]).toFixed(2) : Number(cfg[key]).toFixed(1);
				}
			});
			const visInp = root.querySelector("[data-elvis='" + el.id + "']");
			if (visInp) visInp.checked = cfg.visible !== false;
		});
	}

	function buildLayout() {
		root.innerHTML = "";
		const shell = document.createElement("div");
		shell.className = "settings-shell";
		root.appendChild(shell);

		const head = document.createElement("div");
		head.className = "settings-head";
		head.innerHTML =
			'<h2 class="settings-head__title">' + t("settings.title", "USTAWIENIA") + '</h2>' +
			'<div class="settings-head__tools">' +
				'<button class="settings-head__collapse" data-role="collapse" title="' + t("settings.collapse", "Zwiń") + '">‹</button>' +
				'<button class="settings-head__close" data-role="close">' + t("settings.close", "ZAMKNIJ (ESC)") + '</button>' +
			'</div>';
		shell.appendChild(head);

		head.querySelector("[data-role='close']").addEventListener("click", function () {
			PhoenixBridge.send("phoenix:settings:closeRequest", {});
		});
		head.querySelector("[data-role='collapse']").addEventListener("click", function () {
			toggleCollapsed();
		});

		const body = document.createElement("div");
		body.className = "settings-body";
		shell.appendChild(body);

		const tabs = document.createElement("div");
		tabs.className = "settings-tabs";
		body.appendChild(tabs);

		const tabList = [
			{ id: "hud", labelKey: "settings.tab.hud", fallback: "HUD" },
			{ id: "other", labelKey: "settings.tab.other", fallback: "Inne" }
		];
		tabList.forEach(function (tab) {
			const btn = document.createElement("button");
			btn.className = "settings-tab" + (tab.id === activeTab ? " is-active" : "");
			btn.dataset.tab = tab.id;
			btn.textContent = t(tab.labelKey, tab.fallback);
			btn.addEventListener("click", function () {
				activeTab = tab.id;
				renderTabs();
				renderContent();
			});
			tabs.appendChild(btn);
		});

		const content = document.createElement("div");
		content.className = "settings-content";
		content.dataset.role = "content";
		body.appendChild(content);

		renderContent();
	}

	function renderTabs() {
		root.querySelectorAll(".settings-tab").forEach(function (btn) {
			btn.classList.toggle("is-active", btn.dataset.tab === activeTab);
		});
	}

	function renderContent() {
		const content = root.querySelector("[data-role='content']");
		if (!content) return;
		content.innerHTML = "";
		if (activeTab === "hud") renderHudTab(content);
		else if (activeTab === "other") renderOtherTab(content);
	}

	function renderHudTab(content) {
		const editBar = document.createElement("div");
		editBar.className = "settings-editbar";
		const editBtn = document.createElement("button");
		editBtn.className = "settings-btn settings-btn--primary";
		editBtn.dataset.act = "editmode";
		editBtn.textContent = editMode ? t("settings.editmode.exit", "WYJDŹ Z TRYBU EDYCJI") : t("settings.editmode.enter", "TRYB EDYCJI");
		editBtn.addEventListener("click", function () { setEditMode(!editMode); });
		editBar.appendChild(editBtn);
		const editHint = document.createElement("p");
		editHint.className = "settings-hint";
		editHint.textContent = t("settings.editmode.hint", "W trybie edycji złap dowolny element myszą żeby go przesunąć. Złap rożek (⤡) żeby skalować.");
		editBar.appendChild(editHint);
		content.appendChild(editBar);

		ELEMENTS.forEach(function (el) {
			const cfg = state.hud[el.id] || { x: 0, y: 0, scale: 1, visible: true };
			const section = document.createElement("div");
			section.className = "settings-section";

			const title = document.createElement("h3");
			title.className = "settings-section__title";
			const titleSpan = document.createElement("span");
			titleSpan.textContent = t(el.labelKey, el.fallback);
			title.appendChild(titleSpan);
			const toggle = document.createElement("label");
			toggle.className = "settings-toggle";
			toggle.innerHTML = '<input type="checkbox" data-elvis="' + el.id + '"' + (cfg.visible !== false ? " checked" : "") + '> <span>' + t("settings.visible", "Widoczne") + '</span>';
			toggle.querySelector("input").addEventListener("change", function (e) {
				state.hud[el.id].visible = !!e.target.checked;
				applyToHud();
				persist();
			});
			title.appendChild(toggle);
			section.appendChild(title);

			section.appendChild(makeSlider(el.id, "x", "X (%)", 0, 100, 0.1, cfg.x));
			section.appendChild(makeSlider(el.id, "y", "Y (%)", 0, 100, 0.1, cfg.y));
			section.appendChild(makeSlider(el.id, "scale", t("settings.scale", "Skala"), 0.5, 2.0, 0.05, cfg.scale));

			if (el.orientable) {
				section.appendChild(makeOrientation(el.id, cfg.orientation || "horizontal"));
			}

			content.appendChild(section);
		});

		const actions = document.createElement("div");
		actions.className = "settings-actions";
		actions.innerHTML =
			'<button class="settings-btn settings-btn--primary" data-act="save">' + t("settings.save", "Zapisz") + '</button>' +
			'<button class="settings-btn" data-act="reset">' + t("settings.reset", "Reset domyślny") + '</button>';
		content.appendChild(actions);

		actions.querySelector("[data-act='save']").addEventListener("click", function () {
			persist();
		});
		actions.querySelector("[data-act='reset']").addEventListener("click", function () {
			state = JSON.parse(JSON.stringify(DEFAULT_SETTINGS));
			applyToHud();
			persist();
			renderContent();
		});
	}

	function renderOtherTab(content) {
		const hint = document.createElement("p");
		hint.className = "settings-hint";
		hint.textContent = t("settings.other.hint", "Wkrótce więcej opcji.");
		content.appendChild(hint);
	}

	function makeOrientation(elId, current) {
		const row = document.createElement("div");
		row.className = "settings-row settings-row--toggle";
		const lab = document.createElement("label");
		lab.textContent = t("settings.orientation", "Orientacja");
		const wrap = document.createElement("div");
		wrap.className = "settings-orient";
		["horizontal", "vertical"].forEach(function (orient) {
			const btn = document.createElement("button");
			btn.type = "button";
			btn.className = "settings-orient__btn" + (current === orient ? " is-active" : "");
			btn.dataset.orient = orient;
			btn.textContent = orient === "horizontal" ? t("settings.orientation.horizontal", "Pozioma") : t("settings.orientation.vertical", "Pionowa");
			btn.addEventListener("click", function () {
				state.hud[elId].orientation = orient;
				wrap.querySelectorAll(".settings-orient__btn").forEach(function (b) {
					b.classList.toggle("is-active", b.dataset.orient === orient);
				});
				applyToHud();
				persist();
			});
			wrap.appendChild(btn);
		});
		row.appendChild(lab);
		row.appendChild(wrap);
		return row;
	}

	function makeSlider(elId, key, label, min, max, step, value) {
		const row = document.createElement("div");
		row.className = "settings-row";
		const lab = document.createElement("label");
		lab.textContent = label;
		const range = document.createElement("input");
		range.type = "range";
		range.min = String(min);
		range.max = String(max);
		range.step = String(step);
		range.value = String(value);
		range.dataset.elcfg = elId;
		range.dataset.key = key;
		const val = document.createElement("span");
		val.className = "settings-value";
		val.dataset.elval = elId;
		val.dataset.key = key;
		val.textContent = (key === "scale") ? Number(value).toFixed(2) : Number(value).toFixed(1);
		range.addEventListener("input", function () {
			const v = parseFloat(range.value) || 0;
			state.hud[elId][key] = v;
			val.textContent = (key === "scale") ? v.toFixed(2) : v.toFixed(1);
			applyToHud();
		});
		range.addEventListener("change", function () { persist(); });
		row.appendChild(lab);
		row.appendChild(range);
		row.appendChild(val);
		return row;
	}

	function init() {
		try {
			const cached = localStorage.getItem("phoenix:uisettings:v1");
			if (cached) loadFromString(cached);
		} catch (e) {}

		PhoenixBridge.on("phoenix:uisettings:snapshot", function (payload) {
			if (!payload) return;
			loadFromString(payload.data || "");
		});
	}

	init();

	app.register("settings", {
		onShow: function () {
			root = document.getElementById("page-settings");
			if (!root) return;
			buildLayout();
			applyToHud();
		},
		onHide: function () {
			persist();
			if (editMode) setEditMode(false);
		}
	});

	window.PhoenixSettings = {
		state: function () { return state; },
		apply: applyToHud
	};
})();
