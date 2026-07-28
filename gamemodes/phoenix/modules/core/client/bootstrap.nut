phoenix.core.Bootstrap <- {
	function onInit() {
		try { clearMultiplayerMessages() } catch (e) {}
	}
}

addEventHandler("onInit", phoenix.core.Bootstrap.onInit)
