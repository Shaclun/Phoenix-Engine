phoenix.player.StatsClient <- {
	visible = false

	function init() {
		addEventHandler("onKeyDown", phoenix.player.StatsClient.onKeyDown)
		phoenix.web.Router.on("phoenix:stats:request", phoenix.player.StatsClient.requestSnapshot)
		phoenix.web.Router.on("phoenix:stats:spend", phoenix.player.StatsClient.onSpend)
		phoenix.web.Router.on("phoenix:stats:close", phoenix.player.StatsClient.forceClose)
		try { phoenix.ui.ActiveGui.register("stats", phoenix.player.StatsClient.forceClose) } catch (e) {}
	}

	function isBusy() {
		try { if (phoenix.web.Manager.isUiBlocking()) return true } catch (e) {}
		try { if (phoenix.chat.Client.inputOpen) return true } catch (e) {}
		try { if (phoenix.chat.Client.menuOpen) return true } catch (e) {}
		return false
	}

	function onKeyDown(key) {
		if (key != KEY_B) return
		if (phoenix.player.StatsClient.visible) {
			phoenix.player.StatsClient.close()
			try { cancelEvent() } catch (e) {}
			return
		}
		if (phoenix.player.StatsClient.isBusy()) return
		phoenix.player.StatsClient.open()
		try { cancelEvent() } catch (e) {}
	}

	function open() {
		if (phoenix.player.StatsClient.visible) return
		phoenix.player.StatsClient.visible = true
		try { phoenix.web.Manager.show("stats") } catch (e) {}
		phoenix.player.StatsClient.requestSnapshot(null)
		try { phoenix.ui.ActiveGui.set("stats") } catch (e) {}
	}

	function close() {
		if (!phoenix.player.StatsClient.visible) return
		phoenix.player.StatsClient.visible = false
		try { phoenix.web.Manager.hide() } catch (e) {}
		try {
			if (phoenix.ui.ActiveGui.is("stats")) phoenix.ui.ActiveGui.clear()
		} catch (e) {}
	}

	function forceClose(_a = null) { phoenix.player.StatsClient.close() }

	function requestSnapshot(_payload) {
		try { phoenix.player.Message.StatsRequest().serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onSpend(payload) {
		if (payload == null || !("stat" in payload)) return
		local m = phoenix.player.Message.StatsSpend()
		m.stat = payload.stat.tostring()
		m.amount = ("amount" in payload) ? payload.amount.tointeger() : 1
		try { m.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onSnapshot(message) {
		try {
			phoenix.web.Manager.emit("phoenix:stats:snapshot", {
				level = message.level,
				experience = message.experience,
				experienceNext = message.experienceNext,
				learnPoints = message.learnPoints,
				hp = message.hp, hpMax = message.hpMax,
				mana = message.mana, manaMax = message.manaMax,
				stamina = message.stamina, staminaMax = message.staminaMax,
				strength = message.strength, dexterity = message.dexterity,
				oneHand = message.oneHand, twoHand = message.twoHand,
				bow = message.bow, crossbow = message.crossbow,
				gold = message.gold,
				weaponProgress = message.weaponProgress
			})
		} catch (e) {}
	}

	function onResult(message) {
		try {
			phoenix.web.Manager.emit("phoenix:stats:result", { success = message.success, error = message.error })
		} catch (e) {}
	}
}

phoenix.player.Message.StatsSnapshot.bind(phoenix.player.StatsClient.onSnapshot)
phoenix.player.Message.StatsResult.bind(phoenix.player.StatsClient.onResult)
phoenix.player.StatsClient.init()
