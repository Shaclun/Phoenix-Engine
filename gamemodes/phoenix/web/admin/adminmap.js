(function (global) {
	"use strict";

	var bridge = global.PhoenixBridge;
	var minimap = global.PhoenixMinimap;
	var i18n = global.PhoenixI18n;
	if (!bridge || !minimap) return;

	var root = null;
	var image = null;
	var marker = null;
	var mapSurface = null;
	var activeMap = "newworld";
	var lastPosition = null;
	var lastState = null;
	var isAdmin = false;
	var isOpen = false;

	function t(key, fallback) {
		var value = key;
		try { if (i18n && i18n.t) value = i18n.t(key); } catch (e) {}
		return value && value !== key ? value : (fallback || key);
	}

	function clamp(value, min, max) {
		return Math.max(min, Math.min(max, value));
	}

	function build() {
		if (root) return;
		root = document.createElement("section");
		root.id = "phoenix-adminmap";
		root.className = "phoenix-adminmap";
		root.innerHTML =
			'<header class="phoenix-adminmap__header">' +
				'<div><strong data-role="adminmap-title">MAPA ADMINISTRATORA</strong><span class="phoenix-adminmap__subtitle" data-role="adminmap-subtitle">M · teleportacja</span></div>' +
				'<div class="phoenix-adminmap__tools">' +
					'<button type="button" data-tool="fly">Latanie</button>' +
					'<button type="button" data-tool="freecam">Wolna kamera</button>' +
					'<button type="button" data-tool="godmode">Tryb boga</button>' +
					'<button type="button" class="phoenix-adminmap__close">Zamknij</button>' +
				'</div>' +
			'</header>' +
			'<div class="phoenix-adminmap__stage">' +
				'<div class="phoenix-adminmap__map">' +
					'<img class="phoenix-adminmap__image" draggable="false" alt="Mapa świata">' +
					'<span class="phoenix-adminmap__marker"><i></i></span>' +
				'</div>' +
				'<div class="phoenix-adminmap__hint" data-role="adminmap-hint">Kliknij na mapie, aby się teleportować</div>' +
			'</div>';
		document.body.appendChild(root);
		image = root.querySelector(".phoenix-adminmap__image");
		marker = root.querySelector(".phoenix-adminmap__marker");
		mapSurface = root.querySelector(".phoenix-adminmap__map");
		root.querySelector(".phoenix-adminmap__close").addEventListener("click", function () {
			bridge.send("phoenix:adminmap:close", null);
		});
		root.querySelector(".phoenix-adminmap__tools").addEventListener("click", function (event) {
			var button = event.target.closest("[data-tool]");
			if (!button) return;
			bridge.send("phoenix:adminmap:tool", { action: button.getAttribute("data-tool") });
		});
		mapSurface.addEventListener("click", function (event) {
			if (!isOpen || !isAdmin) return;
			var rect = mapSurface.getBoundingClientRect();
			var u = clamp((event.clientX - rect.left) / rect.width, 0, 1);
			var v = clamp((event.clientY - rect.top) / rect.height, 0, 1);
			var map = minimap.maps[activeMap];
			bridge.send("phoenix:adminmap:teleport", {
				map: activeMap,
				x: map.x1 + u * (map.x2 - map.x1),
				z: map.z1 + v * (map.z2 - map.z1)
			});
		});
		translateUi();
	}

	function selectMap(key) {
		if (!minimap.maps[key] || activeMap === key) return;
		activeMap = key;
		image.src = minimap.maps[key].image;
		translateUi();
	}

	function updatePosition(payload) {
		if (!payload) return;
		lastPosition = payload;
		build();
		var key = minimap.selectMap(Number(payload.x) || 0, Number(payload.z) || 0);
		selectMap(key);
		if (!image.getAttribute("src")) image.src = minimap.maps[activeMap].image;
		var map = minimap.maps[activeMap];
		var u = clamp((Number(payload.x) - map.x1) / (map.x2 - map.x1), 0, 1);
		var v = clamp((Number(payload.z) - map.z1) / (map.z2 - map.z1), 0, 1);
		marker.style.left = (u * 100) + "%";
		marker.style.top = (v * 100) + "%";
		marker.style.transform = "translate(-50%, -50%) rotate(" + (Number(payload.angle) || 0) + "deg)";
	}

	function open() {
		if (!isAdmin) return;
		build();
		isOpen = true;
		root.classList.add("is-open");
		if (lastPosition) updatePosition(lastPosition);
	}

	function close() {
		if (!root) return;
		isOpen = false;
		root.classList.remove("is-open");
	}
	function setIdentity(payload) {
		isAdmin = !!(payload && payload.isAdmin);
		if (!isAdmin) close();
	}

	function renderState() {
		if (!root) return;
		var state = lastState || {};
		["fly", "freecam", "godmode"].forEach(function (action) {
			var button = root.querySelector('[data-tool="' + action + '"]');
			var enabled = !!state[action];
			button.classList.toggle("is-active", enabled);
			button.textContent = t("admin.map.tool." + action, action) + ": " + t(enabled ? "admin.map.state.on" : "admin.map.state.off", enabled ? "ON" : "OFF");
		});
	}

	function translateUi() {
		if (!root) return;
		root.querySelector('[data-role="adminmap-title"]').textContent = t("admin.map.title", "MAPA ADMINISTRATORA");
		root.querySelector('[data-role="adminmap-subtitle"]').textContent = t("admin.map.shortcut", "M · teleportacja") + " · " + t("admin.map.name." + activeMap, activeMap);
		root.querySelector(".phoenix-adminmap__close").textContent = t("admin.a.close", "Zamknij");
		root.querySelector('[data-role="adminmap-hint"]').textContent = t("admin.map.teleportHint", "Kliknij na mapie, aby się teleportować");
		image.alt = t("admin.map.worldAlt", "Mapa świata");
		renderState();
	}

	function setState(payload) {
		if (!payload) return;
		lastState = payload;
		renderState();
	}

	bridge.on("phoenix:account:identity", setIdentity);
	bridge.on("phoenix:minimap:update", updatePosition);
	bridge.on("phoenix:adminmap:open", open);
	bridge.on("phoenix:adminmap:close", close);
	bridge.on("phoenix:adminmap:state", setState);
	if (i18n && i18n.onChange) i18n.onChange(function () { translateUi(); });
})(window);