phoenix.profession.Client <- {
	function request(_payload = null) {
		try { phoenix.profession.Message.Request().serialize().send(RELIABLE_ORDERED) } catch (e) {}
	}

	function onSnapshot(message) {
		local entries = message.entries != null ? message.entries : []
		local lang = "pl"; try { lang = phoenix.web.Storage.read("phoenix:lang") } catch (eLang) {}
		foreach (entry in entries) {
			if (lang == "en" && entry.nameEn != "") { entry.name = entry.nameEn; entry.description = entry.descriptionEn }
			else if (lang == "de" && entry.nameDe != "") { entry.name = entry.nameDe; entry.description = entry.descriptionDe }
			else if (lang == "ru" && entry.nameRu != "") { entry.name = entry.nameRu; entry.description = entry.descriptionRu }
			else { entry.name = entry.namePl; entry.description = entry.descriptionPl }
		}
		try { phoenix.web.Manager.emit("phoenix:profession:snapshot", { entries = entries }) } catch (e) {}
	}

	function onHuntingStarted(message) {
		try { playAni(heroId, "T_PLUNDER") } catch (e) {}
		try { phoenix.web.Manager.emit("phoenix:herb:start", { plantId = message.vobId, label = message.label, gatherMs = message.durationMs }) } catch (e2) {}
	}

	function onHuntingResult(message) {
		try { stopAni(heroId, "T_PLUNDER") } catch (e) {}
		try { phoenix.web.Manager.emit("phoenix:herb:result", { plantId = message.vobId, success = message.success, instance = "", label = message.drops, error = message.error, cooldownSec = 0, amount = 0, xp = message.xp, hunting = true }) } catch (e2) {}
	}
}

try { phoenix.web.Router.on("phoenix:profession:request", function(payload) { phoenix.profession.Client.request(payload) }) } catch (e) {}
phoenix.profession.Message.Snapshot.bind(function(message) { phoenix.profession.Client.onSnapshot(message) })
phoenix.profession.Message.HuntingStarted.bind(function(message) { phoenix.profession.Client.onHuntingStarted(message) })
phoenix.profession.Message.HuntingResult.bind(function(message) { phoenix.profession.Client.onHuntingResult(message) })
