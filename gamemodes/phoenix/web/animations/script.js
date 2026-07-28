(function () {
	"use strict";
	const root = document.getElementById("page-animations");
	if (!root) return;
	const state = {
		catalog: [],
		bindings: new Array(12).fill(""),
		characterId: 0,
		activeId: "",
		selectedId: "",
		selectedSlot: 0,
		category: "all",
		query: "",
		enabled: true,
		toastTimer: null
	};

	function t(key) {
		return window.PhoenixI18n && PhoenixI18n.t ? PhoenixI18n.t(key) : key;
	}

	function escapeHtml(value) {
		return String(value == null ? "" : value).replace(/[&<>'"]/g, function (char) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", "\"": "&quot;" }[char];
		});
	}

	function storageKey() {
		return "phoenix:animations:v1:" + state.characterId;
	}

	function byId(id) {
		return state.catalog.find(function (entry) { return entry.id === id; }) || null;
	}

	function normalizeBindings(source) {
		const output = new Array(12).fill("");
		if (!Array.isArray(source)) return output;
		for (let i = 0; i < 12 && i < source.length; i += 1) {
			const entry = byId(String(source[i] || ""));
			if (entry && entry.playable) output[i] = entry.id;
		}
		return output;
	}

	function loadBindings() {
		if (state.characterId <= 0) return new Array(12).fill("");
		try { return normalizeBindings(JSON.parse(localStorage.getItem(storageKey()) || "[]")); }
		catch (e) { return new Array(12).fill(""); }
	}

	function syncBindings() {
		if (state.characterId <= 0) return;
		try { localStorage.setItem(storageKey(), JSON.stringify(state.bindings)); } catch (e) {}
		PhoenixBridge.send("phoenix:animations:bindings", { slots: state.bindings });
	}

	function featureEnabled(payload) {
		try { return payload.settings.flags.player.animations !== false; } catch (e) { return true; }
	}

	function filteredEntries() {
		const query = state.query.trim().toLocaleLowerCase();
		return state.catalog.filter(function (entry) {
			if (state.category !== "all" && entry.category !== state.category) return false;
			if (!query) return true;
			return (t(entry.labelKey) + " " + entry.id).toLocaleLowerCase().indexOf(query) !== -1;
		});
	}

	function slotMarkup() {
		return state.bindings.map(function (id, index) {
			const entry = byId(id);
			const selected = state.selectedSlot === index ? " is-selected" : "";
			const occupied = entry ? " is-filled" : "";
			return '<button class="anim-slot' + selected + occupied + '" type="button" data-slot="' + index + '" draggable="false">' +
				'<span class="anim-slot__key">F' + (index + 1) + '</span>' +
				'<span class="anim-slot__name">' + escapeHtml(entry ? t(entry.labelKey) : t("animations.slot.empty")) + '</span>' +
				(entry ? '<span class="anim-slot__clear" data-clear-slot="' + index + '" aria-label="' + escapeHtml(t("animations.action.clear")) + '">×</span>' : '') +
				'</button>';
		}).join("");
	}

	function cardMarkup(entry) {
		const selected = state.selectedId === entry.id ? " is-selected" : "";
		const active = state.activeId === entry.id ? " is-active" : "";
		const blocked = entry.playable ? "" : " is-blocked";
		const badge = entry.playable ? t("animations.status.available") : t("animations.status.locked");
		return '<article class="anim-card' + selected + active + blocked + '" data-animation-id="' + escapeHtml(entry.id) + '" draggable="' + (entry.playable ? "true" : "false") + '">' +
			'<span class="anim-card__sigil">' + (entry.playable ? "◆" : "◇") + '</span>' +
			'<div class="anim-card__copy"><strong>' + escapeHtml(t(entry.labelKey)) + '</strong><small>' + escapeHtml(t("animations.category." + entry.category)) + '</small></div>' +
			'<span class="anim-card__badge">' + escapeHtml(badge) + '</span>' +
			'</article>';
	}

	function detailMarkup() {
		const entry = byId(state.selectedId) || filteredEntries()[0] || null;
		if (!entry) return '<div class="anim-detail__empty">' + escapeHtml(t("animations.empty")) + '</div>';
		state.selectedId = entry.id;
		const reason = entry.playable ? t("animations.detail.ready") : t("animations.reason." + entry.reason);
		return '<div class="anim-detail__sigil">✦</div>' +
			'<span class="anim-detail__category">' + escapeHtml(t("animations.category." + entry.category)) + '</span>' +
			'<h2>' + escapeHtml(t(entry.labelKey)) + '</h2>' +
			'<p>' + escapeHtml(reason) + '</p>' +
			'<div class="anim-detail__slot"><span>' + escapeHtml(t("animations.detail.targetSlot")) + '</span><strong>F' + (state.selectedSlot + 1) + '</strong></div>' +
			'<div class="anim-detail__actions">' +
			'<button type="button" data-action="play"' + (entry.playable ? "" : " disabled") + '>' + escapeHtml(t("animations.action.play")) + '</button>' +
			'<button type="button" data-action="assign" class="is-gold"' + (entry.playable ? "" : " disabled") + '>' + escapeHtml(t("animations.action.assign")) + '</button>' +
			'</div>';
	}

	function render() {
		const entries = filteredEntries();
		root.innerHTML = '<div class="anim-shell">' +
			'<header class="anim-head"><div class="anim-head__mark">◆</div><div><span>' + escapeHtml(t("animations.kicker")) + '</span><h1>' + escapeHtml(t("animations.title")) + '</h1></div>' +
			'<div class="anim-head__tools"><span class="anim-head__hint">N · F1–F12</span><button type="button" data-action="stop">' + escapeHtml(t("animations.action.stop")) + '</button><button type="button" data-action="close" aria-label="' + escapeHtml(t("animations.action.close")) + '">×</button></div></header>' +
			'<section class="anim-slots"><div class="anim-section-label"><span>' + escapeHtml(t("animations.slots")) + '</span><small>' + escapeHtml(t("animations.slotsHint")) + '</small></div><div class="anim-slots__grid">' + slotMarkup() + '</div></section>' +
			'<div class="anim-main"><section class="anim-browser"><div class="anim-filters"><div class="anim-tabs">' + ["all", "active", "reaction", "idle"].map(function (category) { return '<button type="button" data-category="' + category + '" class="' + (state.category === category ? "is-active" : "") + '">' + escapeHtml(t("animations.category." + category)) + '</button>'; }).join("") + '</div>' +
			'<input type="search" data-role="search" value="' + escapeHtml(state.query) + '" placeholder="' + escapeHtml(t("animations.search")) + '"></div>' +
			'<div class="anim-list">' + (entries.length ? entries.map(cardMarkup).join("") : '<div class="anim-empty">' + escapeHtml(t("animations.empty")) + '</div>') + '</div></section>' +
			'<aside class="anim-detail">' + detailMarkup() + '</aside></div>' +
			'<footer class="anim-foot"><span>◆</span><p>' + escapeHtml(t("animations.footer")) + '</p><span>◆</span></footer><div class="anim-toast" data-role="toast"></div></div>';
		bindDom();
	}

	function assign(id, slot) {
		const entry = byId(id);
		if (!entry || !entry.playable || slot < 0 || slot > 11) return;
		state.bindings[slot] = entry.id;
		state.selectedSlot = slot;
		syncBindings();
		render();
		showToast(t("animations.result.assigned"), true);
	}

	function clearSlot(slot) {
		if (slot < 0 || slot > 11) return;
		state.bindings[slot] = "";
		syncBindings();
		render();
	}

	function playSelected() {
		const entry = byId(state.selectedId);
		if (entry && entry.playable) PhoenixBridge.send("phoenix:animations:play", { id: entry.id });
	}

	function showToast(text, success) {
		clearTimeout(state.toastTimer);
		const node = root.querySelector('[data-role="toast"]');
		if (!node) return;
		node.textContent = text;
		node.className = "anim-toast is-visible " + (success ? "is-success" : "is-error");
		state.toastTimer = setTimeout(function () { node.classList.remove("is-visible"); }, 2800);
	}

	function bindDom() {
		root.querySelectorAll("[data-category]").forEach(function (button) {
			button.addEventListener("click", function () { state.category = button.getAttribute("data-category"); render(); });
		});
		const search = root.querySelector('[data-role="search"]');
		if (search) search.addEventListener("input", function () { state.query = search.value; render(); const next = root.querySelector('[data-role="search"]'); if (next) { next.focus(); next.setSelectionRange(next.value.length, next.value.length); } });
		root.querySelectorAll("[data-animation-id]").forEach(function (card) {
			card.addEventListener("click", function () { state.selectedId = card.getAttribute("data-animation-id"); render(); });
			card.addEventListener("dblclick", function () { state.selectedId = card.getAttribute("data-animation-id"); playSelected(); });
			card.addEventListener("dragstart", function (event) { if (card.getAttribute("draggable") !== "true") { event.preventDefault(); return; } event.dataTransfer.setData("text/phoenix-animation", card.getAttribute("data-animation-id")); });
		});
		root.querySelectorAll("[data-slot]").forEach(function (slot) {
			const index = Number(slot.getAttribute("data-slot"));
			slot.addEventListener("click", function (event) { if (event.target.closest("[data-clear-slot]")) return; state.selectedSlot = index; const id = state.bindings[index]; if (id) state.selectedId = id; render(); });
			slot.addEventListener("dragover", function (event) { event.preventDefault(); slot.classList.add("is-drop"); });
			slot.addEventListener("dragleave", function () { slot.classList.remove("is-drop"); });
			slot.addEventListener("drop", function (event) { event.preventDefault(); assign(event.dataTransfer.getData("text/phoenix-animation"), index); });
		});
		root.querySelectorAll("[data-clear-slot]").forEach(function (button) { button.addEventListener("click", function (event) { event.stopPropagation(); clearSlot(Number(button.getAttribute("data-clear-slot"))); }); });
		const play = root.querySelector('[data-action="play"]');
		const assignButton = root.querySelector('[data-action="assign"]');
		const stop = root.querySelector('[data-action="stop"]');
		const close = root.querySelector('[data-action="close"]');
		if (play) play.addEventListener("click", playSelected);
		if (assignButton) assignButton.addEventListener("click", function () { assign(state.selectedId, state.selectedSlot); });
		if (stop) stop.addEventListener("click", function () { PhoenixBridge.send("phoenix:animations:stop", {}); });
		if (close) close.addEventListener("click", function () { PhoenixBridge.send("phoenix:animations:close", {}); });
	}

	PhoenixBridge.on("phoenix:animations:state", function (payload) {
		if (!payload) return;
		const previousCharacter = state.characterId;
		state.enabled = payload.enabled !== false;
		state.characterId = Number(payload.characterId || 0);
		state.catalog = Array.isArray(payload.catalog) ? payload.catalog : [];
		state.activeId = String(payload.activeId || "");
		if (!state.enabled) {
			state.catalog = [];
			if (window.app && app.current && app.current() === "animations") { PhoenixBridge.send("phoenix:animations:close", {}); app.hide(); }
			return;
		}
		if (state.characterId > 0 && state.characterId !== previousCharacter) {
			state.bindings = loadBindings();
			syncBindings();
		} else {
			state.bindings = normalizeBindings(payload.bindings);
		}
		if (!byId(state.selectedId)) {
			const first = state.catalog.find(function (entry) { return entry.playable; }) || state.catalog[0];
			state.selectedId = first ? first.id : "";
		}
		if (window.app && app.current && app.current() === "animations") render();
	});

	PhoenixBridge.on("phoenix:animations:result", function (payload) {
		if (!payload) return;
		if (payload.success) state.activeId = payload.active ? String(payload.id || "") : "";
		if (window.app && app.current && app.current() === "animations") {
			render();
			showToast(payload.success ? t(payload.active ? "animations.result.playing" : "animations.result.stopped") : t("animations.error." + payload.error), payload.success);
		}
	});

	PhoenixBridge.on("phoenix:features:snapshot", function (payload) {
		state.enabled = featureEnabled(payload || {});
		if (!state.enabled && window.app && app.current && app.current() === "animations") {
			PhoenixBridge.send("phoenix:animations:close", {});
			app.hide();
		}
	});

	if (window.PhoenixI18n && PhoenixI18n.onChange) PhoenixI18n.onChange(function () { if (window.app && app.current && app.current() === "animations") render(); });

	app.register("animations", {
		onShow: function () {
			if (!state.enabled) { PhoenixBridge.send("phoenix:animations:close", {}); app.hide(); return; }
			document.body.classList.add("phoenix-animations-open");
			PhoenixBridge.send("phoenix:animations:request", {});
			render();
		},
		onHide: function () { document.body.classList.remove("phoenix-animations-open"); }
	});
})();