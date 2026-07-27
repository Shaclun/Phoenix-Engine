phoenix.house.Handlers <- {
	function enabled() {
		return phoenix.features.Settings.isEnabled("housing.enabled")
	}

	function guardTick() {
		if (!phoenix.house.Handlers.enabled()) return
		phoenix.house.Structure.guardTick()
	}

	function onInteract(playerId, message) {
		if (!phoenix.house.Handlers.enabled() || message == null) return
		phoenix.house.Structure.handleAction(playerId, message)
	}

	function onPanelRequest(playerId, _message) {
		if (!phoenix.house.Handlers.enabled()) return
		phoenix.house.Structure.sendPanel(playerId)
	}

	function lateSnapshot(playerId) {
		if (!phoenix.house.Handlers.enabled()) return
		phoenix.house.Structure.sendSnapshot(playerId)
	}
}

try { addEventHandler("onInit", function() { if (phoenix.house.Handlers.enabled()) phoenix.house.Structure.bootLoad() }) } catch (e) {}
try { addEventHandler("onPlayerJoin", function(playerId) { if (!phoenix.house.Handlers.enabled()) return; phoenix.house.Structure.bootLoad(); setTimer(phoenix.house.Handlers.lateSnapshot, 2500, 1, playerId) }) } catch (e) {}
try { setTimer(phoenix.house.Handlers.guardTick, 1000, 0) } catch (e) {}
try { phoenix.house.Message.InteractRequest.bind(phoenix.house.Handlers.onInteract) } catch (e) {}
try { phoenix.house.Message.PanelRequest.bind(phoenix.house.Handlers.onPanelRequest) } catch (e) {}
try { addEventHandler("phoenix.features.OnChanged", function(key, enabled) { if (key == "housing.enabled" && enabled) phoenix.house.Structure.bootLoad() }) } catch (e) {}