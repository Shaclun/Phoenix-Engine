(function () {
	const root = document.getElementById("page-character");

	const listTpl = `
		<div class="char-select">
			<button type="button" class="phoenix-exit-btn" data-action="exit" title="" data-t-title="app.exit" aria-label="exit">×</button>
			<aside class="char-details char-details--hidden" data-role="details"></aside>
			<aside class="char-list">
				<header class="char-list__head">
					<h1 class="char-list__title" data-t="character.list.title">Wybór bohatera</h1>
					<p class="char-list__subtitle" data-t="character.list.subtitle">Wybierz postać lub stwórz nową</p>
				</header>
				<div class="char-list__cards" data-role="list"></div>
				<div class="char-list__error" data-role="error"></div>
				<div class="char-list__actions">
					<button type="button" class="char-button char-button--ghost" data-action="create" data-t="character.list.create">Nowa postać</button>
					<button type="button" class="char-button char-button--ghost" data-action="delete" disabled data-t="character.list.delete">Usuń</button>
				</div>
			</aside>
			<footer class="char-play char-play--hidden" data-role="playbar">
				<p class="char-play__name" data-role="playname">-</p>
				<button type="button" class="char-button char-button--primary" data-action="enter" disabled data-t="character.list.enter">Wejdź do gry</button>
			</footer>
		</div>
	`;

	const createTpl = `
		<div class="create-ui">
			<section class="create-ui__main">
				<div class="create-ui__section">
					<label class="create-ui__label" data-t="character.create.name">Nazwa postaci</label>
					<input type="text" class="create-ui__input" id="char-name" maxlength="20" data-t-placeholder="character.create.namePlaceholder" placeholder="Wprowadź nazwę..." />
					<p class="create-ui__status" data-role="status"></p>
				</div>

				<div class="create-ui__section">
					<h2 class="create-ui__subtitle" data-t="character.create.section.personalization">Personalizacja</h2>
					${optionRow("gender", "character.create.opt.gender")}
					${optionRow("race", "character.create.opt.race")}
					${optionRow("head", "character.create.opt.head")}
					${optionRow("face", "character.create.opt.face")}
					${optionRow("fatness", "character.create.opt.fatness")}
					${optionRow("walking", "character.create.opt.walking")}
				</div>

				<div class="create-ui__section">
					<h2 class="create-ui__subtitle" data-t="character.create.section.equipment">Ekwipunek</h2>
					${optionRow("weapon", "character.create.opt.weapon")}
					${optionRow("ranged", "character.create.opt.ranged")}
					${optionRow("outfit", "character.create.opt.outfit")}
				</div>

				<div class="create-ui__section">
					<h2 class="create-ui__subtitle" data-t="character.create.section.scenario">Scenariusz</h2>
					${optionRow("scenario", "character.create.opt.scenario")}
				</div>
			</section>

			<aside class="create-ui__item-panels" data-role="item-panels"></aside>

			<footer class="create-ui__footer">
				<div class="char-rotate char-rotate--create" data-role="rotate-controls">
					<button type="button" class="char-rotate__btn" data-rotate="-1">&#10226;</button>
					<button type="button" class="char-rotate__btn" data-rotate="1">&#10227;</button>
				</div>
				<button class="char-button char-button--ghost" data-button="back" data-t="character.create.back">Wróć</button>
				<button class="char-button char-button--primary" data-button="create" data-t="character.create.submit">Stwórz postać</button>
			</footer>
		</div>
	`;

	function optionRow(key, labelKey) {
		return `
			<div class="option-row" data-option="${key}">
				<button class="option-row__arrow" data-dir="-1" aria-label="prev">&#10094;</button>
				<div class="option-row__content">
					<span class="option-row__label" data-t="${labelKey}">—</span>
					<span class="option-row__value" data-value="${key}">—</span>
					<button type="button" class="option-row__info" data-info="${key}" aria-label="info">i</button>
				</div>
				<button class="option-row__arrow" data-dir="1" aria-label="next">&#10095;</button>
			</div>
		`;
	}

	let mode = "list";
	let characters = [];
	let selectedId = null;
	let optionState = { gender: 0, weapon: 0, ranged: 0, outfit: 0 };
	// Cache of the latest visuals advertised by the server for each equipment slot.
	// Used by `itemPanelHtml` so the right-side detail panels can render the actual mesh.
	let optionVisuals = { weapon: "", ranged: "", outfit: "" };
	let optionInstances = { weapon: "", ranged: "", outfit: "" };
	const MAX_SLOTS = 4;
	const LAST_SLOT_KEY = "phoenix:character:lastSlot";
	const LAST_ID_KEY = "phoenix:character:lastCharacterId";

	const starterCatalog = {
		weapon: [
			{ nameKey: "character.create.item.ITMW_1H_BAU_AXE.name", descriptionKey: "character.create.item.ITMW_1H_BAU_AXE.desc", modelKey: "character.create.item.model.1h", statKeys: ["character.create.item.ITMW_1H_BAU_AXE.stat.0", "character.create.item.ITMW_1H_BAU_AXE.stat.1", "character.create.item.ITMW_1H_BAU_AXE.stat.2"] },
			{ nameKey: "character.create.item.ITMW_2H_AXE_L_01.name", descriptionKey: "character.create.item.ITMW_2H_AXE_L_01.desc", modelKey: "character.create.item.model.2h", statKeys: ["character.create.item.ITMW_2H_AXE_L_01.stat.0", "character.create.item.ITMW_2H_AXE_L_01.stat.1", "character.create.item.ITMW_2H_AXE_L_01.stat.2"] }
		],
		ranged: [
			{ nameKey: "character.create.item.ITRW_BOW_L_01.name", descriptionKey: "character.create.item.ITRW_BOW_L_01.desc", modelKey: "character.create.item.model.bow", statKeys: ["character.create.item.ITRW_BOW_L_01.stat.0", "character.create.item.ITRW_BOW_L_01.stat.1", "character.create.item.ITRW_BOW_L_01.stat.2"] },
			{ nameKey: "character.create.item.ITRW_CROSSBOW_L_01.name", descriptionKey: "character.create.item.ITRW_CROSSBOW_L_01.desc", modelKey: "character.create.item.model.crossbow", statKeys: ["character.create.item.ITRW_CROSSBOW_L_01.stat.0", "character.create.item.ITRW_CROSSBOW_L_01.stat.1", "character.create.item.ITRW_CROSSBOW_L_01.stat.2"] }
		],
		outfit: [
			{ nameKey: "character.create.item.ITAR_BAU_L.name", descriptionKey: "character.create.item.ITAR_BAU_L.desc", modelKey: "character.create.item.model.outfit", statKeys: ["character.create.item.ITAR_BAU_L.stat.0", "character.create.item.ITAR_BAU_L.stat.1"] },
			{ nameKey: "character.create.item.ITAR_VLK_M.name", descriptionKey: "character.create.item.ITAR_VLK_M.desc", modelKey: "character.create.item.model.outfit", statKeys: ["character.create.item.ITAR_VLK_M.stat.0", "character.create.item.ITAR_VLK_M.stat.1"] },
			{ nameKey: "character.create.item.ITAR_LEATHER_L.name", descriptionKey: "character.create.item.ITAR_LEATHER_L.desc", modelKey: "character.create.item.model.armor", statKeys: ["character.create.item.ITAR_LEATHER_L.stat.0", "character.create.item.ITAR_LEATHER_L.stat.1", "character.create.item.ITAR_LEATHER_L.stat.2"] }
		]
	};

	function escapeHtml(value) {
		return String(value)
			.replace(/&/g, "&amp;")
			.replace(/</g, "&lt;")
			.replace(/>/g, "&gt;")
			.replace(/"/g, "&quot;");
	}

	function setError(text) {
		root.querySelectorAll('[data-role="error"]').forEach(function (n) { n.textContent = text || ""; });
	}

	function setStatus(text) {
		const el = root.querySelector('[data-role="status"]');
		if (el) el.textContent = text || "";
	}

	function tr(key, fallback) {
		if (window.PhoenixI18n) {
			const value = PhoenixI18n.t(key);
			if (value && value !== key) return value;
		}
		return fallback || key;
	}

	function formatDuration(seconds) {
		let total = Math.max(0, parseInt(seconds || 0, 10) || 0);
		const hours = Math.floor(total / 3600);
		total %= 3600;
		const minutes = Math.floor(total / 60);
		if (hours > 0) return hours + "h " + minutes + "m";
		return minutes + "m";
	}

	function formatDate(timestamp) {
		const value = parseInt(timestamp || 0, 10) || 0;
		if (value <= 0) return tr("character.list.never", "Nigdy");
		try { return new Date(value * 1000).toLocaleString(window.PhoenixI18n ? PhoenixI18n.getLang() : undefined); } catch (e) { return "-"; }
	}

	function statusLabel(value) {
		return parseInt(value || 1, 10) === 2 ? tr("character.list.status.blocked", "Zablokowana") : tr("character.list.status.active", "Aktywna");
	}

	function selectedCharacter() {
		if (selectedId == null) return null;
		return characters.find(function (c) { return c.id === selectedId; }) || null;
	}

	function readStoredSelection() {
		let slot = -1;
		let id = null;
		try { slot = parseInt(localStorage.getItem(LAST_SLOT_KEY) || "-1", 10); } catch (e) { slot = -1; }
		try { id = parseInt(localStorage.getItem(LAST_ID_KEY) || "0", 10) || null; } catch (e2) { id = null; }
		return { slot: slot, id: id };
	}

	function storeSelection(id) {
		const slot = characters.findIndex(function (c) { return c.id === id; });
		try { if (slot >= 0) localStorage.setItem(LAST_SLOT_KEY, String(slot)); } catch (e) {}
		try { localStorage.setItem(LAST_ID_KEY, String(id)); } catch (e2) {}
	}

	function focusSelectedPreview() {
		if (selectedId == null) return;
		PhoenixBridge.send("phoenix:character:list:focus", { characterId: selectedId });
	}

	function applyStoredSelection() {
		if (!characters.length) { selectedId = null; return; }
		if (selectedId != null && characters.some(function (c) { return c.id === selectedId; })) return;
		const stored = readStoredSelection();
		if (stored.slot >= 0 && stored.slot < characters.length && characters[stored.slot]) {
			selectedId = characters[stored.slot].id;
			return;
		}
		if (stored.id && characters.some(function (c) { return c.id === stored.id; })) {
			selectedId = stored.id;
			return;
		}
		selectedId = characters[0].id;
	}

	function renderDetails() {
		const details = root.querySelector('[data-role="details"]');
		const playbar = root.querySelector('[data-role="playbar"]');
		const playname = root.querySelector('[data-role="playname"]');
		const c = selectedCharacter();
		if (!details || !playbar) return;
		if (!c) {
			details.classList.add("char-details--hidden");
			playbar.classList.add("char-play--hidden");
			return;
		}
		details.classList.remove("char-details--hidden");
		playbar.classList.remove("char-play--hidden");
		if (playname) playname.textContent = c.name || "-";
		details.innerHTML = `
			<p class="char-details__eyebrow" data-t="character.list.details">Szczegóły</p>
			<div class="char-details__name">${escapeHtml(c.name || "-")}</div>
			<div class="char-details__rows">
				<div class="char-details__row"><span>LV</span><span>${c.level || 1}</span></div>
				<div class="char-details__row"><span data-t="character.create.opt.gender">Płeć</span><span>${genderLabel(c.gender)}</span></div>
				<div class="char-details__row"><span data-t="character.list.playTime">Czas gry</span><span>${escapeHtml(formatDuration(c.playTimeSec))}</span></div>
				<div class="char-details__row"><span data-t="character.list.lastPlayed">Ostatnio grana</span><span>${escapeHtml(formatDate(c.lastPlayedAt))}</span></div>
				<div class="char-details__row"><span data-t="character.list.status">Status</span><span>${escapeHtml(statusLabel(c.status))}</span></div>
				<div class="char-details__row"><span data-t="character.list.createdAt">Utworzona</span><span>${escapeHtml(formatDate(c.createdAt))}</span></div>
			</div>
		`;
		if (window.PhoenixI18n) PhoenixI18n.applyDom(details);
	}

	function detailFor(key) {
		const list = starterCatalog[key];
		if (!list) return null;
		const idx = optionState[key] || 0;
		return list[idx] || list[0] || null;
	}

    function itemPanelHtml(key) {
        const detail = detailFor(key);
        if (!detail) return "";
        const labels = {
            weapon: "character.create.opt.weapon",
            ranged: "character.create.opt.ranged",
            outfit: "character.create.opt.outfit"
        };
        const visual = optionVisuals[key] || "";
        const meshHtml = visual
            ? '<gothic-render width="320" height="160" rot-x="1.584" rot-y="-1.662" rot-z="-0.488" scale="1.4" light-intensity="2.85" visual="' + escapeHtml(visual) + '"></gothic-render>'
            : escapeHtml(tr(detail.modelKey, ""));
        return `
            <div class="char-item-panel" data-panel="${key}">
                <div class="char-item-panel__model">${meshHtml}</div>
                <div class="char-item-panel__meta" data-t="${labels[key] || ""}"></div>
                <div class="char-item-panel__name">${escapeHtml(tr(detail.nameKey, ""))}</div>
                <div class="char-item-panel__desc">${escapeHtml(tr(detail.descriptionKey, ""))}</div>
                <div class="char-item-panel__stats">${detail.statKeys.map(function (s) { return `<span>${escapeHtml(tr(s, ""))}</span>`; }).join("")}</div>
            </div>
        `;
    }

	function renderItemPanels() {
		const panels = root.querySelector('[data-role="item-panels"]');
		if (!panels) return;
		panels.innerHTML = ["weapon", "ranged", "outfit"].map(itemPanelHtml).join("");
		if (window.PhoenixI18n) PhoenixI18n.applyDom(panels);
	}

	function focusItemPanel(key) {
		const panel = root.querySelector('[data-panel="' + key + '"]');
		if (!panel) return;
		panel.classList.remove("is-pulsing");
		void panel.offsetWidth;
		panel.classList.add("is-pulsing");
	}

	function render() {
		document.body.classList.toggle("phoenix-body--cinematic", mode === "create");
		if (mode === "create") {
			renderCreate();
		} else {
			renderList();
		}
	}

	function renderList() {
		root.innerHTML = listTpl;
		if (window.PhoenixI18n) PhoenixI18n.applyDom(root);
		if (window.app && window.app.renderLangSwitcher) window.app.renderLangSwitcher();

		const list = root.querySelector('[data-role="list"]');
		if (characters.length === 0) {
			list.innerHTML = Array.from({ length: MAX_SLOTS }).map(function () {
				return `<button class="char-card char-card--empty" disabled><span class="char-list__empty" data-t="character.list.emptySlot">Pusty slot</span></button>`;
			}).join("");
			if (window.PhoenixI18n) PhoenixI18n.applyDom(list);
		} else {
			const slots = [];
			for (let i = 0; i < MAX_SLOTS; i += 1) slots.push(characters[i] || null);
			list.innerHTML = slots.map(function (c) {
				if (!c) return `<button class="char-card char-card--empty" disabled><span class="char-list__empty" data-t="character.list.emptySlot">Pusty slot</span></button>`;
				const sel = c.id === selectedId ? " is-selected" : "";
				return `
					<button class="char-card${sel}" data-id="${c.id}">
						<div class="char-card__top">
							<div class="char-card__name">${escapeHtml(c.name)}</div>
							<div class="char-card__level">${c.level || 1}</div>
						</div>
						<div class="char-card__meta">${genderLabel(c.gender)}</div>
						<div class="char-card__stats"><span>${escapeHtml(formatDuration(c.playTimeSec))}</span><span>${escapeHtml(statusLabel(c.status))}</span></div>
					</button>
				`;
			}).join("");
			if (window.PhoenixI18n) PhoenixI18n.applyDom(list);
		}

		root.querySelectorAll(".char-card").forEach(function (n) {
			n.addEventListener("click", function () {
				selectedId = parseInt(n.dataset.id, 10);
				storeSelection(selectedId);
				PhoenixBridge.send("phoenix:character:list:focus", { characterId: selectedId });
				renderList();
			});
		});

		root.querySelector('[data-action="create"]').addEventListener("click", function () {
			if (characters.length >= MAX_SLOTS) { setError(tr("phoenix.character.error.noSlots", "Limit postaci na koncie został osiągnięty")); return; }
			mode = "create";
			render();
			PhoenixBridge.send("phoenix:character:create:start", {});
		});
		root.querySelector('[data-action="enter"]').addEventListener("click", function () {
			if (selectedId == null) return;
			storeSelection(selectedId);
			PhoenixBridge.send("phoenix:character:select", { characterId: selectedId });
		});
		root.querySelector('[data-action="delete"]').addEventListener("click", function () {
			if (selectedId == null) return;
			PhoenixBridge.send("phoenix:character:delete", { characterId: selectedId });
		});

		const exitBtn = root.querySelector('[data-action="exit"]');
		if (exitBtn) exitBtn.addEventListener("click", function () { PhoenixBridge.send("phoenix:app:exit", {}); });

		updateActions();
		renderDetails();
	}

	function updateActions() {
		const enter = root.querySelector('[data-action="enter"]');
		const del = root.querySelector('[data-action="delete"]');
		const has = selectedId != null && characters.some(function (c) { return c.id === selectedId; });
		const selected = selectedCharacter();
		if (enter) enter.disabled = !has || (selected && parseInt(selected.status || 1, 10) === 2);
		if (del) del.disabled = !has;
		const create = root.querySelector('[data-action="create"]');
		if (create) create.disabled = characters.length >= MAX_SLOTS;
	}

	function bindRotateControls() {
		root.querySelectorAll('[data-rotate]').forEach(function (button) {
			button.addEventListener("click", function () {
				PhoenixBridge.send("phoenix:character:preview:rotate", { dir: parseInt(button.dataset.rotate, 10) || 0 });
			});
		});
	}

	function renderCreate() {
		root.innerHTML = createTpl;
		if (window.PhoenixI18n) PhoenixI18n.applyDom(root);

		root.querySelectorAll(".option-row").forEach(function (row) {
			const key = row.dataset.option;
			if (key === "weapon" || key === "ranged" || key === "outfit") {
				row.addEventListener("contextmenu", function (event) {
					event.preventDefault();
					focusItemPanel(key);
				});
				const info = row.querySelector(".option-row__info");
				if (info) info.addEventListener("click", function (event) {
					event.preventDefault();
					event.stopPropagation();
					focusItemPanel(key);
				});
			}
			row.querySelectorAll(".option-row__arrow").forEach(function (arrow) {
				const dir = parseInt(arrow.dataset.dir, 10) || 0;
				arrow.addEventListener("click", function () {
					PhoenixBridge.send("phoenix:character:create:cycle", { key: key, dir: dir });
				});
			});
		});

		root.querySelector('[data-button="back"]').addEventListener("click", function () {
			PhoenixBridge.send("phoenix:character:create:stop", {});
			mode = "list";
			render();
		});

		root.querySelector('[data-button="create"]').addEventListener("click", function () {
			const name = (root.querySelector("#char-name").value || "").trim();
			if (!name) {
				setStatus(window.PhoenixI18n ? PhoenixI18n.t("character.create.error.nameRequired") : "Podaj nazwę postaci");
				return;
			}
			setStatus("");
			setError("");
			PhoenixBridge.send("phoenix:character:create:submit", { name: name });
		});

		renderItemPanels();
		bindRotateControls();
	}

	function genderLabel(value) {
		if (window.PhoenixI18n) {
			const k = "character.list.gender." + value;
			const t = PhoenixI18n.t(k);
			if (t && t !== k) return t;
		}
		return value === 2 ? "♀" : "♂";
	}

	app.register("character", {
		onShow: function () {
			mode = "list";
			selectedId = null;
			optionState = { gender: 0, weapon: 0, ranged: 0, outfit: 0 };
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") PhoenixHud.setBlocked(true);
			render();
			PhoenixBridge.send("phoenix:character:requestList", {});
			PhoenixBridge.send("phoenix:character:list:enter", {});
		},
		onHide: function () {
			document.body.classList.remove("phoenix-body--cinematic");
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") PhoenixHud.setBlocked(false);
			PhoenixBridge.send("phoenix:character:create:stop", {});
			PhoenixBridge.send("phoenix:character:list:leave", {});
		}
	});

	PhoenixBridge.on("phoenix:character:list", function (payload) {
		characters = (payload && Array.isArray(payload.characters)) ? payload.characters : [];
		if (selectedId != null && !characters.some(function (c) { return c.id === selectedId; })) {
			selectedId = null;
		}
		applyStoredSelection();
		if (mode === "list") render();
		focusSelectedPreview();
	});

	PhoenixBridge.on("phoenix:character:option", function (payload) {
		if (mode !== "create" || !payload || !payload.key) return;
		const node = root.querySelector('[data-value="' + payload.key + '"]');
		if (!node) return;
		let text = payload.value || "—";
		if (payload.i18n && window.PhoenixI18n) {
			const translated = PhoenixI18n.t(text);
			if (translated && translated !== text) text = translated;
		}
		node.textContent = text;
		if (payload.i18n) node.setAttribute("data-t", payload.value); else node.removeAttribute("data-t");
		const match = String(payload.value || "").match(/\.(\d+)$/);
		if (match) optionState[payload.key] = parseInt(match[1], 10) || 0;
		// Cache the visual + instance for equipment slots so the right-side detail panel can render a 3D mesh.
		if (payload.key === "weapon" || payload.key === "ranged" || payload.key === "outfit") {
			optionVisuals[payload.key] = payload.visual || "";
			optionInstances[payload.key] = payload.instance || "";
			updatePanelMesh(payload.key, payload.visual || "");
		}
		renderItemPanels();
	});

	function updatePanelMesh(key, visual) {
		const slot = root.querySelector('[data-panel="' + key + '"] .char-item-panel__model');
		if (!slot) return;
		if (!visual) {
			slot.textContent = "";
			return;
		}
		const existing = slot.querySelector("gothic-render");
		if (existing) {
			if (existing.getAttribute("visual") !== visual) existing.setAttribute("visual", visual);
			return;
		}
		slot.innerHTML = '<gothic-render width="320" height="160" rot-x="1.584" rot-y="-1.662" rot-z="-0.488" scale="1.4" light-intensity="2.85" visual="' + visual + '"></gothic-render>';
	}

	PhoenixBridge.on("phoenix:character:createResult", function (payload) {
		if (!payload) return;
		if (payload.success) {
			mode = "list";
			PhoenixBridge.send("phoenix:character:create:stop", {});
			render();
			PhoenixBridge.send("phoenix:character:requestList", {});
		} else {
			const key = payload.error;
			const text = (window.PhoenixI18n && key) ? PhoenixI18n.t(key) : (key || "");
			setStatus(text);
		}
	});

	if (window.PhoenixI18n) {
		PhoenixI18n.onChange(function () { render(); });
	}
})();
