(function (global) {
	"use strict";

	var bridge = global.PhoenixBridge;
	var minimap = global.PhoenixMinimap;
	var i18n = global.PhoenixI18n;
	if (!bridge || !minimap) return;

	var STORAGE_KEY = "phoenix.worldMap.markers.v1";
	var MAX_MARKERS = 100;
	var root = null;
	var image = null;
	var marker = null;
	var mapSurface = null;
	var customLayer = null;
	var playerLayer = null;
	var markerInput = null;
	var activeMap = "newworld";
	var lastPosition = null;
	var lastState = null;
	var lastPlayers = [];
	var markers = loadMarkers();
	var isAdmin = false;
	var isOpen = false;
	var mapSelectedByUser = false;
	var markerMode = false;
	var showPlayers = false;

	function t(key, fallback) {
		var value = key;
		try { if (i18n && i18n.t) value = i18n.t(key); } catch (e) {}
		return value && value !== key ? value : (fallback || key);
	}

	function clamp(value, min, max) {
		return Math.max(min, Math.min(max, value));
	}

	function isNumber(value) {
		return typeof value === "number" && isFinite(value);
	}

	function insideMap(mapKey, x, z) {
		var map = minimap.maps[mapKey];
		if (!map || !isNumber(x) || !isNumber(z)) return false;
		return x >= Math.min(map.x1, map.x2) && x <= Math.max(map.x1, map.x2) && z >= Math.min(map.z1, map.z2) && z <= Math.max(map.z1, map.z2);
	}
	function loadMarkers() {
		var raw = [];
		try { raw = JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]"); } catch (e) { raw = []; }
		if (!Array.isArray(raw)) return [];
		return raw.filter(function (entry) {
			return entry && typeof entry.id === "string" && (entry.map === "newworld" || entry.map === "city") && insideMap(entry.map, entry.x, entry.z);
		}).slice(0, MAX_MARKERS).map(function (entry) {
			return {
				id: entry.id.slice(0, 64),
				map: entry.map,
				x: Number(entry.x),
				z: Number(entry.z),
				label: String(entry.label || "").slice(0, 48),
				createdAt: Number(entry.createdAt) || 0
			};
		});
	}

	function saveMarkers() {
		try { localStorage.setItem(STORAGE_KEY, JSON.stringify(markers)); } catch (e) {}
	}

	function setNodePosition(node, x, z) {
		var map = minimap.maps[activeMap];
		var u = clamp((x - map.x1) / (map.x2 - map.x1), 0, 1);
		var v = clamp((z - map.z1) / (map.z2 - map.z1), 0, 1);
		node.style.left = (u * 100) + "%";
		node.style.top = (v * 100) + "%";
	}

	function markerCoordinates(event) {
		var rect = mapSurface.getBoundingClientRect();
		var u = clamp((event.clientX - rect.left) / rect.width, 0, 1);
		var v = clamp((event.clientY - rect.top) / rect.height, 0, 1);
		var map = minimap.maps[activeMap];
		return { x: map.x1 + u * (map.x2 - map.x1), z: map.z1 + v * (map.z2 - map.z1) };
	}

	function build() {
		if (root) return;
		root = document.createElement("section");
		root.id = "phoenix-adminmap";
		root.className = "phoenix-adminmap";
		root.innerHTML =
			'<header class="phoenix-adminmap__header">' +
				'<div><strong data-role="adminmap-title"></strong><span class="phoenix-adminmap__subtitle" data-role="adminmap-subtitle"></span></div>' +
				'<div class="phoenix-adminmap__header-actions">' +
					'<div class="phoenix-adminmap__tools phoenix-adminmap__admin-only">' +
						'<button type="button" data-tool="fly"></button>' +
						'<button type="button" data-tool="freecam"></button>' +
						'<button type="button" data-tool="godmode"></button>' +
					'</div>' +
					'<button type="button" class="phoenix-adminmap__button phoenix-adminmap__close"></button>' +
				'</div>' +
			'</header>' +
			'<div class="phoenix-adminmap__stage">' +
				'<div class="phoenix-adminmap__controls">' +
					'<div class="phoenix-adminmap__switches">' +
						'<button type="button" data-map="newworld"></button>' +
						'<button type="button" data-map="city"></button>' +
					'</div>' +
					'<input class="phoenix-adminmap__marker-input" type="text" maxlength="48">' +
					'<button type="button" data-action="add-marker"></button>' +
					'<button type="button" data-action="clear-markers"></button>' +
					'<button type="button" class="phoenix-adminmap__admin-only" data-action="players"></button>' +
				'</div>' +
				'<div class="phoenix-adminmap__map">' +
					'<img class="phoenix-adminmap__image" draggable="false">' +
					'<div class="phoenix-adminmap__layer phoenix-adminmap__custom-layer"></div>' +
					'<div class="phoenix-adminmap__layer phoenix-adminmap__player-layer"></div>' +
					'<span class="phoenix-adminmap__marker"><i></i></span>' +
				'</div>' +
				'<div class="phoenix-adminmap__hint" data-role="adminmap-hint"></div>' +
			'</div>';
		document.body.appendChild(root);
		image = root.querySelector(".phoenix-adminmap__image");
		marker = root.querySelector(".phoenix-adminmap__marker");
		mapSurface = root.querySelector(".phoenix-adminmap__map");
		customLayer = root.querySelector(".phoenix-adminmap__custom-layer");
		playerLayer = root.querySelector(".phoenix-adminmap__player-layer");
		markerInput = root.querySelector(".phoenix-adminmap__marker-input");
		root.querySelector(".phoenix-adminmap__close").addEventListener("click", function () {
			bridge.send("phoenix:adminmap:close", null);
		});
		root.querySelector(".phoenix-adminmap__tools").addEventListener("click", function (event) {
			var button = event.target.closest("[data-tool]");
			if (!button || !isAdmin) return;
			bridge.send("phoenix:adminmap:tool", { action: button.getAttribute("data-tool") });
		});
		root.querySelector(".phoenix-adminmap__controls").addEventListener("click", function (event) {
			var mapButton = event.target.closest("[data-map]");
			if (mapButton) {
				selectMap(mapButton.getAttribute("data-map"), true);
				return;
			}
			var actionButton = event.target.closest("[data-action]");
			if (!actionButton) return;
			var action = actionButton.getAttribute("data-action");
			if (action === "add-marker") markerMode = !markerMode;
			if (action === "clear-markers") {
				markers = markers.filter(function (entry) { return entry.map !== activeMap; });
				saveMarkers();
				renderCustomMarkers();
			}
			if (action === "players" && isAdmin) {
				showPlayers = !showPlayers;
				lastPlayers = [];
				bridge.send("phoenix:adminmap:playersToggle", { enabled: showPlayers, map: activeMap });
				renderPlayers();
			}
			renderControls();
			translateHint();
		});
		mapSurface.addEventListener("click", function (event) {
			if (!isOpen) return;
			var customMarker = event.target.closest("[data-marker-id]");
			if (customMarker) {
				removeMarker(customMarker.getAttribute("data-marker-id"));
				return;
			}
			var coordinates = markerCoordinates(event);
			if (markerMode) {
				addMarker(coordinates.x, coordinates.z);
				return;
			}
			if (isAdmin) bridge.send("phoenix:adminmap:teleport", { map: activeMap, x: coordinates.x, z: coordinates.z });
		});
		root.classList.toggle("is-admin", isAdmin);
		selectMap(activeMap, false);
		translateUi();
	}
	function selectMap(key, byUser) {
		if (!minimap.maps[key]) return;
		var changed = activeMap !== key;
		activeMap = key;
		if (byUser) mapSelectedByUser = true;
		if (image) image.src = minimap.maps[key].image;
		if (changed) {
			lastPlayers = [];
			bridge.send("phoenix:adminmap:map", { map: activeMap });
		}
		renderCurrentPosition();
		renderCustomMarkers();
		renderPlayers();
		renderControls();
		translateUi();
	}

	function addMarker(x, z) {
		if (markers.length >= MAX_MARKERS || !insideMap(activeMap, x, z)) return;
		var label = markerInput ? markerInput.value.replace(/^\s+|\s+$/g, "").slice(0, 48) : "";
		if (!label) label = t("admin.map.marker.default", "Marker") + " " + (markers.length + 1);
		markers.push({
			id: "m-" + Date.now() + "-" + Math.floor(Math.random() * 1000000),
			map: activeMap,
			x: x,
			z: z,
			label: label,
			createdAt: Date.now()
		});
		markerMode = false;
		if (markerInput) markerInput.value = "";
		saveMarkers();
		renderCustomMarkers();
		renderControls();
		translateHint();
	}

	function removeMarker(id) {
		markers = markers.filter(function (entry) { return entry.id !== id; });
		saveMarkers();
		renderCustomMarkers();
		renderControls();
	}

	function renderCustomMarkers() {
		if (!customLayer) return;
		customLayer.innerHTML = "";
		markers.forEach(function (entry) {
			if (entry.map !== activeMap) return;
			var node = document.createElement("button");
			node.type = "button";
			node.className = "phoenix-adminmap__custom-marker";
			node.setAttribute("data-marker-id", entry.id);
			node.title = t("admin.map.marker.remove", "Click to remove marker");
			setNodePosition(node, entry.x, entry.z);
			var label = document.createElement("span");
			label.textContent = entry.label;
			node.appendChild(label);
			customLayer.appendChild(node);
		});
	}
	function renderPlayers() {
		if (!playerLayer) return;
		playerLayer.innerHTML = "";
		if (!isAdmin || !showPlayers || !isOpen) return;
		lastPlayers.forEach(function (entry) {
			var x = Number(entry.x);
			var z = Number(entry.z);
			if (!insideMap(activeMap, x, z)) return;
			var node = document.createElement("div");
			node.className = "phoenix-adminmap__player";
			setNodePosition(node, x, z);
			var dot = document.createElement("i");
			var label = document.createElement("span");
			label.textContent = String(entry.name || "Gracz").slice(0, 48);
			node.appendChild(dot);
			node.appendChild(label);
			playerLayer.appendChild(node);
		});
	}

	function renderCurrentPosition() {
		if (!marker) return;
		var x = lastPosition ? Number(lastPosition.x) : NaN;
		var z = lastPosition ? Number(lastPosition.z) : NaN;
		if (!insideMap(activeMap, x, z)) {
			marker.style.display = "none";
			return;
		}
		marker.style.display = "block";
		setNodePosition(marker, x, z);
		marker.style.transform = "translate(-50%, -50%) rotate(" + (Number(lastPosition.angle) || 0) + "deg)";
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

	function renderControls() {
		if (!root) return;
		root.querySelectorAll("[data-map]").forEach(function (button) {
			button.classList.toggle("is-active", button.getAttribute("data-map") === activeMap);
		});
		root.querySelector('[data-action="add-marker"]').classList.toggle("is-active", markerMode);
		root.querySelector('[data-action="players"]').classList.toggle("is-active", showPlayers);
		root.querySelector('[data-action="clear-markers"]').disabled = !markers.some(function (entry) { return entry.map === activeMap; });
	}

	function translateHint() {
		if (!root) return;
		var key = markerMode ? "admin.map.marker.placeHint" : (isAdmin ? "admin.map.teleportHint" : "admin.map.marker.playerHint");
		var fallback = markerMode ? "Kliknij na mapie, aby dodać znacznik" : (isAdmin ? "Kliknij na mapie, aby się teleportować" : "Dodaj własne znaczniki na mapie");
		root.querySelector('[data-role="adminmap-hint"]').textContent = t(key, fallback);
	}
	function translateUi() {
		if (!root) return;
		root.querySelector('[data-role="adminmap-title"]').textContent = t(isAdmin ? "admin.map.title" : "admin.map.playerTitle", isAdmin ? "MAPA ADMINISTRATORA" : "MAPA ŚWIATA");
		root.querySelector('[data-role="adminmap-subtitle"]').textContent = t(isAdmin ? "admin.map.shortcut" : "admin.map.playerShortcut", "M") + " · " + t("admin.map.name." + activeMap, activeMap);
		root.querySelector(".phoenix-adminmap__close").textContent = t("admin.a.close", "Zamknij");
		root.querySelector('[data-map="newworld"]').textContent = t("admin.map.switch.world", "Świat");
		root.querySelector('[data-map="city"]').textContent = t("admin.map.switch.city", "Khorinis");
		root.querySelector('[data-action="add-marker"]').textContent = t("admin.map.marker.add", "Dodaj znacznik");
		root.querySelector('[data-action="clear-markers"]').textContent = t("admin.map.marker.clear", "Wyczyść znaczniki");
		root.querySelector('[data-action="players"]').textContent = t("admin.map.players", "Gracze") + ": " + t(showPlayers ? "admin.map.state.on" : "admin.map.state.off", showPlayers ? "ON" : "OFF");
		markerInput.placeholder = t("admin.map.marker.placeholder", "Nazwa znacznika");
		image.alt = t("admin.map.worldAlt", "Mapa świata");
		renderState();
		renderControls();
		translateHint();
		renderCustomMarkers();
	}

	function updatePosition(payload) {
		if (!payload) return;
		lastPosition = payload;
		build();
		if (!mapSelectedByUser) selectMap(minimap.selectMap(Number(payload.x) || 0, Number(payload.z) || 0), false);
		else renderCurrentPosition();
	}

	function open() {
		build();
		isOpen = true;
		mapSelectedByUser = false;
		if (lastPosition) selectMap(minimap.selectMap(Number(lastPosition.x) || 0, Number(lastPosition.z) || 0), false);
		root.classList.add("is-open");
		renderCurrentPosition();
		renderPlayers();
	}

	function close() {
		if (!root) return;
		isOpen = false;
		markerMode = false;
		showPlayers = false;
		lastPlayers = [];
		root.classList.remove("is-open");
		renderPlayers();
		renderControls();
	}

	function setIdentity(payload) {
		isAdmin = !!(payload && payload.isAdmin);
		if (!isAdmin && showPlayers) {
			showPlayers = false;
			lastPlayers = [];
			bridge.send("phoenix:adminmap:playersToggle", { enabled: false, map: activeMap });
		}
		if (root) {
			root.classList.toggle("is-admin", isAdmin);
			translateUi();
			renderPlayers();
		}
	}
	function setState(payload) {
		if (!payload) return;
		lastState = payload;
		renderState();
	}

	function setPlayers(payload) {
		if (!isAdmin || !showPlayers || !isOpen || !payload || payload.map !== activeMap || !Array.isArray(payload.players)) return;
		lastPlayers = payload.players.slice(0, 64);
		renderPlayers();
	}

	bridge.on("phoenix:account:identity", setIdentity);
	bridge.on("phoenix:minimap:update", updatePosition);
	bridge.on("phoenix:adminmap:open", open);
	bridge.on("phoenix:adminmap:close", close);
	bridge.on("phoenix:adminmap:state", setState);
	bridge.on("phoenix:adminmap:players", setPlayers);
	if (i18n && i18n.onChange) i18n.onChange(function () { translateUi(); });
})(window);