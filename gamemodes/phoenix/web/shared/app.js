(function (global) {
	const pages = {};
	let active = null;

	function register(name, page) {
		pages[name] = page;
	}

	function show(name) {
		if (active === name) return;
		const previous = active;
		Object.keys(pages).forEach(function (key) {
			const node = document.getElementById("page-" + key);
			if (!node) return;
			node.classList.toggle("is-active", key === name);
		});
		if (previous && pages[previous] && typeof pages[previous].onHide === "function") {
			try { pages[previous].onHide(); } catch (e) {}
		}
		active = name;
		if (pages[name] && typeof pages[name].onShow === "function") {
			pages[name].onShow();
		}
	}

	function hide() {
		const previous = active;
		Object.keys(pages).forEach(function (key) {
			const node = document.getElementById("page-" + key);
			if (node) node.classList.remove("is-active");
		});
		active = null;
		if (previous && pages[previous] && typeof pages[previous].onHide === "function") {
			try { pages[previous].onHide(); } catch (e) {}
		}
	}

	function emit(name, payload) {
		PhoenixBridge.emit(name, payload);
	}

	const app = {
		register: register,
		show: show,
		hide: hide,
		emit: emit,
		current: function () { return active; }
	};

	global.app = app;
	global.phoenixApp = app;

	global.phoenixShow = function (name) {
		try { show(name); } catch (err) {}
	};

	global.phoenixHide = function () {
		try { hide(); } catch (err) {}
	};

	global.phoenixEmit = function (json) {
		try {
			const data = typeof json === "string" ? JSON.parse(json) : json;
			emit(data.channel, data.payload);
		} catch (err) {}
	};

	const FLAG_SVG = {
		pl: '<svg viewBox="0 0 32 24" aria-hidden="true"><rect width="32" height="12" fill="#fff"/><rect y="12" width="32" height="12" fill="#dc143c"/></svg>',
		en: '<svg viewBox="0 0 32 24" aria-hidden="true"><rect fill="#012169" width="32" height="24"/><path d="M0,0 L32,24 M32,0 L0,24" stroke="#fff" stroke-width="4"/><path d="M0,0 L32,24 M32,0 L0,24" stroke="#C8102E" stroke-width="2.5"/><path d="M16,0 V24 M0,12 H32" stroke="#fff" stroke-width="6"/><path d="M16,0 V24 M0,12 H32" stroke="#C8102E" stroke-width="3.5"/></svg>',
		de: '<svg viewBox="0 0 32 24" aria-hidden="true"><rect width="32" height="8" fill="#000"/><rect y="8" width="32" height="8" fill="#DD0000"/><rect y="16" width="32" height="8" fill="#FFCC00"/></svg>',
		ru: '<svg viewBox="0 0 32 24" aria-hidden="true"><rect width="32" height="8" fill="#fff"/><rect y="8" width="32" height="8" fill="#0039A6"/><rect y="16" width="32" height="8" fill="#D52B1E"/></svg>'
	};

	function renderLangSwitcher() {
		const hosts = document.querySelectorAll("[data-role='lang-switcher']");
		if (!hosts.length || !global.PhoenixI18n) return;
		const I18n = global.PhoenixI18n;
		hosts.forEach(function (host) {
			host.innerHTML = "";
			I18n.listLangs().forEach(function (code) {
				const btn = document.createElement("button");
				btn.type = "button";
				btn.className = "phoenix-langs__btn phoenix-langs__btn--flag";
				btn.dataset.lang = code;
				btn.title = I18n.t("lang." + code);
				btn.innerHTML = FLAG_SVG[code] || code.toUpperCase();
				btn.addEventListener("click", function () { I18n.setLang(code); });
				host.appendChild(btn);
			});
		});
		updateLangSwitcher();
	}

	function updateLangSwitcher() {
		const hosts = document.querySelectorAll("[data-role='lang-switcher']");
		if (!hosts.length || !global.PhoenixI18n) return;
		const current = global.PhoenixI18n.getLang();
		hosts.forEach(function (host) {
			host.querySelectorAll(".phoenix-langs__btn").forEach(function (btn) {
				const lang = btn.dataset.lang || btn.textContent.toLowerCase();
				btn.classList.toggle("is-active", lang === current);
			});
		});
	}

	app.renderLangSwitcher = renderLangSwitcher;

	function syncStoredLanguage() {
		if (!global.PhoenixI18n) return;
		const I18n = global.PhoenixI18n;
		const key = "phoenix:lang";
		let localLang = "";
		try { localLang = localStorage.getItem(key) || ""; } catch (e) { localLang = ""; }
		if (localLang && (!I18n.hasLang || I18n.hasLang(localLang))) {
			I18n.setLang(localLang);
			return;
		}
		if (!global.PhoenixStorage) return;
		global.PhoenixStorage.get(key, function (storedLang) {
			if (!storedLang || (I18n.hasLang && !I18n.hasLang(storedLang))) return;
			I18n.setLang(storedLang);
		});
	}

	document.addEventListener("DOMContentLoaded", function () {
		if (global.PhoenixI18n) {
			syncStoredLanguage();
			renderLangSwitcher();
			global.PhoenixI18n.applyDom(document);
			global.PhoenixI18n.onChange(function () {
				updateLangSwitcher();
				global.PhoenixI18n.applyDom(document);
			});
		}
		PhoenixBridge.send("phoenix:web:ready", {});
	});
})(window);
