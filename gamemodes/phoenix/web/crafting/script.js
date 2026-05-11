(function () {
	const root = document.getElementById("page-crafting");
	if (!root) return;
	const I18n = window.PhoenixI18n;
	const ITEM_RENDER = { rotX: "1.584", rotY: "-1.662", rotZ: "-0.488", scale: "1.35", light: "2.6" };

	const state = {
		station: "",
		recipes: [],
		items: [],
		level: 1,
		selected: -1,
		crafting: false,
		filter: "",
		category: ""
	};

	function t(key, fallback) {
		if (!I18n || typeof I18n.t !== "function") return fallback || key;
		const value = I18n.t(key);
		return value === key && fallback ? fallback : value;
	}

	function escapeHtml(s) {
		return String(s || "").replace(/[&<>"']/g, function (c) {
			return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
		});
	}

	function itemLabel(instance) {
		if (!instance) return "";
		if (I18n && typeof I18n.tItem === "function") {
			const translated = I18n.tItem(instance, "name", "");
			if (translated) return translated;
		}
		return instance;
	}

	function itemDescription(instance) {
		if (!instance) return "";
		if (I18n && typeof I18n.tItem === "function") {
			return I18n.tItem(instance, "desc", "") || "";
		}
		return "";
	}

	function countInInventory(instance) {
		let total = 0;
		const wanted = String(instance || "").toUpperCase();
		state.items.forEach(function (it) {
			if (!it || it.equipped) return;
			if ((it.instance || "").toUpperCase() === wanted) total += it.amount | 0;
		});
		return total;
	}

	function hasTool(instance) {
		const wanted = String(instance || "").toUpperCase();
		for (let i = 0; i < state.items.length; i += 1) {
			const it = state.items[i];
			if (!it) continue;
			if ((it.instance || "").toUpperCase() === wanted) return true;
		}
		return false;
	}

	function canCraft(recipe) {
		if (!recipe) return false;
		if (state.level < (recipe.requiredLevel | 0)) return false;
		for (let i = 0; i < recipe.ingredients.length; i += 1) {
			const ing = recipe.ingredients[i];
			if (ing.role === "tool") {
				if (!hasTool(ing.instance)) return false;
			} else {
				if (countInInventory(ing.instance) < (ing.amount | 0)) return false;
			}
		}
		return true;
	}

	function missingReason(recipe) {
		if (!recipe) return "";
		if (state.level < (recipe.requiredLevel | 0)) {
			return t("crafting.need.level", "Wymagany poziom: {0}").replace("{0}", recipe.requiredLevel);
		}
		for (let i = 0; i < recipe.ingredients.length; i += 1) {
			const ing = recipe.ingredients[i];
			if (ing.role === "tool") {
				if (!hasTool(ing.instance)) return t("crafting.need.tool", "Brakuje narzędzia: {0}").replace("{0}", itemLabel(ing.instance));
			} else {
				const have = countInInventory(ing.instance);
				if (have < (ing.amount | 0)) {
					return t("crafting.need.material", "Brakuje {0} ({1}/{2})")
						.replace("{0}", itemLabel(ing.instance))
						.replace("{1}", have)
						.replace("{2}", ing.amount);
				}
			}
		}
		return "";
	}

	function visualFor(instance) {
		if (!instance) return "";
		// Try from recipes cache
		for (let i = 0; i < state.recipes.length; i += 1) {
			const r = state.recipes[i];
			if (r.resultInstance === instance && r.visual) return r.visual;
			for (let j = 0; j < r.ingredients.length; j += 1) {
				const ing = r.ingredients[j];
				if (ing.instance === instance && ing.visual) return ing.visual;
			}
		}
		// Try from items cache
		for (let k = 0; k < state.items.length; k += 1) {
			if (state.items[k].instance === instance && state.items[k].visual) return state.items[k].visual;
		}
		return "";
	}

	function renderRender3d(instance, width, height, scale, visual) {
		if (!instance) return '<div class="crafting-render__empty">?</div>';
		const v = visual || visualFor(instance) || instance;
		return '<gothic-render width="' + width + '" height="' + height + '" rot-x="' + ITEM_RENDER.rotX +
			'" rot-y="' + ITEM_RENDER.rotY + '" rot-z="' + ITEM_RENDER.rotZ + '" scale="' + (scale || ITEM_RENDER.scale) +
			'" light-intensity="' + ITEM_RENDER.light + '" visual="' + escapeHtml(v) + '"></gothic-render>';
	}

	function findSchemeVisual(instance) {
		return visualFor(instance);
	}

	function renderCategories() {
		const set = {};
		state.recipes.forEach(function (r) { set[r.category || "misc"] = true; });
		const cats = Object.keys(set);
		if (cats.length === 0) return "";
		let html = '<button type="button" class="crafting-cat ' + (state.category === "" ? "is-active" : "") + '" data-action="cat" data-cat="">' + t("crafting.cat.all", "Wszystkie") + '</button>';
		cats.forEach(function (c) {
			const isActive = state.category === c;
			html += '<button type="button" class="crafting-cat ' + (isActive ? "is-active" : "") + '" data-action="cat" data-cat="' + escapeHtml(c) + '">' + escapeHtml(t("crafting.cat." + c, c)) + '</button>';
		});
		return html;
	}

	function filteredRecipes() {
		const q = (state.filter || "").toLowerCase();
		return state.recipes.filter(function (r) {
			if (state.category && r.category !== state.category) return false;
			if (!q) return true;
			if (String(r.name || "").toLowerCase().indexOf(q) !== -1) return true;
			if (String(r.resultInstance || "").toLowerCase().indexOf(q) !== -1) return true;
			return false;
		});
	}

	function renderList() {
		const recipes = filteredRecipes();
		if (recipes.length === 0) {
			return '<div class="crafting-empty">' + t("crafting.empty", "Brak receptur.") + '</div>';
		}
		return recipes.map(function (r) {
			const locked = !canCraft(r);
			const displayName = r.name || itemLabel(r.resultInstance);
			const isSelected = state.selected === r.id;
			return '<button type="button" class="crafting-row ' + (isSelected ? "is-selected" : "") + ' ' + (locked ? "is-locked" : "") + '" data-action="select" data-id="' + r.id + '">' +
				'<span class="crafting-row__visual">' + renderRender3d(r.resultInstance, 64, 64, "1.2", r.visual) + '</span>' +
				'<span class="crafting-row__text">' +
					'<strong>' + escapeHtml(displayName) + '</strong>' +
					'<em>' + (r.resultAmount > 1 ? "x" + r.resultAmount + " · " : "") + escapeHtml(r.category) + '</em>' +
				'</span>' +
				(locked ? '<span class="crafting-row__lock">🔒</span>' : '<span class="crafting-row__ok">✓</span>') +
			'</button>';
		}).join("");
	}

	function renderIngredientLine(ing) {
		const isTool = ing.role === "tool";
		const have = countInInventory(ing.instance);
		const need = ing.amount | 0;
		const label = itemLabel(ing.instance);
		const ok = isTool ? hasTool(ing.instance) : have >= need;
		const countText = isTool ? t("crafting.toolFlag", "narzędzie") : have + " / " + need;
		return '<li class="crafting-ing ' + (isTool ? "is-tool" : "is-consume") + ' ' + (ok ? "is-ok" : "is-missing") + '">' +
			'<span class="crafting-ing__visual">' + renderRender3d(ing.instance, 48, 48, "1.0", ing.visual) + '</span>' +
			'<span class="crafting-ing__body">' +
				'<strong>' + escapeHtml(label) + '</strong>' +
				'<em>' + escapeHtml(ing.instance) + '</em>' +
			'</span>' +
			'<span class="crafting-ing__amount">' + escapeHtml(countText) + '</span>' +
		'</li>';
	}

	function renderDetails() {
		const selected = state.recipes.filter(function (r) { return r.id === state.selected; })[0];
		if (!selected) {
			return '<div class="crafting-details crafting-details--empty">' +
				'<div class="crafting-details__hint">' + t("crafting.pickHint", "Wybierz recepturę z listy po lewej stronie.") + '</div>' +
			'</div>';
		}
		const displayName = selected.name || itemLabel(selected.resultInstance);
		const canDo = canCraft(selected) && !state.crafting;
		const missing = missingReason(selected);
		const toolIngs = selected.ingredients.filter(function (i) { return i.role === "tool"; });
		const consumeIngs = selected.ingredients.filter(function (i) { return i.role !== "tool"; });
		const extraOutputs = selected.outputs || [];
		return '<div class="crafting-details">' +
			'<div class="crafting-details__head">' +
				'<div class="crafting-details__visual">' + renderRender3d(selected.resultInstance, 128, 128, "1.6", selected.visual) + '</div>' +
				'<div class="crafting-details__main">' +
					'<h3>' + escapeHtml(displayName) + '</h3>' +
					'<div class="crafting-details__meta">' +
						'<span>' + escapeHtml(selected.resultInstance) + '</span>' +
						(selected.resultAmount > 1 ? '<span>x' + selected.resultAmount + '</span>' : '') +
						(selected.requiredLevel > 0 ? '<span>' + t("crafting.meta.level", "Lv") + ' ' + selected.requiredLevel + '</span>' : '') +
					'</div>' +
					(selected.description ? '<p class="crafting-details__desc">' + escapeHtml(selected.description) + '</p>' :
						(itemDescription(selected.resultInstance) ? '<p class="crafting-details__desc">' + escapeHtml(itemDescription(selected.resultInstance)) + '</p>' : '')) +
				'</div>' +
			'</div>' +
			(extraOutputs.length > 0 ?
				'<section class="crafting-details__section">' +
					'<h4>' + t("crafting.extraOutputs", "Dodatkowe produkty") + '</h4>' +
					'<ul class="crafting-ing-list">' + extraOutputs.map(function (o) {
						const label = itemLabel(o.instance);
						return '<li class="crafting-ing is-ok">' +
							'<span class="crafting-ing__visual">' + renderRender3d(o.instance, 48, 48, "1.0", o.visual) + '</span>' +
							'<span class="crafting-ing__body">' +
								'<strong>' + escapeHtml(label) + '</strong>' +
								'<em>' + escapeHtml(o.instance) + '</em>' +
							'</span>' +
							'<span class="crafting-ing__amount">x' + (o.amount | 0) + '</span>' +
						'</li>';
					}).join("") + '</ul>' +
				'</section>'
			: '') +
			'<section class="crafting-details__section">' +
				'<h4>' + t("crafting.ingredients", "Składniki") + '</h4>' +
				'<ul class="crafting-ing-list">' + consumeIngs.map(renderIngredientLine).join("") + '</ul>' +
			'</section>' +
			(toolIngs.length > 0 ?
				'<section class="crafting-details__section">' +
					'<h4>' + t("crafting.tools", "Wymagane narzędzia") + '</h4>' +
					'<ul class="crafting-ing-list">' + toolIngs.map(renderIngredientLine).join("") + '</ul>' +
				'</section>'
			: '') +
			'<footer class="crafting-details__foot">' +
				(missing ? '<span class="crafting-details__warn">' + escapeHtml(missing) + '</span>' : '<span></span>') +
				'<button type="button" class="crafting-craft-btn" data-action="craft" ' + (canDo ? "" : "disabled") + '>' +
					(state.crafting ? t("crafting.crafting", "Wytwarzanie...") : t("crafting.craft", "Wytwórz")) +
				'</button>' +
			'</footer>' +
		'</div>';
	}

	function render() {
		root.innerHTML = '' +
			'<div class="crafting-panel">' +
				'<header class="crafting-header">' +
					'<div>' +
						'<span class="crafting-kicker" data-t="crafting.kicker">Stół rzemieślniczy</span>' +
						'<h2>' + escapeHtml(state.station || t("crafting.title", "Warsztat")) + '</h2>' +
					'</div>' +
					'<button type="button" class="phoenix-exit-btn" data-action="close" aria-label="ESC">✕</button>' +
				'</header>' +
				'<div class="crafting-toolbar">' +
					'<div class="crafting-cats">' + renderCategories() + '</div>' +
					'<input class="crafting-filter" type="text" placeholder="' + escapeHtml(t("crafting.search", "Szukaj receptury...")) + '" value="' + escapeHtml(state.filter) + '" data-role="filter" />' +
				'</div>' +
				'<div class="crafting-body">' +
					'<aside class="crafting-list" data-role="list">' + renderList() + '</aside>' +
					'<section class="crafting-main" data-role="details">' + renderDetails() + '</section>' +
				'</div>' +
			'</div>';
	}

	root.addEventListener("click", function (ev) {
		const target = ev.target.closest("[data-action]");
		if (!target) return;
		const action = target.dataset.action;
		if (action === "close") { PhoenixBridge.send("phoenix:crafting:close", null); return; }
		if (action === "cat") { state.category = target.dataset.cat || ""; render(); return; }
		if (action === "select") {
			const id = parseInt(target.dataset.id, 10) || 0;
			state.selected = id;
			render();
			return;
		}
		if (action === "craft") {
			if (state.selected <= 0 || state.crafting) return;
			state.crafting = true;
			PhoenixBridge.send("phoenix:crafting:craft", { recipeId: state.selected });
			render();
			return;
		}
	});

	root.addEventListener("input", function (ev) {
		if (ev.target && ev.target.dataset && ev.target.dataset.role === "filter") {
			state.filter = String(ev.target.value || "");
			const list = root.querySelector("[data-role='list']");
			if (list) list.innerHTML = renderList();
		}
	});

	function onOpen(payload) {
		state.station = payload.stationName || "";
		state.recipes = (payload.recipes || []).slice();
		state.items = (payload.items || []).slice();
		state.level = payload.playerLevel || 1;
		state.crafting = false;
		if (state.recipes.length > 0 && state.selected <= 0) state.selected = state.recipes[0].id;
		render();
	}

	function onResult(payload) {
		state.crafting = false;
		if (payload && Array.isArray(payload.items)) state.items = payload.items.slice();
		if (!payload || !payload.success) {
			if (payload && payload.error && window.PhoenixNotify) {
				const msg = t("crafting.error." + payload.error, payload.error || "błąd");
				PhoenixNotify.notify("error", t("crafting.title", "Warsztat"), msg, 2500);
			}
		} else if (window.PhoenixNotify && payload.resultInstance) {
			const label = itemLabel(payload.resultInstance) || payload.resultInstance;
			const txt = label + (payload.resultAmount > 1 ? " x" + payload.resultAmount : "");
			PhoenixNotify.notify("success", t("crafting.title", "Warsztat"), txt, 2500);
		}
		render();
	}

	function onHide() {
		state.station = "";
		state.recipes = [];
		state.items = [];
		state.selected = -1;
		state.crafting = false;
	}

	PhoenixBridge.on("phoenix:crafting:open", onOpen);
	PhoenixBridge.on("phoenix:crafting:result", onResult);
	PhoenixBridge.on("phoenix:crafting:hide", onHide);

	const page = {
		onShow: function () {
			render();
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") window.PhoenixHud.setBlocked(true);
		},
		onHide: function () {
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") window.PhoenixHud.setBlocked(false);
		}
	};
	if (window.phoenixApp) window.phoenixApp.register("crafting", page);
})();
