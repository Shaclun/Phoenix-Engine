(function () {
	"use strict";

	var MAX_ENTRIES = 500;
	var root = null;
	var bodyEl = null;
	var countEl = null;
	var entries = [];

	function fmtTime() {
		var d = new Date();
		var h = d.getHours(), m = d.getMinutes(), s = d.getSeconds();
		var ms = d.getMilliseconds();
		return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s) + "." + (ms < 100 ? (ms < 10 ? "00" + ms : "0" + ms) : ms);
	}

	function stringify(arg) {
		if (arg === undefined) return "undefined";
		if (arg === null) return "null";
		if (typeof arg === "string") return arg;
		if (typeof arg === "number" || typeof arg === "boolean") return String(arg);
		try { return JSON.stringify(arg); } catch (e) {
			try { return String(arg); } catch (e2) { return "[unprintable]"; }
		}
	}

	function addEntry(level, args) {
		var text = Array.prototype.slice.call(args).map(stringify).join(" ");
		entries.push({ level: level, text: text, time: fmtTime() });
		if (entries.length > MAX_ENTRIES) entries.splice(0, entries.length - MAX_ENTRIES);
		if (!root) return;
		var atBottom = bodyEl.scrollTop + bodyEl.clientHeight >= bodyEl.scrollHeight - 10;
		var row = document.createElement("div");
		row.className = "phoenix-devconsole__entry phoenix-devconsole__entry--" + level;
		var t = document.createElement("span");
		t.className = "phoenix-devconsole__time";
		t.textContent = entries[entries.length - 1].time;
		var tag = document.createElement("span");
		tag.className = "phoenix-devconsole__tag";
		tag.textContent = "[" + level + "]";
		var body = document.createElement("span");
		body.textContent = text;
		row.appendChild(t);
		row.appendChild(tag);
		row.appendChild(body);
		bodyEl.appendChild(row);
		while (bodyEl.childElementCount > MAX_ENTRIES) bodyEl.removeChild(bodyEl.firstChild);
		if (atBottom) bodyEl.scrollTop = bodyEl.scrollHeight;
		if (countEl) countEl.textContent = entries.length + " wpisow";
	}

	function buildDom() {
		if (root) return root;
		root = document.createElement("div");
		root.className = "phoenix-devconsole";
		root.id = "phoenix-devconsole";
		root.innerHTML =
			'<div class="phoenix-devconsole__bar">' +
				'<span class="phoenix-devconsole__title">Phoenix Debug</span>' +
				'<span class="phoenix-devconsole__count" data-role="count">0 wpisow</span>' +
				'<input class="phoenix-devconsole__input" data-role="input" placeholder="filtr (po Enter)" />' +
				'<button class="phoenix-devconsole__btn" data-role="clear">Wyczysc</button>' +
				'<button class="phoenix-devconsole__btn" data-role="copy">Kopiuj</button>' +
				'<button class="phoenix-devconsole__btn" data-role="close">X</button>' +
			'</div>' +
			'<div class="phoenix-devconsole__body" data-role="body"></div>';
		document.body.appendChild(root);
		bodyEl = root.querySelector('[data-role="body"]');
		countEl = root.querySelector('[data-role="count"]');
		root.querySelector('[data-role="close"]').addEventListener("click", hide);
		root.querySelector('[data-role="clear"]').addEventListener("click", function () {
			entries = [];
			bodyEl.innerHTML = "";
			countEl.textContent = "0 wpisow";
		});
		root.querySelector('[data-role="copy"]').addEventListener("click", function () {
			var text = entries.map(function (e) { return e.time + " [" + e.level + "] " + e.text; }).join("\n");
			try {
				var ta = document.createElement("textarea");
				ta.value = text;
				document.body.appendChild(ta);
				ta.select();
				document.execCommand("copy");
				ta.remove();
			} catch (e) {}
		});
		var input = root.querySelector('[data-role="input"]');
		input.addEventListener("keydown", function (e) {
			if (e.key !== "Enter") return;
			var filter = input.value.toLowerCase();
			var rows = bodyEl.querySelectorAll(".phoenix-devconsole__entry");
			rows.forEach(function (row) {
				row.style.display = filter && row.textContent.toLowerCase().indexOf(filter) === -1 ? "none" : "";
			});
		});
		return root;
	}

	function show() {
		buildDom();
		root.classList.add("is-visible");
		if (countEl) countEl.textContent = entries.length + " wpisow";
	}

	function hide() {
		if (root) root.classList.remove("is-visible");
	}

	function toggle() {
		if (root && root.classList.contains("is-visible")) hide();
		else show();
	}

	var nativeLog = console.log.bind(console);
	var nativeInfo = console.info ? console.info.bind(console) : nativeLog;
	var nativeWarn = console.warn ? console.warn.bind(console) : nativeLog;
	var nativeError = console.error ? console.error.bind(console) : nativeLog;
	var nativeDebug = console.debug ? console.debug.bind(console) : nativeLog;

	console.log = function () { addEntry("log", arguments); try { nativeLog.apply(null, arguments); } catch (e) {} };
	console.info = function () { addEntry("info", arguments); try { nativeInfo.apply(null, arguments); } catch (e) {} };
	console.warn = function () { addEntry("warn", arguments); try { nativeWarn.apply(null, arguments); } catch (e) {} };
	console.error = function () { addEntry("error", arguments); try { nativeError.apply(null, arguments); } catch (e) {} };
	console.debug = function () { addEntry("debug", arguments); try { nativeDebug.apply(null, arguments); } catch (e) {} };

	window.addEventListener("error", function (e) {
		addEntry("error", ["[window.error]", e.message || "?", "at", (e.filename || "?") + ":" + (e.lineno || "?")]);
	});
	window.addEventListener("unhandledrejection", function (e) {
		addEntry("error", ["[promise]", (e.reason && e.reason.message) || stringify(e.reason)]);
	});

	document.addEventListener("keydown", function (e) {
		if (e.key === "F12" || (e.ctrlKey && e.shiftKey && (e.key === "I" || e.key === "i"))) {
			e.preventDefault();
			toggle();
		}
	}, true);

	window.PhoenixDebugConsole = {
		show: show,
		hide: hide,
		toggle: toggle,
		log: function () { addEntry("log", arguments); }
	};
})();
