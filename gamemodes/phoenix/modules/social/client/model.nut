phoenix.social.Model <- {
	visible = false
	social = null
	interaction = null
	trade = null
	dms = []

	function send(action, data = null) {
		local msg = phoenix.social.Message.Request()
		msg.action = action
		if (data != null) {
			if ("targetId" in data) msg.targetId = data.targetId.tointeger()
			if ("itemId" in data) msg.itemId = data.itemId.tointeger()
			if ("amount" in data) msg.amount = data.amount.tointeger()
			if ("gold" in data) msg.gold = data.gold.tointeger()
			if ("text" in data && data.text != null) msg.text = data.text.tostring()
			msg.payload = data
		}
		try { msg.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function emit(action, payload = null) {
		try { phoenix.web.Manager.emit("phoenix:social:" + action, payload) } catch (e) {}
	}

	function onState(message) {
		local action = message.action
		if (action == "socialState") {
			phoenix.social.Model.social = message.payload
			phoenix.social.Model.emit("state", message.payload)
			return
		}
		if (action == "interaction") {
			phoenix.social.Model.interaction = message.payload
			phoenix.social.Interface.open("interaction")
			phoenix.social.Model.emit("interaction", message.payload)
			return
		}
		if (action == "tradeOpen" || action == "tradeUpdate") {
			phoenix.social.Model.trade = message.payload
			phoenix.social.Interface.open("trade")
			phoenix.social.Model.emit("trade", message.payload)
			return
		}
		if (action == "tradeClosed") {
			phoenix.social.Model.trade = null
			phoenix.social.Model.emit("tradeClosed", message.payload)
			return
		}
		if (action == "dm") {
			try { message.payload.selfId <- heroId } catch (e) {}
			phoenix.social.Model.dms.append(message.payload)
			phoenix.social.Model.emit("dm", message.payload)
			return
		}
		if (action == "partyInvite") {
			phoenix.social.Model.emit("partyInvite", message.payload)
			phoenix.social.Interface.open("social")
			return
		}
		if (action == "error") {
			phoenix.social.Model.emit("error", { error = message.error })
		}
	}
}

phoenix.social.Message.State.bind(function(message) {
	phoenix.social.Model.onState(message)
})
