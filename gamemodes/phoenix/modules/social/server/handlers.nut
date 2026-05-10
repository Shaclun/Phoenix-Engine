phoenix.social.Handlers <- {
	function handle(playerId, message) {
		if (message == null || message.action == null) return
		local action = message.action.tostring()
		if (action == "requestPanel") { phoenix.social.Structure.pushSocial(playerId); return }
		if (action == "interact") { phoenix.social.Handlers.interact(playerId, message.targetId); return }
		if (action == "tradeStart") { phoenix.social.Structure.startTrade(playerId, message.targetId); return }
		if (action == "tradeGold") { phoenix.social.Structure.setTradeGold(playerId, message.gold); return }
		if (action == "tradeItem") { phoenix.social.Structure.setTradeItem(playerId, message.itemId, message.amount); return }
		if (action == "tradeAccept") { phoenix.social.Structure.acceptTrade(playerId); return }
		if (action == "tradeCancel") { phoenix.social.Structure.cancelTrade(playerId, "cancel"); return }
		if (action == "friendAdd") { phoenix.social.Structure.addFriend(playerId, message.targetId); return }
		if (action == "dm") { phoenix.social.Structure.sendDm(playerId, message.targetId, message.text); return }
		if (action == "partyInvite") { phoenix.social.Structure.inviteParty(playerId, message.targetId); return }
		if (action == "partyAccept") { phoenix.social.Structure.acceptParty(playerId, message.targetId); return }
		if (action == "partyLeave") { phoenix.social.Structure.leaveParty(playerId); return }
	}

	function interact(playerId, targetId) {
		if (!phoenix.social.Structure.canInteract(playerId, targetId)) {
			phoenix.social.Structure.send(playerId, "error", false, "noTarget", null)
			return
		}
		phoenix.social.Structure.send(playerId, "interaction", true, "", { target = phoenix.social.Structure.playerEntry(targetId) })
	}

}

function phoenixSocialOnPlayerDamage(victimId, attackerId, desc) {
	local now = 0
	try { now = getTickCount() } catch (e) { return }
	try { phoenix.social.Structure.recentCombat[victimId] <- now } catch (e2) {}
	try { if (attackerId != null && attackerId >= 0) phoenix.social.Structure.recentCombat[attackerId] <- now } catch (e3) {}
}

phoenix.social.Message.Request.bind(function(playerId, message) {
	phoenix.social.Handlers.handle(playerId, message)
})

addEventHandler("onPlayerDisconnect", function(playerId, reason) {
	try { phoenix.social.Structure.onDisconnect(playerId) } catch (e) {}
})

addEventHandler("onPlayerDamage", phoenixSocialOnPlayerDamage)
