(function () {
	const root = document.getElementById("page-quests");
	if (!root) return;

	const state = {
		entries: [],
		selectedId: null,
		filter: "active",
		dialog: null,
		dialogStage: { source: null, revealed: true, npcName: "" },
		lastError: ""
	};

	function esc(value) {
		return String(value == null ? "" : value)
			.replace(/&/g, "&amp;")
			.replace(/</g, "&lt;")
			.replace(/>/g, "&gt;")
			.replace(/"/g, "&quot;")
			.replace(/'/g, "&#039;");
	}

	function statusGroup(entry) {
		if (entry.status === "completed") return "completed";
		if (entry.status === "failed" || entry.status === "cancelled") return "failed";
		return "active";
	}

	function statusLabel(status) {
		if (status === "completed") return "Ukończone";
		if (status === "ready_to_turn_in") return "Gotowe do oddania";
		if (status === "reward_pending") return "Oczekuje na nagrodę";
		if (status === "failed") return "Nieudane";
		if (status === "cancelled") return "Anulowane";
		return "Aktywne";
	}

	function visibleEntries() {
		return state.entries.filter(function (entry) { return statusGroup(entry) === state.filter; });
	}

	function selectedEntry() {
		for (let i = 0; i < state.entries.length; i += 1) {
			if (String(state.entries[i].id) === String(state.selectedId)) return state.entries[i];
		}
		return null;
	}

	function ensureSelection() {
		const entries = visibleEntries();
		if (!selectedEntry() || statusGroup(selectedEntry()) !== state.filter) state.selectedId = entries.length ? entries[0].id : null;
	}

	function renderDialog() {
		const payload = state.dialog && state.dialog.payload ? state.dialog.payload : {};
		const isNode = state.dialog && state.dialog.action === "node";
		if (state.dialogStage.source !== state.dialog) {
			state.dialogStage.source = state.dialog;
			state.dialogStage.revealed = !isNode;
		}
		if (payload.npcName) state.dialogStage.npcName = payload.npcName;
		const npcName = state.dialogStage.npcName || "NPC";
		const showOptions = !isNode || state.dialogStage.revealed;
		const options = isNode ? (Array.isArray(payload.choices) ? payload.choices : []) : (Array.isArray(payload.options) ? payload.options : []);
		const speakerName = isNode && payload.speaker === "player" ? "Ty" : npcName;
		const speechText = isNode ? (payload.text || "") : "Wybierz temat rozmowy.";
		root.innerHTML = '<div class="npc-cinematic-dialog"><button type="button" class="quest-close npc-cinematic-dialog__close" data-action="close" title="ESC" aria-label="Zamknij">✕</button>' +
			'<section class="npc-cinematic-dialog__speech"><span class="npc-cinematic-dialog__name">' + esc(speakerName) + '</span><p>' + esc(speechText) + '</p>' + (isNode && !showOptions ? '<small>Space / LPM</small>' : '') + '</section>' +
			'<section class="npc-cinematic-dialog__options' + (showOptions ? ' is-visible' : '') + '">' + (showOptions ? options.map(function (option) {
				return '<button type="button" class="quest-dialog-option" data-action="dialog-option" data-key="' + esc(option.key) + '"><span>' + esc(isNode ? option.text : option.title) + '</span>' + (isNode ? '' : '<small>' + (option.kind === "start" ? "Rozpocznij zadanie" : option.kind === "teacher" ? "Nauka" : option.kind === "merchant" ? "Handel" : "Kontynuuj zadanie") + '</small>') + '</button>';
			}).join("") : '') + (showOptions && !options.length ? '<div class="quest-dialog-empty">Brak dostępnych odpowiedzi.</div>' : '') + '</section></div>';
	}

	function advanceDialog() {
		if (!state.dialog || state.dialog.action !== "node" || state.dialogStage.revealed) return false;
		state.dialogStage.revealed = true;
		renderDialog();
		return true;
	}

	root.addEventListener("click", function (event) {
		if (!event.target.closest("[data-action]")) advanceDialog();
	}, true);

	document.addEventListener("keydown", function (event) {
		if (event.code !== "Space" && event.key !== " ") return;
		if (advanceDialog()) {
			event.preventDefault();
			event.stopPropagation();
		}
	});

	function renderLog() {
		ensureSelection();
		const entries = visibleEntries();
		const selected = selectedEntry();
		const tabs = [
			{ id: "active", label: "Aktywne" },
			{ id: "completed", label: "Ukończone" },
			{ id: "failed", label: "Nieudane" }
		];
		let detail = '<div class="quest-empty">Wybierz zadanie z listy.</div>';
		if (selected) {
			const objectives = Array.isArray(selected.objectives) ? selected.objectives : [];
			const objectiveRows = objectives.map(function (objective) {
				const complete = objective.completed || objective.progress >= objective.required;
				return '<div class="quest-objective' + (complete ? ' is-complete' : '') + '"><span class="quest-check">' + (complete ? '✓' : '○') + '</span><div class="quest-objective__body"><strong>' + esc(objective.label || objective.key) + '</strong><span class="quest-objective__progress">' + esc(objective.progress) + ' / ' + esc(objective.required) + '</span></div></div>';
			}).join("");
			detail = '<article class="quest-detail">' +
				'<div class="quest-detail__meta"><span class="quest-code">' + esc(selected.code) + '</span><span class="quest-status quest-status--' + esc(statusGroup(selected)) + '">' + esc(statusLabel(selected.status)) + '</span></div>' +
				'<h2>' + esc(selected.title) + '</h2>' +
				'<p class="quest-description">' + esc(selected.description || "Brak dodatkowego opisu zadania.") + '</p>' +
				'<section class="quest-stage"><span>Aktualny etap</span><strong>' + esc(selected.stageTitle || selected.currentStageKey) + '</strong></section>' +
				'<section class="quest-objectives"><h3>Cele zadania</h3>' + (objectiveRows || '<div class="quest-empty quest-empty--objectives">Brak widocznych celów na tym etapie.</div>') + '</section>' +
				(selected.status === "active" ? '<button class="quest-track' + (selected.tracked ? ' is-active' : '') + '" data-action="track" data-id="' + selected.id + '">' + (selected.tracked ? 'Śledzone zadanie' : 'Śledź zadanie') + '</button>' : '') +
				'</article>';
		}
		root.innerHTML = '<div class="quest-shell">' +
			'<header class="quest-head"><div><span class="quest-kicker">DZIENNIK BOHATERA</span><h1>Zadania</h1></div><button class="quest-close" data-action="close">✕</button></header>' +
			'<nav class="quest-tabs">' + tabs.map(function (tab) { return '<button class="quest-tab' + (tab.id === state.filter ? ' is-active' : '') + '" data-action="filter" data-filter="' + tab.id + '">' + tab.label + '</button>'; }).join("") + '</nav>' +
			'<div class="quest-layout"><aside class="quest-list">' + entries.map(function (entry) {
				return '<button class="quest-list-item' + (String(entry.id) === String(state.selectedId) ? ' is-active' : '') + '" data-action="select" data-id="' + entry.id + '"><strong>' + esc(entry.title) + '</strong><small>' + esc(entry.code) + '</small></button>';
			}).join("") + (entries.length ? "" : '<div class="quest-empty quest-empty--list">Brak zadań w tej kategorii.</div>') + '</aside><section class="quest-content">' + detail + '</section></div>' +
			(state.lastError ? '<div class="quest-error">' + esc(state.lastError) + '</div>' : '') +
			'</div>';
	}

	function render() {
		if (state.dialog && (state.dialog.action === "open" || state.dialog.action === "node")) renderDialog();
		else renderLog();
	}


	root.addEventListener("click", function (event) {
		const button = event.target.closest("[data-action]");
		if (!button) return;
		const action = button.dataset.action;
		if (action === "close") {
			if (state.dialog) PhoenixBridge.send("phoenix:quest:request", { action: "dialogClose", payload: { sessionId: state.dialog.sessionId } });
			state.dialog = null;
			PhoenixBridge.send("phoenix:quest:close", {});
			return;
		}
		if (action === "filter") {
			state.filter = button.dataset.filter || "active";
			render();
			return;
		}
		if (action === "select") {
			state.selectedId = button.dataset.id;
			render();
			return;
		}
		if (action === "track") {
			PhoenixBridge.send("phoenix:quest:request", { action: "track", payload: { stateId: Number(button.dataset.id) } });
			return;
		}
		if (action === "dialog-option") {
			PhoenixBridge.send("phoenix:quest:request", { action: "dialogChoose", payload: { sessionId: state.dialog.sessionId, optionKey: button.dataset.key } });
		}
	});

	PhoenixBridge.on("phoenix:quest:snapshot", function (payload) {
		state.entries = payload && Array.isArray(payload.entries) ? payload.entries : [];
		state.lastError = "";
		render();
	});

	PhoenixBridge.on("phoenix:quest:response", function (payload) {
		if (payload && !payload.success) state.lastError = payload.error || "Nie udało się wykonać operacji.";
		else state.lastError = "";
		render();
	});

	PhoenixBridge.on("phoenix:quest:dialog", function (payload) {
		if (!payload || payload.action === "close") state.dialog = null;
		else state.dialog = payload;
		if (payload && payload.payload && (payload.action === "open" || payload.action === "node")) PhoenixBridge.send("phoenix:npc:dialogStage", { speaker: payload.action === "node" ? (payload.payload.speaker || "npc") : "npc" });
		render();
	});

	app.register("quests", {
		onShow: function () { render(); },
		onHide: function () {}
	});
})();