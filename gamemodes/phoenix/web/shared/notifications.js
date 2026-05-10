(function () {
	"use strict";

	let stackEl = null;
	const stack = [];

	function buildStack() {
		if (stackEl) return stackEl;
		stackEl = document.createElement("div");
		stackEl.className = "phoenix-notify-stack";
		document.body.appendChild(stackEl);
		return stackEl;
	}

	function iconFor(kind) {
		switch (kind) {
			case "success": return "✓";
			case "error": return "✕";
			case "warn": return "!";
			default: return "i";
		}
	}

	function show(payload) {
		if (!payload) return;
		const root = buildStack();
		const kind = payload.kind || "info";
		const item = document.createElement("div");
		item.className = "phoenix-notify phoenix-notify--" + kind;
		item.innerHTML =
			'<div class="phoenix-notify__icon">' + iconFor(kind) + '</div>' +
			'<div class="phoenix-notify__body">' +
				'<div class="phoenix-notify__title"></div>' +
				'<div class="phoenix-notify__text"></div>' +
			'</div>';
		item.querySelector(".phoenix-notify__title").textContent = payload.title || "";
		item.querySelector(".phoenix-notify__text").textContent = payload.text || "";
		root.appendChild(item);
		requestAnimationFrame(function () { item.classList.add("is-visible"); });
		const duration = Math.max(800, (payload.durationMs | 0) || 4000);
		const entry = { el: item, timer: 0 };
		stack.push(entry);
		entry.timer = setTimeout(function () { dismiss(entry); }, duration);
		while (stack.length > 5) {
			const old = stack.shift();
			if (old) dismiss(old, true);
		}
	}

	function dismiss(entry, immediate) {
		if (!entry || !entry.el) return;
		clearTimeout(entry.timer);
		const el = entry.el;
		entry.el = null;
		const remove = function () { if (el && el.parentNode) el.parentNode.removeChild(el); };
		if (immediate) { remove(); return; }
		el.classList.remove("is-visible");
		el.classList.add("is-leaving");
		setTimeout(remove, 350);
	}

	function notify(kind, title, text, durationMs) {
		show({ kind: kind, title: title, text: text, durationMs: durationMs });
	}

	window.PhoenixNotify = { show: show, notify: notify };

	if (window.PhoenixBridge) {
		PhoenixBridge.on("phoenix:notification:show", show);
	}
})();
