(function (global) {
	"use strict";

	const MAP_WIDTH = 1024;
	const MAP_HEIGHT = 768;
	const MAPS = {
		newworld: { image: "shared/minimap/map_newworld.png", x1: -28000, z1: 50500, x2: 95500, z2: -42500, zoom: 4.0 },
		city: { image: "shared/minimap/map_nwcity.png", x1: -6900, z1: 11800, x2: 21600, z2: -9400, zoom: 3.35 }
	};

	let nodes = null;
	let activeMap = "";
	let hudVisible = false;
	let featureVisible = true;
	let lastPayload = null;

	function clamp(value, min, max) { return Math.max(min, Math.min(max, value)); }
	function finite(value, fallback) { const n = Number(value); return Number.isFinite(n) ? n : fallback; }

	function ensure() {
		if (nodes) return nodes;
		const root = document.createElement("section");
		root.id = "phoenix-minimap";
		root.className = "phoenix-minimap";
		root.dataset.hudId = "minimap";
		root.innerHTML =
			'<div class="phoenix-minimap__frame">' +
				'<div class="phoenix-minimap__viewport"><img class="phoenix-minimap__image" alt="" draggable="false"></div>' +
				'<span class="phoenix-minimap__north" aria-hidden="true">N</span>' +
				'<span class="phoenix-minimap__marker" aria-hidden="true"><i></i></span>' +
				'<span class="phoenix-minimap__shade" aria-hidden="true"></span>' +
				'<span class="phoenix-minimap__ornament phoenix-minimap__ornament--top" aria-hidden="true"></span>' +
				'<span class="phoenix-minimap__ornament phoenix-minimap__ornament--bottom" aria-hidden="true"></span>' +
			'</div>' +
			'<div class="phoenix-minimap__meta" id="phoenix-minimap-meta"></div>';
		document.body.appendChild(root);
		const meta = root.querySelector("#phoenix-minimap-meta");
		const existingClock = document.getElementById("phoenix-worldclock");
		if (existingClock && meta) meta.appendChild(existingClock);
		nodes = {
			root: root,
			frame: root.querySelector(".phoenix-minimap__frame"),
			image: root.querySelector(".phoenix-minimap__image"),
			marker: root.querySelector(".phoenix-minimap__marker")
		};
		return nodes;
	}

	function selectMap(x, z) {
		// Obszar aktywacji miasta jest celowo mniejszy od granic tekstury,
		// aby mapa świata pojawiała się już na obrzeżach.
		return x > -4500 && x < 19000 && z < 9000 && z > -7000 ? "city" : "newworld";
	}

	function render(payload) {
		const view = ensure();
		if (!payload) return;
		lastPayload = payload;
		const x = finite(payload.x, 0);
		const z = finite(payload.z, 0);
		const mapKey = selectMap(x, z);
		const map = MAPS[mapKey];
		if (activeMap !== mapKey) {
			activeMap = mapKey;
			view.root.classList.add("is-switching");
			view.image.src = map.image;
			setTimeout(function () { if (nodes) nodes.root.classList.remove("is-switching"); }, 180);
		}

		const width = Math.max(1, view.frame.clientWidth || 232);
		const u = clamp((x - map.x1) / (map.x2 - map.x1), 0, 1);
		const v = clamp((z - map.z1) / (map.z2 - map.z1), 0, 1);
		const imageWidth = width * map.zoom;
		const imageHeight = imageWidth * (MAP_HEIGHT / MAP_WIDTH);
		view.image.style.width = imageWidth + "px";
		view.image.style.height = imageHeight + "px";
		view.image.style.left = (width * 0.5 - u * imageWidth) + "px";
		view.image.style.top = (width * 0.5 - v * imageHeight) + "px";
		view.marker.style.transform = "translate(-50%, -50%) rotate(" + finite(payload.angle, 0) + "deg)";
		view.root.classList.toggle("is-visible", hudVisible && featureVisible);
	}

	function setVisible(value) {
		hudVisible = !!value;
		const view = ensure();
		view.root.classList.toggle("is-visible", hudVisible && featureVisible && !!lastPayload);
	}

	function setFeatureEnabled(value) {
		featureVisible = value !== false;
		const view = ensure();
		view.root.classList.toggle("is-visible", hudVisible && featureVisible && !!lastPayload);
	}

	ensure();
	if (global.PhoenixBridge) {
		PhoenixBridge.on("phoenix:minimap:update", render);
		PhoenixBridge.on("phoenix:hud:show", function () { setVisible(true); });
		PhoenixBridge.on("phoenix:hud:hide", function () { setVisible(false); });
		PhoenixBridge.on("phoenix:features:snapshot", function (payload) {
			const flags = payload && payload.settings && payload.settings.flags;
			const enabled = !flags || !flags.minimap || flags.minimap.enabled !== false;
			setFeatureEnabled(enabled);
		});
	}

	global.PhoenixMinimap = {
		ensure: ensure,
		render: render,
		setVisible: setVisible,
		setFeatureEnabled: setFeatureEnabled,
		maps: MAPS,
		selectMap: selectMap,
		width: MAP_WIDTH,
		height: MAP_HEIGHT
	};
})(window);