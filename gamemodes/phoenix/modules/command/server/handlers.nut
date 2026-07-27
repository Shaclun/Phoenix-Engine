phoenix.command.Handlers <- {

	function _joinArgs(args, from = 0) {
		if (args == null || args.len() <= from) return ""
		local out = ""
		for (local i = from; i < args.len(); i += 1) {
			if (i > from) out += " "
			out += args[i]
		}
		return out
	}

	function cmdPos(playerId, args, raw) {
		local tag = phoenix.command.Handlers._joinArgs(args)
		try { phoenix.chat.Server.savePos(playerId, tag) } catch (e) {}
	}

	function cmdVanish(playerId, args, raw) {
		try { phoenix.chat.Server.toggleVanish(playerId, null) } catch (e) {}
	}

	function cmdRevive(playerId, args, raw) {
		try { phoenix.player.Gate.revive(playerId) } catch (e) {}
	}

	function cmdGiveItem(playerId, args, raw) {
		if (args.len() == 0) {
			phoenix.command.Dispatcher.hint(playerId, "/giveitem <instance> [amt] [quality 0-5] [upgrade 0-9]")
			return
		}
		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) return
		local instance = args[0]
		local amount = args.len() > 1 ? args[1].tointeger() : 1
		local quality = args.len() > 2 ? args[2].tointeger() : PhoenixItemQuality.Common
		local upgrade = args.len() > 3 ? args[3].tointeger() : 0
		phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, active.id, instance, {
			amount = amount, quality = quality, upgrade = upgrade, source = "admin"
		}, function(rec) {
			if (rec == null) {
				phoenix.command.Dispatcher.error(playerId, "[Item] Nieznana instancja: " + instance)
				return
			}
			phoenix.command.Dispatcher.info(playerId, "[Item] +" + amount + "x " + instance + " (q=" + quality + ", +" + upgrade + ")")
		})
	}

	function cmdGiveAll(playerId, args, raw) {
		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) return
		local quality = args.len() > 0 ? args[0].tointeger() : PhoenixItemQuality.Common
		local upgrade = args.len() > 1 ? args[1].tointeger() : 0
		local total = phoenix.item.count()
		phoenix.command.Dispatcher.hint(playerId, "[Item] /giveall - wydawanie " + total + " przedmiotow (q=" + quality + ", +" + upgrade + ")...")
		local given = 0
		foreach (instanceId, _scheme in phoenix.item.Schemes.byInstance) {
			phoenix.item.Structure.giveItem(PhoenixInventoryOwner.Player, active.id, instanceId, {
				amount = 1, quality = quality, upgrade = upgrade, source = "admin-giveall"
			}, null)
			given += 1
		}
		phoenix.command.Dispatcher.info(playerId, "[Item] +" + given + " przedmiotow dodanych do ekwipunku.")
	}

	function cmdClearItems(playerId, args, raw) {
		local active = phoenix.character.Structure.getActive(playerId)
		if (active == null) return
		local sql = "DELETE FROM `phoenix_items` WHERE `ownerType` = " + PhoenixInventoryOwner.Player + " AND `ownerId` = " + active.id
		ORM.engine.executeAsync(sql, function(_) {
			local key = phoenix.item.Structure.key(PhoenixInventoryOwner.Player, active.id)
			if (key in phoenix.item.Structure.cache) phoenix.item.Structure.cache.rawdelete(key)
			phoenix.item.Structure.loadOwner(PhoenixInventoryOwner.Player, active.id, function(_2) {
				phoenix.item.Structure.sendInventorySnapshot(playerId, active.id)
			})
			phoenix.command.Dispatcher.info(playerId, "[Item] /clearitems - ekwipunek wyczyszczony.")
		})
	}

	function cmdHerbSpot(playerId, args, raw) {
		local instance = args.len() > 0 ? args[0].toupper() : "ITPL_HEALTH_HERB_01"
		if (phoenix.herb.catalogOf(instance) == null) {
			phoenix.command.Dispatcher.error(playerId, "[Herb] Nieznana roslina: " + instance)
			return
		}
		local id = args.len() > 1 ? args[1] : ("herb_" + instance.tolower() + "_" + getTickCount())
		local pos = null
		try { pos = getPlayerPosition(playerId) } catch (e) {}
		if (pos == null) return
		local world = "NEWWORLD"
		try { local w = getPlayerWorld(playerId); if (w != null && w != "") world = w } catch (e) {}
		world = phoenix.herb.Structure.normalizeWorld(world)
		local line = "\t{ id = \"" + id + "\", instance = \"" + instance + "\", world = \"" + world + "\", x = " + pos.x + ", y = " + pos.y + ", z = " + pos.z + " },\n"
		phoenix.herb.Structure.saveSpotFromAdmin(playerId, { plantId = id, instance = instance, world = world, posX = pos.x, posY = pos.y, posZ = pos.z }, function(_a, _b, _c) {})
		try {
			local f = file("positions.txt", "a+")
			local b = blob(line.len())
			foreach (idx, ch in line) b.writen(ch, 'b')
			b.seek(0)
			f.writeblob(b)
			f.close()
		} catch (e) {}
		phoenix.command.Dispatcher.info(playerId, "[Herb] Spot zapisany do positions.txt: " + id)
	}

	function cmdTime(playerId, args, raw) {
		if (args.len() == 0) {
			local cur = { hour = 0, min = 0 }
			try { cur = getTime() } catch (e) {}
			phoenix.command.Dispatcher.hint(playerId, "[Czas] Aktualny: " + cur.hour + ":" + (cur.min < 10 ? "0" + cur.min : cur.min) + ". Uzycie: /time HH[:MM]")
			return
		}
		local input = args[0]
		local hour = 0
		local min = 0
		local colonAt = input.find(":")
		if (colonAt != null) {
			hour = input.slice(0, colonAt).tointeger()
			min = input.slice(colonAt + 1).tointeger()
		} else {
			hour = input.tointeger()
			if (args.len() > 1) min = args[1].tointeger()
		}
		if (hour < 0) hour = 0
		if (hour > 23) hour = 23
		if (min < 0) min = 0
		if (min > 59) min = 59
		try { phoenix.worldclock.Clock.applyTime(hour, min, playerId) } catch (e) {
			try { setTime(hour, min) } catch (e2) {}
		}
		try { phoenix.worldclock.Broadcast.sendAll() } catch (eB) {}
		phoenix.command.Dispatcher.info(playerId, "[Czas] Ustawiono: " + hour + ":" + (min < 10 ? "0" + min : min))
	}

	function cmdDayLength(playerId, args, raw) {
		if (args.len() == 0) {
			local cur = 60
			try { cur = phoenix.worldclock.Clock.readDayLength() } catch (e) {}
			phoenix.command.Dispatcher.hint(playerId, "[Dzien] Dlugosc doby: " + cur + " minut. Uzycie: /daylength <minut>")
			return
		}
		local minutes = args[0].tointeger()
		if (minutes < 1) minutes = 1
		try { phoenix.worldclock.Clock.applyDayLength(minutes) } catch (e) {}
		try { phoenix.worldclock.Broadcast.sendAll() } catch (eB) {}
		phoenix.command.Dispatcher.info(playerId, "[Dzien] Dlugosc doby ustawiona: " + minutes + " minut")
	}

	function cmdWeather(playerId, args, raw) {
		if (args.len() == 0) {
			phoenix.command.Dispatcher.hint(playerId, "[Pogoda] Uzycie: /weather <clear|rain|snow|storm|stop>")
			return
		}
		local kind = args[0].tolower()
		try { phoenix.worldclock.Weather.set(kind) } catch (e) {}
		try { phoenix.worldclock.Broadcast.sendAll() } catch (eB) {}
		phoenix.command.Dispatcher.info(playerId, "[Pogoda] Ustawiono: " + kind)
	}

	function cmdWeatherWind(playerId, args, raw) {
		if (args.len() == 0) {
			phoenix.command.Dispatcher.hint(playerId, "[Pogoda] Uzycie: /wind <0.0 - 3.0>")
			return
		}
		local scale = args[0].tofloat()
		if (scale < 0.0) scale = 0.0
		if (scale > 5.0) scale = 5.0
		try { phoenix.worldclock.Weather.setWind(scale) } catch (e) {}
		try { phoenix.worldclock.Broadcast.sendAll() } catch (eB) {}
		phoenix.command.Dispatcher.info(playerId, "[Pogoda] Sila wiatru: " + scale)
	}

	function cmdRpText(playerId, args, channel, usage) {
		local text = phoenix.command.Handlers._joinArgs(args)
		text = phoenix.chat.Server.trim(phoenix.chat.Server.sanitize(text))
		if (text == "") { phoenix.command.Dispatcher.hint(playerId, usage); return }
		phoenix.chat.Server.dispatch(playerId, channel, text, true)
	}

	function cmdOoc(playerId, args, raw) {
		if (!phoenix.features.Settings.isEnabled("chat.ooc")) {
			phoenix.command.Dispatcher.error(playerId, "[RP] Chat OOC jest wyłączony.")
			return
		}
		phoenix.command.Handlers.cmdRpText(playerId, args, phoenix.chat.Channel.OOC, "/b <wiadomość>")
	}

	function cmdMe(playerId, args, raw) {
		phoenix.command.Handlers.cmdRpText(playerId, args, phoenix.chat.Channel.ME, "/me <akcja>")
	}

	function cmdDo(playerId, args, raw) {
		phoenix.command.Handlers.cmdRpText(playerId, args, phoenix.chat.Channel.DO, "/do <opis otoczenia>")
	}

	function cmdTry(playerId, args, raw) {
		local text = phoenix.command.Handlers._joinArgs(args)
		text = phoenix.chat.Server.trim(phoenix.chat.Server.sanitize(text))
		if (text == "") { phoenix.command.Dispatcher.hint(playerId, "/try <próba>"); return }
		if (text.len() > 220) text = text.slice(0, 220)
		local result = (rand() % 2) == 0 ? "SUCCESS" : "FAILURE"
		phoenix.chat.Server.dispatch(playerId, phoenix.chat.Channel.TRY, text + " — " + result, true)
	}

	function cmdTodo(playerId, args, raw) {
		local text = phoenix.command.Handlers._joinArgs(args)
		local separator = text.find("*")
		if (separator == null || text.slice(separator + 1).find("*") != null) {
			phoenix.command.Dispatcher.hint(playerId, "/todo <wypowiedź>*<akcja>")
			return
		}
		local speech = phoenix.chat.Server.trim(text.slice(0, separator))
		local action = phoenix.chat.Server.trim(text.slice(separator + 1))
		if (speech == "" || action == "") { phoenix.command.Dispatcher.hint(playerId, "/todo <wypowiedź>*<akcja>"); return }
		phoenix.chat.Server.dispatch(playerId, phoenix.chat.Channel.TODO, phoenix.chat.Server.sanitize(speech + " — " + action), true)
	}

	function cmdAme(playerId, args, raw) {
		phoenix.command.Handlers.cmdRpText(playerId, args, phoenix.chat.Channel.AME, "/ame <krótka akcja>")
	}

	function cmdFly(playerId, args, raw) {
		phoenix.admin.Server.dispatchAdminFly(playerId, null)
	}

	function registerAll() {
		local D = phoenix.command.Dispatcher
		D.register("pos", phoenix.command.Handlers.cmdPos, true, null, "/pos [etykieta] - zapisuje pozycje do positions.txt")
		D.register("vanish", phoenix.command.Handlers.cmdVanish, true, null, "/vanish - przelacz niewidzialnosc")
		D.register("revive", phoenix.command.Handlers.cmdRevive, false, ["respawn"], "/revive - odrodzenie")
		D.register("giveitem", phoenix.command.Handlers.cmdGiveItem, true, null, "/giveitem <instance> [amt] [q] [up]")
		D.register("giveall", phoenix.command.Handlers.cmdGiveAll, true, null, "/giveall [q] [up]")
		D.register("clearitems", phoenix.command.Handlers.cmdClearItems, true, null, "/clearitems")
		D.register("herbspot", phoenix.command.Handlers.cmdHerbSpot, true, null, "/herbspot [instance] [id]")
		D.register("time", phoenix.command.Handlers.cmdTime, true, ["czas"], "/time HH[:MM]")
		D.register("daylength", phoenix.command.Handlers.cmdDayLength, true, ["dzien"], "/daylength <minut>")
		D.register("weather", phoenix.command.Handlers.cmdWeather, true, ["pogoda"], "/weather <clear|rain|snow|storm|stop>")
		D.register("wind", phoenix.command.Handlers.cmdWeatherWind, true, ["wiatr"], "/wind <skala>")
		D.register("fly", phoenix.command.Handlers.cmdFly, true, ["lataj"], "/fly - przelacz latanie")
		D.register("b", phoenix.command.Handlers.cmdOoc, false, ["ooc"], "/b <wiadomość>", "chat.ooc")
		D.register("me", phoenix.command.Handlers.cmdMe, false, null, "/me <akcja>", "chat.rpActions")
		D.register("do", phoenix.command.Handlers.cmdDo, false, null, "/do <opis otoczenia>", "chat.rpActions")
		D.register("try", phoenix.command.Handlers.cmdTry, false, null, "/try <próba>", "chat.rpActions")
		D.register("todo", phoenix.command.Handlers.cmdTodo, false, null, "/todo <wypowiedź>*<akcja>", "chat.rpActions")
		D.register("ame", phoenix.command.Handlers.cmdAme, false, null, "/ame <krótka akcja>", "chat.rpActions")
	}
}

addEventHandler("onInit", function () {
	try { phoenix.command.Handlers.registerAll() } catch (e) {}
})
