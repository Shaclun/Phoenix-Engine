(function () {
	"use strict";
	const root = document.getElementById("page-crafting");
	if (!root) return;
	const I18n = window.PhoenixI18n;
	const ITEM_RENDER = { rotX: "1.584", rotY: "-1.662", rotZ: "-0.488", scale: "1.35", light: "2.6" };
	const MAX_BATCH = 100;
	let requestSequence = 0;
	let progressTimer = null;
	const state = {
		station: "", recipes: [], items: [], level: 1, stamina: 0, selected: -1,
		filter: "", category: "", quantity: 1, crafting: false,
		requestId: "", progress: null
	};

	function t(key, fallback) {
		if (!I18n || typeof I18n.t !== "function") return fallback || key;
		const value = I18n.t(key);
		return value === key && fallback ? fallback : value;
	}
	function fmt(key, fallback) {
		let value = t(key, fallback);
		for (let i = 2; i < arguments.length; i += 1) value = value.split("{" + (i - 2) + "}").join(String(arguments[i]));
		return value;
	}
	function escapeHtml(value) {
		return String(value == null ? "" : value).replace(/[&<>"']/g, function (c) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
		});
	}
	function itemLabel(instance) {
		if (!instance) return "";
		const translated = I18n && typeof I18n.tItem === "function" ? I18n.tItem(instance, "name", "") : "";
		return translated || instance;
	}
	function itemDescription(instance) {
		return I18n && typeof I18n.tItem === "function" ? (I18n.tItem(instance, "desc", "") || "") : "";
	}
	function selectedRecipe() { return state.recipes.find(function (recipe) { return recipe.id === state.selected; }) || null; }
	function inventoryCounts(instance) {
		const wanted = String(instance || "").toUpperCase();
		let loose = 0, equipped = 0;
		state.items.forEach(function (item) {
			if (!item || String(item.instance || "").toUpperCase() !== wanted) return;
			if (item.equipped) equipped += item.amount | 0;
			else loose += item.amount | 0;
		});
		return { loose: loose, equipped: equipped, all: loose + equipped };
	}
	function requirements(recipe) {
		const consume = {}, tools = {};
		(recipe && recipe.ingredients || []).forEach(function (ing) {
			const instance = String(ing.instance || "").toUpperCase();
			const target = ing.role === "tool" ? tools : consume;
			target[instance] = (target[instance] || 0) + Math.max(1, ing.amount | 0);
		});
		return { consume: consume, tools: tools };
	}
	function maxCraftable(recipe) {
		if (!recipe || state.level < (recipe.requiredLevel | 0)) return 0;
		if ((recipe.professionId | 0) > 0 && (recipe.playerProfessionTier | 0) < (recipe.requiredProfessionTier | 0)) return 0;
		const req = requirements(recipe);
		const instances = {};
		Object.keys(req.consume).forEach(function (key) { instances[key] = true; });
		Object.keys(req.tools).forEach(function (key) { instances[key] = true; });
		let max = MAX_BATCH;
		const staminaUnit = Math.max(0, recipe.effectiveStaminaCost | 0);
		if (staminaUnit > 0) max = Math.min(max, Math.floor(Math.max(0, state.stamina) / staminaUnit));
		Object.keys(instances).forEach(function (instance) {
			const counts = inventoryCounts(instance);
			const toolNeed = req.tools[instance] || 0;
			if (counts.all < toolNeed) { max = 0; return; }
			const reservedLoose = Math.max(0, toolNeed - counts.equipped);
			const perCraft = req.consume[instance] || 0;
			if (perCraft > 0) max = Math.min(max, Math.max(0, Math.floor((counts.loose - reservedLoose) / perCraft)));
		});
		return Math.max(0, max);
	}
	function blockingReasons(recipe, quantity) {
		if (!recipe) return [];
		const reasons = [];
		if (state.level < (recipe.requiredLevel | 0)) reasons.push(fmt("crafting.need.level", "Wymagany poziom: {0}", recipe.requiredLevel));
		if ((recipe.professionId | 0) > 0 && (recipe.playerProfessionTier | 0) < (recipe.requiredProfessionTier | 0))
			reasons.push(fmt("crafting.need.professionTier", "Wymagane {0}: tier {1}", recipe.professionName || recipe.professionCode || t("crafting.profession", "profesja"), recipe.requiredProfessionTier));
		const staminaNeed = Math.max(0, recipe.effectiveStaminaCost | 0) * Math.max(1, quantity | 0);
		if (state.stamina < staminaNeed) reasons.push(fmt("crafting.need.stamina", "Brakuje staminy ({0}/{1})", state.stamina, staminaNeed));
		const req = requirements(recipe);
		const instances = {};
		Object.keys(req.consume).forEach(function (key) { instances[key] = true; });
		Object.keys(req.tools).forEach(function (key) { instances[key] = true; });
		Object.keys(instances).forEach(function (instance) {
			const counts = inventoryCounts(instance);
			const toolNeed = req.tools[instance] || 0;
			if (counts.all < toolNeed) reasons.push(fmt("crafting.need.toolAmount", "Brakuje narzędzia: {0} ({1}/{2})", itemLabel(instance), counts.all, toolNeed));
			const reservedLoose = Math.max(0, toolNeed - counts.equipped);
			const need = (req.consume[instance] || 0) * quantity;
			const available = Math.max(0, counts.loose - reservedLoose);
			if (available < need) reasons.push(fmt("crafting.need.material", "Brakuje {0} ({1}/{2})", itemLabel(instance), available, need));
		});
		return reasons;
	}
	function normalizeQuantity() {
		const max = maxCraftable(selectedRecipe());
		if (max <= 0) state.quantity = 1;
		else state.quantity = Math.max(1, Math.min(max, state.quantity | 0));
	}
	function visualFor(instance) {
		const wanted = String(instance || "").toUpperCase();
		for (let i = 0; i < state.recipes.length; i += 1) {
			const recipe = state.recipes[i];
			if (String(recipe.resultInstance || "").toUpperCase() === wanted && recipe.visual) return recipe.visual;
			const all = (recipe.ingredients || []).concat(recipe.outputs || []);
			for (let j = 0; j < all.length; j += 1) if (String(all[j].instance || "").toUpperCase() === wanted && all[j].visual) return all[j].visual;
		}
		const item = state.items.find(function (entry) { return String(entry.instance || "").toUpperCase() === wanted && entry.visual; });
		return item ? item.visual : "";
	}
	function render3d(instance, width, height, scale, visual) {
		if (!instance) return '<div class="crafting-render__empty">?</div>';
		const model = visual || visualFor(instance) || instance;
		return '<gothic-render width="' + width + '" height="' + height + '" rot-x="' + ITEM_RENDER.rotX + '" rot-y="' + ITEM_RENDER.rotY + '" rot-z="' + ITEM_RENDER.rotZ + '" scale="' + (scale || ITEM_RENDER.scale) + '" light-intensity="' + ITEM_RENDER.light + '" visual="' + escapeHtml(model) + '"></gothic-render>';
	}
	function formatTime(ms) {
		const seconds = Math.max(0, Math.ceil((ms || 0) / 1000));
		if (seconds < 60) return seconds + "s";
		return Math.floor(seconds / 60) + "m " + (seconds % 60) + "s";
	}
	function renderCategories() {
		const categories = {};
		state.recipes.forEach(function (recipe) { categories[recipe.category || "misc"] = true; });
		let html = '<button type="button" class="crafting-cat ' + (!state.category ? "is-active" : "") + '" data-action="cat" data-cat="">' + escapeHtml(t("crafting.cat.all", "Wszystkie")) + '</button>';
		Object.keys(categories).sort().forEach(function (category) {
			html += '<button type="button" class="crafting-cat ' + (state.category === category ? "is-active" : "") + '" data-action="cat" data-cat="' + escapeHtml(category) + '">' + escapeHtml(t("crafting.cat." + category, category)) + '</button>';
		});
		return html;
	}
	function filteredRecipes() {
		const query = String(state.filter || "").toLowerCase();
		return state.recipes.filter(function (recipe) {
			if (state.category && recipe.category !== state.category) return false;
			if (!query) return true;
			return String(recipe.name || "").toLowerCase().indexOf(query) !== -1 || String(recipe.resultInstance || "").toLowerCase().indexOf(query) !== -1 || itemLabel(recipe.resultInstance).toLowerCase().indexOf(query) !== -1;
		});
	}
	function renderList() {
		const recipes = filteredRecipes();
		if (!recipes.length) return '<div class="crafting-empty">' + escapeHtml(t("crafting.empty", "Brak receptur.")) + '</div>';
		return recipes.map(function (recipe) {
			const max = maxCraftable(recipe);
			const selected = state.selected === recipe.id;
			const category = t("crafting.cat." + (recipe.category || "misc"), recipe.category || "misc");
			return '<button type="button" class="crafting-row ' + (selected ? "is-selected " : "") + (max <= 0 ? "is-locked" : "") + '" data-action="select" data-id="' + recipe.id + '" aria-pressed="' + selected + '">' +
				'<span class="crafting-row__visual">' + render3d(recipe.resultInstance, 64, 64, "1.2", recipe.visual) + '</span>' +
				'<span class="crafting-row__text"><strong>' + escapeHtml(recipe.name || itemLabel(recipe.resultInstance)) + '</strong><em>' + escapeHtml(category) + ' · ' + escapeHtml(formatTime(recipe.craftTimeMs)) + '</em></span>' +
				'<span class="crafting-row__state"><b>' + (max > 0 ? max : "—") + '</b><small>' + escapeHtml(t("crafting.maxShort", "MAX")) + '</small></span>' +
			'</button>';
		}).join("");
	}
	function ingredientLine(ing, quantity) {
		const isTool = ing.role === "tool";
		const counts = inventoryCounts(ing.instance);
		const need = Math.max(1, ing.amount | 0) * (isTool ? 1 : quantity);
		const req = requirements(selectedRecipe());
		const reservedLoose = Math.max(0, (req.tools[String(ing.instance || "").toUpperCase()] || 0) - counts.equipped);
		const have = isTool ? counts.all : Math.max(0, counts.loose - reservedLoose);
		const ok = have >= need;
		return '<li class="crafting-ing ' + (isTool ? "is-tool " : "is-consume ") + (ok ? "is-ok" : "is-missing") + '">' +
			'<span class="crafting-ing__visual">' + render3d(ing.instance, 48, 48, "1.0", ing.visual) + '</span>' +
			'<span class="crafting-ing__body"><strong>' + escapeHtml(itemLabel(ing.instance)) + '</strong><em>' + escapeHtml(ing.instance) + '</em></span>' +
			'<span class="crafting-ing__amount">' + have + ' / ' + need + (isTool && counts.equipped > 0 ? '<small>' + escapeHtml(t("crafting.equipped", "założone")) + '</small>' : '') + '</span>' +
		'</li>';
	}
	function progressView(recipe) {
		if (!state.crafting || !state.progress) return "";
		const live = liveProgress();
		const label = state.progress.state === "finalizing" ? t("crafting.finalizing", "Finalizowanie...") : t("crafting.crafting", "Wytwarzanie...");
		return '<div class="crafting-progress" aria-live="polite"><div class="crafting-progress__head"><strong>' + escapeHtml(label) + '</strong><span data-role="progress-time">' + escapeHtml(formatTime(Math.max(0, live.total - live.elapsed))) + '</span></div>' +
			'<div class="crafting-progress__track"><i data-role="progress-bar" style="width:' + live.percent + '%"></i></div>' +
			'<div class="crafting-progress__foot"><span>' + state.quantity + ' × ' + escapeHtml(recipe.name || itemLabel(recipe.resultInstance)) + '</span><button type="button" class="crafting-cancel-btn" data-action="cancel">' + escapeHtml(t("crafting.cancel", "Anuluj")) + '</button></div></div>';
	}
	function renderDetails() {
		const recipe = selectedRecipe();
		if (!recipe) return '<div class="crafting-details crafting-details--empty"><div class="crafting-details__hint">' + escapeHtml(t("crafting.pickHint", "Wybierz recepturę.")) + '</div></div>';
		normalizeQuantity();
		const max = maxCraftable(recipe);
		const reasons = blockingReasons(recipe, state.quantity);
		const consume = (recipe.ingredients || []).filter(function (ing) { return ing.role !== "tool"; });
		const tools = (recipe.ingredients || []).filter(function (ing) { return ing.role === "tool"; });
		const totalTime = (recipe.craftTimeMs | 0) * state.quantity;
		const description = recipe.description || itemDescription(recipe.resultInstance);
		let html = '<div class="crafting-details">';
		html += '<div class="crafting-details__head"><div class="crafting-details__visual">' + render3d(recipe.resultInstance, 128, 128, "1.6", recipe.visual) + '</div><div class="crafting-details__main">';
		html += '<h3>' + escapeHtml(recipe.name || itemLabel(recipe.resultInstance)) + '</h3><div class="crafting-details__meta"><span>' + escapeHtml(t("crafting.cat." + recipe.category, recipe.category)) + '</span><span>' + escapeHtml(formatTime(totalTime)) + '</span>' + (recipe.requiredLevel > 0 ? '<span>' + escapeHtml(t("crafting.meta.level", "Lv")) + ' ' + recipe.requiredLevel + '</span>' : '') + '<span>' + escapeHtml(fmt("crafting.outputAmount", "Wynik: {0}", recipe.resultAmount * state.quantity)) + '</span></div>';
		if ((recipe.professionId | 0) > 0) {
			html += '<div class="crafting-details__meta crafting-details__profession"><span>' + escapeHtml(recipe.professionName || recipe.professionCode) + '</span><span>' + escapeHtml(fmt("crafting.meta.professionLevel", "Poziom {0}", recipe.playerProfessionLevel | 0)) + '</span><span>' + escapeHtml(fmt("crafting.meta.tier", "Tier {0}", recipe.playerProfessionTier | 0)) + ' / ' + (recipe.requiredProfessionTier | 0) + '</span>';
			if ((recipe.professionXp | 0) > 0) html += '<span>+' + ((recipe.professionXp | 0) * state.quantity) + ' XP</span>';
			html += '</div>';
		}
		if ((recipe.effectiveStaminaCost | 0) > 0) html += '<div class="crafting-details__meta"><span>' + escapeHtml(fmt("crafting.meta.stamina", "Stamina: {0}", (recipe.effectiveStaminaCost | 0) * state.quantity)) + '</span></div>';
		if (description) html += '<p class="crafting-details__desc">' + escapeHtml(description) + '</p>';
		html += '</div></div>';
		if ((recipe.outputs || []).length) {
			html += '<section class="crafting-details__section"><h4>' + escapeHtml(t("crafting.extraOutputs", "Dodatkowe produkty")) + '</h4><ul class="crafting-ing-list">';
			html += recipe.outputs.map(function (output) { return '<li class="crafting-ing is-ok"><span class="crafting-ing__visual">' + render3d(output.instance, 48, 48, "1.0", output.visual) + '</span><span class="crafting-ing__body"><strong>' + escapeHtml(itemLabel(output.instance)) + '</strong><em>' + escapeHtml(output.instance) + '</em></span><span class="crafting-ing__amount">×' + ((output.amount | 0) * state.quantity) + '</span></li>'; }).join("");
			html += '</ul></section>';
		}
		html += '<section class="crafting-details__section"><h4>' + escapeHtml(t("crafting.ingredients", "Składniki")) + '</h4><ul class="crafting-ing-list">' + consume.map(function (ing) { return ingredientLine(ing, state.quantity); }).join("") + '</ul></section>';
		if (tools.length) html += '<section class="crafting-details__section"><h4>' + escapeHtml(t("crafting.tools", "Narzędzia")) + '</h4><ul class="crafting-ing-list">' + tools.map(function (ing) { return ingredientLine(ing, state.quantity); }).join("") + '</ul></section>';
		html += progressView(recipe);
		if (!state.crafting) {
			html += '<div class="crafting-batch"><span>' + escapeHtml(t("crafting.quantity", "Ilość")) + '</span><button type="button" data-action="quantity" data-value="-1">−</button><b>' + state.quantity + '</b><button type="button" data-action="quantity" data-value="1">+</button><button type="button" data-action="max">MAX ' + max + '</button></div>';
			html += '<div class="crafting-blockers">' + (reasons.length ? reasons.map(function (reason) { return '<span>' + escapeHtml(reason) + '</span>'; }).join("") : '<span class="is-ready">' + escapeHtml(t("crafting.ready", "Gotowe do wytworzenia")) + '</span>') + '</div>';
			html += '<footer class="crafting-details__foot"><span>' + escapeHtml(fmt("crafting.totalTime", "Łączny czas: {0}", formatTime(totalTime))) + '</span><button type="button" class="crafting-craft-btn" data-action="craft" ' + (reasons.length || max <= 0 ? "disabled" : "") + '>' + escapeHtml(t("crafting.craft", "Wytwórz")) + ' ×' + state.quantity + '</button></footer>';
		}
		return html + '</div>';
	}
	function render() {
		const readyCount = state.recipes.filter(function (recipe) { return maxCraftable(recipe) > 0; }).length;
		root.innerHTML = '<div class="crafting-panel"><header class="crafting-header"><div><span class="crafting-kicker">' + escapeHtml(t("crafting.kicker", "Stół rzemieślniczy")) + '</span><h2>' + escapeHtml(state.station || t("crafting.title", "Warsztat")) + '</h2></div>' +
			'<div class="crafting-summary"><span><b>' + state.recipes.length + '</b>' + escapeHtml(t("crafting.summary.recipes", "receptur")) + '</span><span><b>' + readyCount + '</b>' + escapeHtml(t("crafting.summary.ready", "dostępnych")) + '</span><span><b>' + state.level + '</b>' + escapeHtml(t("crafting.summary.level", "poziom")) + '</span></div>' +
			'<button type="button" class="phoenix-exit-btn" data-action="close" aria-label="' + escapeHtml(t("crafting.close", "Zamknij")) + '">✕</button></header>' +
			'<div class="crafting-toolbar"><div class="crafting-cats">' + renderCategories() + '</div><input class="crafting-filter" type="search" aria-label="' + escapeHtml(t("crafting.search", "Szukaj receptury")) + '" placeholder="' + escapeHtml(t("crafting.search", "Szukaj receptury...")) + '" value="' + escapeHtml(state.filter) + '" data-role="filter"></div>' +
			'<div class="crafting-body"><aside class="crafting-list" data-role="list">' + renderList() + '</aside><section class="crafting-main" data-role="details">' + renderDetails() + '</section></div></div>';
	}
	function nextRequestId() {
		requestSequence += 1;
		return Date.now().toString(36) + "-" + requestSequence.toString(36);
	}
	function liveProgress() {
		if (!state.progress) return { elapsed: 0, total: 1, percent: 0 };
		const total = Math.max(1, state.progress.totalMs | 0);
		let elapsed = state.progress.elapsedMs | 0;
		if (state.progress.state !== "finalizing") elapsed += Math.max(0, Date.now() - state.progress.receivedAt);
		elapsed = Math.min(total, elapsed);
		return { elapsed: elapsed, total: total, percent: Math.max(0, Math.min(100, elapsed / total * 100)) };
	}
	function updateProgressDom() {
		if (!state.crafting || !state.progress) return;
		const live = liveProgress();
		const bar = root.querySelector("[data-role='progress-bar']");
		const time = root.querySelector("[data-role='progress-time']");
		if (bar) bar.style.width = live.percent + "%";
		if (time) time.textContent = formatTime(Math.max(0, live.total - live.elapsed));
	}
	function startProgressTimer() {
		if (progressTimer) clearInterval(progressTimer);
		progressTimer = setInterval(updateProgressDom, 100);
	}
	function stopProgressTimer() {
		if (progressTimer) clearInterval(progressTimer);
		progressTimer = null;
	}
	root.addEventListener("click", function (event) {
		const target = event.target.closest("[data-action]");
		if (!target) return;
		const action = target.dataset.action;
		if (action === "close") { PhoenixBridge.send("phoenix:crafting:close", null); return; }
		if (action === "cat") { state.category = target.dataset.cat || ""; render(); return; }
		if (action === "select") {
			if (state.crafting) return;
			state.selected = parseInt(target.dataset.id, 10) || -1; state.quantity = 1; normalizeQuantity(); render(); return;
		}
		if (action === "quantity") {
			if (state.crafting) return;
			state.quantity += parseInt(target.dataset.value, 10) || 0; normalizeQuantity(); render(); return;
		}
		if (action === "max") { if (!state.crafting) { state.quantity = Math.max(1, maxCraftable(selectedRecipe())); render(); } return; }
		if (action === "craft") {
			const recipe = selectedRecipe();
			if (!recipe || state.crafting || blockingReasons(recipe, state.quantity).length) return;
			state.crafting = true; state.requestId = nextRequestId();
			state.progress = { requestId: state.requestId, recipeId: recipe.id, quantity: state.quantity, elapsedMs: 0, totalMs: recipe.craftTimeMs * state.quantity, state: "crafting", receivedAt: Date.now() };
			PhoenixBridge.send("phoenix:crafting:craft", { recipeId: recipe.id, quantity: state.quantity, requestId: state.requestId });
			startProgressTimer(); render(); return;
		}
		if (action === "cancel") {
			if (!state.crafting) return;
			PhoenixBridge.send("phoenix:crafting:cancel", { requestId: state.requestId });
			target.disabled = true;
		}
	});
	root.addEventListener("input", function (event) {
		if (!event.target || event.target.dataset.role !== "filter") return;
		state.filter = String(event.target.value || "");
		const list = root.querySelector("[data-role='list']");
		if (list) list.innerHTML = renderList();
	});

	function onOpen(payload) {
		state.station = payload.stationName || ""; state.recipes = (payload.recipes || []).slice(); state.items = (payload.items || []).slice();
		state.level = payload.playerLevel || 1; state.stamina = Math.max(0, payload.playerStamina | 0); state.crafting = false; state.requestId = ""; state.progress = null; state.quantity = 1;
		if (!state.recipes.some(function (recipe) { return recipe.id === state.selected; })) state.selected = state.recipes.length ? state.recipes[0].id : -1;
		normalizeQuantity(); stopProgressTimer(); render();
	}
	function onProgress(payload) {
		const incomingId = String(payload && payload.requestId || "");
		const activeId = String(state.requestId || "");
		if (!payload || !state.crafting || (incomingId && activeId && incomingId !== activeId)) return;
		state.progress = {
			requestId: incomingId || activeId, recipeId: payload.recipeId, quantity: payload.quantity,
			elapsedMs: payload.elapsedMs || 0, totalMs: payload.totalMs || 1,
			state: payload.state || "crafting", receivedAt: Date.now()
		};
		if (state.progress.state === "finalizing") {
			render();
			const watchedId = activeId;
			setTimeout(function () {
				if (!state.crafting || String(state.requestId || "") !== watchedId || !state.progress || state.progress.state !== "finalizing") return;
				state.crafting = false; state.requestId = ""; state.progress = null; stopProgressTimer(); render();
				if (window.PhoenixNotify) PhoenixNotify.notify("error", t("crafting.title", "Warsztat"), t("crafting.error.finalizeTimeout", "Serwer nie potwierdził zakończenia. Otwórz warsztat ponownie."), 4000);
			}, 10000);
		} else updateProgressDom();
	}
	function errorText(raw) {
		const value = String(raw || "invalid"); const separator = value.indexOf(":");
		const code = separator >= 0 ? value.slice(0, separator) : value;
		const detail = separator >= 0 ? value.slice(separator + 1) : "";
		let message = t("crafting.error." + code, code);
		if (detail) message += ": " + (code === "missing" || code === "missingTool" ? itemLabel(detail) : detail);
		return message;
	}
	function onResult(payload) {
		const incomingId = String(payload && payload.requestId || "");
		const activeId = String(state.requestId || "");
		if (incomingId && activeId && incomingId !== activeId) return;
		state.crafting = false; state.requestId = ""; state.progress = null; stopProgressTimer();
		if (payload && Array.isArray(payload.items)) state.items = payload.items.slice();
		if (payload && payload.playerStamina != null) state.stamina = Math.max(0, payload.playerStamina | 0);
		if (!payload || !payload.success) {
			if (window.PhoenixNotify) PhoenixNotify.notify("error", t("crafting.title", "Warsztat"), errorText(payload && payload.error), 3000);
		} else if (window.PhoenixNotify) {
			const crafted = payload.resultInstance ? itemLabel(payload.resultInstance) + (payload.resultAmount > 1 ? " ×" + payload.resultAmount : "") : t("crafting.success.generic", "Wytworzono przedmiot");
			PhoenixNotify.notify("success", t("crafting.title", "Warsztat"), crafted, 2500);
		}
		normalizeQuantity(); render();
	}
	function onHide() {
		state.station = ""; state.recipes = []; state.items = []; state.selected = -1; state.crafting = false; state.requestId = ""; state.progress = null;
		stopProgressTimer();
	}
	PhoenixBridge.on("phoenix:crafting:open", onOpen);
	PhoenixBridge.on("phoenix:crafting:progress", onProgress);
	PhoenixBridge.on("phoenix:crafting:result", onResult);
	PhoenixBridge.on("phoenix:crafting:hide", onHide);
	const page = {
		onShow: function () { render(); if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") window.PhoenixHud.setBlocked(true); },
		onHide: function () { stopProgressTimer(); if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") window.PhoenixHud.setBlocked(false); }
	};
	if (window.phoenixApp) window.phoenixApp.register("crafting", page);
})();
