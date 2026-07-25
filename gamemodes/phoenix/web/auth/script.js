(function () {
	const root = document.getElementById("page-auth");
	if (!root) return;

	const I18n = window.PhoenixI18n;
	const Bridge = window.PhoenixBridge;

	let mode = "login";
	let busy = false;
	const state = {
		login: { username: "", password: "" },
		register: { username: "", password: "", passwordRepeat: "", email: "" },
		status: { type: null, key: null, text: null }
	};

	function template() {
		return `
			<div class="phoenix-auth">
				<div class="phoenix-card">
					<button type="button" class="phoenix-exit-btn" data-role="exit" title="" data-t-title="app.exit" aria-label="exit">×</button>
					<h1 class="phoenix-card__title" data-t="app.title">PHOENIX</h1>
					<p class="phoenix-card__subtitle" data-role="subtitle"></p>

					<div class="phoenix-divider"></div>

					<div class="phoenix-auth__tabs" role="tablist">
						<button type="button" class="phoenix-auth__tab" data-tab="login" data-t="auth.tab.login"></button>
						<button type="button" class="phoenix-auth__tab" data-tab="register" data-t="auth.tab.register"></button>
					</div>

					<form class="phoenix-auth__form" data-form="login" autocomplete="off" novalidate>
						<label class="phoenix-field">
							<span class="phoenix-field__label" data-t="auth.field.username"></span>
							<input class="phoenix-input" type="text" name="username" maxlength="32" autocomplete="off" />
						</label>
						<label class="phoenix-field">
							<span class="phoenix-field__label" data-t="auth.field.password"></span>
							<input class="phoenix-input" type="password" name="password" maxlength="64" autocomplete="off" />
						</label>
						<label class="phoenix-checkbox">
							<input type="checkbox" name="remember" />
							<span data-t="auth.field.rememberMe"></span>
						</label>
						<div class="phoenix-status" data-role="status"></div>
						<button type="submit" class="phoenix-button" data-role="submit-login">
							<span data-t="auth.button.login"></span>
						</button>
						<a class="phoenix-link" data-role="switch-to-register" data-t="auth.linkRegister"></a>
					</form>

					<form class="phoenix-auth__form" data-form="register" autocomplete="off" novalidate>
						<label class="phoenix-field">
							<span class="phoenix-field__label" data-t="auth.field.username"></span>
							<input class="phoenix-input" type="text" name="username" maxlength="32" autocomplete="off" />
						</label>
						<label class="phoenix-field">
							<span class="phoenix-field__label" data-t="auth.field.email"></span>
							<input class="phoenix-input" type="email" name="email" maxlength="80" autocomplete="off" />
						</label>
						<label class="phoenix-field">
							<span class="phoenix-field__label" data-t="auth.field.password"></span>
							<input class="phoenix-input" type="password" name="password" maxlength="64" autocomplete="off" />
						</label>
						<label class="phoenix-field">
							<span class="phoenix-field__label" data-t="auth.field.passwordRepeat"></span>
							<input class="phoenix-input" type="password" name="passwordRepeat" maxlength="64" autocomplete="off" />
						</label>
						<div class="phoenix-status" data-role="status"></div>
						<button type="submit" class="phoenix-button" data-role="submit-register">
							<span data-t="auth.button.register"></span>
						</button>
						<a class="phoenix-link" data-role="switch-to-login" data-t="auth.linkLogin"></a>
					</form>
				</div>
			</div>
		`;
	}

	function render() {
		root.innerHTML = template();

		root.querySelectorAll("[data-tab]").forEach(function (btn) {
			btn.addEventListener("click", function () { setMode(btn.getAttribute("data-tab")); });
		});

		root.querySelector("[data-form='login']").addEventListener("submit", function (e) {
			e.preventDefault();
			submitLogin();
		});

		root.querySelector("[data-form='register']").addEventListener("submit", function (e) {
			e.preventDefault();
			submitRegister();
		});

		root.querySelector("[data-role='switch-to-register']").addEventListener("click", function (e) {
			e.preventDefault();
			setMode("register");
		});

		root.querySelector("[data-role='switch-to-login']").addEventListener("click", function (e) {
			e.preventDefault();
			setMode("login");
		});

		const exitBtn = root.querySelector("[data-role='exit']");
		if (exitBtn) exitBtn.addEventListener("click", function () { PhoenixBridge.send("phoenix:app:exit", {}); });

		applyMode();
		applyStatus();
		I18n.applyDom(root);
		if (window.app && window.app.renderLangSwitcher) window.app.renderLangSwitcher();
		updateSubtitle();
	}

	function setMode(next) {
		if (mode === next) return;
		mode = next;
		state.status = { type: null, key: null, text: null };
		applyMode();
		applyStatus();
		updateSubtitle();
	}

	function applyMode() {
		root.querySelectorAll("[data-tab]").forEach(function (btn) {
			btn.classList.toggle("is-active", btn.getAttribute("data-tab") === mode);
		});
		root.querySelectorAll("[data-form]").forEach(function (form) {
			form.classList.toggle("is-active", form.getAttribute("data-form") === mode);
		});
		const focusName = mode === "login" ? "username" : "username";
		const focusEl = root.querySelector("[data-form='" + mode + "'] input[name='" + focusName + "']");
		if (focusEl) setTimeout(function () { focusEl.focus(); }, 50);
	}

	function updateSubtitle() {
		const sub = root.querySelector("[data-role='subtitle']");
		if (sub) sub.textContent = I18n.t(mode === "login" ? "auth.login.subtitle" : "auth.register.subtitle");
	}

	function applyStatus() {
		root.querySelectorAll("[data-role='status']").forEach(function (node) {
			node.className = "phoenix-status";
			node.textContent = "";
		});
		if (!state.status.type) return;
		const node = root.querySelector("[data-form='" + mode + "'] [data-role='status']");
		if (!node) return;
		node.classList.add("phoenix-status--" + state.status.type);
		node.textContent = state.status.text || (state.status.key ? I18n.t(state.status.key) : "");
	}

	function setStatus(type, keyOrText, isKey) {
		if (isKey === false) {
			state.status = { type: type, key: null, text: keyOrText };
		} else {
			state.status = { type: type, key: keyOrText, text: null };
		}
		applyStatus();
	}

	function setBusy(value) {
		busy = value;
		root.querySelectorAll(".phoenix-button").forEach(function (btn) {
			btn.disabled = value;
			const span = btn.querySelector("span");
			if (!span) return;
			if (value) {
				span.dataset.tCached = span.getAttribute("data-t") || "";
				span.removeAttribute("data-t");
				span.textContent = I18n.t("auth.button.busy");
			} else if (span.dataset.tCached) {
				span.setAttribute("data-t", span.dataset.tCached);
				span.textContent = I18n.t(span.dataset.tCached);
				delete span.dataset.tCached;
			}
		});
	}

	function readForm(name) {
		const form = root.querySelector("[data-form='" + name + "']");
		const out = {};
		if (!form) return out;
		form.querySelectorAll("input").forEach(function (input) {
			if (input.type === "checkbox") {
				out[input.name] = input.checked;
			} else {
				out[input.name] = input.value.trim();
			}
		});
		return out;
	}

	function prefillRemember() {
		const apply = function (saved) {
			if (!saved || !saved.username) return;
			const form = root.querySelector("[data-form='login']");
			if (!form) return;
			const u = form.querySelector("input[name='username']");
			const p = form.querySelector("input[name='password']");
			const c = form.querySelector("input[name='remember']");
			if (u) u.value = saved.username;
			if (p && saved.password) p.value = saved.password;
			if (c) c.checked = true;
		};
		try {
			const raw = localStorage.getItem("phoenix:auth:remember");
			if (raw) apply(JSON.parse(raw));
		} catch (e) {}
		if (window.PhoenixStorage) {
			window.PhoenixStorage.get("phoenix:auth:remember", function (value) {
				if (!value) return;
				try {
					const saved = (typeof value === "string") ? JSON.parse(value) : value;
					apply(saved);
				} catch (e) {}
			});
		}
	}

	function submitLogin() {
		if (busy) return;
		const data = readForm("login");
		if (!data.username || !data.password) {
			setStatus("error", "auth.error.empty");
			return;
		}
		try {
			if (data.remember) {
				const payload = JSON.stringify({ username: data.username, password: data.password });
				localStorage.setItem("phoenix:auth:remember", payload);
				if (window.PhoenixStorage) window.PhoenixStorage.set("phoenix:auth:remember", payload);
			} else {
				localStorage.removeItem("phoenix:auth:remember");
				if (window.PhoenixStorage) window.PhoenixStorage.set("phoenix:auth:remember", "");
			}
		} catch (e) {}
		setStatus("info", "auth.button.busy");
		setBusy(true);
		Bridge.send("phoenix:account:login", {
			username: data.username,
			password: data.password
		});
	}

	function submitRegister() {
		if (busy) return;
		const data = readForm("register");
		if (!data.username || !data.password || !data.passwordRepeat || !data.email) {
			setStatus("error", "auth.error.empty");
			return;
		}
		if (data.password !== data.passwordRepeat) {
			setStatus("error", "auth.error.passwordMismatch");
			return;
		}
		setStatus("info", "auth.button.busy");
		setBusy(true);
		Bridge.send("phoenix:account:register", {
			username: data.username,
			password: data.password,
			email: data.email
		});
	}

	function onResult(kind, payload) {
		setBusy(false);
		if (!payload) return;
		if (payload.success) {
			setStatus("success", kind === "login" ? "auth.success.login" : "auth.success.register");
			if (kind === "register") {
				setTimeout(function () { setMode("login"); }, 900);
			}
			return;
		}
		const errKey = payload.error || "phoenix.account.error.notFound";
		setStatus("error", errKey);
	}

	Bridge.on("phoenix:account:authMode", function (payload) {
		if (payload && payload.mode) setMode(payload.mode);
	});

	Bridge.on("phoenix:account:loginResult", function (payload) { onResult("login", payload); });
	Bridge.on("phoenix:account:registerResult", function (payload) { onResult("register", payload); });

	I18n.onChange(function () {
		updateSubtitle();
		applyStatus();
	});

	window.app.register("auth", {
		onShow: function () {
			document.body.classList.add("phoenix-body--veiled");
			render();
			prefillRemember();
			setBusy(false);
		},
		onHide: function () {
			document.body.classList.remove("phoenix-body--veiled");
		}
	});

	render();
})();
