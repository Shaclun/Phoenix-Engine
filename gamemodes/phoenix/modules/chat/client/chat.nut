

phoenix.chat.Client <- {

	dotSequence = ["", ".", "..", "..."]
	dotIntervalMs = 350
	heartbeatMs = 1200
	timeoutMs = 4000
	overheadLifeMs = 6000
	overheadFadeInMs = 250
	overheadFadeOutMs = 1500
	overheadAlphaMax = 235
	baseHeight = 115.0
	typingDotOffset = 30.0
	maxLen = 240

	inputOpen = false
	localTyping = false
	lastInputLen = 0
	lastSendTick = 0
	typingEntries = {}
	overheadEntries = {}
	currentChannel = 0
	chatVisible = false
	menuOpen = false
	lastInputCloseTick = 0

	function init() {
		addEventHandler("onRender", phoenix.chat.Client.onRender)
		addEventHandler("onKeyDown", phoenix.chat.Client.onKeyDown)
		phoenix.chat.Message.Broadcast.bind(phoenix.chat.Client.onBroadcast)
		phoenix.chat.Message.Typing.bind(phoenix.chat.Client.onTypingPacket)

		phoenix.web.Router.on("phoenix:chat:submit", phoenix.chat.Client.onCefSubmit)
		phoenix.web.Router.on("phoenix:chat:close",  phoenix.chat.Client.onCefClose)
		phoenix.web.Router.on("phoenix:chat:input",  phoenix.chat.Client.onCefInput)

		phoenix.web.Router.on("phoenix:menu:open",       phoenix.chat.Client.onMenuOpen)
		phoenix.web.Router.on("phoenix:menu:close",      phoenix.chat.Client.onMenuClose)
		phoenix.web.Router.on("phoenix:menu:logout",     phoenix.chat.Client.onMenuLogout)
		phoenix.web.Router.on("phoenix:menu:changeChar", phoenix.chat.Client.onMenuChangeChar)
	}

	function show() {
		if (phoenix.chat.Client.chatVisible) return
		phoenix.chat.Client.chatVisible = true
		try { phoenix.web.Manager.showOverlay() } catch (e) {}
		phoenix.web.Manager.emit("phoenix:chat:show", null)
		phoenix.chat.Client.systemLine("Phoenix chat: T = pisz, TAB = kanal, /g globalny, /pos <nazwa> = zapis pozycji")
	}

	function hide() {
		if (!phoenix.chat.Client.chatVisible) return
		phoenix.chat.Client.chatVisible = false
		phoenix.web.Manager.emit("phoenix:chat:hide", null)
		try { phoenix.web.Manager.hideOverlay() } catch (e) {}
	}

	function systemLine(text) {
		phoenix.web.Manager.emit("phoenix:chat:append", {
			channel = 0, name = "*", text = text, system = true, playerId = 0
		})
	}

	function openInput() {
		if (phoenix.chat.Client.inputOpen) return
		if (!phoenix.chat.Client.chatVisible) return
		phoenix.chat.Client.inputOpen = true
		try { disableControls(true) } catch (e) {}
		try { setFreeze(true) } catch (e) {}
		try { phoenix.camera.Structure.freeze() } catch (e) {}
		try { Camera.movementEnabled = false } catch (e) {}
		try { Camera.modeChangeEnabled = false } catch (e) {}

		try { phoenix.web.Manager.focusInput() } catch (e) {}

		try { playGesticulation(heroId) } catch (e) {}
		phoenix.web.Manager.emit("phoenix:chat:open", null)
	}

	function closeInputLocal(sent) {
		if (!phoenix.chat.Client.inputOpen) return
		phoenix.chat.Client.inputOpen = false
		phoenix.chat.Client.lastInputCloseTick = getTickCount()
		try { stopAni(heroId) } catch (e) {}
		try { disableControls(false) } catch (e) {}
		try { setFreeze(false) } catch (e) {}
		try { phoenix.camera.Structure.release() } catch (e) {}

		try { phoenix.web.Manager.blurInput() } catch (e) {}

		phoenix.web.Manager.emit("phoenix:chat:close", null)
		if (phoenix.chat.Client.localTyping) phoenix.chat.Client.sendLocalState(false)
		phoenix.chat.Client.lastInputLen = 0
	}

	function onCefSubmit(payload) {
		if (payload == null) return
		local channel = ("channel" in payload) ? payload.channel : 0
		local text = ("text" in payload) ? payload.text : ""
		if (text == null) return
		text = phoenix.chat.Client.trim(text.tostring())
		if (text == "") return
		if (text.len() > phoenix.chat.Client.maxLen) text = text.slice(0, phoenix.chat.Client.maxLen)

		try {
			local packet = phoenix.chat.Message.Submit()
			packet.channel = channel
			packet.text = text
			packet.serialize().send(RELIABLE_ORDERED)
		} catch (e) {}

		try { playGesticulation(heroId) } catch (e) {}
		phoenix.chat.Client.closeInputLocal(true)
	}

	function onCefClose(_payload) {
		phoenix.chat.Client.closeInputLocal(false)
	}

	function onCefInput(payload) {
		if (payload == null) return
		local len = ("length" in payload) ? payload.length : 0
		if ("channel" in payload) phoenix.chat.Client.currentChannel = payload.channel
		local now = getTickCount()
		if (len != phoenix.chat.Client.lastInputLen) {
			phoenix.chat.Client.lastInputLen = len
			if (len > 0 && !phoenix.chat.Client.localTyping) phoenix.chat.Client.sendLocalState(true)
			else if (len == 0 && phoenix.chat.Client.localTyping) phoenix.chat.Client.sendLocalState(false)
		} else if (phoenix.chat.Client.localTyping
			&& (now - phoenix.chat.Client.lastSendTick) >= phoenix.chat.Client.heartbeatMs) {
			phoenix.chat.Client.sendLocalState(true)
		}

		if (phoenix.chat.Client.inputOpen) {
			try { playGesticulation(heroId) } catch (e) {}
		}
	}

	function trim(s) {
		if (s == null) return ""
		local i = 0
		local j = s.len()
		while (i < j && (s[i] == ' ' || s[i] == '\t')) i += 1
		while (j > i && (s[j - 1] == ' ' || s[j - 1] == '\t')) j -= 1
		return s.slice(i, j)
	}

	function sendLocalState(typing) {
		phoenix.chat.Client.localTyping = (typing == true)
		phoenix.chat.Client.lastSendTick = getTickCount()

		if (typing == true) {
			phoenix.chat.Client.activateTyping(heroId)
		}
		else phoenix.chat.Client.removeTyping(heroId)
		try {
			local packet = phoenix.chat.Message.Typing()
			packet.playerId = heroId
			packet.typing = (typing == true)
			packet.channel = phoenix.chat.Client.currentChannel
			packet.serialize().send(RELIABLE)
		} catch (e) {}
	}

	function onTypingPacket(message) {
		if (message == null || !("playerId" in message)) return
		local ch = ("channel" in message) ? message.channel : 0
		if (message.typing == true) phoenix.chat.Client.activateTyping(message.playerId, ch)
		else phoenix.chat.Client.removeTyping(message.playerId)
	}

	function activateTyping(playerId, channel = 0) {
		local now = getTickCount()
		if (!(playerId in phoenix.chat.Client.typingEntries)) {
			local d = phoenix.chat.Client.makeDraw(playerId, ".", channel)
			phoenix.chat.Client.typingEntries[playerId] <- {
				draw = d
				dotIdx = 0
				nextDotAt = now + phoenix.chat.Client.dotIntervalMs
				lastBeat = now
			}
		} else {
			phoenix.chat.Client.typingEntries[playerId].lastBeat = now
		}
	}

	function removeTyping(playerId) {
		if (!(playerId in phoenix.chat.Client.typingEntries)) return
		local entry = phoenix.chat.Client.typingEntries[playerId]
		try { if (entry.draw != null) entry.draw.remove() } catch (e) {}
		phoenix.chat.Client.typingEntries.rawdelete(playerId)
	}

	function makeDraw(playerId, text, channel) {
		try {
			local pos = getPlayerPosition(playerId)
			if (pos == null) return null
			local d = Draw3d(pos.x, pos.y + phoenix.chat.Client.baseHeight, pos.z)
			try { d.setFont("FONT_OLD_10_WHITE_HI.TGA") } catch (e) {}
			local r = 240; local g = 220; local b = 180
			if (channel == 1) { r = 120; g = 200; b = 255 }
			else if (channel == 2) { r = 212; g = 175; b = 55 }
			try { d.setColor(Color(r, g, b, 235)) } catch (e) {}
			if (text != null && text != "") d.insertText(phoenix.text.Encoding.forLabel(text))
			else d.insertText(" ")
			d.distance = 2500
			d.visible = true
			try { d.top() } catch (e) {}
			return d
		} catch (e) { return null }
	}

	function updateDrawPosition(playerId, draw, yOffset = 0) {
		try {
			local pos = getPlayerPosition(playerId)
			if (pos == null) { draw.visible = false; return }
			draw.setWorldPosition(pos.x, pos.y + phoenix.chat.Client.baseHeight + yOffset, pos.z)
			draw.visible = true
		} catch (e) {}
	}

	function setAllDrawsVisible(v) {
		foreach (pid, entry in phoenix.chat.Client.typingEntries) {
			try { if (entry.draw != null) entry.draw.visible = v } catch (e) {}
		}
		foreach (pid, entry in phoenix.chat.Client.overheadEntries) {
			try { if (entry.draw != null) entry.draw.visible = v } catch (e) {}
		}
	}

	function onBroadcast(message) {
		if (message == null) return

		phoenix.web.Manager.emit("phoenix:chat:append", {
			channel = message.channel,
			name = message.name,
			text = message.text,
			system = false,
			playerId = message.playerId
		})

		phoenix.chat.Client.showOverhead(message.playerId, message.text, message.channel)
		phoenix.chat.Client.removeTyping(message.playerId)
	}

	function showOverhead(playerId, text, channel) {
		local now = getTickCount()
		local entry = null
		if (playerId in phoenix.chat.Client.overheadEntries) {
			entry = phoenix.chat.Client.overheadEntries[playerId]
			try { if (entry.draw != null) entry.draw.remove() } catch (e) {}
		} else {
			entry = { draw = null, expiresAt = 0, channel = 0, appearedAt = 0 }
			phoenix.chat.Client.overheadEntries[playerId] <- entry
		}
		entry.channel = channel
		entry.draw = phoenix.chat.Client.makeDraw(playerId, text, channel)
		entry.appearedAt = now
		entry.expiresAt = now + phoenix.chat.Client.overheadLifeMs

		if (entry.draw != null) {
			try {
				for (local i = 0; i < entry.draw.labels.len(); i += 1)
					entry.draw.setLineAlpha(i, 0)
			} catch (e) {}
		}
	}

	function applyOverheadAlpha(entry, now) {
		if (entry == null || entry.draw == null) return
		local max = phoenix.chat.Client.overheadAlphaMax
		local alpha = max
		local sinceAppear = now - entry.appearedAt
		local remaining = entry.expiresAt - now
		if (sinceAppear < phoenix.chat.Client.overheadFadeInMs) {
			alpha = (sinceAppear * max) / phoenix.chat.Client.overheadFadeInMs
		}
		if (remaining < phoenix.chat.Client.overheadFadeOutMs) {
			local fadeAlpha = (remaining * max) / phoenix.chat.Client.overheadFadeOutMs
			if (fadeAlpha < alpha) alpha = fadeAlpha
		}
		if (alpha < 0) alpha = 0
		if (alpha > max) alpha = max
		try {
			for (local i = 0; i < entry.draw.labels.len(); i += 1)
				entry.draw.setLineAlpha(i, alpha)
		} catch (e) {}
	}

	function onKeyDown(key) {
		if (key == KEY_ESCAPE) {
			try {
				if ("item" in phoenix && "Interface" in phoenix.item && phoenix.item.Interface.visible) {
					phoenix.item.Interface.close()
					cancelEvent()
					return
				}
			} catch (e) {}
			if (!phoenix.chat.Client.chatVisible) return

			if ((getTickCount() - phoenix.chat.Client.lastInputCloseTick) < 250) return
			if (phoenix.chat.Client.inputOpen) {
				phoenix.chat.Client.closeInputLocal(false)
				try { cancelEvent() } catch (e) {}
				return
			}

			try { phoenix.web.Manager.focusInput() } catch (e) {}
			if (phoenix.chat.Client.menuOpen) {
				phoenix.web.Manager.emit("phoenix:menu:closeRequest", null)
			} else {
				phoenix.web.Manager.emit("phoenix:menu:openRequest", null)
			}
			try { cancelEvent() } catch (e) {}
			return
		}
		if (phoenix.chat.Client.inputOpen) return
		if (phoenix.chat.Client.menuOpen) return
		if (!phoenix.chat.Client.chatVisible) return
		if (key == KEY_T || key == KEY_RETURN) {
			phoenix.chat.Client.openInput()
			try { cancelEvent() } catch (e) {}
		}
	}

	function onMenuOpen(_payload) {
		phoenix.chat.Client.menuOpen = true
		try { phoenix.ui.ActiveGui.set("menu") } catch (e) {}
		try { disableControls(true) } catch (e) {}
		try { phoenix.web.Manager.focusInput() } catch (e) {}
	}

	function onMenuClose(_payload) {
		phoenix.chat.Client.menuOpen = false
		try { if (phoenix.ui.ActiveGui.is("menu")) phoenix.ui.ActiveGui.clear() } catch (e) {}
		try {
			if (phoenix.player.HudClient.knockedDown) {
				disableControls(true)
				setFreeze(true)
				phoenix.web.Manager.focusInput()
				setCursorVisible(true)
				return
			}
		} catch (e) {}
		try { disableControls(false) } catch (e) {}
		try { phoenix.web.Manager.blurInput() } catch (e) {}
	}

	function resetForLogout() {

		if (phoenix.chat.Client.inputOpen) {
			try { phoenix.chat.Client.closeInputLocal(false) } catch (e) {}
		}
		foreach (pid, entry in phoenix.chat.Client.typingEntries) {
			try { entry.draw.remove() } catch (e) {}
		}
		phoenix.chat.Client.typingEntries = {}
		foreach (pid, entry in phoenix.chat.Client.overheadEntries) {
			try { entry.draw.remove() } catch (e) {}
		}
		phoenix.chat.Client.overheadEntries = {}
		phoenix.chat.Client.menuOpen = false
		try { disableControls(false) } catch (e) {}
		try { phoenix.web.Manager.blurInput() } catch (e) {}
		try { phoenix.web.Manager.emit("phoenix:hud:hide", null) } catch (eHud) {}
		try { phoenix.web.Manager.emit("phoenix:hud:target:clear", null) } catch (eTarget) {}
		phoenix.chat.Client.hide()

		try { phoenix.player.Controls.dettach() } catch (e) {}
	}

	function onMenuLogout(_payload) {
		try {
			local packet = phoenix.account.Message.Logout()
			packet.serialize().send(RELIABLE)
		} catch (e) {}
		phoenix.chat.Client.resetForLogout()
		try { phoenix.account.Interface.showLogin() } catch (e) {
			try { phoenix.web.Manager.show("auth") } catch (e2) {}
		}
	}

	function onMenuChangeChar(_payload) {
		phoenix.chat.Client.resetForLogout()
		try { phoenix.character.Interface.showSelection() } catch (e) {
			try { phoenix.web.Manager.show("character") } catch (e2) {}
		}
	}

	function onRender() {
		local now = getTickCount()

		local uiBlocking = false
		try { uiBlocking = phoenix.web.Manager.isUiBlocking() } catch (e) {}
		if (uiBlocking || phoenix.chat.Client.menuOpen) {
			phoenix.chat.Client.setAllDrawsVisible(false)
			return
		}

		local toRemove = []
		foreach (pid, entry in phoenix.chat.Client.typingEntries) {
			if (now - entry.lastBeat > phoenix.chat.Client.timeoutMs) { toRemove.append(pid); continue }
			if (entry.draw == null) entry.draw = phoenix.chat.Client.makeDraw(pid, ".", null)
			if (entry.draw == null) continue
			phoenix.chat.Client.updateDrawPosition(pid, entry.draw, phoenix.chat.Client.typingDotOffset)
			if (now >= entry.nextDotAt) {
				entry.dotIdx = (entry.dotIdx + 1) % phoenix.chat.Client.dotSequence.len()
				entry.nextDotAt = now + phoenix.chat.Client.dotIntervalMs
				local txt = phoenix.chat.Client.dotSequence[entry.dotIdx]
				if (txt == "") txt = " "
				try { entry.draw.setText(txt) } catch (e) {}
			}
		}
		foreach (pid in toRemove) phoenix.chat.Client.removeTyping(pid)

		local toRemoveO = []
		foreach (pid, entry in phoenix.chat.Client.overheadEntries) {
			if (now >= entry.expiresAt) { toRemoveO.append(pid); continue }
			if (entry.draw != null) {
				phoenix.chat.Client.updateDrawPosition(pid, entry.draw, 0)
				phoenix.chat.Client.applyOverheadAlpha(entry, now)
			}
		}
		foreach (pid in toRemoveO) {
			local e = phoenix.chat.Client.overheadEntries[pid]
			try { if (e.draw != null) e.draw.remove() } catch (err) {}
			phoenix.chat.Client.overheadEntries.rawdelete(pid)
		}
	}
}

phoenix.chat.Client.init()

addEventHandler("phoenix.character.OnSelected", function(_characterId, _name) {
	phoenix.chat.Client.show()
})
