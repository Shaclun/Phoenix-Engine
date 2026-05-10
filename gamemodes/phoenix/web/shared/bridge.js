(function (global) {
	const listeners = {};

	function on(name, handler) {
		if (!listeners[name]) listeners[name] = [];
		listeners[name].push(handler);
	}

	function off(name, handler) {
		if (!listeners[name]) return;
		listeners[name] = listeners[name].filter(function (h) { return h !== handler; });
	}

	function emit(name, payload) {
		if (!listeners[name]) return;
		listeners[name].forEach(function (h) {
			try { h(payload); } catch (err) {}
		});
	}

	function send(channel, payload) {
		const data = { channel: channel, payload: payload };
		const json = JSON.stringify(data);
		if (global.squirrel && typeof global.squirrel.call === "function") {
			global.squirrel.call("phoenixWebSend", json);
		} else if (global.G2O && typeof global.G2O.sendMessage === "function") {
			global.G2O.sendMessage(json);
		} else if (typeof global.external !== "undefined" && typeof global.external.invoke === "function") {
			global.external.invoke(json);
		}
	}

	global.PhoenixBridge = {
		on: on,
		off: off,
		emit: emit,
		send: send
	};

	const storageWaiters = {};
	const storageCache = {};

	on("phoenix:storage:value", function (payload) {
		if (!payload || typeof payload.key !== "string") return;
		storageCache[payload.key] = payload.value;
		const list = storageWaiters[payload.key] || [];
		delete storageWaiters[payload.key];
		list.forEach(function (cb) { try { cb(payload.value); } catch (e) {} });
	});

	function storageGet(key, cb) {
		if (typeof cb !== "function") return;
		if (Object.prototype.hasOwnProperty.call(storageCache, key)) {
			cb(storageCache[key]);
			return;
		}
		if (!storageWaiters[key]) storageWaiters[key] = [];
		storageWaiters[key].push(cb);
		send("phoenix:storage:get", { key: key });
	}

	function storageSet(key, value) {
		storageCache[key] = value;
		send("phoenix:storage:set", { key: key, value: value });
	}

	global.PhoenixStorage = {
		get: storageGet,
		set: storageSet
	};
})(window);
