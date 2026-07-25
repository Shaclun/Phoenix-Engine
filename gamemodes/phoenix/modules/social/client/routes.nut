if ("Router" in phoenix.web && phoenix.web.Router != null) {
	phoenix.web.Router.on("phoenix:social:close", function(payload) { phoenix.social.Interface.close() })
	phoenix.web.Router.on("phoenix:social:request", function(payload) { phoenix.social.Model.send("requestPanel") })
	phoenix.web.Router.on("phoenix:social:tradeStart", function(payload) {
		if (payload == null || !("targetId" in payload)) return
		phoenix.social.Model.send("tradeStart", { targetId = payload.targetId })
	})
	phoenix.web.Router.on("phoenix:social:tradeItem", function(payload) {
		if (payload == null || !("itemId" in payload)) return
		local amount = ("amount" in payload) ? payload.amount : 0
		phoenix.social.Model.send("tradeItem", { itemId = payload.itemId, amount = amount })
	})
	phoenix.web.Router.on("phoenix:social:tradeGold", function(payload) {
		local gold = (payload != null && "gold" in payload) ? payload.gold : 0
		phoenix.social.Model.send("tradeGold", { gold = gold })
	})
	phoenix.web.Router.on("phoenix:social:tradeAccept", function(payload) { phoenix.social.Model.send("tradeAccept") })
	phoenix.web.Router.on("phoenix:social:tradeCancel", function(payload) { phoenix.social.Model.send("tradeCancel") })
	phoenix.web.Router.on("phoenix:social:friendAdd", function(payload) {
		if (payload == null || !("targetId" in payload)) return
		phoenix.social.Model.send("friendAdd", { targetId = payload.targetId })
	})
	phoenix.web.Router.on("phoenix:social:dm", function(payload) {
		if (payload == null || !("targetId" in payload)) return
		local text = ("text" in payload && payload.text != null) ? payload.text.tostring() : ""
		phoenix.social.Model.send("dm", { targetId = payload.targetId, text = text })
	})
	phoenix.web.Router.on("phoenix:social:partyInvite", function(payload) {
		if (payload == null || !("targetId" in payload)) return
		phoenix.social.Model.send("partyInvite", { targetId = payload.targetId })
	})
	phoenix.web.Router.on("phoenix:social:partyAccept", function(payload) {
		if (payload == null || !("inviteId" in payload)) return
		phoenix.social.Model.send("partyAccept", { inviteId = payload.inviteId })
	})
	phoenix.web.Router.on("phoenix:social:partyDecline", function(payload) {
		local inviteId = (payload != null && "inviteId" in payload) ? payload.inviteId : 0
		phoenix.social.Model.send("partyDecline", { inviteId = inviteId })
	})
	phoenix.web.Router.on("phoenix:social:partyLeave", function(payload) { phoenix.social.Model.send("partyLeave") })
	phoenix.web.Router.on("phoenix:social:partyKick", function(payload) {
		if (payload == null || !("targetId" in payload)) return
		phoenix.social.Model.send("partyKick", { targetId = payload.targetId })
	})
	phoenix.web.Router.on("phoenix:social:partyTransfer", function(payload) {
		if (payload == null || !("targetId" in payload)) return
		phoenix.social.Model.send("partyTransfer", { targetId = payload.targetId })
	})
}
