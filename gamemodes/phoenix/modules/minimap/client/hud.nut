phoenix.minimap <- {
	lastWorld = ""

	function push() {
		local id = -1
		try { id = heroId } catch (e) { return }
		if (id == -1) return

		local pos = null
		try { pos = getPlayerPosition(id) } catch (e2) { return }
		if (pos == null) return

		local angle = 0.0
		try { angle = getPlayerAngle(id).tofloat() } catch (e3) {}

		local world = ""
		try { world = getPlayerWorld(id) } catch (e4) {}
		if (world == null || world == "") { try { world = getWorld() } catch (e5) {} }
		if (world == null) world = ""

		try {
			phoenix.web.Manager.emit("phoenix:minimap:update", {
				x = pos.x.tofloat(),
				y = pos.y.tofloat(),
				z = pos.z.tofloat(),
				angle = angle,
				world = world
			})
		} catch (e6) {}
	}
}

addEventHandler("onInit", function () {
	setTimer(function () {
		try { phoenix.minimap.push() } catch (e) {}
	}, 100, 0)
})