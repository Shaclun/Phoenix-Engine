

(function () {
	"use strict";

	function t(key, fallback) {
		try { return (window.PhoenixI18n && window.PhoenixI18n.t)
			? window.PhoenixI18n.t(key) : (fallback != null ? fallback : key); }
		catch (e) { return fallback != null ? fallback : key; }
	}
	function tItem(instance, suffix, fallback) {
		try { return (window.PhoenixI18n && window.PhoenixI18n.tItem)
			? window.PhoenixI18n.tItem(instance, suffix, fallback) : (fallback || ""); }
		catch (e) { return fallback || ""; }
	}
	function itemName(item) {
		return tItem(item.instance, "name", item.name || item.instance || "?");
	}
	function itemDesc(item) {
		return tItem(item.instance, "desc", item.description || "");
	}

	const QUALITY = [
		{ key: "inv.quality.0", color: "#7d7d7d" },
		{ key: "inv.quality.1", color: "#9aa07a" },
		{ key: "inv.quality.2", color: "#d8d3c1" },
		{ key: "inv.quality.3", color: "#5e9bff" },
		{ key: "inv.quality.4", color: "#b56cff" },
		{ key: "inv.quality.5", color: "#ffb84d" }
	];
	const ITEM_RENDER = { rotX: "1.584", rotY: "-1.662", rotZ: "-0.488", scale: "1.40", light: "2.85" };
	function qualityLabel(q) { return t((QUALITY[q] || QUALITY[2]).key); }

	function slotLabel(slotName) { return t("inv.slot." + slotName, slotName); }
	const SLOT_NAMES = ["None","MainHand","OffHand","Ranged","Armor","Helmet","Amulet","Ring1","Ring2","Belt"];
	const SLOT_ORDER = ["Amulet","Armor","Belt","MainHand","Ranged","Ring1","Ring2"];
	const TOTAL_BAG_CELLS = 64;

	const TABS = [
		{ id: "all",         labelKey: "inv.tab.all",         icon: "✦",  cats: null },
		{ id: "weapons",     labelKey: "inv.tab.weapons",     icon: "⚔",  cats: [1, 2, 3, 4, 15] },
		{ id: "armor",       labelKey: "inv.tab.armor",       icon: "🛡", cats: [5, 6, 7] },
		{ id: "jewelry",     labelKey: "inv.tab.jewelry",     icon: "💍", cats: [8, 9, 10] },
		{ id: "magic",       labelKey: "inv.tab.magic",       icon: "📜", cats: [11, 12] },
		{ id: "consumables", labelKey: "inv.tab.consumables", icon: "🧪", cats: [13, 14] },
		{ id: "materials",   labelKey: "inv.tab.materials",   icon: "⛏",  cats: [16] },
		{ id: "docs",        labelKey: "inv.tab.docs",        icon: "📖", cats: [17, 18] },
		{ id: "other",       labelKey: "inv.tab.other",       icon: "◆",  cats: [19] }
	];

	let state = {
		items: [],
		gold: 0,
		selectedId: null,
		activeTab: "all",
		player: { strength: 0, dexterity: 0, hpMax: 0, manaMax: 0 }
	};

	let root = null;
	let goldNode = null;
	let gearNode = null;
	let dollNode = null;
	let gridNode = null;
	let countNode = null;
	let tabsNode = null;
	let actionsNode = null;
	let tooltipNode = null;
	let tip_name, tip_quality, tip_desc, tip_stats, tip_hint;

	function buildLayout() {
		root.innerHTML = "";
		const shell = document.createElement("div");
		shell.className = "invui-root";
		root.appendChild(shell);

		const leftPanel = document.createElement("section");
		leftPanel.className = "invui-side invui-side--left";
		shell.appendChild(leftPanel);

		const toolbar = document.createElement("div");
		toolbar.className = "invui-toolbar";
		toolbar.innerHTML =
			'<div class="invui-toolbar__left">' +
				'<span class="invui-toolbar__title" data-role="title"></span>' +
			'</div>' +
			'<div class="invui-toolbar__right">' +
				'<span class="invui-stat"><span class="invui-stat__icon"></span><span data-role="gold">0</span> <span data-role="goldUnit"></span></span>' +
				'<span class="invui-stat invui-stat--gear"><span class="invui-stat__icon"></span><span data-role="gearLabel"></span> <span data-role="gear">0</span></span>' +
				'<button class="invui-toolbar__close" data-role="close"></button>' +
			'</div>';
		leftPanel.appendChild(toolbar);
		goldNode = toolbar.querySelector("[data-role='gold']");
		gearNode = toolbar.querySelector("[data-role='gear']");
		toolbar.querySelector("[data-role='close']").addEventListener("click", function () {
			PhoenixBridge.send("phoenix:item:closeRequest", {});
		});

		const equipped = document.createElement("div");
		equipped.className = "invui-equipped";
		equipped.innerHTML = '<div class="invui-equipped__title" data-role="eqTitle"></div>';
		const doll = document.createElement("div");
		doll.className = "invui-doll";
		SLOT_ORDER.forEach(function (s) {
			const slot = document.createElement("div");
			slot.className = "invui-eq-slot";
			slot.dataset.slot  = s;
			slot.dataset.label = slotLabel(s);
			doll.appendChild(slot);
		});
		equipped.appendChild(doll);
		leftPanel.appendChild(equipped);
		dollNode = doll;
		bindDollEvents();

		actionsNode = document.createElement("div");
		actionsNode.className = "invui-actions";
		leftPanel.appendChild(actionsNode);

		const footer = document.createElement("div");
		footer.className = "invui-footer";
		footer.dataset.role = "footer";
		footer.textContent = t("inv.footer");
		leftPanel.appendChild(footer);

		const center = document.createElement("div");
		center.className = "invui-center";
		shell.appendChild(center);

		const rightPanel = document.createElement("section");
		rightPanel.className = "invui-side invui-side--right";
		shell.appendChild(rightPanel);

		const bag = document.createElement("div");
		bag.className = "invui-bag";
		const bagHead = document.createElement("div");
		bagHead.className = "invui-bag__header";
		bagHead.innerHTML = '<span data-role="bagTitle"></span><span class="invui-bag__count" data-role="count">0 / ' + TOTAL_BAG_CELLS + '</span>';
		bag.appendChild(bagHead);

		const tabs = document.createElement("div");
		tabs.className = "invui-tabs";
		TABS.forEach(function (tab) {
			const btn = document.createElement("button");
			btn.type = "button";
			btn.className = "invui-tab" + (state.activeTab === tab.id ? " is-active" : "");
			btn.dataset.tabId = tab.id;
			btn.innerHTML =
				'<span class="invui-tab__icon">' + tab.icon + '</span>' +
				'<span class="invui-tab__label" data-role="tabLabel"></span>' +
				'<span class="invui-tab__count" data-role="tabCount">0</span>';
			btn.addEventListener("click", function () {
				if (state.activeTab === tab.id) return;
				state.activeTab = tab.id;
				renderTabs();
				renderGrid();
			});
			tabs.appendChild(btn);
		});
		bag.appendChild(tabs);
		tabsNode = tabs;
		const grid = document.createElement("div");
		grid.className = "invui-grid";
		bag.appendChild(grid);
		rightPanel.appendChild(bag);
		gridNode = grid;
		countNode = bagHead.querySelector("[data-role='count']");

		if (!document.getElementById("invui-tooltip")) {
			tooltipNode = document.createElement("div");
			tooltipNode.id = "invui-tooltip";
			tooltipNode.className = "invui-tooltip";
			tooltipNode.innerHTML =
				'<div class="invui-tooltip__name" data-role="name"></div>' +
				'<div class="invui-tooltip__quality" data-role="quality"></div>' +
				'<div class="invui-tooltip__desc" data-role="desc"></div>' +
				'<div class="invui-tooltip__divider"></div>' +
				'<div data-role="stats"></div>' +
				'<div class="invui-tooltip__hint" data-role="hint"></div>';
			document.body.appendChild(tooltipNode);
		} else {
			tooltipNode = document.getElementById("invui-tooltip");
		}
		tip_name    = tooltipNode.querySelector("[data-role='name']");
		tip_quality = tooltipNode.querySelector("[data-role='quality']");
		tip_desc    = tooltipNode.querySelector("[data-role='desc']");
		tip_stats   = tooltipNode.querySelector("[data-role='stats']");
		tip_hint    = tooltipNode.querySelector("[data-role='hint']");
	}

	var INVENTORY_3D_ENABLED = true;

	function visualForItem(item) {
		if (!INVENTORY_3D_ENABLED) return null;
		if (!item) return null;
		var v = item.visual;
		return (typeof v === "string" && v.length) ? v : null;
	}

	function categoryGlyph(category) {

		return "";
	}

	function renderFallback(target, item) {
		const wrap = document.createElement("div");
		wrap.className = "invui-cell__fallback is-loading";

		const spinner = document.createElement("span");
		spinner.className = "invui-cell__spinner";
		const label = document.createElement("span");
		label.className = "invui-cell__label";
		label.textContent = (itemName(item) || "?").substring(0, 12);
		wrap.appendChild(spinner);
		wrap.appendChild(label);
		target.appendChild(wrap);
	}

	function renderItemMesh(target, item, opts) {
		const visual = visualForItem(item);
		if (!visual) {
			renderFallback(target, item);
			return;
		}

		renderFallback(target, item);
		meshQueue.schedule(target, visual, opts);
	}

	const MESH_QUEUE_CONCURRENCY = 1;
	const MESH_QUEUE_TIMEOUT_MS  = 1500;
	const MESH_QUEUE_GAP_MS      = 25;
	const meshQueue = {
		pending: [],
		active: 0,
		generation: 0,
		schedule: function (target, visual, opts) {
			this.pending.push({ gen: this.generation, target: target, visual: visual, opts: opts });
			this._tick();
		},

		reset: function () {
			this.generation++;
			this.pending.length = 0;
		},
		_tick: function () {
			while (this.active < MESH_QUEUE_CONCURRENCY && this.pending.length) {
				const task = this.pending.shift();
				if (task.gen !== this.generation) continue;
				this._run(task);
			}
		},
		_run: function (task) {
			const self = this;
			self.active++;
			if (!task.target || !task.target.isConnected || task.gen !== self.generation) {
				self.active--;
				setTimeout(function () { self._tick(); }, MESH_QUEUE_GAP_MS);
				return;
			}
			const fallback = task.target.querySelector(".invui-cell__fallback");
			const el = document.createElement("gothic-render");
			const w = (task.opts && task.opts.width)  || 192;
			const h = (task.opts && task.opts.height) || 192;
			el.setAttribute("width",  String(w));
			el.setAttribute("height", String(h));
			el.setAttribute("rot-x", ITEM_RENDER.rotX);
			el.setAttribute("rot-y", ITEM_RENDER.rotY);
			el.setAttribute("rot-z", ITEM_RENDER.rotZ);
			el.setAttribute("scale", ITEM_RENDER.scale);
			el.setAttribute("light-intensity", ITEM_RENDER.light);
			el.style.position = "absolute";
			el.style.inset = "0";
			el.style.zIndex = "1";
			task.target.appendChild(el);
			task.target.dataset.meshVisual = task.visual;
			let done = false;
			const finish = function (success) {
				if (done) return;
				done = true;
				clearTimeout(watchdog);
				try { obs.disconnect(); } catch (e) {  }
				if (success) {

					if (fallback) {
						fallback.classList.remove("is-loading");
						fallback.classList.add("is-loaded");
					}
					task.target.dataset.meshLoaded = "1";
				} else {

					try { el.remove(); } catch (e) {  }
					delete task.target.dataset.meshVisual;
				}
				self.active--;
				setTimeout(function () { self._tick(); }, MESH_QUEUE_GAP_MS);
			};
			const obs = new MutationObserver(function () {
				if (el.querySelector("canvas")) { finish(true); return; }
				if (el.childElementCount === 0) finish(false);
			});
			obs.observe(el, { childList: true });
			const watchdog = setTimeout(function () { finish(false); }, MESH_QUEUE_TIMEOUT_MS);

			el.setAttribute("visual", task.visual);
		}
	};

	const MESH_RETRY_INTERVAL_MS = 1500;
	let meshRetryTimer = null;
	function startMeshRetrySweeps() {
		if (meshRetryTimer) return;
		meshRetryTimer = setInterval(function () {
			if (!root || !gridNode) return;

			if (root.style.display === "none" || !root.offsetParent) return;
			const stuck = root.querySelectorAll(".invui-cell__fallback.is-loading, .invui-eq-slot .invui-cell__fallback.is-loading");
			stuck.forEach(function (fb) {
				const cell = fb.parentElement;
				if (!cell) return;
				if (cell.dataset.meshLoaded === "1") return;
				if (cell.querySelector("gothic-render canvas")) {
					fb.classList.remove("is-loading");
					fb.classList.add("is-loaded");
					cell.dataset.meshLoaded = "1";
					return;
				}
				const itemId = cell.dataset.itemId;
				if (!itemId) return;
				const item = state.items.find(function (it) { return String(it.id) === String(itemId); });
				if (!item) return;
				const visual = visualForItem(item);
				if (!visual) return;

				const old = cell.querySelector("gothic-render");
				if (old) { try { old.remove(); } catch (e) {} }
				meshQueue.schedule(cell, visual, null);
			});
		}, MESH_RETRY_INTERVAL_MS);
	}
	function stopMeshRetrySweeps() {
		if (meshRetryTimer) { clearInterval(meshRetryTimer); meshRetryTimer = null; }
	}

	function buildCell(item) {
		const cell = document.createElement("div");
		cell.className = "invui-cell has-item";
		cell.dataset.itemId = String(item.id);
		const q = QUALITY[item.quality] || QUALITY[2];
		cell.style.setProperty("--cell-border-color", q.color);
		if (item.equipped) cell.classList.add("is-equipped");
		if (state.selectedId === item.id) cell.classList.add("is-selected");
		if (item.equipped) {
			const eq = document.createElement("span");
			eq.className = "invui-cell__eq";
			eq.textContent = "✓";
			cell.appendChild(eq);
		}
		if (item.upgrade > 0) {
			const u = document.createElement("span");
			u.className = "invui-cell__upgrade";
			u.textContent = "+" + item.upgrade;
			cell.appendChild(u);
		}
		if (item.amount > 1) {
			const a = document.createElement("span");
			a.className = "invui-cell__amount";
			a.textContent = "×" + item.amount;
			cell.appendChild(a);
		}
		renderItemMesh(cell, item);
		cell.addEventListener("mouseenter", function (e) { showTooltip(item, e); });
		cell.addEventListener("mousemove",  moveTooltip);
		cell.addEventListener("mouseleave", hideTooltip);
		cell.addEventListener("click",      function () { selectItem(item.id); });
		cell.addEventListener("dblclick",   function () { quickUse(item); });
		cell.draggable = true;
		cell.addEventListener("dragstart", function (e) {
			if (!e.dataTransfer) return;
			const payload = { instance: item.instance || "", name: itemName(item), icon: item.icon || "", visual: item.visual || "", category: item.category || 0, onUse: !!item.onUse };
			try { e.dataTransfer.setData("text/phoenix-item", JSON.stringify(payload)); } catch (err) {}
			e.dataTransfer.effectAllowed = "copy";
		});
		return cell;
	}

	function tabMatches(tab, item) {
		if (!tab || !tab.cats) return true;
		return tab.cats.indexOf(item.category || 0) >= 0;
	}

	function renderTabs() {
		if (!tabsNode) return;
		const inBag = state.items.filter(function (it) { return !it.equipped; });
		const counts = {};
		TABS.forEach(function (tab) {
			counts[tab.id] = inBag.filter(function (it) { return tabMatches(tab, it); }).length;
		});
		tabsNode.querySelectorAll(".invui-tab").forEach(function (btn) {
			const id = btn.dataset.tabId;
			const tab = TABS.find(function (t) { return t.id === id; });
			btn.classList.toggle("is-active", state.activeTab === id);
			const lbl = btn.querySelector("[data-role='tabLabel']");
			const cnt = btn.querySelector("[data-role='tabCount']");
			if (lbl && tab) lbl.textContent = t(tab.labelKey);
			if (cnt) cnt.textContent = String(counts[id] || 0);
		});
	}

	function renderGrid() {
		gridNode.innerHTML = "";
		const activeTab = TABS.find(function (t) { return t.id === state.activeTab; });
		const inBag = state.items.filter(function (it) {
			return !it.equipped && tabMatches(activeTab, it);
		});
		inBag.sort(function (a, b) {
			if (a.category !== b.category) return (a.category || 0) - (b.category || 0);
			if (a.instance === b.instance) return b.quality - a.quality;
			return a.instance < b.instance ? -1 : 1;
		});
		inBag.forEach(function (item) { gridNode.appendChild(buildCell(item)); });
		const used = inBag.length;
		const fill = Math.max(0, TOTAL_BAG_CELLS - used);
		for (let i = 0; i < fill; i++) {
			const empty = document.createElement("div");
			empty.className = "invui-cell is-empty";
			gridNode.appendChild(empty);
		}
		const totalUsed = state.items.filter(function (it) { return !it.equipped; }).length;
		countNode.textContent = (state.activeTab === "all" ? totalUsed : (used + " / " + totalUsed)) + " / " + TOTAL_BAG_CELLS;
	}

	function renderEquipment() {
		const slots = dollNode.querySelectorAll(".invui-eq-slot");
		slots.forEach(function (slot) {
			slot.classList.remove("has-item");
			slot.classList.remove("is-selected");
			slot.style.removeProperty("--quality-color");
			slot.removeAttribute("data-item-id");
			const oldMesh = slot.querySelector("gothic-render");
			if (oldMesh) oldMesh.remove();
			const oldFb = slot.querySelector(".invui-cell__fallback");
			if (oldFb) oldFb.remove();
			slot.dataset.label = slotLabel(slot.dataset.slot);

		});
		state.items.filter(function (it) { return it.equipped; }).forEach(function (item) {
			const name = SLOT_NAMES[item.slot] || "None";
			const slot = dollNode.querySelector("[data-slot='" + name + "']");
			if (!slot) return;
			slot.classList.add("has-item");
			slot.dataset.itemId = String(item.id);
			if (state.selectedId === item.id) slot.classList.add("is-selected");
			const q = QUALITY[item.quality] || QUALITY[2];
			slot.style.setProperty("--quality-color", q.color);
			renderItemMesh(slot, item);
			const label = itemName(item);
			slot.dataset.label = item.upgrade > 0 ? (label + "  +" + item.upgrade) : label;
		});
	}

	function bindDollEvents() {
		if (dollNode._invuiBound) return;
		dollNode._invuiBound = true;
		dollNode.addEventListener("mouseover", function (e) {
			const slot = e.target.closest(".invui-eq-slot.has-item");
			if (!slot) return;
			const id = parseInt(slot.dataset.itemId, 10);
			const item = state.items.find(function (it) { return it.id === id; });
			if (item) showTooltip(item, e);
		});
		dollNode.addEventListener("mousemove", function (e) {
			if (e.target.closest(".invui-eq-slot.has-item")) moveTooltip(e);
		});
		dollNode.addEventListener("mouseout", function (e) {
			if (e.target.closest(".invui-eq-slot")) hideTooltip();
		});
		dollNode.addEventListener("click", function (e) {
			const slot = e.target.closest(".invui-eq-slot.has-item");
			if (!slot) return;
			const id = parseInt(slot.dataset.itemId, 10);
			if (!isNaN(id)) selectItem(id);
		});
		dollNode.addEventListener("dblclick", function (e) {
			const slot = e.target.closest(".invui-eq-slot.has-item");
			if (!slot) return;
			const id = parseInt(slot.dataset.itemId, 10);
			const item = state.items.find(function (it) { return it.id === id; });
			if (item) quickUse(item);
		});
	}

	function calcGearScore() {

		let gs = 0;
		state.items.forEach(function (it) {
			if (!it.equipped) return;
			if (it.stats) {
				if (it.stats.damage)     gs += it.stats.damage;
				if (it.stats.protection) {
					Object.keys(it.stats.protection).forEach(function (k) {
						gs += it.stats.protection[k] || 0;
					});
				}
			}
		});
		return gs;
	}

	function showTooltip(item, e) {
		const q = QUALITY[item.quality] || QUALITY[2];
		tooltipNode.style.setProperty("--tooltip-color", q.color);
		tip_name.textContent = itemName(item);
		tip_name.style.setProperty("--tooltip-color", q.color);
		tip_quality.textContent = qualityLabel(item.quality) + (item.upgrade > 0 ? "  •  +" + item.upgrade : "");
		const desc = itemDesc(item);
		tip_desc.textContent = desc;
		tip_desc.style.display = desc ? "block" : "none";
		tip_stats.innerHTML = "";
		const rows = [];
		if (item.stats) {
			if (item.stats.damage)     rows.push([t("inv.stat.damage"), item.stats.damage]);
			if (item.stats.protection) {
				const p = item.stats.protection;
				if (p.edge)  rows.push([t("inv.stat.prot.edge"),  p.edge]);
				if (p.blunt) rows.push([t("inv.stat.prot.blunt"), p.blunt]);
				if (p.point) rows.push([t("inv.stat.prot.point"), p.point]);
				if (p.fire)  rows.push([t("inv.stat.prot.fire"),  p.fire]);
				if (p.magic) rows.push([t("inv.stat.prot.magic"), p.magic]);
			}
		}
		if (item.value)  rows.push([t("inv.stat.value"),  item.value  + " " + t("inv.unit.gold")]);
		if (item.weight) rows.push([t("inv.stat.weight"), item.weight + " " + t("inv.unit.kg")]);
		rows.forEach(function (r) {
			const row = document.createElement("div");
			row.className = "invui-tooltip__stat";
			row.innerHTML = "<span>" + r[0] + "</span><span>" + r[1] + "</span>";
			tip_stats.appendChild(row);
		});

		renderRequirements(item);
		renderEffects(item);

		const hints = [];
		if (item.onUse) hints.push(t("inv.hint.use"));
		else if (item.slot >= 1 && item.slot <= 9) hints.push(t(item.equipped ? "inv.hint.unequip" : "inv.hint.equip"));
		tip_hint.textContent = hints.join("  •  ");
		tip_hint.style.display = hints.length ? "block" : "none";
		tooltipNode.classList.add("is-visible");
		moveTooltip(e);
	}

	function attrLabel(attr) {
		const map = {
			strength: "inv.req.strength",
			dexterity: "inv.req.dexterity",
			hpMax: "stats.attr.hpMax",
			manaMax: "stats.attr.manaMax",
			hp: "stats.hp",
			mana: "stats.mana"
		};
		return t(map[attr] || ("inv.effect." + attr), attr);
	}

	function playerAttrValue(attr) {
		const p = state.player || {};
		return p[attr] | 0;
	}

	function renderRequirements(item) {
		if (!item || !item.requirements || !item.requirements.length) return;
		const header = document.createElement("div");
		header.className = "invui-tooltip__section";
		header.textContent = t("inv.section.requirements", "Wymagania");
		tip_stats.appendChild(header);
		item.requirements.forEach(function (r) {
			const row = document.createElement("div");
			row.className = "invui-tooltip__stat";
			const have = playerAttrValue(r.attr);
			const ok = have >= r.value;
			row.innerHTML =
				"<span>" + attrLabel(r.attr) + "</span>" +
				"<span style='color:" + (ok ? "#b5e8b0" : "#ff7a7a") + "'>" + r.value + (have > 0 ? " (" + have + ")" : "") + "</span>";
			tip_stats.appendChild(row);
		});
	}

	function renderEffects(item) {
		if (!item || !item.effect) return;
		const eff = item.effect;
		const rows = [];
		const pushAttr = function (attr, value) {
			if (!attr || !value) return;
			const sign = value > 0 ? "+" : "";
			rows.push([attrLabel(attr), sign + value]);
		};
		if (eff.attribute && eff.value) pushAttr(eff.attribute, eff.value | 0);
		["strength", "dexterity", "hpMax", "manaMax", "hp", "mana"].forEach(function (k) {
			if (k in eff && (eff.attribute !== k)) pushAttr(k, eff[k] | 0);
		});
		if (eff.durationMs) rows.push([t("inv.effect.duration", "Czas"), Math.round((eff.durationMs | 0) / 1000) + "s"]);
		if (!rows.length) return;
		const header = document.createElement("div");
		header.className = "invui-tooltip__section";
		header.textContent = item.onUse ? t("inv.section.effects", "Efekty") : t("inv.section.bonuses", "Bonusy");
		tip_stats.appendChild(header);
		rows.forEach(function (r) {
			const row = document.createElement("div");
			row.className = "invui-tooltip__stat";
			row.innerHTML = "<span>" + r[0] + "</span><span style='color:#9bd6ff'>" + r[1] + "</span>";
			tip_stats.appendChild(row);
		});
	}
	function moveTooltip(e) {
		if (!tooltipNode.classList.contains("is-visible")) return;
		const x = Math.min(window.innerWidth  - tooltipNode.offsetWidth  - 16, e.clientX + 18);
		const y = Math.min(window.innerHeight - tooltipNode.offsetHeight - 16, e.clientY + 18);
		tooltipNode.style.left = x + "px";
		tooltipNode.style.top  = y + "px";
	}
	function hideTooltip() { tooltipNode && tooltipNode.classList.remove("is-visible"); }

	function selectItem(itemId) {
		state.selectedId = itemId;

		gridNode.querySelectorAll(".invui-cell.is-selected").forEach(function (c) { c.classList.remove("is-selected"); });
		dollNode.querySelectorAll(".invui-eq-slot.is-selected").forEach(function (s) { s.classList.remove("is-selected"); });
		const cell = gridNode.querySelector("[data-item-id='" + itemId + "']");
		if (cell) cell.classList.add("is-selected");
		const dollSlot = dollNode.querySelector(".invui-eq-slot[data-item-id='" + itemId + "']");
		if (dollSlot) dollSlot.classList.add("is-selected");

		const item = state.items.find(function (it) { return it.id === itemId; });
		actionsNode.innerHTML = "";
		if (!item) return;
		const canEquip = item.slot >= 1 && item.slot <= 9;
		if (item.onUse) actionsNode.appendChild(makeAction(t("inv.action.use"), function () {
			PhoenixBridge.send("phoenix:item:requestUse", { id: item.id });
		}));
		if (canEquip) actionsNode.appendChild(makeAction(t(item.equipped ? "inv.action.unequip" : "inv.action.equip"), function () {
			PhoenixBridge.send("phoenix:item:requestEquip", { id: item.id, equip: !item.equipped });
		}));
		if (item.upgrade !== undefined && item.upgrade < 9 && (item.slot >= 1 && item.slot <= 5)) {
			actionsNode.appendChild(makeAction(t("inv.action.upgrade") + " +" + (item.upgrade + 1), function () {
				PhoenixBridge.send("phoenix:item:requestUpgrade", { id: item.id });
			}, "invui-action--upgrade"));
		}
		const hotbarSlot = window.PhoenixHud && typeof PhoenixHud.slotOf === "function" ? PhoenixHud.slotOf(item.instance || "") : -1;
		if (hotbarSlot >= 0) {
			actionsNode.appendChild(makeAction(t("inv.action.hotbarUnassign", "Odepnij z hotbara") + " " + (hotbarSlot + 1), function () {
				if (window.PhoenixHud && typeof PhoenixHud.clearSlot === "function") PhoenixHud.clearSlot(hotbarSlot);
				selectItem(item.id);
			}));
		} else {
			actionsNode.appendChild(makeAction(t("inv.action.hotbarAssign", "Przypisz do hotbara"), function () {
				showHotbarPicker(item);
			}));
		}
		actionsNode.appendChild(makeAction(t("inv.action.drop"), function () {
			PhoenixBridge.send("phoenix:item:requestDrop", { id: item.id, amount: item.amount, name: itemName(item), visual: item.visual || "" });
		}, "invui-action--danger"));
	}
	function showHotbarPicker(item) {
		root.querySelectorAll(".invui-hotbar-picker").forEach(function (node) { node.remove(); });
		const picker = document.createElement("div");
		picker.className = "invui-hotbar-picker";
		picker.innerHTML = '<div class="invui-hotbar-picker__title">' + t("inv.hotbar.choose", "Wybierz slot hotbara") + '</div>';
		const slots = window.PhoenixHud && typeof PhoenixHud.getSlots === "function" ? PhoenixHud.getSlots() : [];
		for (let i = 0; i < 8; i++) {
			const button = document.createElement("button");
			button.type = "button";
			button.className = "invui-hotbar-slot";
			button.innerHTML = '<span class="invui-hotbar-slot__key">' + (i + 1) + '</span><div class="invui-hotbar-slot__render"></div><span class="invui-hotbar-slot__name"></span>';
			const entry = slots[i];
			if (entry && entry.instance) {
				const entryItem = state.items.find(function (it) { return it.instance === entry.instance; }) || entry;
				button.querySelector(".invui-hotbar-slot__name").textContent = entryItem.name || entry.name || entry.instance;
				renderItemMesh(button.querySelector(".invui-hotbar-slot__render"), entryItem, { width: 96, height: 96 });
			}
			button.addEventListener("click", function () {
				if (window.PhoenixHud && typeof PhoenixHud.assignSlot === "function") PhoenixHud.assignSlot(i, { instance: item.instance || "", name: itemName(item), icon: item.icon || "", visual: item.visual || "", category: item.category || 0, onUse: !!item.onUse });
				picker.remove();
				selectItem(item.id);
			});
			picker.appendChild(button);
		}
		const cancel = document.createElement("button");
		cancel.type = "button";
		cancel.className = "invui-hotbar-picker__cancel";
		cancel.textContent = t("social.action.cancel", "Anuluj");
		cancel.addEventListener("click", function () { picker.remove(); });
		picker.appendChild(cancel);
		actionsNode.appendChild(picker);
	}
	function makeAction(label, handler, modifier) {
		const btn = document.createElement("button");
		btn.className = "invui-action" + (modifier ? " " + modifier : "");
		btn.textContent = label;
		btn.addEventListener("click", handler);
		return btn;
	}
	function quickUse(item) {
		if (item.onUse) {
			PhoenixBridge.send("phoenix:item:requestUse", { id: item.id });
		} else if (item.slot >= 1 && item.slot <= 9) {
			PhoenixBridge.send("phoenix:item:requestEquip", { id: item.id, equip: !item.equipped });
		}
	}

	function applyChrome() {
		if (!root) return;
		const $ = function (sel) { return root.querySelector(sel); };
		const setIf = function (sel, text) { const n = $(sel); if (n) n.textContent = text; };
		setIf("[data-role='title']",     t("inv.title"));
		setIf("[data-role='goldUnit']",  t("inv.gold.suffix"));
		setIf("[data-role='gearLabel']", t("inv.gear"));
		setIf("[data-role='close']",     t("inv.close"));
		setIf("[data-role='eqTitle']",   t("inv.equipped"));
		setIf("[data-role='bagTitle']",  t("inv.bag"));
		setIf("[data-role='footer']",    t("inv.footer"));
	}

	function rerender() {
		if (!root) return;

		meshQueue.reset();
		applyChrome();
		goldNode.textContent = String(state.gold);
		gearNode.textContent = String(calcGearScore());
		renderEquipment();
		renderTabs();
		renderGrid();

		if (state.selectedId != null) selectItem(state.selectedId);
		else actionsNode.innerHTML = "";
	}

	try {
		if (window.PhoenixI18n && window.PhoenixI18n.onChange) {
			window.PhoenixI18n.onChange(function () { rerender(); });
		}
	} catch (e) {}

	PhoenixBridge.on("phoenix:item:inventory", function (payload) {
		if (!payload) return;
		state.gold  = payload.gold || 0;
		state.items = Array.isArray(payload.items) ? payload.items : [];
		rerender();
	});
	PhoenixBridge.on("phoenix:item:add", function (payload) {
		if (!payload || !payload.item) return;
		state.items.push(payload.item);
		rerender();
	});
	PhoenixBridge.on("phoenix:item:remove", function (payload) {
		if (!payload) return;
		state.items = state.items.filter(function (it) { return it.id !== payload.id; });
		if (state.selectedId === payload.id) state.selectedId = null;
		rerender();
	});
	PhoenixBridge.on("phoenix:item:update", function (payload) {
		if (!payload || !payload.item) return;
		const idx = state.items.findIndex(function (it) { return it.id === payload.item.id; });
		if (idx >= 0) state.items[idx] = payload.item;
		else state.items.push(payload.item);
		rerender();
	});
	PhoenixBridge.on("phoenix:item:upgradeResult", function (payload) {
		if (!payload) return;
		const cell = gridNode && gridNode.querySelector("[data-item-id='" + payload.id + "']");
		if (cell) {
			cell.style.transition = "background 0.4s";
			cell.style.background = payload.success ? "rgba(80, 200, 100, 0.3)" : "rgba(220, 80, 80, 0.35)";
			setTimeout(function () { cell.style.background = ""; }, 600);
		}
	});

	PhoenixBridge.on("phoenix:stats:snapshot", function (payload) {
		if (!payload) return;
		state.player.strength  = payload.strength  | 0;
		state.player.dexterity = payload.dexterity | 0;
		state.player.hpMax     = payload.hpMax     | 0;
		state.player.manaMax   = payload.manaMax   | 0;
	});

	app.register("inventory", {
		onShow: function () {
			root = document.getElementById("page-inventory");
			document.body.classList.add("phoenix-inventory-open");
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") PhoenixHud.setBlocked(true);
			buildLayout();
			rerender();
			PhoenixBridge.send("phoenix:item:requestRefresh", {});
			try { PhoenixBridge.send("phoenix:stats:request", null); } catch (e) {}
			startMeshRetrySweeps();
		},
		onHide: function () {
			document.body.classList.remove("phoenix-inventory-open");
			if (window.PhoenixHud && typeof window.PhoenixHud.setBlocked === "function") PhoenixHud.setBlocked(false);
			stopMeshRetrySweeps();
			meshQueue.reset();
			hideTooltip();
			state.selectedId = null;
		}
	});

})();
