(function (global) {
	const pages = {};
	let active = null;
	let splashComplete = false;
	let splashTimer = null;
	let pendingIntroPage = null;

	function register(name, page) {
		pages[name] = page;
	}

	function splashElement() {
		return document.getElementById("phoenix-splash");
	}

	function setSplashStatus(key, fallback) {
		const splash = splashElement();
		const node = splash ? splash.querySelector('[data-role="splash-status"]') : null;
		if (!node) return;
		let value = fallback;
		try {
			if (global.PhoenixI18n && PhoenixI18n.t) {
				const translated = PhoenixI18n.t(key);
				if (translated && translated !== key) value = translated;
			}
		} catch (error) {}
		node.textContent = value;
	}

	function revealPage(name) {
		if (active === name) return;
		const previous = active;
		Object.keys(pages).forEach(function (key) {
			const node = document.getElementById("page-" + key);
			if (!node) return;
			node.classList.toggle("is-active", key === name);
		});
		if (previous) {
			document.body.classList.remove("phoenix-" + previous + "-open");
		}
		if (previous && pages[previous] && typeof pages[previous].onHide === "function") {
			try { pages[previous].onHide(); } catch (e) {}
		}
		active = name;
		if (name) {
			document.body.classList.add("phoenix-" + name + "-open");
		}
		if (pages[name] && typeof pages[name].onShow === "function") {
			pages[name].onShow();
		}
	}

	function finishIntro() {
		if (splashComplete) return;
		if (splashTimer) clearTimeout(splashTimer);
		splashTimer = null;
		const splash = splashElement();
		if (splash) splash.classList.add("is-leaving");
		setTimeout(function () {
			splashComplete = true;
			document.body.classList.remove("phoenix-splash-active");
			if (splash) splash.classList.remove("is-active", "is-intro", "is-leaving");
			const target = pendingIntroPage;
			pendingIntroPage = null;
			if (target) revealPage(target);
		}, 680);
	}

	function startIntro(name) {
		pendingIntroPage = name || pendingIntroPage;
		const splash = splashElement();
		document.body.classList.add("phoenix-splash-active");
		if (splash) {
			splash.classList.remove("is-loading", "is-leaving");
			splash.classList.add("is-active", "is-intro");
		}
		setSplashStatus("app.tagline", "POWSTAŃ Z POPIOŁÓW");
		if (!splashTimer) splashTimer = setTimeout(finishIntro, 2350);
	}

	function showLoading(kind) {
		const splash = splashElement();
		if (!splash) return;
		document.body.classList.add("phoenix-splash-active");
		splash.classList.remove("is-intro", "is-leaving");
		splash.classList.add("is-active", "is-loading");
		setSplashStatus(kind === "world" ? "quest.tracker.loadingWorld" : "app.loading", kind === "world" ? "ŁADOWANIE ŚWIATA" : "ŁADOWANIE");
	}

	function hideLoading(immediate) {
		const splash = splashElement();
		if (!splash || !splash.classList.contains("is-loading")) return;
		const finish = function () {
			document.body.classList.remove("phoenix-splash-active");
			splash.classList.remove("is-active", "is-loading", "is-leaving");
		};
		if (immediate) { finish(); return; }
		splash.classList.add("is-leaving");
		setTimeout(finish, 680);
	}

	function show(name) {
		if (!splashComplete && name === "auth") {
			startIntro(name);
			return;
		}
		hideLoading(true);
		revealPage(name);
	}

	function hide() {
		hideLoading(true);
		const previous = active;
		Object.keys(pages).forEach(function (key) {
			const node = document.getElementById("page-" + key);
			if (node) node.classList.remove("is-active");
		});
		active = null;
		if (previous) {
			document.body.classList.remove("phoenix-" + previous + "-open");
		}
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
		showLoading: showLoading,
		hideLoading: hideLoading,
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
