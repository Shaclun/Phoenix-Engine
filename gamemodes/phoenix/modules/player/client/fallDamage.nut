phoenix.player.FallDamage <- {
	function onPlayerDamage(killerId, playerId, description) {
		if (playerId != heroId) return
		if (killerId != null) return
		if (description == null) return

		local flags = 0
		try { flags = description.flags.tointeger() } catch (e) { return }
		if ((flags & DAMAGE_FALL) == 0) return

		try { cancelEvent() } catch (e) {}
		if (!phoenix.features.Client.effectiveEnabled("player.fallDamage")) return

		local amount = 0
		try { amount = description.damage.tointeger() } catch (e) { return }
		if (amount <= 0) return
		if (amount > 65535) amount = 65535

		local message = phoenix.player.Message.FallDamage()
		message.amount = amount
		try { message.serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}
}

addEventHandler("onPlayerDamageClient", phoenix.player.FallDamage.onPlayerDamage)