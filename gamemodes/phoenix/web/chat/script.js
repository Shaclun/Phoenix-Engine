
(function (global) {
	const CHANNELS = [
		{ id: 0, key: "local",  short: "L", labelKey: "chat.tab.local",  defaultLabel: "LOKALNY"  },
		{ id: 1, key: "global", short: "G", labelKey: "chat.tab.global", defaultLabel: "GLOBALNY" },
		{ id: 2, key: "admin",  short: "A", labelKey: "chat.tab.admin",  defaultLabel: "ADMIN",   adminOnly: true }
	];
	const HISTORY_MAX = 200;
	const MAX_LEN = 240;

	let root, list, input, prefix, tabsHost;
	let escMenu, escLangs;
	let currentChannel = 0;
	let inputOpen = false;
	let escMenuOpen = false;
	let isAdmin = false;
	let vanished = false;
	let unread = [0, 0, 0];
	let dmTabs = {};
	let history = [];
	let historyIdx = -1;

	function ensureI18n() {
		const labels = {
			pl: { local: "LOKALNY", global: "GLOBALNY", admin: "ADMIN",    hint: "ENTER wyślij • TAB zmień kanał • ESC anuluj • /g globalny • /a admin" },
			en: { local: "LOCAL",   global: "GLOBAL",   admin: "ADMIN",    hint: "ENTER send • TAB switch channel • ESC cancel • /g global • /a admin" },
			de: { local: "LOKAL",   global: "GLOBAL",   admin: "ADMIN",    hint: "ENTER senden • TAB Kanal • ESC abbrechen • /g global • /a admin" },
			ru: { local: "ЛОКАЛЬН", global: "ГЛОБАЛЬН", admin: "АДМИН", hint: "ENTER отправить • TAB канал • ESC отмена • /g глобальный • /a админ" }
		};
		global.__phxChatT = function (key) {
			const lang = (global.PhoenixI18n && global.PhoenixI18n.getLang()) || "pl";
			const m = labels[lang] || labels.pl;
			return m[key] || key;
		};
	}

	function build() {
		root = document.createElement("div");
		root.className = "phoenix-chat";
		root.id = "phoenix-chat";
		root.dataset.hudId = "chat";
		root.innerHTML = `
			<div class="phoenix-chat__tabs" data-role="chat-tabs"></div>
			<div class="phoenix-chat__panel">
				<div class="phoenix-chat__list" data-role="chat-list"></div>
			</div>
			<div class="phoenix-chat__input">
				<span class="phoenix-chat__prefix" data-role="chat-prefix">[L] &gt;</span>
				<input class="phoenix-chat__field" type="text" maxlength="${MAX_LEN}" data-role="chat-field" autocomplete="off" />
			</div>
			<div class="phoenix-chat__hint" data-role="chat-hint"></div>
		`;
		document.body.appendChild(root);
		list = root.querySelector("[data-role='chat-list']");
		input = root.querySelector("[data-role='chat-field']");
		prefix = root.querySelector("[data-role='chat-prefix']");
		tabsHost = root.querySelector("[data-role='chat-tabs']");
		buildTabs();
		bindInput();
		refreshHint();
	}

	function buildTabs() {
		tabsHost.innerHTML = "";
		CHANNELS.forEach(function (ch) {
			if (ch.adminOnly && !isAdmin) return;
			appendTabButton(ch);
		});
		Object.keys(dmTabs).forEach(function (key) { appendTabButton(dmTabs[key]); });
		refreshTabs();
	}

	function appendTabButton(ch) {
		const btn = document.createElement("button");
		btn.type = "button";
		btn.className = "phoenix-chat__tab" + (ch.dm ? " phoenix-chat__tab--dm" : "");
		btn.dataset.channel = String(ch.id);
		btn.innerHTML = "<span class='phoenix-chat__tab__label'>" + label(ch) + "</span><span class='phoenix-chat__tab__badge' style='display:none'></span>" + (ch.dm ? "<span class='phoenix-chat__tab__close' data-close='1'>x</span>" : "");
		btn.addEventListener("click", function (event) {
			if (event.target && event.target.dataset.close === "1") { closeDmTab(ch.id); return; }
			setChannel(ch.id);
		});
		tabsHost.appendChild(btn);
	}

	function label(ch) {
		if (ch.dm) return ch.name || ch.defaultLabel || "DM";
		if (global.__phxChatT) return global.__phxChatT(ch.key);
		return ch.defaultLabel;
	}

	function channelById(id) {
		for (let i = 0; i < CHANNELS.length; i += 1) if (CHANNELS[i].id === id) return CHANNELS[i];
		return dmTabs[String(id)] || CHANNELS[0];
	}

	function refreshTabs() {
		tabsHost.querySelectorAll(".phoenix-chat__tab").forEach(function (btn) {
			const id = parseInt(btn.dataset.channel, 10);
			btn.classList.toggle("is-active", id === currentChannel);
			const labelNode = btn.querySelector(".phoenix-chat__tab__label");
			if (labelNode) labelNode.textContent = label(channelById(id));
			const badge = btn.querySelector(".phoenix-chat__tab__badge");
			if (badge) {
				if (unread[id] > 0 && id !== currentChannel) {
					badge.style.display = "";
					badge.textContent = unread[id] > 99 ? "99+" : String(unread[id]);
				} else {
					badge.style.display = "none";
				}
			}
		});
	}

	function refreshPrefix() {
		const ch = channelById(currentChannel);
		prefix.textContent = "[" + ch.short + "] >";
		prefix.classList.toggle("phoenix-chat__prefix--global", currentChannel === 1);
		prefix.classList.toggle("phoenix-chat__prefix--admin", currentChannel === 2);
		prefix.classList.toggle("phoenix-chat__prefix--dm", !!ch.dm);
	}

	function refreshHint() {
		const hint = root.querySelector("[data-role='chat-hint']");
		if (hint) hint.textContent = global.__phxChatT ? global.__phxChatT("hint") : "ENTER • TAB • ESC";
	}

	function setChannel(id) {
		if (!channelById(id)) id = 0;
		currentChannel = id;
		unread[id] = 0;
		refreshTabs();
		refreshPrefix();
		if (inputOpen) input.focus();
	}

	function bindInput() {

		document.addEventListener("mousedown", function (e) {
			if (!inputOpen) return;
			if (escMenuOpen) return;
			if (!root || !e.target) return;
			if (root.contains(e.target)) return;
			closeInput(false);
		}, true);

		input.addEventListener("keydown", function (e) {
			if (e.key === "Enter") {
				e.preventDefault();
				submit();
			} else if (e.key === "Escape") {
				e.preventDefault();
				closeInput(false);
			} else if (e.key === "Tab") {
				e.preventDefault();
				let next = currentChannel;
				for (let step = 0; step < CHANNELS.length; step += 1) {
					next = (next + 1) % CHANNELS.length;
					const c = CHANNELS[next];
					if (!c.adminOnly || isAdmin) break;
				}
				setChannel(next);
			} else if (e.key === "ArrowUp") {
				e.preventDefault();
				if (history.length === 0) return;
				historyIdx = Math.max(0, (historyIdx === -1 ? history.length : historyIdx) - 1);
				input.value = history[historyIdx] || "";
			} else if (e.key === "ArrowDown") {
				e.preventDefault();
				if (history.length === 0) return;
				historyIdx = Math.min(history.length, historyIdx + 1);
				input.value = historyIdx >= history.length ? "" : history[historyIdx];
			}
			setTimeout(function () {
				PhoenixBridge.send("phoenix:chat:input", { length: input.value.length, channel: currentChannel });
			}, 0);
		});
	}

	function submit() {
		const text = (input.value || "").trim();
		if (text.length === 0) {
			closeInput(false);
			return;
		}
		let channel = currentChannel;
		let body = text;
		if (text.indexOf("/g ") === 0) { channel = 1; body = text.slice(3).trim(); }
		else if (text === "/g") { setChannel(1); input.value = ""; return; }
		else if (text.indexOf("/l ") === 0) { channel = 0; body = text.slice(3).trim(); }
		else if (isAdmin && text.indexOf("/a ") === 0) { channel = 2; body = text.slice(3).trim(); }
		else if (isAdmin && text === "/a") { setChannel(2); input.value = ""; return; }
		if (body.length === 0) { closeInput(false); return; }
		const active = channelById(channel);
		if (active && active.dm) {
			PhoenixBridge.send("phoenix:social:dm", { targetId: active.playerId, text: body });
			history.push(text);
			if (history.length > 50) history.shift();
			historyIdx = -1;
			input.value = "";
			closeInput(true);
			return;
		}
		PhoenixBridge.send("phoenix:chat:submit", { channel: channel, text: body });
		history.push(text);
		if (history.length > 50) history.shift();
		historyIdx = -1;
		input.value = "";
		closeInput(true);
	}

	function open() {
		if (inputOpen) return;
		inputOpen = true;
		root.classList.add("is-input-open");
		refreshPrefix();

		const focusInput = function () {
			try { input.focus(); input.select(); } catch (e) {}
		};
		focusInput();
		setTimeout(focusInput, 10);
		setTimeout(function () {
			focusInput();
			PhoenixBridge.send("phoenix:chat:input", { length: input.value.length, channel: currentChannel });
		}, 50);
	}

	function closeInput(sent) {
		if (!inputOpen) return;
		inputOpen = false;
		root.classList.remove("is-input-open");
		input.value = "";
		try { input.blur(); } catch (e) {}
		PhoenixBridge.send("phoenix:chat:close", { sent: !!sent });
	}

	function appendMsg(payload) {
		const wrap = document.createElement("div");
		const channel = (typeof payload.channel === "number") ? payload.channel : 0;
		const ch = channelById(channel);
		const isSystem = !!payload.system;
		const textKey = payload.textKey ? String(payload.textKey) : "";
		wrap.className = "phoenix-chat__msg " + (isSystem ? "phoenix-chat__msg--system" : ("phoenix-chat__msg--" + ch.key));
		const tag = "<span class='phoenix-chat__tag" + (channel === 1 ? " phoenix-chat__tag--global" : (channel === 2 ? " phoenix-chat__tag--admin" : (ch.dm ? " phoenix-chat__tag--dm" : ""))) + "'>[" + ch.short + "]</span>";
		const name = isSystem
			? "<span class='phoenix-chat__name phoenix-chat__name--system'>*</span>"
			: ("<span class='phoenix-chat__name" + (channel === 1 ? " phoenix-chat__name--global" : (channel === 2 ? " phoenix-chat__name--admin" : (ch.dm ? " phoenix-chat__name--dm" : ""))) + "'>" + escapeHtml(payload.name || "?") + ":</span>");
		wrap.innerHTML = tag + " " + name + " ";
		const message = document.createElement("span");
		if (textKey) message.setAttribute("data-t", textKey);
		message.textContent = textKey && global.PhoenixI18n ? global.PhoenixI18n.t(textKey) : (payload.text || "");
		wrap.appendChild(message);
		list.insertBefore(wrap, list.firstChild);
		while (list.children.length > HISTORY_MAX) list.removeChild(list.lastChild);
		if (!isSystem && channel !== currentChannel) {
			unread[channel] = Math.min(99, (unread[channel] || 0) + 1);
			refreshTabs();
		}
	}

	function dmChannelId(playerId) { return 1000 + parseInt(playerId, 10); }

	function openDmTab(player) {
		if (!player || typeof player.playerId === "undefined") return;
		const id = dmChannelId(player.playerId);
		if (!dmTabs[String(id)]) dmTabs[String(id)] = { id: id, key: "dm", short: "P", labelKey: "", defaultLabel: player.name || "DM", name: player.name || "DM", playerId: parseInt(player.playerId, 10), dm: true };
		else dmTabs[String(id)].name = player.name || dmTabs[String(id)].name;
		buildTabs();
		setChannel(id);
		open();
	}

	function closeDmTab(id) {
		delete dmTabs[String(id)];
		if (currentChannel === id) setChannel(0);
		buildTabs();
	}

	function appendDm(payload) {
		if (!payload || !payload.from || !payload.to) return;
		const selfId = parseInt(payload.selfId, 10);
		const fromId = parseInt(payload.from.playerId, 10);
		const other = fromId === selfId ? payload.to : payload.from;
		const id = dmChannelId(other.playerId);
		if (!dmTabs[String(id)]) dmTabs[String(id)] = { id: id, key: "dm", short: "P", defaultLabel: other.name || "DM", name: other.name || "DM", playerId: parseInt(other.playerId, 10), dm: true };
		buildTabs();
		appendMsg({ channel: id, name: payload.from.name || "?", text: payload.text || "", system: false, playerId: payload.from.playerId });
	}

	function escapeHtml(s) {
		return String(s).replace(/[&<>"']/g, function (c) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
		});
	}

	function buildEscMenu() {
		escMenu = document.getElementById("phoenix-escmenu");
		if (!escMenu) return;
		escLangs = escMenu.querySelector("[data-role='escmenu-langs'], [data-role='lang-switcher']");
		renderEscLangs();
		if (global.PhoenixI18n && global.PhoenixI18n.onChange) {
			global.PhoenixI18n.onChange(function () { renderEscLangs(); refreshEscMenuAdmin(); });
		}

		escMenu.addEventListener("click", function (e) {
			if (e.target === escMenu) closeEscMenu();
		});
		const back = escMenu.querySelector("#escmenu-back");
		const char = escMenu.querySelector("#escmenu-char");
		const admin = escMenu.querySelector("#escmenu-admin");
		const vanish = escMenu.querySelector("#escmenu-vanish");
		const logout = escMenu.querySelector("#escmenu-logout");
		const exit = escMenu.querySelector("#escmenu-exit");
		const settings = escMenu.querySelector("#escmenu-settings");
		const partyLeave = escMenu.querySelector("#escmenu-party-leave");
		let inParty = false;
		const refreshPartyLeave = function () {
			if (!partyLeave) return;
			if (inParty) partyLeave.removeAttribute("hidden");
			else partyLeave.setAttribute("hidden", "");
		};
		if (back)   back.addEventListener("click", function () { closeEscMenu(); });
		if (char)   char.addEventListener("click", function () { PhoenixBridge.send("phoenix:menu:changeChar", {}); closeEscMenu(); });
		if (settings) settings.addEventListener("click", function () {
			closeEscMenu();
			PhoenixBridge.send("phoenix:settings:openRequest", {});
		});
		if (partyLeave) partyLeave.addEventListener("click", function () {
			inParty = false;
			refreshPartyLeave();
			PhoenixBridge.send("phoenix:social:partyLeave", {});
			closeEscMenu();
		});
		if (admin)  admin.addEventListener("click", function () {
			closeEscMenu();
			if (global.PhoenixAdminPanel) global.PhoenixAdminPanel.open();
		});
		if (vanish) vanish.addEventListener("click", function () {
			PhoenixBridge.send("phoenix:admin:request", { action: "vanish", payload: null });
		});
		if (logout) logout.addEventListener("click", function () { PhoenixBridge.send("phoenix:menu:logout", {}); closeEscMenu(); });
		if (exit)   exit.addEventListener("click", function () { PhoenixBridge.send("phoenix:app:exit", {}); });
		escMenu.addEventListener("focus", function () { PhoenixBridge.send("phoenix:social:request", {}); });
		PhoenixBridge.on("phoenix:social:state", function (payload) {
			inParty = !!(payload && (parseInt(payload.partyId, 10) || 0) > 0);
			refreshPartyLeave();
		});
		refreshPartyLeave();
		refreshEscMenuAdmin();
	}

	function refreshEscMenuAdmin() {
		if (!escMenu) return;
		const adminBtn = escMenu.querySelector("#escmenu-admin");
		const vanishBtn = escMenu.querySelector("#escmenu-vanish");
		if (adminBtn) {
			if (isAdmin) adminBtn.removeAttribute("hidden");
			else adminBtn.setAttribute("hidden", "");
		}
		if (vanishBtn) {
			if (isAdmin) vanishBtn.removeAttribute("hidden");
			else vanishBtn.setAttribute("hidden", "");
			const lang = (global.PhoenixI18n && global.PhoenixI18n.getLang()) || "pl";
			const labels = {
				pl: vanished ? "Vanish: WŁĄCZONY (niewidzialny)" : "Vanish: WYŁĄCZONY (widzialny)",
				en: vanished ? "Vanish: ON (invisible)" : "Vanish: OFF (visible)",
				de: vanished ? "Vanish: EIN (unsichtbar)" : "Vanish: AUS (sichtbar)",
				ru: vanished ? "Vanish: ВКЛ (невидимый)" : "Vanish: ВЫКЛ (видимый)"
			};
			vanishBtn.textContent = labels[lang] || labels.pl;
			vanishBtn.classList.toggle("phoenix-escmenu__btn--danger", vanished);
		}
	}

	function renderEscLangs() {
		if (!escLangs || !global.PhoenixI18n) return;
		const FLAG_SVG = {
			pl: '<svg viewBox="0 0 32 24" aria-hidden="true"><rect width="32" height="12" fill="#fff"/><rect y="12" width="32" height="12" fill="#dc143c"/></svg>',
			en: '<svg viewBox="0 0 32 24" aria-hidden="true"><rect fill="#012169" width="32" height="24"/><path d="M0,0 L32,24 M32,0 L0,24" stroke="#fff" stroke-width="4"/><path d="M0,0 L32,24 M32,0 L0,24" stroke="#C8102E" stroke-width="2.5"/><path d="M16,0 V24 M0,12 H32" stroke="#fff" stroke-width="6"/><path d="M16,0 V24 M0,12 H32" stroke="#C8102E" stroke-width="3.5"/></svg>',
			de: '<svg viewBox="0 0 32 24" aria-hidden="true"><rect width="32" height="8" fill="#000"/><rect y="8" width="32" height="8" fill="#DD0000"/><rect y="16" width="32" height="8" fill="#FFCC00"/></svg>',
			ru: '<svg viewBox="0 0 32 24" aria-hidden="true"><rect width="32" height="8" fill="#fff"/><rect y="8" width="32" height="8" fill="#0039A6"/><rect y="16" width="32" height="8" fill="#D52B1E"/></svg>'
		};
		escLangs.innerHTML = "";
		const I18n = global.PhoenixI18n;
		I18n.listLangs().forEach(function (code) {
			const btn = document.createElement("button");
			btn.type = "button";
			btn.className = "phoenix-langs__btn phoenix-langs__btn--flag";
			btn.dataset.lang = code;
			btn.title = I18n.t("lang." + code);
			btn.innerHTML = FLAG_SVG[code] || code.toUpperCase();
			if (code === I18n.getLang()) btn.classList.add("is-active");
			btn.addEventListener("click", function () {
				I18n.setLang(code);
				try { localStorage.setItem("phoenix:lang", code); } catch (e) {}
				if (global.PhoenixStorage) global.PhoenixStorage.set("phoenix:lang", code);
				renderEscLangs();
			});
			escLangs.appendChild(btn);
		});
	}

	function openEscMenu() {
		if (escMenuOpen) return;
		escMenuOpen = true;
		document.body.classList.add("phoenix-escmenu-open");
		PhoenixBridge.send("phoenix:menu:open", {});
		setTimeout(function () {
			try { if (escMenu) escMenu.focus(); } catch (e) {}
		}, 30);
	}

	function closeEscMenu() {
		if (!escMenuOpen) return;
		escMenuOpen = false;
		document.body.classList.remove("phoenix-escmenu-open");
		PhoenixBridge.send("phoenix:menu:close", {});
	}

	function handleEscKey(e) {
		if (e.key !== "Escape" && e.keyCode !== 27) return;
		if (inputOpen) return;
		if (global.PhoenixAdminPanel && global.PhoenixAdminPanel.isOpen && global.PhoenixAdminPanel.isOpen()) {
			e.preventDefault();
			global.PhoenixAdminPanel.close();
			return;
		}
		if (escMenuOpen) {
			e.preventDefault();
			closeEscMenu();
			return;
		}
		if (document.body.classList.contains("phoenix-inventory-open")) {
			e.preventDefault();
			PhoenixBridge.send("phoenix:item:closeRequest", {});
			return;
		}
		if (document.body.classList.contains("phoenix-settings-open")) {
			e.preventDefault();
			PhoenixBridge.send("phoenix:settings:closeRequest", {});
			return;
		}
		if (!document.body.classList.contains("phoenix-in-game")) return;
		e.preventDefault();
		openEscMenu();
	}
	document.addEventListener("keydown", handleEscKey, true);
	window.addEventListener("keydown", handleEscKey, true);

	function init() {
		ensureI18n();
		build();
		buildEscMenu();
		PhoenixBridge.on("phoenix:chat:open",   function () { open(); });
		PhoenixBridge.on("phoenix:chat:close",  function () {
			if (!inputOpen) return;
			inputOpen = false;
			root.classList.remove("is-input-open");
			input.value = "";
			historyIdx = -1;
			try { input.blur(); } catch (e) {}
		});
		PhoenixBridge.on("phoenix:chat:append", function (p) { appendMsg(p || {}); });
		PhoenixBridge.on("phoenix:social:dm", function (p) { appendDm(p || {}); });
		PhoenixBridge.on("phoenix:chat:dmOpen", function (p) { openDmTab(p || {}); });
		PhoenixBridge.on("phoenix:chat:setChannel", function (p) {
			if (p && typeof p.channel === "number") setChannel(p.channel);
		});
		PhoenixBridge.on("phoenix:chat:show", function () { document.body.classList.add("phoenix-in-game"); });
		PhoenixBridge.on("phoenix:chat:hide", function () {
			document.body.classList.remove("phoenix-in-game");
			closeEscMenu();
		});
		PhoenixBridge.on("phoenix:menu:openRequest", function () { openEscMenu(); });
		PhoenixBridge.on("phoenix:menu:closeRequest", function () { closeEscMenu(); });
		PhoenixBridge.on("phoenix:account:identity", function (p) {
			isAdmin = !!(p && p.isAdmin);
			buildTabs();
			refreshEscMenuAdmin();
		});
		PhoenixBridge.on("phoenix:account:vanish", function (p) {
			vanished = !!(p && p.vanished);
			refreshEscMenuAdmin();
		});
		if (global.PhoenixI18n) {
			global.PhoenixI18n.onChange(function () {
				buildTabs();
				refreshHint();
				refreshPrefix();
				renderEscLangs();
				refreshEscMenuAdmin();
			});
		}
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", init);
	} else {
		init();
	}

	global.phoenixChatOpen = function () { open(); };
	global.phoenixChatClose = function () { closeInput(false); };
	global.phoenixChatAppend = function (json) {
		try { appendMsg(typeof json === "string" ? JSON.parse(json) : json); } catch (e) {}
	};
	global.phoenixChatShow = function () { document.body.classList.add("phoenix-in-game"); };
	global.phoenixChatHide = function () { document.body.classList.remove("phoenix-in-game"); closeEscMenu(); };
	global.phoenixMenuOpen = function () { openEscMenu(); };
	global.phoenixMenuClose = function () { closeEscMenu(); };
})(window);
