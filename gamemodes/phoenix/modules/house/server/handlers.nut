phoenix.house.Handlers <- {
	function guardTick() {
		phoenix.house.Structure.guardTick()
	}

	function onInteract(playerId, message) {
		if (message == null) return
		phoenix.house.Structure.handleAction(playerId, message)
	}

	function onPanelRequest(playerId, _message) {
		phoenix.house.Structure.sendPanel(playerId)
	}

	function lateSnapshot(playerId) {
		phoenix.house.Structure.sendSnapshot(playerId)
	}
}

try { addEventHandler("onInit", function() { phoenix.house.Structure.bootLoad() }) } catch (e) {}
try { addEventHandler("onPlayerJoin", function(playerId) { phoenix.house.Structure.bootLoad(); setTimer(phoenix.house.Handlers.lateSnapshot, 2500, 1, playerId) }) } catch (e) {}
try { setTimer(phoenix.house.Handlers.guardTick, 1000, 0) } catch (e) {}
try { phoenix.house.Message.InteractRequest.bind(phoenix.house.Handlers.onInteract) } catch (e) {}
try { phoenix.house.Message.PanelRequest.bind(phoenix.house.Handlers.onPanelRequest) } catch (e) {}