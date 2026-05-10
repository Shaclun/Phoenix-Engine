(function (global) {
    "use strict";

    var bridge = global.PhoenixBridge;
    if (!bridge) return;

    var panel, body, tabsEl, tooltipEl;
    var isOpen = false;
    var isAdmin = false;
    var activeTab = "players";
    var panelCollapsed = false;
    var renderPending = false;

    var TABS = [
        { id: "players", labelKey: "admin.tab.players", fallback: "Gracze" },
        { id: "items",   labelKey: "admin.tab.items",   fallback: "Przedmioty" },
        { id: "custom",  labelKey: "admin.tab.custom",  fallback: "Custom" },
        { id: "inv",     labelKey: "admin.tab.inv",     fallback: "Ekwipunek" },
        { id: "bans",    labelKey: "admin.tab.bans",    fallback: "Bany" },
        { id: "npc",     labelKey: "admin.tab.npc",     fallback: "NPC" },
        { id: "herbs",   labelKey: "admin.tab.herbs",   fallback: "Zioła" },
        { id: "vobs",    labelKey: "admin.tab.vobs",    fallback: "VOB-y" },
        { id: "houses",  labelKey: "admin.tab.houses",  fallback: "Domy" },
        { id: "debug",   labelKey: "admin.tab.debug",   fallback: "Debug" },
        { id: "log",     labelKey: "admin.tab.log",     fallback: "Historia" }
    ];

    var CATEGORY_LABELS = {
        0: "—", 1: "1H", 2: "2H", 3: "Łuk", 4: "Kusza", 5: "Tarcza",
        6: "Zbroja", 7: "Hełm", 8: "Amulet", 9: "Pierścień", 10: "Pas",
        11: "Runa", 12: "Zwój", 13: "Mikstura", 14: "Jedzenie", 15: "Amunicja",
        16: "Materiał", 17: "Klucz", 18: "Dokument", 19: "Inne"
    };
    var SLOT_LABELS = {
        0: "—", 1: "Główna ręka", 2: "Druga ręka", 3: "Dystans",
        4: "Zbroja", 5: "Hełm", 6: "Amulet", 7: "Pierścień 1", 8: "Pierścień 2", 9: "Pas"
    };
    var DAMAGE_TYPES = { 0: "Sieczne", 1: "Obuchowe", 2: "Kłute", 3: "Ogień", 4: "Magia" };
    var BAN_SCOPES = { 1: "Konto", 2: "Postać", 3: "IP", 4: "Serial" };
    var RENDER_DEBUG_VERSION = "screen-2026-05-05-xflip";
    var RENDER_DEBUG_DEFAULTS = { rotX: 1.584, rotY: -1.662, rotZ: -0.488, scale: 1.40, light: 2.85 };
    var VOB_SOURCE_TABS = [
        { id: "data.xml", labelKey: "admin.vobs.source.data", fallback: "Data.xml", limit: 120 },
        { id: "drakaniaverse:g1", labelKey: "admin.vobs.source.g1", fallback: "Gothic 1", limit: 120 },
        { id: "drakaniaverse:g2", labelKey: "admin.vobs.source.g2", fallback: "Gothic 2", limit: 120 },
        { id: "drakaniaverse:notr", labelKey: "admin.vobs.source.notr", fallback: "Noc Kruka", limit: 120 }
    ];

    var HUMAN_OPTIONS = {
        gender: [
            { label: "character.create.gender.0", bodyModel: "HUM_BODY_BABE0", bodyTex: 5, headModel: "HUM_HEAD_BABE", headTex: 137 },
            { label: "character.create.gender.1", bodyModel: "HUM_BODY_NAKED0", bodyTex: 1, headModel: "HUM_HEAD_BALD", headTex: 0 }
        ],
        race: [
            { label: "character.create.race.0", maleBodyTex: 0, femaleBodyTex: 4, maleFace: 19, femaleFace: 151 },
            { label: "character.create.race.1", maleBodyTex: 1, femaleBodyTex: 5, maleFace: 0, femaleFace: 137 },
            { label: "character.create.race.2", maleBodyTex: 2, femaleBodyTex: 6, maleFace: 8, femaleFace: 141 },
            { label: "character.create.race.3", maleBodyTex: 3, femaleBodyTex: 7, maleFace: 4, femaleFace: 142 }
        ],
        headMale: ["HUM_HEAD_BALD", "HUM_HEAD_PONY", "HUM_HEAD_THIEF", "HUM_HEAD_PSIONIC", "HUM_HEAD_FIGHTER", "HUM_HEAD_FATBALD", "HUM_HEAD_LONGHAIR", "HUM_HEAD_PONYBEARD"],
        headFemale: ["HUM_HEAD_BABE", "HUM_HEAD_BABE1", "HUM_HEAD_BABE2", "HUM_HEAD_BABE3", "HUM_HEAD_BABE4", "HUM_HEAD_BABEHAIR"],
        faceMale: [
            [19, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 88],
            [0, 1, 2, 3, 5, 6, 7, 9, 10, 13, 14, 16, 18, 20, 21, 22, 23, 24, 25, 26, 27, 31, 32, 33, 34, 35, 36, 37, 38, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 159, 160, 161],
            [8, 15, 29, 30, 40, 120, 121, 122, 123, 124, 125, 126, 127, 128],
            [4, 11, 12, 17, 28, 129, 130, 131, 132, 133, 134, 135, 136]
        ],
        faceFemale: [
            [151],
            [137, 138, 139, 140, 143, 144, 145, 146, 147, 148, 149, 150],
            [141, 158],
            [142, 157]
        ],
        fatness: [-1, 0, 1, 2],
        outfit: [
            { label: "character.create.outfit.0", male: "ITAR_BAU_L", female: "ITAR_BAUBABE_L" },
            { label: "character.create.outfit.1", male: "ITAR_BDT_H", female: "ITAR_BAUBABE_M" },
            { label: "character.create.outfit.2", male: "ITAR_DJG_H", female: "ITAR_BAUBABE_L2" },
            { label: "character.create.outfit.3", male: "ITAR_SLD_H", female: "ITAR_BAUBABE_M3" }
        ],
        weapon: ["", "ITMW_SCHWERT1", "ITMW_SCHWERT5", "ITMW_SCHWERT2", "ITRW_BOW_H_01"]
    };

    var state = {
        players: [],
        schemes: [],
        schemesById: {},
        bans: [],
        log: [],
        inv: null,
        playerFilter: "",
        playerSelectedPid: null,
        schemeFilter: "",
        schemeCategoryFilter: 0,
        selectedScheme: null,
        itemRenderDebug: { rotX: RENDER_DEBUG_DEFAULTS.rotX, rotY: RENDER_DEBUG_DEFAULTS.rotY, rotZ: RENDER_DEBUG_DEFAULTS.rotZ, scale: RENDER_DEBUG_DEFAULTS.scale, light: RENDER_DEBUG_DEFAULTS.light },
        details: {},
        giveTarget: null,
        giveAmount: 1,
        giveQuality: 2,
        giveUpgrade: 0,
        custom: defaultCustom(),
        humanPickSlot: "",
        npcCatalog: [],
        npcCatalogEdit: "",
        npcSpawns: [],
        npcPresets: [],
        herbCatalog: [],
        herbSpots: [],
        herbForm: defaultHerbForm(),
        vobCatalog: [],
        vobCategories: [],
        vobCategoryStats: [],
        vobSource: "data.xml",
        vobCategory: "",
        vobPage: 0,
        vobPageSize: 120,
        vobMatched: 0,
        vobSourceTotal: 0,
        vobs: [],
        vobForm: defaultVobForm(),
        houses: [],
        houseForm: defaultHouseForm(),
        houseGhostActive: false,
        houseBoundaryActive: false,
        npcView: "catalog",
        npcForm: { instance: "", hostile: 1, respawnSec: 60, name: "", tag: "", kind: "monster", filter: "", preview: 0, posX: 0, posY: 0, posZ: 0, angle: 0, step: 50, world: "", cameraMode: "orbital" },
        npcEditor: defaultNpcEditor(),
        humanCreator: defaultHumanCreator(),
        npcEditingId: 0,
        status: null
    };

    function defaultHumanCreator() {
        return {
            instance: "PC_HERO",
            name: "",
            tag: "human",
            respawnSec: 0,
            hostile: 0,
            gender: 0,
            race: 1,
            head: 0,
            face: 0,
            outfit: 0,
            weaponIndex: 0,
            fatnessIndex: 1,
            bodyModel: "HUM_BODY_BABE0",
            bodyTex: 5,
            headModel: "HUM_HEAD_BABE",
            headTex: 137,
            fatness: 0,
            voice: 0,
            hp: 100,
            level: 1,
            strength: 10,
            dexterity: 10,
            idleAnimation: "S_STAND",
            baseExperience: 50,
            aggroRadius: 900,
            weapon: "",
            armor: "",
            ranged: "",
            teacherSkills: "",
            teachCost: 100,
            merchantItems: "",
            merchantAmount: 1,
            preview: 0,
            posX: 0,
            posY: 0,
            posZ: 0,
            angle: 0,
            step: 50,
            world: "",
            cameraMode: "orbital"
        };
    }

    function defaultNpcEditor() {
        return {
            id: 0,
            code: "",
            label: "",
            instance: "",
            category: "monster",
            kind: "monster",
            hostile: 1,
            respawnSec: 60,
            scaleX: 1.0, scaleY: 1.0, scaleZ: 1.0,
            fatness: 0.0,
            hp: 0, level: 0, strength: 0, dexterity: 0,
            bodyModel: "",
            bodyTex: -1,
            headModel: "",
            headTex: -1,
            voice: 0,
            idleAnimation: "",
            baseExperience: 0,
            aggroRadius: 900,
            attackRange: 180,
            attackDamage: 10,
            walkSpeed: 250
        };
    }

    function defaultCustom() {
        return {
            instance: "PHX_CUSTOM_",
            name: "",
            description: "",
            visual: "",
            category: 19,
            slot: 0,
            value: 0,
            weight: 0,
            stackMax: 1,
            damage: 0,
            damageType: 0,
            protEdge: 0, protBlunt: 0, protPoint: 0, protFire: 0, protMagic: 0,
            flags: 0
        };
    }

    function defaultHerbForm() {
        return { instance: "ITPL_HEALTH_HERB_01", plantId: "", filter: "", posX: 0, posY: 0, posZ: 0, world: "", gatherMs: 7000, cooldownSec: 3600, successChance: 92 };
    }

    function defaultVobForm() {
        return { instance: "", name: "", visual: "", vobId: "", filter: "", posX: 0, posY: 0, posZ: 0, rotX: 0, rotY: 0, rotZ: 0, world: "", interactive: 0, step: 50 };
    }

    function defaultHouseForm() {
        return {
            id: 0,
            name: "Nowy dom",
            slug: "",
            world: "",
            ownerType: "",
            ownerId: "",
            priceGold: 0,
            weeklyRentGold: 0,
            color: "#79C8FF",
            modeId: 0,
            entryX: 0,
            entryY: 0,
            entryZ: 0,
            entryHeading: 0,
            points: []
        };
    }

    function normalizeVobVisual(visual) {
        var value = String(visual || "").trim().toUpperCase();
        return value;
    }

    function vobPreviewVisual(visual) {
        var value = normalizeVobVisual(visual);
        if (value.indexOf(".3DS") >= 0) value = value.replace(/\.3DS/g, ".MRM");
        return value;
    }

    function isVobVisual(visual) {
        var value = normalizeVobVisual(visual);
        return value.indexOf(".3DS") >= 0 || value.indexOf(".MRM") >= 0 || value.indexOf(".MMB") >= 0 || value.indexOf(".MDL") >= 0 || value.indexOf(".MDS") >= 0 || value.indexOf(".ASC") >= 0;
    }

    function buildVobCatalogFromSchemes() {
        var seen = {};
        var out = [];
        (state.schemes || []).forEach(function (scheme) {
            var instance = String(scheme.instance || "").toUpperCase();
            var visual = normalizeVobVisual(scheme.visual || "");
            if (!instance || !isVobVisual(visual) || seen[instance]) return;
            seen[instance] = true;
            out.push({ instance: instance, name: scheme.name || instance, visual: visual, previewVisual: vobPreviewVisual(visual), source: "schemes" });
        });
        return out;
    }

    function t(key, fallback) {
        try {
            var value = (global.PhoenixI18n && global.PhoenixI18n.t) ? global.PhoenixI18n.t(key) : (fallback || key);
            if (fallback && value === key) return fallback;
            return value;
        } catch (e) { return fallback || key; }
    }

    function tFmt(key) {
        var s = t(key, key);
        for (var i = 1; i < arguments.length; i += 1) {
            var v = arguments[i];
            s = s.split("{" + (i - 1) + "}").join(v == null ? "" : String(v));
        }
        return s;
    }

    function tItem(instance, suffix, fallback) {
        try {
            return (global.PhoenixI18n && global.PhoenixI18n.tItem)
                ? global.PhoenixI18n.tItem(instance, suffix, fallback) : (fallback || "");
        } catch (e) { return fallback || ""; }
    }
    function itemName(s) {
        var n = tItem(s.instance, "name", s.name && s.name !== s.instance ? s.name : "");
        if (!n || n === s.instance) n = s.name && s.name !== s.instance ? s.name : "";
        return n || s.instance;
    }
    function itemDesc(s) {
        var d = tItem(s.instance, "desc", s.description || "");
        return d || s.description || "";
    }

    function npcLabel(e) {
        if (!e) return "";
        return t("admin.npc.instance." + String(e.instance || "").toUpperCase(), e.label || e.instance || "");
    }

    function catLabel(id) { return t("inv.cat." + id, CATEGORY_LABELS[id] || "?"); }
    function slotLabel(id) {
        var keys = { 1: "MainHand", 2: "OffHand", 3: "Ranged", 4: "Armor", 5: "Helmet", 6: "Amulet", 7: "Ring1", 8: "Ring2", 9: "Belt" };
        return id && keys[id] ? t("inv.slot." + keys[id], SLOT_LABELS[id] || "") : (SLOT_LABELS[id] || "—");
    }
    function damageLabel(id) { return t("admin.damage." + id, DAMAGE_TYPES[id] || "?"); }

    function send(action, payload) {
        bridge.send("phoenix:admin:request", { action: action, payload: payload || null });
    }

    function humanHasPosition() {
        var h = state.humanCreator;
        return !!h.preview || !!(+h.posX || +h.posY || +h.posZ);
    }

    function npcHasPosition() {
        var n = state.npcForm;
        return !!n.preview || !!(+n.posX || +n.posY || +n.posZ);
    }

    function cycleIndex(value, dir, len) {
        if (!len) return 0;
        return ((+value || 0) + dir + len) % len;
    }

    function humanHeadList(h) {
        return h.gender === 0 ? HUMAN_OPTIONS.headFemale : HUMAN_OPTIONS.headMale;
    }

    function humanFaceList(h) {
        var set = h.gender === 0 ? HUMAN_OPTIONS.faceFemale : HUMAN_OPTIONS.faceMale;
        return set[h.race] || set[1] || [];
    }

    function applyHumanChoice() {
        var h = state.humanCreator;
        var gender = HUMAN_OPTIONS.gender[h.gender] || HUMAN_OPTIONS.gender[0];
        var race = HUMAN_OPTIONS.race[h.race] || HUMAN_OPTIONS.race[1];
        var heads = humanHeadList(h);
        var faces = humanFaceList(h);
        h.head = cycleIndex(h.head, 0, heads.length);
        h.face = cycleIndex(h.face, 0, faces.length);
        h.fatnessIndex = cycleIndex(h.fatnessIndex, 0, HUMAN_OPTIONS.fatness.length);
        h.outfit = cycleIndex(h.outfit, 0, HUMAN_OPTIONS.outfit.length);
        h.weaponIndex = cycleIndex(h.weaponIndex, 0, HUMAN_OPTIONS.weapon.length);
        h.bodyModel = gender.bodyModel;
        h.bodyTex = h.gender === 0 ? race.femaleBodyTex : race.maleBodyTex;
        h.headModel = heads[h.head];
        h.headTex = faces[h.face];
        h.fatness = HUMAN_OPTIONS.fatness[h.fatnessIndex];
    }

    function humanOptionValue(key) {
        var h = state.humanCreator;
        if (key === "gender") return t(HUMAN_OPTIONS.gender[h.gender].label);
        if (key === "race") return t(HUMAN_OPTIONS.race[h.race].label);
        if (key === "head") return h.headModel;
        if (key === "face") return String(h.headTex);
        if (key === "fatness") return String(h.fatness);
        if (key === "outfit") return t(HUMAN_OPTIONS.outfit[h.outfit].label);
        if (key === "weapon") return h.weapon || t("admin.npc.human.none");
        return "";
    }

    function humanEquipmentRows(categories) {
        var rows = (state.schemes || []).filter(function (s) {
            return categories.indexOf(+s.category || 0) >= 0;
        });
        rows.sort(function (a, b) { return itemName(a).localeCompare(itemName(b)); });
        return rows.slice(0, 180);
    }

    function renderHumanEquipmentPicker(slot, labelKey, categories) {
        var h = state.humanCreator;
        var selected = h[slot] || "";
        var sch = selected ? state.schemesById[selected] : null;
        var title = sch ? itemName(sch) : t("admin.npc.human.none");
        var html = '<div class="adm-human-equip"><button type="button" class="adm-btn adm-btn--ghost" data-action="human-equip-toggle" data-slot="' + slot + '"><b>' + escapeHtml(t(labelKey)) + '</b><br><small>' + escapeHtml(title) + (selected ? ' [' + escapeHtml(selected) + ']' : '') + '</small></button>';
        if (state.humanPickSlot === slot) {
            html += '<div class="adm-itemgrid adm-itemgrid--compact" data-role="itemgrid">';
            html += '<div class="adm-itemcell adm-human-itemcell" data-action="human-equip-pick" data-slot="' + slot + '" data-instance="" data-visual=""><div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(t("admin.npc.human.none")) + '</span></div></div>';
            humanEquipmentRows(categories).forEach(function (s) {
                var picked = selected === s.instance ? " is-selected" : "";
                var nm = itemName(s);
                html += '<div class="adm-itemcell adm-human-itemcell' + picked + '" data-action="human-equip-pick" data-slot="' + slot + '" data-instance="' + escapeHtml(s.instance) + '" data-visual="' + escapeHtml(s.visual || "") + '" title="' + escapeHtml(nm) + '">';
                html += '<div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(nm.slice(0, 18)) + '</span></div>';
                html += '<span class="adm-itemcell__cat">' + escapeHtml(catLabel(s.category)) + '</span></div>';
            });
            html += '</div>';
        }
        html += '</div>';
        return html;
    }

    function renderTeacherSkills(current) {
        var active = {};
        String(current || "").split(",").forEach(function (x) { if (x) active[x] = true; });
        var skills = [
            ["strength", "stats.attr.strength"], ["dexterity", "stats.attr.dexterity"],
            ["hpMax", "stats.attr.hpMax"], ["manaMax", "stats.attr.manaMax"],
            ["oneHand", "stats.weapon.oneHand"], ["twoHand", "stats.weapon.twoHand"],
            ["bow", "stats.weapon.bow"], ["crossbow", "stats.weapon.crossbow"]
        ];
        var html = '<div class="adm-checkgrid">';
        skills.forEach(function (s) {
            html += '<label class="adm-check"><input type="checkbox" data-teacher-skill="' + s[0] + '"' + (active[s[0]] ? " checked" : "") + '> ' + escapeHtml(t(s[1], s[0])) + '</label>';
        });
        html += '</div>';
        return html;
    }

    function parseMerchantStock(raw) {
        return String(raw || "").split(",").map(function (part) {
            var bits = part.split(":");
            return { instance: bits[0] || "", amount: Math.max(1, +(bits[1] || 1)) };
        }).filter(function (entry) { return entry.instance; });
    }

    function serializeMerchantStock(list) {
        return list.filter(function (entry) { return entry.instance && entry.amount > 0; }).map(function (entry) {
            return entry.instance + ":" + Math.max(1, +entry.amount || 1);
        }).join(",");
    }

    function renderMerchantStock() {
        var h = state.humanCreator;
        var stock = parseMerchantStock(h.merchantItems);
        var html = '<div class="adm-merchant-stock">';
        html += '<div class="adm-toolbar"><input class="adm-input" type="number" min="1" data-hf="merchantAmount" value="' + (+h.merchantAmount || 1) + '"><button type="button" class="adm-btn adm-btn--ghost" data-action="merchant-stock-toggle">' + escapeHtml(t("merchant.addItem", "Dodaj towar")) + '</button></div>';
        if (state.humanMerchantPick) {
            html += '<div class="adm-itemgrid adm-itemgrid--compact" data-role="itemgrid">';
            humanEquipmentRows([1,2,3,4,5,6,7,8,9,10,11,12]).forEach(function (s) {
                var name = itemName(s);
                html += '<div class="adm-itemcell adm-human-itemcell" data-action="merchant-stock-add" data-instance="' + escapeHtml(s.instance) + '" data-visual="' + escapeHtml(s.visual || "") + '" title="' + escapeHtml(name) + '"><div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(name.slice(0, 18)) + '</span></div><span class="adm-itemcell__cat">' + escapeHtml(catLabel(s.category)) + '</span></div>';
            });
            html += '</div>';
        }
        if (stock.length) {
            html += '<div class="adm-stock-list adm-itemgrid adm-itemgrid--compact" data-role="itemgrid">';
            stock.forEach(function (entry, index) {
                var scheme = state.schemesById[entry.instance];
                var name = scheme ? itemName(scheme) : entry.instance;
                html += '<button type="button" class="adm-itemcell adm-human-itemcell" data-action="merchant-stock-remove" data-index="' + index + '" data-instance="' + escapeHtml(entry.instance) + '" data-visual="' + escapeHtml(scheme ? (scheme.visual || "") : "") + '" title="' + escapeHtml(name) + '"><div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(name.slice(0, 18)) + '</span></div><span class="adm-itemcell__cat">x' + entry.amount + '</span></button>';
            });
            html += '</div>';
        }
        html += '<input class="adm-input" data-hf="merchantItems" value="' + escapeHtml(h.merchantItems || "") + '" placeholder="ITFO_APPLE:5,ITMW_1H_BAU_AXE:1">';
        html += '</div>';
        return html;
    }

    function humanCycle(key, dir) {
        var h = state.humanCreator;
        if (key === "gender") { h.gender = cycleIndex(h.gender, dir, HUMAN_OPTIONS.gender.length); h.head = 0; h.face = 0; }
        else if (key === "race") { h.race = cycleIndex(h.race, dir, HUMAN_OPTIONS.race.length); h.face = 0; }
        else if (key === "head") h.head = cycleIndex(h.head, dir, humanHeadList(h).length);
        else if (key === "face") h.face = cycleIndex(h.face, dir, humanFaceList(h).length);
        else if (key === "fatness") h.fatnessIndex = cycleIndex(h.fatnessIndex, dir, HUMAN_OPTIONS.fatness.length);
        else if (key === "outfit") h.outfit = cycleIndex(h.outfit, dir, HUMAN_OPTIONS.outfit.length);
        else if (key === "weapon") h.weaponIndex = cycleIndex(h.weaponIndex, dir, HUMAN_OPTIONS.weapon.length);
        applyHumanChoice();
        syncHumanPreview();
    }

    function humanPayload(includePosition) {
        applyHumanChoice();
        var h = state.humanCreator;
        var payload = {
            mode: "human",
            instance: h.instance,
            bodyModel: h.bodyModel,
            bodyTex: +h.bodyTex || 0,
            headModel: h.headModel,
            headTex: +h.headTex || 0,
            fatness: +h.fatness || 0,
            weapon: h.weapon || "",
            armor: h.armor || "",
            ranged: h.ranged || "",
            cameraMode: h.cameraMode || "orbital"
        };
        payload.aggroRadius = +h.aggroRadius || 900;
        payload.teacherSkills = h.teacherSkills || "";
        payload.teachCost = +h.teachCost || 100;
        if (includePosition !== false && humanHasPosition()) {
            payload.posX = +h.posX || 0;
            payload.posY = +h.posY || 0;
            payload.posZ = +h.posZ || 0;
            payload.angle = +h.angle || 0;
            payload.world = h.world || "";
        }
        return payload;
    }

    function npcPayload(includePosition) {
        var n = state.npcForm;
        var catalog = catalogEditRow();
        var payload = {
            mode: "npc",
            instance: n.instance,
            name: n.name || "",
            kind: n.kind || "monster",
            hostile: +n.hostile || 0,
            respawnSec: +n.respawnSec || 0,
            baseExperience: catalog ? (+catalog.baseExperience || 0) : 0,
            tag: n.tag || "",
            cameraMode: n.cameraMode || "orbital"
        };
        if (includePosition !== false && npcHasPosition()) {
            payload.posX = +n.posX || 0;
            payload.posY = +n.posY || 0;
            payload.posZ = +n.posZ || 0;
            payload.angle = +n.angle || 0;
            payload.world = n.world || "";
        }
        return payload;
    }

    function catalogEditRow() {
        var inst = state.npcCatalogEdit || state.npcForm.instance || "";
        return (state.npcCatalog || []).filter(function (x) {
            return String(x.instance || "").toUpperCase() === String(inst || "").toUpperCase();
        })[0] || null;
    }

    function syncNpcPreview() {
        if (!state.npcForm.preview || !state.npcForm.instance) return;
        send("adminNpcPreviewUpdate", npcPayload());
    }

    function syncHumanPreview() {
        if (!state.humanCreator.preview) return;
        send("adminNpcPreviewUpdate", humanPayload());
    }

    function shouldSyncHumanPreview(key) {
        return ["gender", "race", "head", "face", "fatness", "bodyModel", "bodyTex", "headModel", "headTex", "fatnessIndex", "voice", "scaleX", "scaleY", "scaleZ", "weapon", "armor", "ranged", "idleAnimation", "posX", "posY", "posZ", "angle", "world", "cameraMode"].indexOf(key) >= 0;
    }

    function setStatus(text, kind) {
        state.status = text ? { text: text, kind: kind || "" } : null;
        render();
    }

    function isEditingField() {
        return !!(body && document.activeElement && body.contains(document.activeElement) && document.activeElement.matches("input, textarea, select"));
    }

    function flushPendingRender() {
        if (!renderPending || isEditingField()) return;
        renderPending = false;
        render(true);
    }

    function escapeHtml(s) {
        if (s == null) return "";
        return String(s).replace(/[&<>"']/g, function (c) {
            return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
        });
    }

    function build() {
        panel = document.getElementById("phoenix-adminpanel");
        if (!panel) return;
        if (!panel.dataset.wheelGuard) {
            panel.dataset.wheelGuard = "1";
            panel.addEventListener("wheel", function (event) { event.stopPropagation(); }, true);
        }
        body = panel.querySelector("[data-role='adminpanel-body']");
        tabsEl = panel.querySelector("[data-role='adminpanel-tabs']");
        var closeBtn = panel.querySelector("#adminpanel-close");
        if (closeBtn) closeBtn.addEventListener("click", close);
        var tools = panel.querySelector(".phoenix-adminpanel__tools");
        if (tools && !panel.querySelector("#adminpanel-collapse")) {
            var collapseBtn = document.createElement("button");
            collapseBtn.className = "phoenix-adminpanel__collapse";
            collapseBtn.id = "adminpanel-collapse";
            collapseBtn.type = "button";
            collapseBtn.addEventListener("click", togglePanelCollapsed);
            tools.insertBefore(collapseBtn, closeBtn || null);
        }
        ensureTooltip();
        panel.classList.add("phoenix-adminpanel--dark");
        syncPanelCollapsed();
        buildTabs();
    }

    function syncPanelCollapsed() {
        if (!panel) return;
        panel.classList.toggle("phoenix-adminpanel--body-collapsed", !!panelCollapsed);
        var btn = panel.querySelector("#adminpanel-collapse");
        if (btn) {
            btn.textContent = panelCollapsed ? "<" : ">";
            btn.title = t(panelCollapsed ? "admin.panel.showBody" : "admin.panel.hideBody");
            btn.setAttribute("aria-label", btn.title);
        }
    }

    function togglePanelCollapsed() {
        panelCollapsed = !panelCollapsed;
        syncPanelCollapsed();
    }

    function loadRenderDebug() {
        try {
            var raw = localStorage.getItem("phoenix:admin-item-render-debug");
            if (!raw) return;
            var parsed = JSON.parse(raw);
            if (parsed.__presetVersion !== RENDER_DEBUG_VERSION) { saveRenderDebug(); return; }
            ["rotX", "rotY", "rotZ", "scale", "light"].forEach(function (k) {
                if (parsed[k] != null && !isNaN(+parsed[k])) state.itemRenderDebug[k] = +parsed[k];
            });
        } catch (e) {}
    }

    function saveRenderDebug() {
        try {
            var payload = { __presetVersion: RENDER_DEBUG_VERSION };
            ["rotX", "rotY", "rotZ", "scale", "light"].forEach(function (k) { payload[k] = state.itemRenderDebug[k]; });
            localStorage.setItem("phoenix:admin-item-render-debug", JSON.stringify(payload));
        } catch (e) {}
    }

    function ensureTooltip() {
        if (tooltipEl) return;
        tooltipEl = document.createElement("div");
        tooltipEl.id = "adm-tooltip";
        tooltipEl.className = "adm-tooltip";
        document.body.appendChild(tooltipEl);
    }

    function open() {
        if (!isAdmin) return;
        if (!panel) build();
        if (!panel) return;
        isOpen = true;
        panel.removeAttribute("hidden");
        syncPanelCollapsed();
        document.body.classList.add("phoenix-admin-open");
        try { bridge.send("phoenix:menu:open", {}); } catch (e) {}
        try { bridge.send("phoenix:admin:request", { action: "adminPanelOpen", payload: null }); } catch (e) {}
        try { if (global.app && global.app.renderLangSwitcher) global.app.renderLangSwitcher(); } catch (e) {}
        send("players");
        send("schemes");
        send("bans");
        send("log", { limit: 100 });
        if (activeTab === "npc" || activeTab === "herbs") { send("herbCatalog"); send("herbList"); }
        if (activeTab === "vobs") { requestVobCatalog(); send("vobList"); }
        if (activeTab === "houses") send("houseList");
        render();
    }

    function close() {
        if (!isOpen) return;
        isOpen = false;
        if (panel) panel.setAttribute("hidden", "");
        document.body.classList.remove("phoenix-admin-open");
        hideTooltip();
        send("adminNpcPreviewStop", {});
        send("adminHerbPreviewStop", {});
        send("adminVobPreviewStop", {});
        try { bridge.send("phoenix:menu:close", {}); } catch (e) {}
        try { bridge.send("phoenix:admin:request", { action: "adminPanelClose", payload: null }); } catch (e) {}
    }

    function buildTabs() {
        if (!tabsEl) return;
        tabsEl.innerHTML = "";
        TABS.forEach(function (tab) {
            var b = document.createElement("button");
            b.type = "button";
            b.className = "phoenix-adminpanel__tab" + (tab.id === activeTab ? " is-active" : "");
            b.textContent = t(tab.labelKey, tab.fallback);
            b.addEventListener("click", function () {
                activeTab = tab.id;
                buildTabs();
                if (tab.id === "log") send("log", { limit: 100 });
                if (tab.id === "bans") send("bans");
                if (tab.id === "items") { send("players"); send("schemes"); }
                if (tab.id === "inv") send("players");
                if (tab.id === "npc") { send("npcCatalog"); send("npcList"); send("npcPresetList"); send("herbCatalog"); send("herbList"); }
                if (tab.id === "herbs") { send("herbCatalog"); send("herbList"); }
                if (tab.id === "vobs") { requestVobCatalog(); send("vobList"); }
                if (tab.id === "houses") send("houseList");
                render();
            });
            tabsEl.appendChild(b);
        });
    }

    function render(force) {
        if (!body || !isOpen) return;
        if (!force && isEditingField()) {
            renderPending = true;
            return;
        }
        renderPending = false;
        var html = "";
        if (activeTab === "players") html = renderPlayers();
        else if (activeTab === "items") html = renderItems();
        else if (activeTab === "custom") html = renderCustom();
        else if (activeTab === "bans") html = renderBans();
        else if (activeTab === "inv") html = renderInventory();
        else if (activeTab === "npc") html = renderNpc();
        else if (activeTab === "herbs") html = renderHerbs();
        else if (activeTab === "vobs") html = renderVobs();
        else if (activeTab === "houses") html = renderHouses();
        else if (activeTab === "debug") html = renderDebug();
        else if (activeTab === "log") html = renderLog();

        if (state.status) {
            html += '<div class="adm-status' + (state.status.kind ? " is-" + state.status.kind : "") + '">' +
                escapeHtml(state.status.text) + "</div>";
        }
        body.innerHTML = html;
        bindHandlers();
        if (activeTab === "items" || activeTab === "npc" || activeTab === "vobs") populateItemMeshes();
    }

    function renderPlayers() {
        var rows = state.players || [];
        var f = (state.playerFilter || "").toLowerCase();
        if (f) rows = rows.filter(function (p) {
            return (p.accountName || "").toLowerCase().indexOf(f) >= 0
                || (p.characterName || "").toLowerCase().indexOf(f) >= 0
                || (p.name || "").toLowerCase().indexOf(f) >= 0
                || String(p.playerId) === f;
        });
        var html = '<div class="adm-section">';
        html += '<div class="adm-toolbar">';
        html += '<input type="text" class="adm-search" data-role="player-filter" value="' +
            escapeHtml(state.playerFilter) + '" placeholder="' + escapeHtml(t("admin.players.filter")) + '">';
        html += '<button class="adm-btn" data-action="refresh-players">' + escapeHtml(t("admin.common.refresh")) + '</button>';
        html += "</div>";

        var sel = state.playerSelectedPid != null
            ? rows.filter(function (p) { return p.playerId === state.playerSelectedPid; })[0]
            : null;
        if (sel) html += renderPlayerCard(sel);

        if (!rows.length) {
            html += '<div class="adm-empty">' + escapeHtml(t("admin.players.empty")) + '</div></div>';
            return html;
        }
        html += '<table class="adm-table"><thead><tr>' +
            "<th>PID</th><th>" + escapeHtml(t("admin.players.account")) + "</th><th>" + escapeHtml(t("admin.players.character")) + "</th><th>" + escapeHtml(t("admin.players.level")) + "</th><th>HP</th><th>" + escapeHtml(t("admin.players.gold")) + "</th><th>" + escapeHtml(t("admin.players.world")) + "</th><th>" + escapeHtml(t("admin.players.actions")) + "</th>" +
            "</tr></thead><tbody>";
        rows.forEach(function (p) {
            html += '<tr data-action="select-player" data-pid="' + p.playerId + '" style="cursor:pointer">';
            html += "<td>" + p.playerId + "</td>";
            html += "<td>" + escapeHtml(p.accountName) +
                (p.role === 1 ? " <span style='color:#d4af37' title='Admin'>★</span>" : "") +
                (p.vanished ? " <span style='color:#b8c8ff' title='Vanish'>👻</span>" : "") + "</td>";
            html += "<td>" + escapeHtml(p.characterName || "—") + "</td>";
            html += "<td>" + (p.level || 0) + "</td>";
            html += "<td>" + (p.hp || 0) + "/" + (p.hpMax || 0) + "</td>";
            html += "<td>" + (p.gold || 0) + "</td>";
            html += "<td>" + escapeHtml(p.world) + "</td>";
            html += '<td><div class="adm-actions" data-stop>';
            html += '<button class="adm-btn" data-action="tp-to" data-pid="' + p.playerId + '" title="Idź do gracza">→</button>';
            html += '<button class="adm-btn" data-action="tp-here" data-pid="' + p.playerId + '" title="Przyzwij gracza">←</button>';
            if (p.characterId) {
                html += '<button class="adm-btn" data-action="give-pick" data-cid="' + p.characterId + '" data-name="' + escapeHtml(p.characterName) + '">Daj</button>';
                html += '<button class="adm-btn" data-action="inspect-inv" data-cid="' + p.characterId + '" data-name="' + escapeHtml(p.characterName) + '">EQ</button>';
            } else {
                html += '<button class="adm-btn" disabled title="' + escapeHtml(t("admin.status.noChars")) + '">' + escapeHtml(t("admin.items.give")) + '</button>';
                html += '<button class="adm-btn" disabled title="' + escapeHtml(t("admin.status.noChars")) + '">EQ</button>';
            }
            html += '<button class="adm-btn adm-btn--danger" data-action="kick" data-pid="' + p.playerId + '" data-name="' + escapeHtml(p.characterName || p.accountName) + '">Kick</button>';
            html += '<button class="adm-btn adm-btn--danger" data-action="ban-pick" data-pid="' + p.playerId + '" data-aid="' + p.accountId + '" data-cid="' + p.characterId + '" data-name="' + escapeHtml(p.accountName) + '">Ban</button>';
            html += "</div></td></tr>";
        });
        html += "</tbody></table></div>";
        return html;
    }

    function renderDebug() {
        var html = '<div class="adm-section">';
        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.debug.playerNpc.title")) + '</h4>';
        html += '<p class="adm-muted">' + escapeHtml(t("admin.debug.playerNpc.desc")) + '</p>';
        html += '<div class="adm-toolbar">';
        html += '<button class="adm-btn adm-btn--primary" data-action="spawn-test-player-npc">' + escapeHtml(t("admin.debug.playerNpc.spawn")) + '</button>';
        html += '</div></div>';
        html += '</div>';
        return html;
    }

    function renderPlayerCard(p) {
        var html = '<div class="adm-player-card">';
        html += '<div class="adm-player-card__col">';
        html += '<h4>' + escapeHtml(t("admin.players.account")) + '</h4>';
        html += field(t("admin.players.accountId"), p.accountId);
        html += field("Login", p.accountName);
        html += field(t("admin.players.role"), p.role === 1
            ? '<span class="adm-player-card__role-admin">Administrator ★</span>'
            : t("admin.players.player"), true);
        html += field("Vanish", p.vanished
            ? '<span class="adm-player-card__vanish">' + escapeHtml(t("admin.players.hidden")) + '</span>'
            : t("admin.players.visible"), true);
        html += "</div>";

        html += '<div class="adm-player-card__col">';
        html += '<h4>' + escapeHtml(t("admin.players.character")) + '</h4>';
        html += field(t("admin.players.characterId"), p.characterId || "—");
        html += field(t("admin.players.name"), p.characterName || "—");
        html += field(t("admin.players.level"), p.level || 0);
        html += field("HP", (p.hp || 0) + " / " + (p.hpMax || 0));
        html += field(t("admin.players.gold"), p.gold || 0);
        html += field(t("admin.players.items"), p.itemCount || 0);
        html += "</div>";

        html += '<div class="adm-player-card__col">';
        html += '<h4>' + escapeHtml(t("admin.players.network")) + '</h4>';
        html += field("PID", p.playerId);
        html += field("IP", p.ip || "—");
        html += field("Serial", short(p.serial, 16));
        html += field("Ping", (p.ping || 0) + " ms");
        html += field(t("admin.players.world"), short(p.world, 18));
        html += field("Pos", Math.round(p.posX) + " " + Math.round(p.posY) + " " + Math.round(p.posZ));
        html += "</div>";
        html += "</div>";
        return html;
    }

    function field(label, value, raw) {
        return '<div class="adm-player-card__field"><span>' + escapeHtml(label) + "</span><b>" +
            (raw ? value : escapeHtml(String(value))) + "</b></div>";
    }
    function short(s, n) { s = String(s || ""); return s.length > n ? s.slice(0, n) + "…" : s; }

    function renderItems() {
        var rows = state.schemes || [];
        var f = (state.schemeFilter || "").toLowerCase();
        var cf = +state.schemeCategoryFilter || 0;
        if (f) rows = rows.filter(function (s) {
            return s.instance.toLowerCase().indexOf(f) >= 0 ||
                itemName(s).toLowerCase().indexOf(f) >= 0;
        });
        if (cf > 0) rows = rows.filter(function (s) { return s.category === cf; });
        rows = rows.slice(0, 600);

        var target = state.giveTarget;
        var html = '<div class="adm-section"><h3>' + escapeHtml(t("admin.items.giveTitle")) + '</h3>';
        html += '<div class="adm-form">';
        html += '<label>' + escapeHtml(t("admin.items.target")) + '</label><select data-bind="giveTarget-cid">';
        html += '<option value="">' + escapeHtml(t("admin.items.pickPlayer")) + '</option>';
        (state.players || []).forEach(function (p) {
            if (!p.characterId) return;
            var sel = (target && target.cid === p.characterId) ? " selected" : "";
            html += '<option value="' + p.characterId + '" data-name="' + escapeHtml(p.characterName) + '"' + sel + '>' +
                escapeHtml(p.characterName + " (#" + p.characterId + " / " + p.accountName + ")") + "</option>";
        });
        html += "</select>";
        var selSch = state.selectedScheme ? state.schemesById[state.selectedScheme] : null;
        var selName = selSch ? itemName(selSch) : "";
        html += '<label>' + escapeHtml(t("admin.items.item")) + '</label><div>';
        if (selSch) {
            html += '<div class="adm-pick"><b style="color:#f0d785">' + escapeHtml(selName) + '</b>' +
                ' <span style="color:#8a7c5a;font-size:11px">[' + escapeHtml(selSch.instance) + ']</span></div>';
        } else {
            html += '<div class="adm-pick adm-pick--empty">' + escapeHtml(t("admin.items.pickBelow")) + '</div>';
        }
        html += '<input type="text" data-bind="selectedScheme" value="' +
            escapeHtml(state.selectedScheme || "") + '" placeholder="' + escapeHtml(t("admin.items.manualInstance")) + '" style="width:100%;margin-top:4px">';
        html += '</div>';
        html += '<label>' + escapeHtml(t("admin.items.amount")) + '</label><input type="number" data-bind="giveAmount" min="1" value="' + state.giveAmount + '">';
        html += '<label>' + escapeHtml(t("admin.items.quality")) + '</label><input type="number" data-bind="giveQuality" min="0" max="5" value="' + state.giveQuality + '">';
        html += '<label>' + escapeHtml(t("admin.items.upgrade")) + '</label><input type="number" data-bind="giveUpgrade" min="0" max="9" value="' + state.giveUpgrade + '">';
        html += '<div class="adm-form__row">';
        html += '<button class="adm-btn adm-btn--primary" data-action="give-submit">' + escapeHtml(t("admin.items.give")) + '</button>';
        html += "</div></div></div>";

        html += '<div class="adm-section"><h3>' + escapeHtml(t("admin.items.schemes")) + ' (' + (state.schemes || []).length + ")</h3>";
        html += renderItemRenderDebug();
        html += '<div class="adm-toolbar">';
        html += '<input type="text" class="adm-search" data-role="scheme-filter" value="' +
            escapeHtml(state.schemeFilter) + '" placeholder="' + escapeHtml(t("admin.items.search")) + '">';
        html += '<select data-role="scheme-cat" style="padding:5px 8px;background:rgba(0,0,0,0.5);border:1px solid rgba(165,112,14,0.4);color:#f0e0c0;font-size:12px"><option value="0">' + escapeHtml(t("admin.items.allCategories")) + '</option>';
        Object.keys(CATEGORY_LABELS).forEach(function (k) {
            if (k === "0") return;
            var sel = +k === cf ? " selected" : "";
            html += '<option value="' + k + '"' + sel + '>' + escapeHtml(catLabel(k)) + "</option>";
        });
        html += "</select></div>";

        html += '<div class="adm-itemgrid" data-role="itemgrid">';
        rows.forEach(function (s) {
            var sel = state.selectedScheme === s.instance ? " is-selected" : "";
            var nm = itemName(s);
            html += '<div class="adm-itemcell' + sel + '" data-instance="' + escapeHtml(s.instance) +
                '" data-visual="' + escapeHtml(s.visual || "") + '" title="' + escapeHtml(nm) + '">';
            html += '<div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' +
                escapeHtml(nm.slice(0, 18)) + "</span></div>";
            html += '<span class="adm-itemcell__cat">' + escapeHtml(catLabel(s.category)) + "</span>";
            html += "</div>";
        });
        html += "</div></div>";
        return html;
    }

    function renderDebugSlider(key, label, min, max, step) {
        var value = state.itemRenderDebug[key];
        return '<label class="adm-render-debug__control"><span>' + escapeHtml(label) + '</span><input type="range" min="' + min + '" max="' + max + '" step="' + step + '" data-render-debug="' + key + '" value="' + value + '"><b>' + (+value).toFixed(key === "scale" || key === "light" ? 2 : 3) + '</b></label>';
    }

    function renderItemRenderDebug() {
        var sch = state.selectedScheme ? state.schemesById[state.selectedScheme] : null;
        var title = sch ? itemName(sch) : "Wybierz item z grida";
        var visual = sch && sch.visual ? sch.visual : "";
        var d = state.itemRenderDebug;
        var html = '<div class="adm-render-debug">';
        html += '<div class="adm-render-debug__preview">';
        if (visual) {
            html += '<gothic-render width="180" height="180" rot-x="' + d.rotX + '" rot-y="' + d.rotY + '" rot-z="' + d.rotZ + '" scale="' + d.scale + '" light-intensity="' + d.light + '" visual="' + escapeHtml(visual) + '"></gothic-render>';
        } else {
            html += '<div class="adm-render-debug__empty">Brak visuala</div>';
        }
        html += '</div><div class="adm-render-debug__body"><h4>Render debug</h4><p><b>' + escapeHtml(title) + '</b>' + (sch ? ' <small>[' + escapeHtml(sch.instance) + ']</small>' : '') + '</p>';
        html += '<div class="adm-render-debug__grid">' + renderDebugSlider("rotX", "rot-x", -3.142, 3.142, 0.01) + renderDebugSlider("rotY", "rot-y", -3.142, 3.142, 0.01) + renderDebugSlider("rotZ", "rot-z", -3.142, 3.142, 0.01) + renderDebugSlider("scale", "scale", 0.2, 3, 0.05) + renderDebugSlider("light", "light", 0.2, 3, 0.05) + '</div>';
        html += '<div class="adm-render-debug__values">rot-x=' + d.rotX.toFixed(3) + ' rot-y=' + d.rotY.toFixed(3) + ' rot-z=' + d.rotZ.toFixed(3) + ' scale=' + d.scale.toFixed(2) + ' light=' + d.light.toFixed(2) + '</div>';
        html += '</div></div>';
        return html;
    }

    var meshQueue = {
        pending: [], active: 0, gen: 0,
        schedule: function (cell, visual) { this.pending.push({ gen: this.gen, cell: cell, visual: visual }); this._tick(); },
        reset: function () { this.gen++; this.pending.length = 0; },
        _tick: function () {
            var self = this;
            while (self.active < 1 && self.pending.length) {
                var task = self.pending.shift();
                if (task.gen !== self.gen) continue;
                self._run(task);
            }
        },
        _run: function (task) {
            var self = this;
            self.active++;
            var cell = task.cell;
            if (!cell || !cell.isConnected || task.gen !== self.gen) {
                self.active--; setTimeout(function () { self._tick(); }, 25); return;
            }
            var fallback = cell.querySelector(".adm-itemcell__fallback");
            var el = document.createElement("gothic-render");
            el.setAttribute("width", "96"); el.setAttribute("height", "96");
            el.setAttribute("rot-x", String(state.itemRenderDebug.rotX)); el.setAttribute("rot-y", String(state.itemRenderDebug.rotY)); el.setAttribute("rot-z", String(state.itemRenderDebug.rotZ));
            el.setAttribute("scale", String(state.itemRenderDebug.scale)); el.setAttribute("light-intensity", String(state.itemRenderDebug.light));
            el.style.position = "absolute"; el.style.inset = "0"; el.style.zIndex = "1";
            cell.appendChild(el);
            cell.dataset.meshLoaded = "0";
            var done = false;
            var finish = function (ok) {
                if (done) return; done = true;
                clearTimeout(wd);
                try { obs.disconnect(); } catch (e) {}
                if (ok) {
                    if (fallback) { fallback.style.display = "none"; }
                    cell.dataset.meshLoaded = "1";
                } else {
                    try { el.remove(); } catch (e) {}
                }
                self.active--;
                setTimeout(function () { self._tick(); }, 25);
            };
            var obs = new MutationObserver(function () {
                if (el.querySelector("canvas")) finish(true);
                else if (el.childElementCount === 0) finish(false);
            });
            obs.observe(el, { childList: true });
            var wd = setTimeout(function () { finish(false); }, 1500);
            el.setAttribute("visual", task.visual);
        }
    };

    function populateItemMeshes() {
        meshQueue.reset();
        var grids = body.querySelectorAll("[data-role='itemgrid'],[data-role='vobgrid']");
        grids.forEach(function (grid) {
            var cells = grid.querySelectorAll(".adm-itemcell");
            cells.forEach(function (cell) {
                var v = cell.dataset.previewVisual || cell.dataset.visual;
                if (!v) return;
                meshQueue.schedule(cell, v);
            });
        });
    }

    function renderCustom() {
        var c = state.custom;
        var html = '<div class="adm-section"><h3>' + escapeHtml(t("admin.custom.title")) + '</h3>';
        html += '<p style="color:#8a7c5a;font-size:11px;margin-bottom:10px">' + escapeHtml(t("admin.custom.description")) + '</p>';
        html += '<div class="adm-form">';
        html += '<label>' + escapeHtml(t("admin.custom.field.instance")) + '</label><input type="text" data-cbind="instance" value="' + escapeHtml(c.instance) + '" placeholder="PHX_CUSTOM_SWORD_01" maxlength="64">';
        html += '<label>' + escapeHtml(t("admin.custom.field.name")) + '</label><input type="text" data-cbind="name" value="' + escapeHtml(c.name) + '" placeholder="' + escapeHtml(t("admin.custom.placeholder.name")) + '">';
        html += '<label>' + escapeHtml(t("admin.custom.field.description")) + '</label><textarea data-cbind="description" placeholder="' + escapeHtml(t("admin.custom.placeholder.description")) + '">' + escapeHtml(c.description) + "</textarea>";
        html += '<label>Visual (.MRM/.MMB)</label><input type="text" data-cbind="visual" value="' + escapeHtml(c.visual) + '" placeholder="ITMW_035_1H_SWORD_04.MRM">';
        html += '<label>' + escapeHtml(t("admin.npc.col.category")) + '</label>' + categorySelect("category", c.category);
        html += '<label>Slot</label>' + slotSelect("slot", c.slot);
        html += '<label>' + escapeHtml(t("admin.custom.field.value")) + '</label><input type="number" data-cbind="value" value="' + c.value + '" min="0">';
        html += '<label>' + escapeHtml(t("admin.custom.field.weight")) + '</label><input type="number" data-cbind="weight" value="' + c.weight + '" min="0" step="0.1">';
        html += '<label>' + escapeHtml(t("admin.custom.field.stackMax")) + '</label><input type="number" data-cbind="stackMax" value="' + c.stackMax + '" min="1">';
        html += '<label>' + escapeHtml(t("inv.stat.damage")) + '</label><input type="number" data-cbind="damage" value="' + c.damage + '" min="0">';
        html += '<label>' + escapeHtml(t("admin.custom.field.damageType")) + '</label>' + damageTypeSelect("damageType", c.damageType);
        html += '<label>' + escapeHtml(t("inv.stat.prot.edge")) + '</label><input type="number" data-cbind="protEdge" value="' + c.protEdge + '" min="0">';
        html += '<label>' + escapeHtml(t("inv.stat.prot.blunt")) + '</label><input type="number" data-cbind="protBlunt" value="' + c.protBlunt + '" min="0">';
        html += '<label>' + escapeHtml(t("inv.stat.prot.point")) + '</label><input type="number" data-cbind="protPoint" value="' + c.protPoint + '" min="0">';
        html += '<label>' + escapeHtml(t("inv.stat.prot.fire")) + '</label><input type="number" data-cbind="protFire" value="' + c.protFire + '" min="0">';
        html += '<label>' + escapeHtml(t("inv.stat.prot.magic")) + '</label><input type="number" data-cbind="protMagic" value="' + c.protMagic + '" min="0">';
        html += '<div class="adm-form__row">';
        html += '<button class="adm-btn" data-action="custom-reset">' + escapeHtml(t("admin.common.reset")) + '</button>';
        html += '<button class="adm-btn adm-btn--primary" data-action="custom-save">' + escapeHtml(t("admin.custom.btn.save")) + '</button>';
        html += "</div></div></div>";
        return html;
    }

    function categorySelect(bind, current) {
        var html = '<select data-cbind="' + bind + '">';
        Object.keys(CATEGORY_LABELS).forEach(function (k) {
            html += '<option value="' + k + '"' + (+k === +current ? " selected" : "") + ">" + escapeHtml(catLabel(k)) + "</option>";
        });
        return html + "</select>";
    }
    function slotSelect(bind, current) {
        var html = '<select data-cbind="' + bind + '">';
        Object.keys(SLOT_LABELS).forEach(function (k) {
            html += '<option value="' + k + '"' + (+k === +current ? " selected" : "") + ">" + escapeHtml(slotLabel(k)) + "</option>";
        });
        return html + "</select>";
    }
    function damageTypeSelect(bind, current) {
        var html = '<select data-cbind="' + bind + '">';
        Object.keys(DAMAGE_TYPES).forEach(function (k) {
            html += '<option value="' + k + '"' + (+k === +current ? " selected" : "") + ">" + escapeHtml(damageLabel(k)) + "</option>";
        });
        return html + "</select>";
    }

    function renderBans() {
        var rows = state.bans || [];
        var html = '<div class="adm-section"><h3>' + escapeHtml(t("admin.bans.active")) + '</h3>';
        html += '<div class="adm-toolbar"><button class="adm-btn" data-action="refresh-bans">' + escapeHtml(t("admin.common.refresh")) + '</button></div>';
        if (!rows.length) { html += '<div class="adm-empty">' + escapeHtml(t("admin.bans.empty")) + '</div></div>'; return html; }
        html += '<table class="adm-table"><thead><tr><th>ID</th><th>' + escapeHtml(t("admin.bans.scope")) + '</th><th>' + escapeHtml(t("admin.players.account")) + '</th><th>' + escapeHtml(t("admin.players.character")) + '</th><th>IP</th><th>Serial</th><th>' + escapeHtml(t("admin.bans.reason")) + '</th><th>' + escapeHtml(t("admin.bans.expires")) + '</th><th></th></tr></thead><tbody>';
        rows.forEach(function (b) {
            var exp = b.expiresAt ? new Date(b.expiresAt * 1000).toISOString().replace("T", " ").slice(0, 19) : "perma";
            html += "<tr>";
            html += "<td>" + b.id + "</td>";
            html += "<td>" + (BAN_SCOPES[b.scope] || b.scope) + "</td>";
            html += "<td>" + (b.accountId || "") + "</td>";
            html += "<td>" + (b.characterId || "") + "</td>";
            html += "<td>" + escapeHtml(b.ipAddress || "") + "</td>";
            html += "<td>" + escapeHtml(short(b.serial, 18)) + "</td>";
            html += "<td>" + escapeHtml(b.reason || "") + "</td>";
            html += "<td>" + exp + "</td>";
            html += '<td><button class="adm-btn adm-btn--danger" data-action="unban" data-id="' + b.id + '">' + escapeHtml(t("admin.bans.unban")) + '</button></td>';
            html += "</tr>";
        });
        html += "</tbody></table></div>";
        return html;
    }

    function renderInventory() {
        var inv = state.inv;
        var html = '<div class="adm-section"><h3>' + escapeHtml(t("admin.inv.title")) + '</h3>';
        if (!inv) { html += '<div class="adm-empty">' + escapeHtml(t("admin.inv.pick")) + '</div></div>'; return html; }
        html += "<p>" + escapeHtml(t("admin.players.character")) + " #" + inv.characterId + " · " + escapeHtml(t("admin.players.gold")) + ": <b>" + (inv.gold || 0) + "</b> · " + escapeHtml(t("admin.inv.itemCount")) + ": <b>" + (inv.items.length || 0) + "</b></p>";
        if (!inv.items.length) { html += '<div class="adm-empty">' + escapeHtml(t("admin.inv.empty")) + '</div></div>'; return html; }
        html += '<table class="adm-table"><thead><tr><th>ID</th><th>' + escapeHtml(t("admin.npc.col.instance")) + '</th><th>' + escapeHtml(t("admin.items.amount")) + '</th><th>' + escapeHtml(t("admin.items.qualityShort")) + '</th><th>' + escapeHtml(t("admin.items.upgradeShort")) + '</th><th>Slot</th></tr></thead><tbody>';
        inv.items.forEach(function (i) {
            html += "<tr><td>" + i.id + "</td><td><code>" + escapeHtml(i.instance) + "</code></td><td>" +
                i.amount + "</td><td>" + i.quality + "</td><td>+" + i.upgrade + "</td><td>" + (i.slot || 0) + "</td></tr>";
        });
        html += "</tbody></table></div>";
        return html;
    }

    function renderLog() {
        var rows = state.log || [];
        var html = '<div class="adm-section"><h3>' + escapeHtml(t("admin.log.title")) + '</h3>';
        html += '<div class="adm-toolbar"><button class="adm-btn" data-action="refresh-log">' + escapeHtml(t("admin.common.refresh")) + '</button></div>';
        if (!rows.length) { html += '<div class="adm-empty">' + escapeHtml(t("admin.log.empty")) + '</div></div>'; return html; }
        html += '<div class="adm-log">';
        rows.forEach(function (e) {
            var when = e.createdAt ? new Date(e.createdAt * 1000).toISOString().replace("T", " ").slice(0, 19) : "";
            var danger = (e.action === "kick" || e.action === "ban" || e.action === "unban");
            html += '<div class="adm-log__entry">';
            html += '<span class="adm-log__time">' + escapeHtml(when) + "</span>";
            html += '<span class="adm-log__action' + (danger ? " is-danger" : "") + '">' + escapeHtml(e.action) + "</span>";
            html += '<span class="adm-log__admin">' + escapeHtml(e.adminName || ("#" + (e.adminId || "?"))) + "</span>";
            html += '<span class="adm-log__details">' +
                (e.targetName ? "<b>" + escapeHtml(e.targetName) + "</b> " : "") +
                (e.targetId ? "(#" + e.targetId + ") " : "") +
                escapeHtml(e.details || "") + "</span>";
            html += "</div>";
        });
        html += "</div></div>";
        return html;
    }

    function renderNpc() {
        var view = state.npcView || "presets";
        var presets = state.npcPresets || [];
        var spawns = state.npcSpawns || [];
        var herbs = state.herbSpots || [];
        var html = '<div class="adm-section">';
        html += '<div class="adm-tabs adm-tabs--sub">';
        var subTabs = [
            ["catalog", t("admin.npc.subtab.catalog")],
            ["human", t("admin.npc.subtab.human")],
            ["presets", t("admin.npc.subtab.presets")],
            ["editor",  t("admin.npc.subtab.editor")],
            ["active",  tFmt("admin.npc.subtab.active", spawns.length)],
            ["herbs", tFmt("admin.herbs.subtab", herbs.length)]
        ];
        subTabs.forEach(function (st) {
            var cls = "adm-tab" + (view === st[0] ? " is-active" : "");
            html += '<button class="' + cls + '" data-action="npc-view" data-view="' + st[0] + '">' + escapeHtml(st[1]) + '</button>';
        });
        html += '</div>';
        if (view === "catalog") html += renderNpcCatalog();
        else if (view === "human") html += renderHumanCreator();
        else if (view === "presets") html += renderNpcPresets(presets);
        else if (view === "editor") html += renderNpcEditor();
        else if (view === "herbs") html += renderHerbs();
        else html += renderNpcActive(spawns);
        html += '</div>';
        return html;
    }

    function herbLabel(entry) {
        if (!entry) return "";
        return tItem(entry.instance, "name", entry.labelPl || entry.name || entry.instance) || entry.labelPl || entry.name || entry.instance;
    }

    function applyHerbCatalogDefaults(instance) {
        var row = (state.herbCatalog || []).filter(function (h) { return h.instance === instance; })[0];
        if (!row) return;
        state.herbForm.gatherMs = row.gatherMs || state.herbForm.gatherMs;
        state.herbForm.cooldownSec = row.cooldownSec || state.herbForm.cooldownSec;
        state.herbForm.successChance = row.successChance || state.herbForm.successChance;
    }

    function herbPreviewPayload(includePosition) {
        var f = state.herbForm;
        var payload = { instance: f.instance || "" };
        if (includePosition !== false) {
            payload.posX = +f.posX || 0;
            payload.posY = +f.posY || 0;
            payload.posZ = +f.posZ || 0;
        }
        return payload;
    }

    function syncHerbPreview(includePosition) {
        if (!state.herbForm.instance) return;
        send("adminHerbPreviewUpdate", herbPreviewPayload(includePosition));
    }

    function renderHerbs() {
        var form = state.herbForm;
        var catalog = state.herbCatalog || [];
        var filter = (form.filter || "").toLowerCase();
        var filtered = filter ? catalog.filter(function (h) {
            return String(h.instance || "").toLowerCase().indexOf(filter) >= 0 || herbLabel(h).toLowerCase().indexOf(filter) >= 0;
        }) : catalog;
        var html = '<div class="adm-toolbar"><input class="adm-search" data-herb="filter" value="' + escapeHtml(form.filter) + '" placeholder="' + escapeHtml(t("admin.herbs.search")) + '"><button class="adm-btn" data-action="refresh-herbs">⟳</button></div>';
        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.herbs.placement")) + '</h4>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>' + escapeHtml(t("admin.vobs.field.instance")) + '<input class="adm-input" data-herb="instance" value="' + escapeHtml(form.instance) + '" placeholder="ITPL_HEALTH_HERB_01"></label>';
        html += '<label>' + escapeHtml(t("admin.herbs.field.spotId")) + '<input class="adm-input" data-herb="plantId" value="' + escapeHtml(form.plantId) + '" placeholder="' + escapeHtml(t("admin.common.auto")) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.vobs.field.world")) + '<input class="adm-input" data-herb="world" value="' + escapeHtml(form.world) + '" placeholder="' + escapeHtml(t("admin.vobs.placeholder.adminPosition")) + '"></label>';
        html += '<label>X<input class="adm-input" type="number" data-herb="posX" value="' + form.posX + '"></label>';
        html += '<label>Y<input class="adm-input" type="number" data-herb="posY" value="' + form.posY + '"></label>';
        html += '<label>Z<input class="adm-input" type="number" data-herb="posZ" value="' + form.posZ + '"></label>';
        html += '<label>' + escapeHtml(t("admin.herbs.field.gatherMs")) + '<input class="adm-input" type="number" data-herb="gatherMs" value="' + form.gatherMs + '"></label>';
        html += '<label>' + escapeHtml(t("admin.herbs.field.cooldownSec")) + '<input class="adm-input" type="number" data-herb="cooldownSec" value="' + form.cooldownSec + '"></label>';
        html += '<label>' + escapeHtml(t("admin.herbs.field.successChance")) + '<input class="adm-input" type="number" min="1" max="100" data-herb="successChance" value="' + form.successChance + '"></label>';
        html += '</div><div class="adm-toolbar" style="margin-top:10px"><button class="adm-btn" data-action="herb-preview">' + escapeHtml(t("admin.herbs.btn.preview")) + '</button><button class="adm-btn" data-action="herb-floor">' + escapeHtml(t("admin.vobs.btn.floor")) + '</button><button class="adm-btn adm-btn--primary" data-action="herb-save-here">' + escapeHtml(t("admin.vobs.btn.saveHere")) + '</button><button class="adm-btn adm-btn--primary" data-action="herb-save-pos">' + escapeHtml(t("admin.vobs.btn.savePreview")) + '</button><button class="adm-btn" data-action="herb-reset">' + escapeHtml(t("admin.common.reset")) + '</button></div>';
        html += '<div class="adm-toolbar" style="margin-top:8px">';
        [["x-","X-"],["x+","X+"],["y-","Y-"],["y+","Y+"],["z-","Z-"],["z+","Z+"],["ry-","Obrót-"],["ry+","Obrót+"]].forEach(function (b) { html += '<button class="adm-btn" data-action="herb-nudge" data-axis="' + b[0] + '">' + b[1] + '</button>'; });
        html += '</div></div>';
        if (filtered.length) {
            html += '<div class="adm-grid adm-grid--3">';
            filtered.slice(0, 180).forEach(function (h) {
                var picked = form.instance === h.instance ? " is-selected" : "";
                html += '<button class="adm-btn adm-btn--ghost' + picked + '" data-action="herb-pick" data-instance="' + escapeHtml(h.instance) + '"><b>' + escapeHtml(herbLabel(h)) + '</b><br><small>' + escapeHtml(h.instance) + ' · r' + (h.rarity || 1) + ' · ' + Math.round((h.cooldownSec || 0) / 60) + 'm</small></button>';
            });
            html += '</div>';
        }
        html += renderHerbSpots();
        return html;
    }

    function renderHerbSpots() {
        var spots = state.herbSpots || [];
        var html = '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.herbs.activeSpots")) + '</h4>';
        if (!spots.length) return html + '<div class="adm-empty">' + escapeHtml(t("admin.herbs.emptySpots")) + '</div></div>';
        html += '<div class="adm-table-wrap"><table class="adm-table"><thead><tr><th>ID</th><th>' + escapeHtml(t("admin.herbs.col.plant")) + '</th><th>' + escapeHtml(t("admin.vobs.field.world")) + '</th><th>' + escapeHtml(t("admin.vobs.col.position")) + '</th><th>Cooldown</th><th></th></tr></thead><tbody>';
        spots.forEach(function (s) {
            var pos = Math.round(s.x || 0) + ", " + Math.round(s.y || 0) + ", " + Math.round(s.z || 0);
            html += '<tr><td><code>' + escapeHtml(s.plantId || "") + '</code></td><td><b>' + escapeHtml(herbLabel(s)) + '</b><br><small>' + escapeHtml(s.instance || "") + '</small></td><td><small>' + escapeHtml(s.world || "") + '</small></td><td><small>' + pos + '</small></td><td>' + (s.cooldownSec || 0) + 's</td><td><div class="adm-actions"><button class="adm-btn" data-action="herb-edit" data-id="' + escapeHtml(s.plantId || "") + '">' + escapeHtml(t("admin.npc.btn.edit")) + '</button><button class="adm-btn adm-btn--danger" data-action="herb-delete" data-id="' + escapeHtml(s.plantId || "") + '">' + escapeHtml(t("admin.npc.btn.delete")) + '</button></div></td></tr>';
        });
        return html + '</tbody></table></div></div>';
    }

    function vobLabel(entry) {
        if (!entry) return "";
        return entry.name || entry.instance || entry.visual || "VOB";
    }

    function selectedVobCatalog() {
        var visual = String(state.vobForm.visual || "").toUpperCase();
        var inst = String(state.vobForm.instance || "").toUpperCase();
        return (state.vobCatalog || []).filter(function (v) {
            return (visual && String(v.visual || "").toUpperCase() === visual) || (inst && String(v.instance || "").toUpperCase() === inst);
        })[0] || null;
    }

    function vobPreviewPayload(includePosition) {
        var f = state.vobForm;
        var payload = { instance: f.instance || "", visual: f.visual || "", interactive: +f.interactive || 0 };
        if (includePosition !== false) {
            payload.posX = +f.posX || 0;
            payload.posY = +f.posY || 0;
            payload.posZ = +f.posZ || 0;
            payload.rotX = +f.rotX || 0;
            payload.rotY = +f.rotY || 0;
            payload.rotZ = +f.rotZ || 0;
        }
        return payload;
    }

    function requestVobCatalog() {
        var tab = VOB_SOURCE_TABS.filter(function (x) { return x.id === state.vobSource; })[0] || VOB_SOURCE_TABS[0];
        state.vobPageSize = tab.limit;
        send("vobCatalog", { filter: state.vobForm.filter || "", source: tab.id, category: state.vobCategory || "", limit: tab.limit, offset: state.vobPage * tab.limit });
    }

    function vobCategories(catalog) {
        var seen = {};
        var out = [];
        (catalog || []).forEach(function (v) {
            var category = String(v.category || "").trim();
            if (!category || seen[category]) return;
            seen[category] = true;
            out.push(category);
        });
        return out.sort(function (a, b) { return a.localeCompare(b); });
    }

    function vobCategoryStats(catalog) {
        var counts = {};
        (catalog || []).forEach(function (v) {
            var category = String(v.category || "").trim();
            if (!category) return;
            counts[category] = (counts[category] || 0) + 1;
        });
        return Object.keys(counts).sort(function (a, b) { return a.localeCompare(b); }).map(function (name) { return { name: name, count: counts[name] }; });
    }

    function syncVobPreview(includePosition) {
        if (!state.vobForm.visual && !state.vobForm.instance) return;
        send("adminVobPreviewUpdate", vobPreviewPayload(includePosition));
    }

    function renderVobPreviewBox() {
        var f = state.vobForm;
        var visual = f.visual || "";
        var previewVisual = (selectedVobCatalog() && selectedVobCatalog().previewVisual) ? selectedVobCatalog().previewVisual : vobPreviewVisual(visual);
        var html = '<div class="adm-render-debug adm-vob-preview">';
        html += '<div class="adm-render-debug__preview">';
        if (previewVisual) html += '<gothic-render width="180" height="180" rot-x="' + state.itemRenderDebug.rotX + '" rot-y="' + state.itemRenderDebug.rotY + '" rot-z="' + state.itemRenderDebug.rotZ + '" scale="' + state.itemRenderDebug.scale + '" light-intensity="' + state.itemRenderDebug.light + '" visual="' + escapeHtml(previewVisual) + '"></gothic-render>';
        else html += '<div class="adm-render-debug__empty">' + escapeHtml(t("admin.vobs.preview.empty")) + '</div>';
        html += '</div><div class="adm-render-debug__body"><h4>' + escapeHtml(t("admin.vobs.preview.title")) + '</h4>';
        html += '<p><b>' + escapeHtml(vobLabel(selectedVobCatalog()) || f.name || "VOB") + '</b>' + (visual ? ' <small>[' + escapeHtml(visual) + ']</small>' : '') + '</p>';
        html += '<div class="adm-render-debug__values" data-role="vob-preview-values">rot=' + Math.round(+f.rotX || 0) + ', ' + Math.round(+f.rotY || 0) + ', ' + Math.round(+f.rotZ || 0) + ' pos=' + Math.round(+f.posX || 0) + ', ' + Math.round(+f.posY || 0) + ', ' + Math.round(+f.posZ || 0) + '</div>';
        html += '</div></div>';
        return html;
    }

    function updateVobPreviewDom() {
        if (!body || activeTab !== "vobs") return;
        ["instance", "visual", "posX", "posY", "posZ", "rotX", "rotY", "rotZ"].forEach(function (key) {
            var el = body.querySelector('[data-vob="' + key + '"]');
            if (el) el.value = state.vobForm[key] || "";
        });
        var values = body.querySelector('[data-role="vob-preview-values"]');
        if (values) values.textContent = "rot=" + Math.round(+state.vobForm.rotX || 0) + ", " + Math.round(+state.vobForm.rotY || 0) + ", " + Math.round(+state.vobForm.rotZ || 0) + " pos=" + Math.round(+state.vobForm.posX || 0) + ", " + Math.round(+state.vobForm.posY || 0) + ", " + Math.round(+state.vobForm.posZ || 0);
    }

    function updateHerbPreviewDom() {
        if (!body || activeTab !== "herbs") return;
        ["instance", "posX", "posY", "posZ"].forEach(function (key) {
            var el = body.querySelector('[data-herb="' + key + '"]');
            if (el) el.value = state.herbForm[key] || "";
        });
    }

    function updateNpcPreviewDom(mode) {
        if (!body || activeTab !== "npc") return;
        var target = mode === "npc" ? state.npcForm : state.humanCreator;
        var prefix = mode === "npc" ? "data-field" : "data-hf";
        var names = mode === "npc"
            ? { posX: "npc-posX", posY: "npc-posY", posZ: "npc-posZ", angle: "npc-angle", world: "npc-world" }
            : { posX: "posX", posY: "posY", posZ: "posZ", angle: "angle", world: "world" };
        Object.keys(names).forEach(function (key) {
            var el = body.querySelector('[' + prefix + '="' + names[key] + '"]');
            if (el) el.value = target[key] || "";
        });
    }

    function renderVobs() {
        var form = state.vobForm;
        var catalog = state.vobCatalog || [];
        var categories = state.vobCategories && state.vobCategories.length ? state.vobCategories : vobCategories(catalog);
        var categoryStats = state.vobCategoryStats && state.vobCategoryStats.length ? state.vobCategoryStats : vobCategoryStats(catalog);
        var filtered = catalog;
        var pageCount = Math.max(1, Math.ceil((state.vobMatched || filtered.length) / (state.vobPageSize || 120)));
        var html = '<div class="adm-tabs--sub adm-vob-tabs">';
        VOB_SOURCE_TABS.forEach(function (tab) {
            html += '<button class="adm-tab' + (state.vobSource === tab.id ? ' is-active' : '') + '" data-action="vob-source" data-source="' + escapeHtml(tab.id) + '">' + escapeHtml(t(tab.labelKey, tab.fallback)) + '</button>';
        });
        html += '</div>';
        html += '<div class="adm-toolbar"><input class="adm-search" data-vob="filter" value="' + escapeHtml(form.filter) + '" placeholder="' + escapeHtml(t("admin.vobs.search")) + '"><button class="adm-btn" data-action="refresh-vobs">⟳</button></div>';
        if (categories.length) {
            html += '<div class="adm-tabs--sub adm-vob-categories"><button class="adm-tab' + (!state.vobCategory ? ' is-active' : '') + '" data-action="vob-category" data-category="">' + escapeHtml(t("admin.common.all")) + ' (' + (state.vobSourceTotal || catalog.length) + ')</button>';
            categoryStats.forEach(function (category) {
                html += '<button class="adm-tab' + (state.vobCategory === category.name ? ' is-active' : '') + '" data-action="vob-category" data-category="' + escapeHtml(category.name) + '">' + escapeHtml(category.name) + ' (' + category.count + ')</button>';
            });
            html += '</div>';
        }
        html += '<div class="adm-toolbar adm-vob-pager"><button class="adm-btn" data-action="vob-page" data-dir="-1"' + (state.vobPage <= 0 ? ' disabled' : '') + '>' + escapeHtml(t("admin.common.previous")) + '</button><span>' + escapeHtml(tFmt("admin.vobs.pageInfo", state.vobPage + 1, pageCount, state.vobMatched || 0)) + '</span><button class="adm-btn" data-action="vob-page" data-dir="1"' + (state.vobPage + 1 >= pageCount ? ' disabled' : '') + '>' + escapeHtml(t("admin.common.next")) + '</button></div>';
        html += renderVobPreviewBox();
        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.vobs.placement")) + '</h4>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>' + escapeHtml(t("admin.vobs.field.name")) + '<input class="adm-input" data-vob="name" value="' + escapeHtml(form.name) + '" placeholder="' + escapeHtml(t("admin.vobs.placeholder.name")) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.vobs.field.vobId")) + '<input class="adm-input" data-vob="vobId" value="' + escapeHtml(form.vobId) + '" placeholder="' + escapeHtml(t("admin.common.auto")) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.vobs.field.world")) + '<input class="adm-input" data-vob="world" value="' + escapeHtml(form.world) + '" placeholder="' + escapeHtml(t("admin.vobs.placeholder.adminPosition")) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.vobs.field.instance")) + '<input class="adm-input" data-vob="instance" value="' + escapeHtml(form.instance) + '" placeholder="' + escapeHtml(t("admin.vobs.placeholder.dataXml")) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.vobs.field.visual")) + '<input class="adm-input" data-vob="visual" value="' + escapeHtml(form.visual) + '" placeholder="MODEL.3DS"></label>';
        html += '<label>' + escapeHtml(t("admin.vobs.field.interactive")) + '<select class="adm-input" data-vob="interactive"><option value="0"' + (+form.interactive ? '' : ' selected') + '>' + escapeHtml(t("admin.common.no")) + '</option><option value="1"' + (+form.interactive ? ' selected' : '') + '>' + escapeHtml(t("admin.common.yes")) + '</option></select></label>';
        html += '<label>X<input class="adm-input" type="number" data-vob="posX" value="' + form.posX + '"></label>';
        html += '<label>Y<input class="adm-input" type="number" data-vob="posY" value="' + form.posY + '"></label>';
        html += '<label>Z<input class="adm-input" type="number" data-vob="posZ" value="' + form.posZ + '"></label>';
        html += '<label>Rot X<input class="adm-input" type="number" data-vob="rotX" value="' + form.rotX + '"></label>';
        html += '<label>Rot Y<input class="adm-input" type="number" data-vob="rotY" value="' + form.rotY + '"></label>';
        html += '<label>Rot Z<input class="adm-input" type="number" data-vob="rotZ" value="' + form.rotZ + '"></label>';
        html += '<label>' + escapeHtml(t("admin.vobs.field.step")) + '<input class="adm-input" type="number" data-vob="step" value="' + form.step + '"></label>';
        html += '</div><div class="adm-toolbar" style="margin-top:10px"><button class="adm-btn" data-action="vob-preview">' + escapeHtml(t("admin.vobs.btn.preview")) + '</button><button class="adm-btn" data-action="vob-floor">' + escapeHtml(t("admin.vobs.btn.floor")) + '</button><button class="adm-btn adm-btn--primary" data-action="vob-save-here">' + escapeHtml(t("admin.vobs.btn.saveHere")) + '</button><button class="adm-btn adm-btn--primary" data-action="vob-save-pos">' + escapeHtml(t("admin.vobs.btn.savePreview")) + '</button><button class="adm-btn" data-action="vob-reset">' + escapeHtml(t("admin.common.reset")) + '</button></div>';
        html += '<div class="adm-toolbar" style="margin-top:8px">';
        [["x-","X-"],["x+","X+"],["y-","Y-"],["y+","Y+"],["z-","Z-"],["z+","Z+"],["rx-","RotX-"],["rx+","RotX+"],["ry-","RotY-"],["ry+","RotY+"],["rz-","RotZ-"],["rz+","RotZ+"]].forEach(function (b) { html += '<button class="adm-btn" data-action="vob-nudge" data-axis="' + b[0] + '">' + b[1] + '</button>'; });
        html += '</div></div>';
        if (filtered.length) {
            html += '<div class="adm-itemgrid adm-vob-grid" data-role="vobgrid">';
            filtered.forEach(function (v) {
                var picked = String(form.visual || "").toUpperCase() === String(v.visual || "").toUpperCase() ? " is-selected" : "";
                html += '<div class="adm-itemcell adm-vob-cell' + picked + '" data-action="vob-pick" data-instance="' + escapeHtml(v.instance || "") + '" data-name="' + escapeHtml(vobLabel(v)) + '" data-visual="' + escapeHtml(v.visual || "") + '" data-preview-visual="' + escapeHtml(v.previewVisual || vobPreviewVisual(v.visual || "")) + '" title="' + escapeHtml(vobLabel(v)) + '">';
                html += '<div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(vobLabel(v).slice(0, 18)) + '</span></div>';
                html += '<span class="adm-itemcell__cat">' + escapeHtml(v.category || v.source || "VOB") + '</span>';
                html += '<span class="adm-vob-cell__visual">' + escapeHtml(v.visual || "") + '</span></div>';
            });
            html += '</div>';
        } else html += '<div class="adm-empty">' + escapeHtml(t("admin.vobs.emptyCatalog")) + '</div>';
        html += renderVobList();
        return html;
    }

    function renderVobList() {
        var vobs = state.vobs || [];
        var html = '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.vobs.placed")) + '</h4>';
        if (!vobs.length) return html + '<div class="adm-empty">' + escapeHtml(t("admin.vobs.emptyWorld")) + '</div></div>';
        html += '<div class="adm-table-wrap"><table class="adm-table"><thead><tr><th>ID</th><th>' + escapeHtml(t("admin.vobs.col.model")) + '</th><th>' + escapeHtml(t("admin.vobs.field.world")) + '</th><th>' + escapeHtml(t("admin.vobs.col.position")) + '</th><th>' + escapeHtml(t("admin.vobs.col.rotation")) + '</th><th>' + escapeHtml(t("admin.vobs.field.interactive")) + '</th><th></th></tr></thead><tbody>';
        vobs.forEach(function (v) {
            var pos = Math.round(v.x || 0) + ', ' + Math.round(v.y || 0) + ', ' + Math.round(v.z || 0);
            var rot = Math.round(v.rotX || 0) + ', ' + Math.round(v.rotY || 0) + ', ' + Math.round(v.rotZ || 0);
            html += '<tr><td><code>' + escapeHtml(v.vobId || "") + '</code></td><td><b>' + escapeHtml(v.name || "VOB") + '</b><br><small>' + escapeHtml(v.visual || "") + '</small></td><td><small>' + escapeHtml(v.world || "") + '</small></td><td><small>' + pos + '</small></td><td><small>' + rot + '</small></td><td>' + escapeHtml(t(v.interactive ? "admin.common.yes" : "admin.common.no")) + '</td><td><div class="adm-actions"><button class="adm-btn" data-action="vob-edit" data-id="' + escapeHtml(v.vobId || "") + '">' + escapeHtml(t("admin.npc.btn.edit")) + '</button><button class="adm-btn adm-btn--danger" data-action="vob-delete" data-id="' + escapeHtml(v.vobId || "") + '">' + escapeHtml(t("admin.npc.btn.delete")) + '</button></div></td></tr>';
        });
        return html + '</tbody></table></div></div>';
    }

    function houseSlug(text) {
        return String(text || "").trim().toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
    }

    function housePointInputs(points) {
        var list = points || [];
        var html = "";
        if (!list.length) return '<div class="adm-empty">' + escapeHtml(t("admin.houses.noPoints")) + '</div>';
        for (var i = 0; i < list.length; i += 1) {
            var p = list[i] || { x: 0, y: 0, z: 0 };
            html += '<div class="adm-house-point"><strong>' + String.fromCharCode(65 + i) + '</strong>';
            html += '<input class="adm-input" type="number" data-house-point="' + i + ':x" value="' + Math.round(+p.x || 0) + '">';
            html += '<input class="adm-input" type="number" data-house-point="' + i + ':y" value="' + Math.round(+p.y || 0) + '">';
            html += '<input class="adm-input" type="number" data-house-point="' + i + ':z" value="' + Math.round(+p.z || 0) + '">';
            html += '<button class="adm-btn" data-action="house-capture" data-slot="point" data-index="' + i + '">' + escapeHtml(t("admin.houses.capture")) + '</button>';
            html += '<button class="adm-btn adm-btn--danger" data-action="house-remove-point" data-index="' + i + '">-</button>';
            html += '</div>';
        }
        return html;
    }

    function housePayload() {
        var f = state.houseForm;
        var points = (f.points || []).filter(function (p) { return p != null; });
        return {
            id: +f.id || 0,
            name: f.name || "",
            slug: f.slug || houseSlug(f.name),
            world: f.world || "",
            points: points,
            entry: { x: +f.entryX || 0, y: +f.entryY || 0, z: +f.entryZ || 0 },
            entryHeading: +f.entryHeading || 0,
            ownerType: f.ownerType === "" ? null : +f.ownerType || null,
            ownerId: f.ownerId === "" ? null : +f.ownerId || null,
            priceGold: +f.priceGold || 0,
            weeklyRentGold: +f.weeklyRentGold || 0,
            color: f.color || "",
            modeId: +f.modeId || 0,
            guests: []
        };
    }

    function houseGhostPayload() {
        return {
            visual: "BOOTS.3DS",
            world: state.houseForm.world || "",
            points: (state.houseForm.points || []).map(function (p) {
                return { x: +p.x || 0, y: +p.y || 0, z: +p.z || 0 };
            })
        };
    }

    function syncHouseGhost() {
        if (state.houseGhostActive) send("adminHouseGhostSync", houseGhostPayload());
    }

    function renderHouses() {
        var f = state.houseForm;
        var houses = state.houses || [];
        var html = '<div class="adm-section"><div class="adm-toolbar"><button class="adm-btn" data-action="refresh-houses">' + escapeHtml(t("admin.common.refresh")) + '</button><button class="adm-btn adm-btn--primary" data-action="house-new">' + escapeHtml(t("admin.houses.new")) + '</button></div>';
        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.houses.editor")) + '</h4>';
        html += '<div class="adm-grid adm-grid--2">';
        html += '<label>' + escapeHtml(t("admin.houses.name")) + '<input class="adm-input" data-house="name" value="' + escapeHtml(f.name) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.houses.slug")) + '<input class="adm-input" data-house="slug" value="' + escapeHtml(f.slug) + '" placeholder="' + escapeHtml(houseSlug(f.name)) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.houses.world")) + '<input class="adm-input" data-house="world" value="' + escapeHtml(f.world) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.houses.color")) + '<input class="adm-input" data-house="color" value="' + escapeHtml(f.color) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.houses.ownerType")) + '<input class="adm-input" type="number" data-house="ownerType" value="' + escapeHtml(f.ownerType) + '" placeholder="1"></label>';
        html += '<label>' + escapeHtml(t("admin.houses.ownerId")) + '<input class="adm-input" type="number" data-house="ownerId" value="' + escapeHtml(f.ownerId) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.houses.price")) + '<input class="adm-input" type="number" data-house="priceGold" value="' + (+f.priceGold || 0) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.houses.weeklyRent")) + '<input class="adm-input" type="number" data-house="weeklyRentGold" value="' + (+f.weeklyRentGold || 0) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.houses.mode")) + '<input class="adm-input" type="number" data-house="modeId" value="' + (+f.modeId || 0) + '"></label>';
        html += '</div>';
        html += '<h4>' + escapeHtml(t("admin.houses.points")) + '</h4>';
        html += '<div class="adm-house-boundary-help">' + escapeHtml(t("admin.houses.boundaryHelp")) + '</div>';
        html += '<div class="adm-toolbar adm-house-ghostbar">';
        html += '<button class="adm-btn ' + (state.houseGhostActive ? 'adm-btn--primary' : '') + '" data-action="house-ghost-toggle">' + escapeHtml(state.houseGhostActive ? t("admin.houses.ghostStop") : t("admin.houses.ghostStart")) + '</button>';
        html += '<button class="adm-btn" data-action="house-ghost-focus"' + (state.houseGhostActive ? '' : ' disabled') + '>' + escapeHtml(t("admin.houses.ghostFocus")) + '</button>';
        html += '<button class="adm-btn ' + (state.houseBoundaryActive ? 'adm-btn--primary' : '') + '" data-action="house-boundary-toggle">' + escapeHtml(state.houseBoundaryActive ? "Granice poza panelem: ON" : "Granice poza panelem: OFF") + '</button>';
        html += '</div>';
        html += '<div class="adm-house-boundary-count">' + escapeHtml(tFmt("admin.houses.pointCount", (f.points || []).length)) + '</div>';
        html += '<div class="adm-house-points">' + housePointInputs(f.points) + '</div>';
        html += '<div class="adm-toolbar"><button class="adm-btn adm-btn--primary" data-action="house-add-point">' + escapeHtml(t("admin.houses.addPoint")) + '</button><button class="adm-btn" data-action="house-undo-point">' + escapeHtml(t("admin.houses.undoPoint")) + '</button><button class="adm-btn adm-btn--danger" data-action="house-clear-points">' + escapeHtml(t("admin.houses.clearPoints")) + '</button></div>';
        html += '<h4>' + escapeHtml(t("admin.houses.entry")) + '</h4><div class="adm-grid adm-grid--3">';
        html += '<label>X<input class="adm-input" type="number" data-house="entryX" value="' + Math.round(+f.entryX || 0) + '"></label>';
        html += '<label>Y<input class="adm-input" type="number" data-house="entryY" value="' + Math.round(+f.entryY || 0) + '"></label>';
        html += '<label>Z<input class="adm-input" type="number" data-house="entryZ" value="' + Math.round(+f.entryZ || 0) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.houses.heading")) + '<input class="adm-input" type="number" data-house="entryHeading" value="' + Math.round(+f.entryHeading || 0) + '"></label>';
        html += '</div><div class="adm-toolbar"><button class="adm-btn" data-action="house-capture" data-slot="entry">' + escapeHtml(t("admin.houses.captureEntry")) + '</button><button class="adm-btn adm-btn--primary" data-action="house-save">' + escapeHtml(t("admin.common.save")) + '</button>';
        if (+f.id > 0) html += '<button class="adm-btn adm-btn--danger" data-action="house-delete" data-id="' + (+f.id || 0) + '">' + escapeHtml(t("admin.npc.btn.delete")) + '</button>';
        html += '</div></div>';
        if (!houses.length) return html + '<div class="adm-empty">' + escapeHtml(t("admin.houses.empty")) + '</div></div>';
        html += '<div class="adm-table-wrap"><table class="adm-table"><thead><tr><th>ID</th><th>' + escapeHtml(t("admin.houses.name")) + '</th><th>' + escapeHtml(t("admin.houses.world")) + '</th><th>' + escapeHtml(t("admin.houses.owner")) + '</th><th>' + escapeHtml(t("admin.houses.points")) + '</th><th></th></tr></thead><tbody>';
        houses.forEach(function (h) {
            var owner = h.ownerType ? ((h.ownerLabel || "") + " (#" + h.ownerId + ")") : t("admin.houses.free");
            html += '<tr><td>' + h.id + '</td><td><b>' + escapeHtml(h.name || "") + '</b><br><small>' + escapeHtml(h.slug || "") + '</small></td><td>' + escapeHtml(h.world || "") + '</td><td>' + escapeHtml(owner) + '</td><td>' + ((h.points || h.corners || []).length) + '</td><td><div class="adm-actions"><button class="adm-btn" data-action="house-edit" data-id="' + h.id + '">' + escapeHtml(t("admin.npc.btn.edit")) + '</button><button class="adm-btn adm-btn--danger" data-action="house-delete" data-id="' + h.id + '">' + escapeHtml(t("admin.npc.btn.delete")) + '</button></div></td></tr>';
        });
        return html + '</tbody></table></div></div>';
    }

    function renderHumanCreator() {
        applyHumanChoice();
        var h = state.humanCreator;
        var html = '<div class="adm-creator">';
        html += '<div class="adm-section adm-section--inline adm-creator__identity"><h4>' + escapeHtml(t("admin.npc.human.identity")) + '</h4>';
        html += '<label>' + escapeHtml(t("admin.npc.field.name")) + '<input class="adm-input" data-hf="name" value="' + escapeHtml(h.name) + '" placeholder="' + escapeHtml(t("admin.npc.human.namePlaceholder")) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.instance")) + '<input class="adm-input" data-hf="instance" value="' + escapeHtml(h.instance) + '" placeholder="PC_HERO"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.tag")) + '<input class="adm-input" data-hf="tag" value="' + escapeHtml(h.tag) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.respawn")) + '<input class="adm-input" type="number" data-hf="respawnSec" value="' + h.respawnSec + '"></label>';
        html += '</div>';
        html += '<div class="adm-section adm-section--inline adm-creator__options"><h4>' + escapeHtml(t("admin.npc.section.visual")) + '</h4>';
        html += renderHumanOption("gender", "character.create.opt.gender");
        html += renderHumanOption("race", "character.create.opt.race");
        html += renderHumanOption("head", "character.create.opt.head");
        html += renderHumanOption("face", "character.create.opt.face");
        html += renderHumanOption("fatness", "character.create.opt.fatness");
        html += '<label>' + escapeHtml(t("admin.npc.field.voice")) + '<input class="adm-input" type="number" data-hf="voice" value="' + h.voice + '"></label>';
        html += '</div>';
        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.section.stats")) + '</h4><div class="adm-grid adm-grid--2">';
        html += '<label>' + escapeHtml(t("admin.npc.field.hp")) + '<input class="adm-input" type="number" data-hf="hp" value="' + h.hp + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.level")) + '<input class="adm-input" type="number" data-hf="level" value="' + h.level + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.strength")) + '<input class="adm-input" type="number" data-hf="strength" value="' + h.strength + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.dexterity")) + '<input class="adm-input" type="number" data-hf="dexterity" value="' + h.dexterity + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.aggroRadius")) + '<input class="adm-input" type="number" data-hf="aggroRadius" value="' + h.aggroRadius + '"></label>';
        html += '</div></div>';
        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.human.equipment")) + '</h4>';
        html += renderHumanEquipmentPicker("weapon", "admin.npc.human.weapon", [1, 2]);
        html += renderHumanEquipmentPicker("ranged", "admin.npc.human.ranged", [3, 4]);
        html += renderHumanEquipmentPicker("armor", "admin.npc.human.armor", [6]);
        html += '</div>';
        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("teacher.title", "Nauczyciel")) + '</h4>';
        html += renderTeacherSkills(h.teacherSkills || "");
        html += '<label>' + escapeHtml(t("teacher.cost", "Koszt")) + '<input class="adm-input" type="number" data-hf="teachCost" value="' + h.teachCost + '"></label>';
        html += '</div>';
        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("merchant.title", "Handlarz")) + '</h4>';
        html += renderMerchantStock();
        html += '</div>';
        html += '<div class="adm-section adm-section--inline"><h4>Animacja i nagroda</h4>';
        html += '<div class="adm-grid adm-grid--2">';
        html += '<label>Animacja idle' + renderAnimSelect(h.idleAnimation || "", "idleAnimation") + '</label>';
        html += '<label>Doświadczenie za zabicie<input class="adm-input" type="number" data-hf="baseExperience" value="' + (h.baseExperience || 0) + '"></label>';
        html += '<label>Wrogi<select class="adm-input" data-hf="hostile"><option value="0"' + (+h.hostile === 0 ? " selected" : "") + '>Nie</option><option value="1"' + (+h.hostile === 1 ? " selected" : "") + '>Tak</option></select></label>';
        html += '</div>';
        html += '<div class="adm-toolbar"><button class="adm-btn" data-action="human-anim-preview">▶ Podgląd animacji</button><button class="adm-btn" data-action="human-anim-stop">■ Stop</button></div>';
        html += '</div>';
        html += '</div>';
        html += renderHumanPlacement(h);
        html += '<div class="adm-toolbar"><button class="adm-btn" data-action="human-preview">' + escapeHtml(t(h.preview ? "admin.npc.human.previewUpdate" : "admin.npc.human.previewStart")) + '</button><button class="adm-btn" data-action="human-preview-stop">' + escapeHtml(t("admin.npc.human.previewStop")) + '</button><button class="adm-btn" data-action="human-reset">' + escapeHtml(t("admin.common.reset")) + '</button><button class="adm-btn adm-btn--primary" data-action="human-spawn">' + escapeHtml(t("admin.npc.human.spawn")) + '</button></div>';
        return html;
    }

    function renderHumanOption(key, labelKey) {
        return '<div class="adm-option" data-hopt="' + key + '"><button class="adm-option__arrow" data-action="human-cycle" data-key="' + key + '" data-dir="-1">‹</button><div class="adm-option__body"><span>' + escapeHtml(t(labelKey)) + '</span><b>' + escapeHtml(humanOptionValue(key)) + '</b></div><button class="adm-option__arrow" data-action="human-cycle" data-key="' + key + '" data-dir="1">›</button></div>';
    }

    var ANIMATION_LIST = [
        { group: "Postawy / Idle", items: ["S_STAND", "S_FISTSTAND", "S_LGUARD", "S_RGUARD", "S_HGUARD", "S_CHAIR_S1", "S_BENCH_S1", "S_THRONE_S1", "S_LEAN", "S_PRAY", "S_FOOD_S0", "S_BEER_S0", "S_POTION_S0", "S_MEAT_S0"] },
        { group: "Przejścia", items: ["T_STAND_2_LGUARD", "T_LGUARD_2_STAND", "T_STAND_2_RGUARD", "T_RGUARD_2_STAND", "T_STAND_2_HGUARD", "T_HGUARD_2_STAND", "T_STAND_2_LEAN", "T_LEAN_2_STAND", "T_STAND_2_PRAY", "T_PRAY_2_STAND", "T_STAND_2_SLEEP", "T_SLEEP_2_STAND", "T_STAND_2_SIT", "T_SIT_2_STAND", "T_STAND_2_DEADB", "T_STAND_2_TALK", "T_TALK_2_STAND"] },
        { group: "Praca", items: ["T_DANCE_01", "T_DANCE_02", "T_DANCE_03", "T_DANCE_04", "T_PEE_S0_2_S1", "T_VOMIT_S0_2_S1", "T_BAU_S0_2_S1", "T_REPAIR_S0_2_S1", "T_SMOKE_S0_2_S1", "T_PRACTICEMAGIC", "T_PRACTICEMAGIC2", "T_PRACTICEMAGIC3", "T_PRACTICEMAGIC4", "T_PRACTICEMAGIC5"] },
        { group: "Walka", items: ["T_1HATTACK", "T_1HPARADE", "T_1HRUNL", "T_2HATTACK", "T_2HPARADE", "T_BOWRELOAD", "T_BOWAIM", "T_BOWSHOOT", "T_CBOWAIM", "T_CBOWSHOOT", "T_FISTATTACK", "T_FISTPARADE", "T_FISTRUNL", "T_MAGRUN_2_TARGETED", "T_WARN", "T_THREATEN"] },
        { group: "Emocje", items: ["T_PLUNDER", "T_HGUARDLOOK_LO", "T_HGUARDLOOK_HI", "T_LOOKAROUND", "T_SLEEP_LOOK", "T_SHRUG_S0_2_S1", "T_NO_S0", "T_YES_S0", "T_HOWAMI_S0", "T_TURNAROUND_S0_2_S1"] }
    ];

    function renderAnimSelect(current, fieldKey) {
        var html = '<select class="adm-input" data-hf="' + fieldKey + '">';
        html += '<option value=""' + (current === "" ? " selected" : "") + '>— brak —</option>';
        ANIMATION_LIST.forEach(function (g) {
            html += '<optgroup label="' + escapeHtml(g.group) + '">';
            g.items.forEach(function (a) {
                html += '<option value="' + a + '"' + (current === a ? " selected" : "") + '>' + a + '</option>';
            });
            html += '</optgroup>';
        });
        html += '</select>';
        return html;
    }

    function renderHumanPlacement(h) {
        var html = '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.human.placement")) + '</h4>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>X<input class="adm-input" type="number" data-hf="posX" value="' + h.posX + '"></label>';
        html += '<label>Y<input class="adm-input" type="number" data-hf="posY" value="' + h.posY + '"></label>';
        html += '<label>Z<input class="adm-input" type="number" data-hf="posZ" value="' + h.posZ + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.human.angle")) + '<input class="adm-input" type="number" data-hf="angle" value="' + h.angle + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.human.step")) + '<input class="adm-input" type="number" data-hf="step" value="' + h.step + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.human.world")) + '<input class="adm-input" data-hf="world" value="' + escapeHtml(h.world) + '"></label>';
        html += '<label>Kamera<select class="adm-input" data-hf="cameraMode"><option value="static"' + (h.cameraMode === "static" ? " selected" : "") + '>Statyczna</option><option value="orbital"' + (h.cameraMode !== "static" && h.cameraMode !== "off" ? " selected" : "") + '>Orbital</option><option value="off"' + (h.cameraMode === "off" ? " selected" : "") + '>Wyłączona</option></select></label>';
        html += '</div><div class="adm-placement">';
        [["z+", "↑"], ["x-", "←"], ["x+", "→"], ["z-", "↓"], ["y+", "+Y"], ["y-", "-Y"], ["a-", "⟲"], ["a+", "⟳"]].forEach(function (b) {
            html += '<button class="adm-btn" data-action="human-nudge" data-axis="' + b[0] + '">' + b[1] + '</button>';
        });
        html += '</div></div>';
        return html;
    }

    function renderNpcCatalog() {
        var form = state.npcForm;
        var cat = state.npcCatalog || [];
        var f = (form.filter || "").toLowerCase();
        var filtered = f ? cat.filter(function (e) {
            return String(e.instance || "").toLowerCase().indexOf(f) >= 0
                || npcLabel(e).toLowerCase().indexOf(f) >= 0
                || String(e.category || "").toLowerCase().indexOf(f) >= 0;
        }) : cat;
        var html = '<div class="adm-toolbar">';
        html += '<input class="adm-search" data-field="npc-filter" value="' + escapeHtml(form.filter) + '" placeholder="' + escapeHtml(t("admin.npc.search")) + '">';
        html += '<button class="adm-btn" data-action="refresh-npc">⟳</button>';
        html += '</div>';
        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.section.base")) + '</h4>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>' + escapeHtml(t("admin.npc.field.name")) + '<input class="adm-input" data-field="npc-name" value="' + escapeHtml(form.name) + '" placeholder="' + escapeHtml(t("admin.npc.placeholder.optionalName")) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.tag")) + '<input class="adm-input" data-field="npc-tag" value="' + escapeHtml(form.tag) + '" placeholder="quest / guard"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.respawn")) + '<input class="adm-input" type="number" min="0" data-field="npc-respawn" value="' + form.respawnSec + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.kind")) + '<select class="adm-input" data-field="npc-kind">';
        [["monster", t("admin.npc.kind.monster")], ["npc", t("admin.npc.kind.npc")]].forEach(function (k) {
            html += '<option value="' + k[0] + '"' + (form.kind === k[0] ? " selected" : "") + '>' + escapeHtml(k[1]) + '</option>';
        });
        html += '</select></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.hostile")) + '<select class="adm-input" data-field="npc-hostile">';
        [["0", "—"], ["1", "✓ " + t("admin.npc.field.hostile")]].forEach(function (h) {
            html += '<option value="' + h[0] + '"' + (String(form.hostile) === h[0] ? " selected" : "") + '>' + escapeHtml(h[1]) + '</option>';
        });
        html += '</select></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.instance")) + '<input class="adm-input" data-field="npc-instance" value="' + escapeHtml(form.instance) + '" placeholder="WOLF"></label>';
        html += '</div>';
        var edit = catalogEditRow();
        if (edit) {
            html += '<div class="adm-section adm-section--inline"><h4>Bazowy schemat potwora</h4><div class="adm-grid adm-grid--3">';
            html += '<label>Etykieta<input class="adm-input" data-catalog="label" value="' + escapeHtml(edit.label || "") + '"></label>';
            html += '<label>Kategoria<input class="adm-input" data-catalog="category" value="' + escapeHtml(edit.category || "monster") + '"></label>';
            html += '<label>Tier<input class="adm-input" type="number" min="1" data-catalog="tier" value="' + (+edit.tier || 1) + '"></label>';
            html += '<label>Wrogi<select class="adm-input" data-catalog="defaultHostile"><option value="0"' + (+edit.defaultHostile ? '' : ' selected') + '>Nie</option><option value="1"' + (+edit.defaultHostile ? ' selected' : '') + '>Tak</option></select></label>';
            html += '<label>Bazowy EXP<input class="adm-input" type="number" min="0" data-catalog="baseExperience" value="' + (+edit.baseExperience || 0) + '"></label>';
            html += '</div><div class="adm-toolbar" style="margin-top:10px"><button class="adm-btn adm-btn--primary" data-action="npc-catalog-save">Zapisz bazowy schemat</button></div></div>';
        }
        html += '<div class="adm-toolbar" style="margin-top:10px"><button class="adm-btn" data-action="npc-preview">' + escapeHtml(t(form.preview ? "admin.npc.human.previewUpdate" : "admin.npc.human.previewStart")) + '</button><button class="adm-btn" data-action="npc-preview-stop">' + escapeHtml(t("admin.npc.human.previewStop")) + '</button><button class="adm-btn adm-btn--primary" data-action="npc-spawn">' + escapeHtml(t("admin.npc.btn.spawnBase")) + '</button></div>';
        html += '</div>';
        html += renderNpcPlacement(form);
        if (!filtered.length) return html + '<div class="adm-empty">' + escapeHtml(t("admin.npc.empty.catalog")) + '</div>';
        html += '<div class="adm-grid adm-grid--3">';
        filtered.slice(0, 240).forEach(function (e) {
            var label = npcLabel(e);
            var catKey = "admin.npc.cat." + (e.category || "monster");
            var picked = form.instance === e.instance ? " is-selected" : "";
            html += '<button type="button" class="adm-btn adm-btn--ghost' + picked + '" data-action="npc-spawn-instance" data-instance="' + escapeHtml(e.instance) + '" data-hostile="' + e.defaultHostile + '" data-kind="' + ((e.category === "humanoid" || e.category === "merchant" || e.category === "guard") ? "npc" : "monster") + '">';
            html += '<b>' + escapeHtml(label) + '</b><br><small>' + escapeHtml(e.instance) + ' · ' + escapeHtml(t(catKey, e.category)) + ' · t' + e.tier + ' · EXP ' + (+e.baseExperience || 0) + '</small><br><span>' + escapeHtml(t("admin.npc.btn.spawnBase")) + '</span></button>';
        });
        html += '</div>';
        return html;
    }

    function renderNpcPlacement(n) {
        if (!n.instance) return "";
        var html = '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.human.placement")) + '</h4>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>X<input class="adm-input" type="number" data-field="npc-posX" value="' + n.posX + '"></label>';
        html += '<label>Y<input class="adm-input" type="number" data-field="npc-posY" value="' + n.posY + '"></label>';
        html += '<label>Z<input class="adm-input" type="number" data-field="npc-posZ" value="' + n.posZ + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.human.angle")) + '<input class="adm-input" type="number" data-field="npc-angle" value="' + n.angle + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.human.step")) + '<input class="adm-input" type="number" data-field="npc-step" value="' + n.step + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.human.world")) + '<input class="adm-input" data-field="npc-world" value="' + escapeHtml(n.world) + '"></label>';
        html += '<label>Kamera<select class="adm-input" data-field="npc-cameraMode"><option value="static"' + (n.cameraMode === "static" ? " selected" : "") + '>Statyczna</option><option value="orbital"' + (n.cameraMode !== "static" && n.cameraMode !== "off" ? " selected" : "") + '>Orbital</option><option value="off"' + (n.cameraMode === "off" ? " selected" : "") + '>Wyłączona</option></select></label>';
        html += '</div><div class="adm-placement">';
        [["z+", "↑"], ["x-", "←"], ["x+", "→"], ["z-", "↓"], ["y+", "+Y"], ["y-", "-Y"], ["a-", "⟲"], ["a+", "⟳"]].forEach(function (b) {
            html += '<button class="adm-btn" data-action="npc-nudge" data-axis="' + b[0] + '">' + b[1] + '</button>';
        });
        html += '</div></div>';
        return html;
    }

    function renderNpcPresets(presets) {
        var html = '<div class="adm-toolbar">';
        html += '<button class="adm-btn adm-btn--primary" data-action="npc-preset-new">' + escapeHtml(t("admin.npc.btn.newPreset")) + '</button>';
        html += '<button class="adm-btn" data-action="refresh-npc">⟳</button>';
        html += '</div>';
        if (!presets.length) {
            html += '<div class="adm-empty">' + escapeHtml(t("admin.npc.empty.presets")) + '</div>';
            return html;
        }
        html += '<div class="adm-table-wrap"><table class="adm-table"><thead><tr>' +
            '<th>' + escapeHtml(t("admin.npc.col.id")) + '</th>' +
            '<th>' + escapeHtml(t("admin.npc.col.label")) + '</th>' +
            '<th>' + escapeHtml(t("admin.npc.col.instance")) + '</th>' +
            '<th>' + escapeHtml(t("admin.npc.col.category")) + '</th>' +
            '<th>HP / lvl / EXP</th>' +
            '<th>' + escapeHtml(t("admin.npc.field.scale")) + '</th>' +
            '<th>' + escapeHtml(t("admin.npc.col.actions")) + '</th>' +
            '</tr></thead><tbody>';
        presets.forEach(function (p) {
            var catKey = "admin.npc.cat." + (p.category || "monster");
            var sc = (p.scaleX || 1).toFixed(2) + " × " + (p.scaleY || 1).toFixed(2) + " × " + (p.scaleZ || 1).toFixed(2);
            html += "<tr>";
            html += "<td>" + p.id + "</td>";
            html += "<td><b>" + escapeHtml(p.label || t("admin.npc.instance." + String(p.instance || "").toUpperCase(), p.code)) + "</b><br><small>" + escapeHtml(p.code) + "</small></td>";
            html += "<td><code>" + escapeHtml(p.instance) + "</code></td>";
            html += "<td>" + escapeHtml(t(catKey, p.category)) + "</td>";
            html += "<td>" + (p.hp || "—") + " / " + (p.level || "—") + " / " + (p.baseExperience || 0) + "</td>";
            html += "<td><small>" + sc + "</small></td>";
            html += '<td><div class="adm-actions">';
            html += '<button class="adm-btn adm-btn--primary" data-action="npc-spawn-preset" data-id="' + p.id + '">' + escapeHtml(t("admin.npc.btn.spawnHere")) + '</button>';
            html += '<button class="adm-btn" data-action="npc-preset-edit" data-id="' + p.id + '">' + escapeHtml(t("admin.npc.btn.edit")) + '</button>';
            html += '<button class="adm-btn" data-action="npc-preset-clone" data-id="' + p.id + '">' + escapeHtml(t("admin.npc.btn.clone")) + '</button>';
            html += '<button class="adm-btn adm-btn--danger" data-action="npc-preset-delete" data-id="' + p.id + '">' + escapeHtml(t("admin.npc.btn.delete")) + '</button>';
            html += '</div></td></tr>';
        });
        html += '</tbody></table></div>';
        return html;
    }

    function renderNpcEditor() {
        var ed = state.npcEditor;
        var cat = state.npcCatalog || [];
        var instFilter = (state.npcForm.filter || "").toLowerCase();
        var filtered = instFilter
            ? cat.filter(function (e) {
                return e.instance.toLowerCase().indexOf(instFilter) >= 0
                    || (e.label || "").toLowerCase().indexOf(instFilter) >= 0;
            })
            : cat;
        var html = '<div class="adm-grid adm-grid--2">';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.section.identity")) + '</h4>';
        html += '<label>' + escapeHtml(t("admin.npc.field.code")) + '<input class="adm-input" data-ef="code" value="' + escapeHtml(ed.code) + '" placeholder="wolf_young_small"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.label")) + '<input class="adm-input" data-ef="label" value="' + escapeHtml(ed.label) + '" placeholder="Mały młody wilk"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.category")) + '<select class="adm-input" data-ef="category">';
        ["monster","humanoid","merchant","guard"].forEach(function (c) {
            html += '<option value="' + c + '"' + (ed.category === c ? " selected" : "") + '>' + escapeHtml(t("admin.npc.cat." + c)) + '</option>';
        });
        html += '</select></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.instance")) + '<input class="adm-input" data-ef="instance" value="' + escapeHtml(ed.instance) + '" placeholder="WOLF"></label>';
        html += '</div>';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.section.behavior")) + '</h4>';
        html += '<label>' + escapeHtml(t("admin.npc.field.kind")) + '<select class="adm-input" data-ef="kind">';
        [["monster", t("admin.npc.kind.monster")], ["npc", t("admin.npc.kind.npc")]].forEach(function (k) {
            html += '<option value="' + k[0] + '"' + (ed.kind === k[0] ? " selected" : "") + '>' + escapeHtml(k[1]) + '</option>';
        });
        html += '</select></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.hostile")) + '<select class="adm-input" data-ef="hostile">';
        [["0", "—"], ["1", "✓ " + t("admin.npc.field.hostile")]].forEach(function (h) {
            html += '<option value="' + h[0] + '"' + (String(ed.hostile) === h[0] ? " selected" : "") + '>' + escapeHtml(h[1]) + '</option>';
        });
        html += '</select></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.respawn")) + '<input class="adm-input" type="number" min="0" data-ef="respawnSec" value="' + ed.respawnSec + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.idleAnimation")) + '<select class="adm-input" data-ef="idleAnimation">';
        var anims = [
            ["", t("admin.npc.anim.none")],
            ["S_STAND", t("admin.npc.anim.idle.stand")],
            ["T_STAND_2_EAT", t("admin.npc.anim.idle.eat")],
            ["T_1HPARADE_0", t("admin.npc.anim.idle.parade")],
            ["T_FISTPARADEJUMPB", t("admin.npc.anim.idle.fistparade")],
            ["T_WARN", t("admin.npc.anim.idle.warn")],
            ["S_FISTRUNL", t("admin.npc.anim.run.fist")],
            ["S_1HRUNL", t("admin.npc.anim.run.1h")],
            ["S_BOWRUNL", t("admin.npc.anim.run.bow")]
        ];
        anims.forEach(function (a) {
            html += '<option value="' + a[0] + '"' + (ed.idleAnimation === a[0] ? " selected" : "") + '>' + escapeHtml(a[1]) + '</option>';
        });
        html += '</select></label>';
        html += '<div class="adm-grid adm-grid--2">';
        html += '<label>' + escapeHtml(t("admin.npc.field.aggroRadius")) + '<input class="adm-input" type="number" min="0" data-ef="aggroRadius" value="' + ed.aggroRadius + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.attackRange")) + '<input class="adm-input" type="number" min="0" data-ef="attackRange" value="' + ed.attackRange + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.attackDamage")) + '<input class="adm-input" type="number" min="0" data-ef="attackDamage" value="' + ed.attackDamage + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.walkSpeed")) + '<input class="adm-input" type="number" min="0" data-ef="walkSpeed" value="' + ed.walkSpeed + '"></label>';
        html += '<label>Bazowy EXP<input class="adm-input" type="number" min="0" data-ef="baseExperience" value="' + (ed.baseExperience || 0) + '"></label>';
        html += '</div>';
        html += '</div>';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.section.visual")) + '</h4>';
        html += '<label>' + escapeHtml(t("admin.npc.field.bodyModel")) + '<select class="adm-input" data-ef="bodyModel">';
        var bodies = [
            ["", "—"],
            ["HUM_BODY_NAKED0", t("admin.npc.body.male")],
            ["HUM_BODY_BABE0",  t("admin.npc.body.female")],
            ["ORC_BODY_BALD",   t("admin.npc.body.orc")]
        ];
        bodies.forEach(function (b) {
            html += '<option value="' + b[0] + '"' + (ed.bodyModel === b[0] ? " selected" : "") + '>' + escapeHtml(b[1]) + '</option>';
        });
        html += '</select></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.bodyTex")) + '<input class="adm-input" type="number" data-ef="bodyTex" value="' + ed.bodyTex + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.headModel")) + '<select class="adm-input" data-ef="headModel">';
        var heads = [
            ["", "—"],
            ["HUM_HEAD_BALD",     t("admin.npc.head.bald")],
            ["HUM_HEAD_PONY",     t("admin.npc.head.ponytail")],
            ["HUM_HEAD_FATBALD",  t("admin.npc.head.short")],
            ["HUM_HEAD_PSIONIC",  t("admin.npc.head.psionic")]
        ];
        heads.forEach(function (h) {
            html += '<option value="' + h[0] + '"' + (ed.headModel === h[0] ? " selected" : "") + '>' + escapeHtml(h[1]) + '</option>';
        });
        html += '</select></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.headTex")) + '<input class="adm-input" type="number" data-ef="headTex" value="' + ed.headTex + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.fatness")) + '<input class="adm-input" type="number" step="0.1" min="-1" max="3" data-ef="fatness" value="' + ed.fatness + '"></label>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>' + escapeHtml(t("admin.npc.field.scaleX")) + '<input class="adm-input" type="number" step="0.05" min="0.1" max="5" data-ef="scaleX" value="' + ed.scaleX + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.scaleY")) + '<input class="adm-input" type="number" step="0.05" min="0.1" max="5" data-ef="scaleY" value="' + ed.scaleY + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.scaleZ")) + '<input class="adm-input" type="number" step="0.05" min="0.1" max="5" data-ef="scaleZ" value="' + ed.scaleZ + '"></label>';
        html += '</div>';
        html += '<label>' + escapeHtml(t("admin.npc.field.voice")) + '<input class="adm-input" type="number" min="0" max="20" data-ef="voice" value="' + ed.voice + '"></label>';
        html += '</div>';
        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.section.stats")) + '</h4>';
        html += '<div class="adm-grid adm-grid--2">';
        html += '<label>' + escapeHtml(t("admin.npc.field.hp")) + '<input class="adm-input" type="number" min="0" data-ef="hp" value="' + ed.hp + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.level")) + '<input class="adm-input" type="number" min="0" data-ef="level" value="' + ed.level + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.strength")) + '<input class="adm-input" type="number" min="0" data-ef="strength" value="' + ed.strength + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.dexterity")) + '<input class="adm-input" type="number" min="0" data-ef="dexterity" value="' + ed.dexterity + '"></label>';
        html += '</div></div>';

        html += '</div>';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.field.instance")) + '</h4>';
        html += '<input class="adm-input" data-field="npc-filter" placeholder="' + escapeHtml(t("admin.npc.search")) + '" value="' + escapeHtml(state.npcForm.filter) + '" />';
        html += '<div class="adm-grid adm-grid--3" style="margin-top:8px;max-height:240px;overflow:auto;">';
        filtered.slice(0, 240).forEach(function (e) {
            var sel = ed.instance === e.instance ? " is-selected" : "";
            html += '<button type="button" class="adm-btn adm-btn--ghost' + sel + '" data-action="npc-editor-pick" data-instance="' + escapeHtml(e.instance) + '" data-hostile="' + e.defaultHostile + '">' +
                '<b>' + escapeHtml(npcLabel(e)) + "</b><br><small>" + escapeHtml(e.instance) + " · t" + e.tier + "</small></button>";
        });
        html += '</div></div>';

        html += '<div class="adm-toolbar">';
        html += '<button class="adm-btn adm-btn--primary" data-action="npc-preset-save">' + escapeHtml(t("admin.npc.btn.savePreset")) + '</button>';
        html += '<button class="adm-btn adm-btn--primary" data-action="npc-preset-save-spawn">' + escapeHtml(t("admin.npc.btn.saveAndSpawn")) + '</button>';
        html += '<button class="adm-btn" data-action="npc-editor-cancel">' + escapeHtml(t("admin.npc.btn.cancel")) + '</button>';
        html += '</div>';
        return html;
    }

    function renderNpcActive(spawns) {
        var html = '<div class="adm-toolbar"><button class="adm-btn" data-action="refresh-npc">⟳</button></div>';
        if (!spawns.length) {
            html += '<div class="adm-empty">' + escapeHtml(t("admin.npc.empty.spawns")) + '</div>';
            return html;
        }
        html += '<div class="adm-table-wrap"><table class="adm-table"><thead><tr>' +
            '<th>' + escapeHtml(t("admin.npc.col.id")) + '</th>' +
            '<th>' + escapeHtml(t("admin.npc.col.instance")) + '</th>' +
            '<th>' + escapeHtml(t("admin.npc.col.world")) + '</th>' +
            '<th>' + escapeHtml(t("admin.npc.col.pos")) + '</th>' +
            '<th>' + escapeHtml(t("admin.npc.field.scale")) + '</th>' +
            '<th>' + escapeHtml(t("admin.npc.field.respawn")) + '</th>' +
            '<th>' + escapeHtml(t("admin.npc.col.alive")) + '</th><th></th>' +
            '</tr></thead><tbody>';
        spawns.forEach(function (s) {
            var pos = Math.round(s.posX) + ", " + Math.round(s.posY) + ", " + Math.round(s.posZ);
            var sc = (s.scaleX || 1).toFixed(2);
            var alive = s.alive
                ? '<span style="color:#7fbf6f">' + escapeHtml(t("admin.npc.alive.yes")) + '</span>'
                : '<span style="color:#bf6f6f">' + escapeHtml(t("admin.npc.alive.no")) + '</span>';
            html += "<tr><td>" + s.id + "</td><td><code>" + escapeHtml(s.instance) + "</code>" +
                (s.name ? "<br><small>" + escapeHtml(s.name) + "</small>" : "") + "</td>" +
                "<td><small>" + escapeHtml(s.world || "") + "</small></td>" +
                "<td><small>" + pos + "</small></td>" +
                "<td>" + sc + "×</td>" +
                "<td>" + s.respawnSec + "s</td>" +
                "<td>" + alive + "</td>" +
                '<td><button class="adm-btn adm-btn--danger" data-action="npc-delete" data-id="' + s.id + '">' + escapeHtml(t("admin.npc.btn.deleteSpawn")) + '</button></td></tr>';
        });
        html += "</tbody></table></div>";
        return html;
    }


    function bindHandlers() {
        body.querySelectorAll("input, textarea, select").forEach(function (el) {
            el.addEventListener("focus", function () { send("adminInputFocus", {}); });
            el.addEventListener("blur", function () {
                setTimeout(function () {
                    if (!body.contains(document.activeElement) || !document.activeElement.matches("input, textarea, select")) send("adminInputBlur", {});
                    flushPendingRender();
                }, 20);
            });
            el.addEventListener("keydown", function (ev) { ev.stopPropagation(); });
            el.addEventListener("keyup", function (ev) { ev.stopPropagation(); });
            el.addEventListener("keypress", function (ev) { ev.stopPropagation(); });
        });
        body.querySelectorAll("[data-action]").forEach(function (el) {
            el.addEventListener("click", onAction);
        });
        body.querySelectorAll("[data-bind]").forEach(function (el) {
            el.addEventListener("input", function () {
                var k = el.dataset.bind;
                if (k === "giveTarget-cid") {
                    var cid = +el.value || 0;
                    if (cid > 0) {
                        var p = (state.players || []).filter(function (x) { return x.characterId === cid; })[0];
                        state.giveTarget = p ? { cid: cid, name: p.characterName } : { cid: cid, name: "" };
                    } else state.giveTarget = null;
                } else if (k === "selectedScheme") {
                    state.selectedScheme = el.value;
                } else state[k] = el.type === "number" ? +el.value : el.value;
            });
        });
        body.querySelectorAll("[data-cbind]").forEach(function (el) {
            el.addEventListener("input", function () {
                var k = el.dataset.cbind;
                state.custom[k] = el.type === "number" ? +el.value : el.value;
            });
        });
        body.querySelectorAll("[data-render-debug]").forEach(function (el) {
            el.addEventListener("input", function () {
                state.itemRenderDebug[el.dataset.renderDebug] = parseFloat(el.value) || 0;
                saveRenderDebug();
                render();
            });
        });
        body.querySelectorAll("[data-ef]").forEach(function (el) {
            var ev = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(ev, function () {
                var k = el.dataset.ef;
                var v = el.value;
                if (el.type === "number") v = parseFloat(v);
                if (k === "instance" && typeof v === "string") v = v.trim().toUpperCase();
                state.npcEditor[k] = v;
            });
        });
        body.querySelectorAll("[data-hf]").forEach(function (el) {
            var ev = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(ev, function () {
                var k = el.dataset.hf;
                var v = el.value;
                if (el.type === "number") v = parseFloat(v) || 0;
                if (k === "instance" && typeof v === "string") v = v.trim().toUpperCase();
                state.humanCreator[k] = v;
                if (shouldSyncHumanPreview(k)) syncHumanPreview();
                if (k === "idleAnimation" && state.humanCreator.preview) {
                    send("adminNpcPreviewAnim", { animation: v || "" });
                }
            });
        });
        body.querySelectorAll("[data-herb]").forEach(function (el) {
            var ev = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(ev, function () {
                var k = el.dataset.herb;
                var v = el.value;
                if (el.type === "number") v = parseFloat(v) || 0;
                if (k === "instance" && typeof v === "string") v = v.trim().toUpperCase();
                state.herbForm[k] = v;
                if (k === "instance") applyHerbCatalogDefaults(v);
                if (k === "filter") {
                    render();
                    var f = body.querySelector('[data-herb="filter"]');
                    if (f) { f.focus(); f.setSelectionRange(f.value.length, f.value.length); }
                } else if (["instance", "posX", "posY", "posZ"].indexOf(k) >= 0) {
                    syncHerbPreview(true);
                }
            });
        });
        body.querySelectorAll("[data-vob]").forEach(function (el) {
            var ev = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(ev, function () {
                var k = el.dataset.vob;
                var v = el.value;
                if (el.type === "number") v = parseFloat(v) || 0;
                if ((k === "instance" || k === "visual") && typeof v === "string") v = normalizeVobVisual(v);
                state.vobForm[k] = v;
                if (k === "filter") {
                    state.vobPage = 0;
                    requestVobCatalog();
                    render();
                    var f = body.querySelector('[data-vob="filter"]');
                    if (f) { f.focus(); f.setSelectionRange(f.value.length, f.value.length); }
                } else if (["instance", "visual", "posX", "posY", "posZ", "rotX", "rotY", "rotZ"].indexOf(k) >= 0) {
                    syncVobPreview(true);
                } else if (k === "interactive") {
                    state.vobForm.interactive = +v || 0;
                }
            });
        });
        body.querySelectorAll("[data-house]").forEach(function (el) {
            var ev = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(ev, function () {
                var k = el.dataset.house;
                var v = el.value;
                if (el.type === "number" && v !== "") v = parseFloat(v) || 0;
                state.houseForm[k] = v;
                if (k === "name" && !state.houseForm.slug) state.houseForm.slug = houseSlug(v);
            });
        });
        body.querySelectorAll("[data-house-point]").forEach(function (el) {
            el.addEventListener("input", function () {
                var parts = String(el.dataset.housePoint || "").split(":");
                var idx = parseInt(parts[0], 10) || 0;
                var key = parts[1] || "x";
                while (state.houseForm.points.length <= idx) state.houseForm.points.push({ x: 0, y: 0, z: 0 });
                state.houseForm.points[idx][key] = parseFloat(el.value) || 0;
                syncHouseGhost();
            });
        });
        body.querySelectorAll("[data-teacher-skill]").forEach(function (el) {
            el.addEventListener("change", function () {
                var list = [];
                body.querySelectorAll("[data-teacher-skill]:checked").forEach(function (cb) { list.push(cb.dataset.teacherSkill); });
                state.humanCreator.teacherSkills = list.join(",");
            });
        });
        body.querySelectorAll("[data-field]").forEach(function (el) {
            var ev = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(ev, function () {
                var k = el.dataset.field;
                if (k === "npc-instance")  { state.npcForm.instance  = el.value.trim().toUpperCase(); state.npcCatalogEdit = state.npcForm.instance; }
                else if (k === "npc-name") state.npcForm.name      = el.value;
                else if (k === "npc-hostile")  state.npcForm.hostile  = +el.value || 0;
                else if (k === "npc-respawn")  state.npcForm.respawnSec = +el.value || 0;
                else if (k === "npc-tag")  state.npcForm.tag       = el.value;
                else if (k === "npc-kind")  state.npcForm.kind       = el.value;
                else if (k === "npc-posX") state.npcForm.posX = parseFloat(el.value) || 0;
                else if (k === "npc-posY") state.npcForm.posY = parseFloat(el.value) || 0;
                else if (k === "npc-posZ") state.npcForm.posZ = parseFloat(el.value) || 0;
                else if (k === "npc-angle") state.npcForm.angle = parseFloat(el.value) || 0;
                else if (k === "npc-step") state.npcForm.step = parseFloat(el.value) || 50;
                else if (k === "npc-world") state.npcForm.world = el.value;
                else if (k === "npc-cameraMode") state.npcForm.cameraMode = el.value;
                else if (k === "npc-filter") {
                    state.npcForm.filter = el.value;
                    render();
                    var f = body.querySelector('[data-field="npc-filter"]');
                    if (f) { f.focus(); f.setSelectionRange(f.value.length, f.value.length); }
                }
                syncNpcPreview();
            });
        });
        body.querySelectorAll("[data-catalog]").forEach(function (el) {
            var ev = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(ev, function () {
                var row = catalogEditRow();
                if (!row) return;
                var key = el.dataset.catalog;
                var value = el.value;
                if (el.type === "number") value = parseFloat(value) || 0;
                if (key === "tier") value = Math.max(1, parseInt(value, 10) || 1);
                if (key === "baseExperience") value = Math.max(0, parseInt(value, 10) || 0);
                if (key === "defaultHostile") value = +value ? 1 : 0;
                row[key] = value;
                if (key === "defaultHostile") state.npcForm.hostile = value;
            });
        });
        var pf = body.querySelector("[data-role='player-filter']");
        if (pf) pf.addEventListener("input", debounce(function () {
            state.playerFilter = pf.value;
            render();
            var f = body.querySelector("[data-role='player-filter']");
            if (f) { f.focus(); f.setSelectionRange(f.value.length, f.value.length); }
        }, 80));
        var sf = body.querySelector("[data-role='scheme-filter']");
        if (sf) sf.addEventListener("input", debounce(function () {
            state.schemeFilter = sf.value;
            render();
            var f = body.querySelector("[data-role='scheme-filter']");
            if (f) { f.focus(); f.setSelectionRange(f.value.length, f.value.length); }
        }, 120));
        var sc = body.querySelector("[data-role='scheme-cat']");
        if (sc) sc.addEventListener("change", function () {
            state.schemeCategoryFilter = +sc.value || 0;
            render();
        });
        var grids = body.querySelectorAll("[data-role='itemgrid']");
        grids.forEach(function (grid) {
            grid.addEventListener("mousemove", onItemMouseMove);
            grid.addEventListener("mouseleave", hideTooltip);
            grid.addEventListener("click", onItemClick);
        });
    }

    function debounce(fn, ms) {
        var t = null;
        return function () { clearTimeout(t); t = setTimeout(fn, ms); };
    }

    function onItemMouseMove(e) {
        var cell = e.target.closest(".adm-itemcell");
        if (!cell) { hideTooltip(); return; }
        var inst = cell.dataset.instance;
        if (!inst) return;
        var sch = state.schemesById[inst];
        if (!sch) return;
        showTooltip(sch, e);
        if (!state.details[inst]) {
            state.details[inst] = "loading";
            send("schemeDetails", { instance: inst });
        }
    }

    function onItemClick(e) {
        var cell = e.target.closest(".adm-itemcell");
        if (!cell) return;
        if (cell.classList.contains("adm-human-itemcell")) return;
        state.selectedScheme = cell.dataset.instance;
        render();
    }

    var QUALITY_COLOR_DEFAULT = "#d4af37";
    function showTooltip(sch, e) {
        ensureTooltip();
        var d = state.details[sch.instance];
        var detailed = (d && typeof d === "object") ? d : null;
        var name = itemName({ instance: sch.instance, name: (detailed && detailed.name) || sch.name });
        var desc = itemDesc({ instance: sch.instance, description: (detailed && detailed.description) || sch.description });
        var category = (detailed ? detailed.category : sch.category) || 0;
        var slot = (detailed ? detailed.slot : sch.slot) || 0;
        var damage = (detailed ? detailed.damage : sch.damage) || 0;
        var damageType = detailed ? detailed.damageType : 0;
        var value = (detailed ? detailed.value : sch.value) || 0;
        var weight = (detailed ? detailed.weight : sch.weight) || 0;
        var prot = (detailed && detailed.protection) || null;

        var color = QUALITY_COLOR_DEFAULT;
        var html = '<div class="adm-tooltip__name" style="color:' + color + '">' + escapeHtml(name) + "</div>";
        html += '<div class="adm-tooltip__sub">' + escapeHtml(catLabel(category) || "—") +
            (slot ? "  •  " + escapeHtml(slotLabel(slot) || "") : "") + "</div>";
        if (desc) html += '<div class="adm-tooltip__desc">' + escapeHtml(desc) + "</div>";
        html += '<div class="adm-tooltip__divider"></div>';
        if (damage)  html += stat(t("inv.stat.damage"), damage + (damageType != null ? " (" + damageLabel(damageType) + ")" : ""));
        if (prot) {
            if (prot.edge)  html += stat("Och. sieczne",  prot.edge);
            if (prot.blunt) html += stat("Och. obuchowe", prot.blunt);
            if (prot.point) html += stat("Och. kłute",    prot.point);
            if (prot.fire)  html += stat("Och. ogień",    prot.fire);
            if (prot.magic) html += stat("Och. magia",    prot.magic);
        }
        if (value)  html += stat(t("inv.stat.value"),  value + " " + t("inv.unit.gold"));
        if (weight) html += stat(t("inv.stat.weight"), weight);
        html += '<div class="adm-tooltip__instance">' + escapeHtml(sch.instance) + "</div>";
        tooltipEl.innerHTML = html;
        tooltipEl.style.setProperty("--tooltip-color", color);
        tooltipEl.classList.add("is-visible");
        moveTooltip(e);
    }
    function stat(label, value) {
        return '<div class="adm-tooltip__stat"><span>' + escapeHtml(label) + "</span><span>" + escapeHtml(String(value)) + "</span></div>";
    }
    function moveTooltip(e) {
        if (!tooltipEl) return;
        var x = Math.min(window.innerWidth - tooltipEl.offsetWidth - 16, e.clientX + 18);
        var y = Math.min(window.innerHeight - tooltipEl.offsetHeight - 16, e.clientY + 18);
        tooltipEl.style.left = x + "px";
        tooltipEl.style.top = y + "px";
    }
    function hideTooltip() { if (tooltipEl) tooltipEl.classList.remove("is-visible"); }

    function onAction(e) {
        var el = e.currentTarget;
        var a = el.dataset.action;
        if (a === "select-player") {
            if (e.target.closest("[data-stop]")) { e.stopPropagation(); return; }
            state.playerSelectedPid = +el.dataset.pid;
            return render();
        }
        if (a === "refresh-players") return send("players");
        if (a === "spawn-test-player-npc") { send("spawnTestPlayerNpc", {}); return setStatus(t("admin.debug.playerNpc.status"), ""); }
        if (a === "refresh-bans") return send("bans");
        if (a === "refresh-log") return send("log", { limit: 100 });
        if (a === "tp-to") return send("tpTo", { playerId: +el.dataset.pid });
        if (a === "tp-here") return send("tpHere", { playerId: +el.dataset.pid });
        if (a === "kick") {
            return openKickModal(+el.dataset.pid, el.dataset.name || ("PID " + el.dataset.pid));
        }
        if (a === "ban-pick") return openBanModal(+el.dataset.pid, +el.dataset.aid, +el.dataset.cid, el.dataset.name);
        if (a === "unban") return send("unban", { banId: +el.dataset.id });
        if (a === "give-pick") {
            state.giveTarget = { cid: +el.dataset.cid, name: el.dataset.name };
            activeTab = "items";
            buildTabs();
            send("players");
            send("schemes");
            return render();
        }
        if (a === "give-submit") {
            if (!state.giveTarget || !state.giveTarget.cid) return setStatus(t("admin.status.pickTarget"), "error");
            if (!state.selectedScheme) return setStatus(t("admin.status.pickItem"), "error");
            send("giveItem", {
                characterId: state.giveTarget.cid,
                instance: state.selectedScheme,
                amount: +state.giveAmount || 1,
                quality: +state.giveQuality || 0,
                upgrade: +state.giveUpgrade || 0
            });
            return setStatus(t("admin.status.giving"), "");
        }
        if (a === "inspect-inv") {
            activeTab = "inv";
            buildTabs();
            send("inv", { characterId: +el.dataset.cid });
            state.inv = null;
            return render();
        }
        if (a === "custom-reset") { state.custom = defaultCustom(); return render(); }
        if (a === "refresh-npc") { send("npcCatalog"); send("npcList"); send("npcPresetList"); return; }
        if (a === "npc-view") {
            state.npcView = el.dataset.view || "presets";
            if (state.npcView === "active") send("npcList");
            if (state.npcView === "herbs") { send("herbCatalog"); send("herbList"); }
            if (state.npcView === "presets") send("npcPresetList");
            if (state.npcView === "catalog") send("npcCatalog");
            if (state.npcView === "human") { if (!state.schemes.length) send("schemes"); state.humanCreator.preview = 1; send("adminNpcPreviewStart", humanPayload(false)); }
            return render();
        }
        if (a === "human-reset") {
            send("adminNpcPreviewStop", {});
            state.humanCreator = defaultHumanCreator();
            return render();
        }
        if (a === "human-cycle") {
            humanCycle(el.dataset.key || "", +el.dataset.dir || 1);
            return render();
        }
        if (a === "human-equip-toggle") {
            var slot = el.dataset.slot || "";
            state.humanPickSlot = state.humanPickSlot === slot ? "" : slot;
            return render();
        }
        if (a === "human-equip-pick") {
            var pickSlot = el.dataset.slot || "";
            state.humanCreator[pickSlot] = el.dataset.instance || "";
            state.humanPickSlot = "";
            syncHumanPreview();
            return render();
        }
        if (a === "merchant-stock-toggle") {
            state.humanMerchantPick = !state.humanMerchantPick;
            return render();
        }
        if (a === "merchant-stock-add") {
            var stock = parseMerchantStock(state.humanCreator.merchantItems);
            var instance = el.dataset.instance || "";
            var amount = Math.max(1, +state.humanCreator.merchantAmount || 1);
            var found = false;
            stock.forEach(function (entry) {
                if (entry.instance === instance) { entry.amount += amount; found = true; }
            });
            if (!found && instance) stock.push({ instance: instance, amount: amount });
            state.humanCreator.merchantItems = serializeMerchantStock(stock);
            state.humanMerchantPick = false;
            return render();
        }
        if (a === "merchant-stock-remove") {
            var currentStock = parseMerchantStock(state.humanCreator.merchantItems);
            currentStock.splice(+el.dataset.index || 0, 1);
            state.humanCreator.merchantItems = serializeMerchantStock(currentStock);
            return render();
        }
        if (a === "human-preview") {
            state.humanCreator.preview = 1;
            send("adminNpcPreviewStart", humanPayload(false));
            return render();
        }
        if (a === "human-preview-stop") {
            state.humanCreator.preview = 0;
            send("adminNpcPreviewStop", {});
            return render();
        }
        if (a === "human-nudge") {
            var h = state.humanCreator;
            var step = +h.step || 50;
            var axis = el.dataset.axis || "";
            if (!h.preview) { h.preview = 1; send("adminNpcPreviewStart", humanPayload(false)); }
            send("adminNpcPreviewNudge", { axis: axis, step: step });
            return render();
        }
        if (a === "human-anim-preview") {
            var ha = state.humanCreator;
            if (!ha.preview) { ha.preview = 1; send("adminNpcPreviewStart", humanPayload(false)); }
            send("adminNpcPreviewAnim", { animation: ha.idleAnimation || "" });
            return;
        }
        if (a === "human-anim-stop") {
            send("adminNpcPreviewAnim", { animation: "" });
            return;
        }
        if (a === "human-spawn") {
            var hc = state.humanCreator;
            if (!hc.instance) return setStatus(t("admin.status.pickInstance"), "error");
            var equipment = { weapon: hc.weapon || "", armor: hc.armor || "", ranged: hc.ranged || "" };
            var spawnPayload = {
                instance: hc.instance,
                name: hc.name || "",
                tag: hc.tag || "human",
                kind: (hc.merchantItems || "") ? "merchant" : "npc",
                hostile: +hc.hostile || 0,
                respawnSec: +hc.respawnSec || 0,
                bodyModel: hc.bodyModel || "HUM_BODY_NAKED0",
                bodyTex: +hc.bodyTex || 0,
                headModel: hc.headModel || "HUM_HEAD_BALD",
                headTex: +hc.headTex || 0,
                fatness: +hc.fatness || 0,
                voice: +hc.voice || 0,
                hp: +hc.hp || 0,
                level: +hc.level || 0,
                strength: +hc.strength || 0,
                dexterity: +hc.dexterity || 0,
                idleAnimation: hc.idleAnimation || "S_STAND",
                aggroRadius: +hc.aggroRadius || 900,
                baseExperience: +hc.baseExperience || 0,
                teacherSkills: hc.teacherSkills || "",
                teachCost: +hc.teachCost || 100,
                metadata: JSON.stringify({ equipment: equipment, weapon: hc.weapon || "", armor: hc.armor || "", ranged: hc.ranged || "", expReward: +hc.baseExperience || 0, animation: hc.idleAnimation || "", merchantItems: hc.merchantItems || "" })
            };
            if (humanHasPosition()) {
                spawnPayload.posX = +hc.posX || 0;
                spawnPayload.posY = +hc.posY || 0;
                spawnPayload.posZ = +hc.posZ || 0;
                spawnPayload.angle = +hc.angle || 0;
                spawnPayload.world = hc.world || "";
            }
            send("npcSpawn", spawnPayload);
            send("adminNpcPreviewStop", {});
            state.humanCreator.preview = 0;
            return setStatus(tFmt("admin.status.spawning", hc.name || hc.instance), "");
        }
        if (a === "npc-pick") {
            state.npcForm.instance = el.dataset.instance || "";
            var h = +el.dataset.hostile;
            if (!isNaN(h)) state.npcForm.hostile = h;
            syncNpcPreview();
            return render();
        }
        if (a === "npc-preview") {
            if (!state.npcForm.instance) return setStatus(t("admin.status.pickInstance"), "error");
            state.npcForm.preview = 1;
            send("adminNpcPreviewStart", npcPayload(false));
            return render();
        }
        if (a === "npc-preview-stop") {
            state.npcForm.preview = 0;
            send("adminNpcPreviewStop", {});
            return render();
        }
        if (a === "npc-nudge") {
            if (!state.npcForm.instance) return setStatus(t("admin.status.pickInstance"), "error");
            var nf = state.npcForm;
            var nstep = +nf.step || 50;
            if (!nf.preview) { nf.preview = 1; send("adminNpcPreviewStart", npcPayload(false)); }
            send("adminNpcPreviewNudge", { axis: el.dataset.axis || "", step: nstep });
            return render();
        }
        if (a === "npc-editor-pick") {
            state.npcEditor.instance = el.dataset.instance || "";
            var h2 = +el.dataset.hostile;
            if (!isNaN(h2)) state.npcEditor.hostile = h2;
            var pickedCatalog = (state.npcCatalog || []).filter(function (x) { return x.instance === state.npcEditor.instance; })[0];
            if (pickedCatalog) {
                state.npcEditor.category = pickedCatalog.category || state.npcEditor.category;
                state.npcEditor.baseExperience = pickedCatalog.baseExperience || state.npcEditor.baseExperience || 0;
            }
            return render();
        }
        if (a === "npc-editor-cancel") {
            state.npcEditor = defaultNpcEditor();
            state.npcEditingId = 0;
            state.npcView = "presets";
            return render();
        }
        if (a === "npc-preset-new") {
            state.npcEditor = defaultNpcEditor();
            state.npcEditingId = 0;
            state.npcView = "editor";
            return render();
        }
        if (a === "npc-preset-edit" || a === "npc-preset-clone") {
            var pid = +el.dataset.id;
            var src = (state.npcPresets || []).filter(function (x) { return x.id === pid; })[0];
            if (!src) return;
            state.npcEditor = {
                id: a === "npc-preset-edit" ? src.id : 0,
                code: a === "npc-preset-edit" ? src.code : (src.code + "_copy"),
                label: src.label || "",
                instance: src.instance || "",
                category: src.category || "monster",
                hostile: src.hostile || 0,
                respawnSec: src.respawnSec || 60,
                scaleX: src.scaleX || 1.0, scaleY: src.scaleY || 1.0, scaleZ: src.scaleZ || 1.0,
                fatness: src.fatness || 0.0,
                hp: src.hp || 0, level: src.level || 0,
                strength: src.strength || 0, dexterity: src.dexterity || 0,
                bodyModel: src.bodyModel || "", bodyTex: (src.bodyTex == null ? -1 : src.bodyTex),
                headModel: src.headModel || "", headTex: (src.headTex == null ? -1 : src.headTex),
                voice: src.voice || 0,
                kind: src.kind || "monster",
                idleAnimation: src.idleAnimation || "",
                aggroRadius: src.aggroRadius || 900,
                attackRange: src.attackRange || 180,
                attackDamage: src.attackDamage || 10,
                walkSpeed: src.walkSpeed || 250,
                baseExperience: src.baseExperience || 0
            };
            state.npcEditingId = state.npcEditor.id;
            state.npcView = "editor";
            return render();
        }
        if (a === "npc-preset-delete") {
            send("npcPresetDelete", { id: +el.dataset.id });
            return setStatus(t("admin.status.deletingPreset"), "");
        }
        if (a === "npc-preset-save" || a === "npc-preset-save-spawn") {
            var ed = state.npcEditor;
            if (!ed.instance) return setStatus(t("admin.status.pickInstance"), "error");
            send("npcPresetSave", ed);
            if (a === "npc-preset-save-spawn") {
                send("npcSpawn", {
                    instance: ed.instance,
                    name: ed.label || "",
                    kind: ed.kind || "monster",
                    hostile: +ed.hostile || 0,
                    respawnSec: +ed.respawnSec || 0,
                    scaleX: +ed.scaleX || 1, scaleY: +ed.scaleY || 1, scaleZ: +ed.scaleZ || 1,
                    fatness: +ed.fatness || 0,
                    hp: +ed.hp || 0, level: +ed.level || 0,
                    strength: +ed.strength || 0, dexterity: +ed.dexterity || 0,
                    bodyModel: ed.bodyModel || "", bodyTex: +ed.bodyTex,
                    headModel: ed.headModel || "", headTex: +ed.headTex,
                    voice: +ed.voice || 0,
                    idleAnimation: ed.idleAnimation || "",
                    aggroRadius: +ed.aggroRadius || 0,
                    attackRange: +ed.attackRange || 0,
                    attackDamage: +ed.attackDamage || 0,
                    walkSpeed: +ed.walkSpeed || 0,
                    baseExperience: +ed.baseExperience || 0
                });
            }
            return setStatus(t("admin.status.savingPreset"), "");
        }
        if (a === "npc-spawn-preset") {
            send("npcSpawn", { presetId: +el.dataset.id });
            return setStatus(tFmt("admin.status.spawning", "preset#" + el.dataset.id), "");
        }
        if (a === "npc-spawn") {
            if (!state.npcForm.instance) return setStatus(t("admin.status.pickInstance"), "error");
            send("npcSpawn", npcPayload());
            send("adminNpcPreviewStop", {});
            state.npcForm.preview = 0;
            return setStatus(tFmt("admin.status.spawning", state.npcForm.instance), "");
        }
        if (a === "npc-spawn-instance") {
            var inst = el.dataset.instance || "";
            if (!inst) return setStatus(t("admin.status.pickInstance"), "error");
            var wasPreviewing = !!state.npcForm.preview;
            state.npcForm.instance = inst;
            state.npcCatalogEdit = inst;
            state.npcForm.hostile = +el.dataset.hostile || 0;
            state.npcForm.kind = el.dataset.kind || "monster";
            state.npcForm.preview = 1;
            send(wasPreviewing ? "adminNpcPreviewUpdate" : "adminNpcPreviewStart", npcPayload(false));
            return render();
        }
        if (a === "npc-delete") {
            send("npcDelete", { id: +el.dataset.id });
            return setStatus(tFmt("admin.status.deleting", el.dataset.id), "");
        }
        if (a === "npc-catalog-save") {
            var base = catalogEditRow();
            if (!base) return setStatus(t("admin.status.pickInstance"), "error");
            send("npcCatalogSave", base);
            return setStatus("Zapisuję bazowy schemat " + base.instance, "");
        }
        if (a === "refresh-herbs") { send("herbCatalog"); send("herbList"); return; }
        if (a === "herb-reset") { state.herbForm = defaultHerbForm(); send("adminHerbPreviewStop", {}); return render(); }
        if (a === "herb-pick") {
            state.herbForm.instance = el.dataset.instance || "";
            applyHerbCatalogDefaults(state.herbForm.instance);
            send("adminHerbPreviewStart", herbPreviewPayload(false));
            return render();
        }
        if (a === "herb-preview") {
            send("adminHerbPreviewStart", herbPreviewPayload(false));
            return setStatus(t("admin.herbs.status.previewActive"), "");
        }
        if (a === "herb-floor") {
            send("adminHerbPreviewFloor", {});
            return;
        }
        if (a === "herb-nudge") {
            send("adminHerbPreviewNudge", { axis: el.dataset.axis || "", step: +state.npcForm.step || 50 });
            return;
        }
        if (a === "herb-edit") {
            var hs = (state.herbSpots || []).filter(function (x) { return x.plantId === el.dataset.id; })[0];
            if (!hs) return;
            state.herbForm = { instance: hs.instance || "", plantId: hs.plantId || "", filter: state.herbForm.filter || "", posX: Math.round(hs.x || 0), posY: Math.round(hs.y || 0), posZ: Math.round(hs.z || 0), world: hs.world || "", gatherMs: hs.gatherMs || 7000, cooldownSec: hs.cooldownSec || 3600, successChance: hs.successChance || 90 };
            send("adminHerbPreviewStart", herbPreviewPayload(true));
            return render();
        }
        if (a === "herb-save-here" || a === "herb-save-pos") {
            if (!state.herbForm.instance) return setStatus(t("admin.status.pickInstance"), "error");
            var hf = state.herbForm;
            var payload = { instance: hf.instance, plantId: hf.plantId || "", gatherMs: +hf.gatherMs || 0, cooldownSec: +hf.cooldownSec || 0, successChance: +hf.successChance || 100 };
            if (a === "herb-save-pos") { payload.posX = +hf.posX || 0; payload.posY = +hf.posY || 0; payload.posZ = +hf.posZ || 0; payload.world = hf.world || ""; }
            send("herbSave", payload);
            return setStatus(tFmt("admin.herbs.status.saving", hf.instance), "");
        }
        if (a === "herb-delete") {
            send("herbDelete", { plantId: el.dataset.id || "" });
            return setStatus(tFmt("admin.herbs.status.deleting", el.dataset.id || ""), "");
        }
        if (a === "refresh-houses") { send("houseList"); return; }
        if (a === "house-new") { state.houseForm = defaultHouseForm(); syncHouseGhost(); return render(); }
        if (a === "house-ghost-toggle") {
            if (state.houseGhostActive) {
                state.houseGhostActive = false;
                send("adminHouseGhostStop", {});
                return render();
            }
            state.houseGhostActive = true;
            send("adminHouseGhostStart", houseGhostPayload());
            setStatus(t("admin.houses.ghostActive"), "ok");
            return render();
        }
        if (a === "house-ghost-focus") { send("adminHouseGhostFocus", {}); return; }
        if (a === "house-boundary-toggle") { send("adminHouseBoundaryToggle", {}); return; }
        if (a === "house-add-point") {
            if (!state.houseGhostActive) {
                state.houseGhostActive = true;
                send("adminHouseGhostStart", houseGhostPayload());
            }
            send("adminHouseCapture", { slot: "point", index: (state.houseForm.points || []).length });
            return setStatus(t("admin.houses.capturing"), "");
        }
        if (a === "house-undo-point") {
            if ((state.houseForm.points || []).length) state.houseForm.points.pop();
            syncHouseGhost();
            return render();
        }
        if (a === "house-clear-points") { state.houseForm.points = []; syncHouseGhost(); return render(); }
        if (a === "house-remove-point") { state.houseForm.points.splice(+el.dataset.index || 0, 1); syncHouseGhost(); return render(); }
        if (a === "house-capture") { send("adminHouseCapture", { slot: el.dataset.slot || "point", index: +el.dataset.index || 0 }); return; }
        if (a === "house-edit") {
            var he = (state.houses || []).filter(function (x) { return +x.id === (+el.dataset.id || 0); })[0];
            if (!he) return;
            var entry = he.entry || { x: 0, y: 0, z: 0 };
            state.houseForm = {
                id: he.id || 0,
                name: he.name || "",
                slug: he.slug || "",
                world: he.world || "",
                ownerType: he.ownerType == null ? "" : he.ownerType,
                ownerId: he.ownerId == null ? "" : he.ownerId,
                priceGold: he.priceGold || 0,
                weeklyRentGold: he.weeklyRentGold || 0,
                color: he.color || "#79C8FF",
                modeId: he.modeId || 0,
                entryX: Math.round(entry.x || 0),
                entryY: Math.round(entry.y || 0),
                entryZ: Math.round(entry.z || 0),
                entryHeading: Math.round(he.entryHeading || 0),
                points: (he.points || he.corners || []).map(function (p) { return { x: Math.round(p.x || 0), y: Math.round(p.y || 0), z: Math.round(p.z || 0) }; })
            };
            syncHouseGhost();
            return render();
        }
        if (a === "house-save") {
            if (!state.houseForm.name) return setStatus(t("admin.houses.errorName"), "error");
            if ((state.houseForm.points || []).length < 3) return setStatus(t("admin.houses.errorPoints"), "error");
            send("houseSave", housePayload());
            return setStatus(t("admin.houses.saving"), "");
        }
        if (a === "house-delete") {
            send("houseDelete", { id: +el.dataset.id || +state.houseForm.id || 0 });
            return setStatus(t("admin.houses.deleting"), "");
        }
        if (a === "refresh-vobs") { requestVobCatalog(); send("vobList"); return; }
        if (a === "vob-source") {
            state.vobSource = el.dataset.source || "data.xml";
            state.vobCategory = "";
            state.vobPage = 0;
            state.vobCatalog = [];
            state.vobCategories = [];
            state.vobCategoryStats = [];
            requestVobCatalog();
            return render();
        }
        if (a === "vob-category") {
            state.vobCategory = el.dataset.category || "";
            state.vobPage = 0;
            state.vobCatalog = [];
            requestVobCatalog();
            return render();
        }
        if (a === "vob-page") {
            state.vobPage = Math.max(0, state.vobPage + (+el.dataset.dir || 0));
            state.vobCatalog = [];
            requestVobCatalog();
            return render();
        }
        if (a === "vob-reset") { state.vobForm = defaultVobForm(); send("adminVobPreviewStop", {}); return render(); }
        if (a === "vob-pick") {
            state.vobForm.instance = el.dataset.instance || "";
            state.vobForm.visual = el.dataset.visual || "";
            state.vobForm.name = el.dataset.name || state.vobForm.instance || state.vobForm.visual;
            send("adminVobPreviewStart", vobPreviewPayload(false));
            return render();
        }
        if (a === "vob-preview") {
            if (!state.vobForm.visual && !state.vobForm.instance) return setStatus(t("admin.status.pickInstance"), "error");
            send("adminVobPreviewStart", vobPreviewPayload(false));
            return setStatus(t("admin.vobs.status.previewActive"), "");
        }
        if (a === "vob-floor") {
            send("adminVobPreviewFloor", {});
            return;
        }
        if (a === "vob-nudge") {
            send("adminVobPreviewNudge", { axis: el.dataset.axis || "", step: +state.vobForm.step || 50 });
            return;
        }
        if (a === "vob-edit") {
            var vs = (state.vobs || []).filter(function (x) { return x.vobId === el.dataset.id; })[0];
            if (!vs) return;
            state.vobForm = { instance: "", name: vs.name || "", visual: vs.visual || "", vobId: vs.vobId || "", filter: state.vobForm.filter || "", posX: Math.round(vs.x || 0), posY: Math.round(vs.y || 0), posZ: Math.round(vs.z || 0), rotX: Math.round(vs.rotX || 0), rotY: Math.round(vs.rotY || 0), rotZ: Math.round(vs.rotZ || 0), world: vs.world || "", interactive: vs.interactive ? 1 : 0, step: state.vobForm.step || 50 };
            send("adminVobPreviewStart", vobPreviewPayload(true));
            return render();
        }
        if (a === "vob-save-here" || a === "vob-save-pos") {
            var vf = state.vobForm;
            if (!vf.visual && !vf.instance) return setStatus(t("admin.status.pickInstance"), "error");
            var vPayload = { instance: vf.instance || "", visual: vf.visual || "", name: vf.name || "", vobId: vf.vobId || "", interactive: +vf.interactive || 0, rotX: +vf.rotX || 0, rotY: +vf.rotY || 0, rotZ: +vf.rotZ || 0 };
            if (a === "vob-save-pos") {
                vPayload.posX = +vf.posX || 0; vPayload.posY = +vf.posY || 0; vPayload.posZ = +vf.posZ || 0;
                vPayload.rotX = +vf.rotX || 0; vPayload.rotY = +vf.rotY || 0; vPayload.rotZ = +vf.rotZ || 0;
                vPayload.world = vf.world || "";
            }
            send("vobSave", vPayload);
            return setStatus(tFmt("admin.vobs.status.saving", vf.name || vf.visual || vf.instance), "");
        }
        if (a === "vob-delete") {
            send("vobDelete", { vobId: el.dataset.id || "" });
            return setStatus(tFmt("admin.vobs.status.deleting", el.dataset.id || ""), "");
        }
        if (a === "custom-save") {
            var c = state.custom;
            if (!c.instance || c.instance.length < 3) return setStatus(t("admin.status.instanceTooShort"), "error");
            send("saveCustom", {
                instance: c.instance, name: c.name, description: c.description, visual: c.visual,
                category: +c.category, slot: +c.slot, value: +c.value, weight: +c.weight,
                stackMax: +c.stackMax || 1, damage: +c.damage, damageType: +c.damageType,
                protection: { edge: +c.protEdge, blunt: +c.protBlunt, point: +c.protPoint, fire: +c.protFire, magic: +c.protMagic },
                flags: +c.flags
            });
            return setStatus(tFmt("admin.status.saving", c.instance), "");
        }
    }

    function promptBan(pid, aid, cid, name) {
        openBanModal(pid, aid, cid, name);
    }

    var modalEl = null;
    function ensureModal() {
        if (modalEl) return modalEl;
        modalEl = document.createElement("div");
        modalEl.id = "adm-modal";
        modalEl.className = "adm-modal";
        modalEl.hidden = true;
        modalEl.innerHTML = '<div class="adm-modal__backdrop"></div><div class="adm-modal__panel"></div>';
        document.body.appendChild(modalEl);
        modalEl.querySelector(".adm-modal__backdrop").addEventListener("click", closeModal);
        return modalEl;
    }
    function closeModal() {
        if (modalEl) { modalEl.hidden = true; modalEl.querySelector(".adm-modal__panel").innerHTML = ""; }
    }
    function openModal(html, onMount) {
        ensureModal();
        var pnl = modalEl.querySelector(".adm-modal__panel");
        pnl.innerHTML = html;
        modalEl.hidden = false;
        if (onMount) onMount(pnl);
    }

    function openKickModal(pid, name) {
        var html = '<h3 class="adm-modal__title">' + escapeHtml(t("admin.modal.kick", "Kick")) + '</h3>';
        html += '<p class="adm-modal__sub">' + escapeHtml(name) + ' <span class="adm-modal__pid">PID ' + pid + '</span></p>';
        html += '<label class="adm-modal__label">' + escapeHtml(t("admin.modal.reason")) + '</label>';
        html += '<input type="text" class="adm-modal__input" id="kick-reason" placeholder="AFK / cheating" autofocus>';
        html += '<div class="adm-modal__actions">';
        html += '<button class="adm-btn" data-mclose>' + escapeHtml(t("admin.modal.cancel")) + '</button>';
        html += '<button class="adm-btn adm-btn--danger" data-mok>' + escapeHtml(t("admin.modal.kick")) + '</button>';
        html += '</div>';
        openModal(html, function (pnl) {
            var inp = pnl.querySelector("#kick-reason");
            try { inp.focus(); } catch (e) {}
            pnl.querySelector("[data-mclose]").addEventListener("click", closeModal);
            pnl.querySelector("[data-mok]").addEventListener("click", function () {
                var reason = (inp.value || "").trim() || "Kicked by admin";
                send("kick", { playerId: pid, reason: reason });
                setStatus(tFmt("admin.status.kicking", name), "");
                closeModal();
            });
            inp.addEventListener("keydown", function (e) {
                if (e.key === "Enter") pnl.querySelector("[data-mok]").click();
                else if (e.key === "Escape") closeModal();
            });
        });
    }

    function openBanModal(pid, aid, cid, name) {
        var html = '<h3 class="adm-modal__title">Ban gracza</h3>';
        html += '<p class="adm-modal__sub">' + escapeHtml(name || "?") + ' <span class="adm-modal__pid">PID ' + pid + ' · ACC ' + aid + ' · CHAR ' + cid + '</span></p>';
        html += '<div class="adm-modal__grid">';
        html += '<label class="adm-modal__label">Czas (minuty)</label>';
        html += '<input type="number" class="adm-modal__input" id="ban-min" value="0" min="0" placeholder="0 = perma">';
        html += '<label class="adm-modal__label">' + escapeHtml(t("admin.modal.reason")) + '</label>';
        html += '<input type="text" class="adm-modal__input" id="ban-reason" placeholder="reason">';
        html += '<label class="adm-modal__label">Zakres</label>';
        html += '<select class="adm-modal__input" id="ban-scope">' +
            '<option value="1">Konto</option>' +
            '<option value="2">Tylko postać</option>' +
            '<option value="3">Sam IP</option>' +
            '<option value="4">Sam Serial</option>' +
            '</select>';
        html += '<label class="adm-modal__label">Dodatkowo</label>';
        html += '<div class="adm-modal__checks">' +
            '<label><input type="checkbox" id="ban-ip"> + IP</label>' +
            '<label><input type="checkbox" id="ban-ser"> + Serial</label>' +
            '<label><input type="checkbox" id="ban-all"> Wszystko</label>' +
            '</div>';
        html += '<label class="adm-modal__label">Skróty</label>';
        html += '<div class="adm-modal__chips">' +
            '<button class="adm-chip" data-min="60">1h</button>' +
            '<button class="adm-chip" data-min="1440">1 dzień</button>' +
            '<button class="adm-chip" data-min="10080">7 dni</button>' +
            '<button class="adm-chip" data-min="43200">30 dni</button>' +
            '<button class="adm-chip" data-min="0">Perma</button>' +
            '</div>';
        html += '</div>';
        html += '<div class="adm-modal__actions">';
        html += '<button class="adm-btn" data-mclose>' + escapeHtml(t("admin.modal.cancel")) + '</button>';
        html += '<button class="adm-btn adm-btn--danger" data-mok>' + escapeHtml(t("admin.modal.banKick")) + '</button>';
        html += '</div>';
        openModal(html, function (pnl) {
            var minEl = pnl.querySelector("#ban-min");
            var reasonEl = pnl.querySelector("#ban-reason");
            var scopeEl = pnl.querySelector("#ban-scope");
            var ipEl = pnl.querySelector("#ban-ip");
            var serEl = pnl.querySelector("#ban-ser");
            var allEl = pnl.querySelector("#ban-all");
            try { reasonEl.focus(); } catch (e) {}
            allEl.addEventListener("change", function () {
                if (allEl.checked) { ipEl.checked = true; serEl.checked = true; scopeEl.value = "1"; }
            });
            pnl.querySelectorAll(".adm-chip").forEach(function (b) {
                b.addEventListener("click", function () { minEl.value = b.dataset.min; });
            });
            pnl.querySelector("[data-mclose]").addEventListener("click", closeModal);
            pnl.querySelector("[data-mok]").addEventListener("click", function () {
                var minutes = +minEl.value || 0;
                var reason = (reasonEl.value || "").trim() || "—";
                var scope = +scopeEl.value || 1;
                var banIp = ipEl.checked || allEl.checked;
                var banSerial = serEl.checked || allEl.checked;
                send("ban", {
                    playerId: pid, accountId: aid, characterId: cid, scope: scope,
                    minutes: minutes, reason: reason, banIp: banIp, banSerial: banSerial
                });
                setStatus(tFmt("admin.status.banning", name || pid), "");
                closeModal();
            });
        });
    }

    function onResponse(p) {
        if (!p || !p.action) return;
        var pl = p.payload || {};
        if (p.action === "players" && p.success) { state.players = pl.players || []; return render(); }
        if (p.action === "schemes" && p.success) {
            state.schemes = pl.schemes || [];
            state.schemesById = {};
            state.schemes.forEach(function (s) { state.schemesById[s.instance] = s; });
            return render();
        }
        if (p.action === "schemeDetails" && p.success) {
            state.details[pl.instance] = pl;
            return;
        }
        if (p.action === "bans" && p.success) { state.bans = pl.bans || []; return render(); }
        if (p.action === "log"  && p.success) { state.log  = pl.entries || []; return render(); }
        if (p.action === "inv"  && p.success) { state.inv  = pl; return render(); }
        if (p.action === "npcCatalog" && p.success) { state.npcCatalog = pl.entries || []; return render(); }
        if (p.action === "npcCatalogSave" && p.success) { send("npcCatalog"); return setStatus("Zapisano bazowy schemat NPC", "ok"); }
        if (p.action === "npcList" && p.success)    { state.npcSpawns  = pl.spawns  || []; return render(); }
        if (p.action === "npcPresetList" && p.success) { state.npcPresets = pl.presets || []; return render(); }
        if (p.action === "herbCatalog" && p.success) { state.herbCatalog = pl.entries || []; return render(); }
        if (p.action === "herbList" && p.success) { state.herbSpots = pl.spots || []; return render(); }
        if (p.action === "vobCatalog" && p.success) {
            state.vobCatalog = pl.entries || [];
            state.vobCategories = pl.categories || [];
            state.vobCategoryStats = pl.categoryStats || [];
            state.vobCategory = pl.category || state.vobCategory || "";
            state.vobMatched = +pl.matched || 0;
            state.vobSourceTotal = +pl.sourceTotal || 0;
            state.vobPageSize = +pl.limit || state.vobPageSize || 120;
            return render();
        }
        if (p.action === "vobList" && p.success) { state.vobs = pl.vobs || []; return render(); }
        if (p.action === "houseList" && p.success) { state.houses = pl.houses || []; return render(); }
        if (p.action === "adminHouseGhost" && p.success) {
            state.houseGhostActive = !!(+pl.active || 0);
            return render(true);
        }
        if (p.action === "adminHouseBoundaryToggle" && p.success) {
            state.houseBoundaryActive = !!(+pl.active || 0);
            return render(true);
        }
        if (p.action === "adminHouseCapture" && p.success) {
            if (pl.world) state.houseForm.world = pl.world;
            if (pl.slot === "entry") {
                state.houseForm.entryX = Math.round(pl.posX || 0);
                state.houseForm.entryY = Math.round(pl.posY || 0);
                state.houseForm.entryZ = Math.round(pl.posZ || 0);
                state.houseForm.entryHeading = Math.round(pl.angle || 0);
            } else {
                var idx = +pl.index || 0;
                var point = { x: Math.round(pl.posX || 0), y: Math.round(pl.posY || 0), z: Math.round(pl.posZ || 0) };
                if (idx < 0 || idx >= state.houseForm.points.length) state.houseForm.points.push(point);
                else state.houseForm.points[idx] = point;
            }
            syncHouseGhost();
            setStatus(t("admin.houses.captured"), "ok");
            return render(true);
        }
        if (p.action === "adminHerbPreview" && p.success) {
            state.herbForm.instance = pl.instance || state.herbForm.instance;
            state.herbForm.posX = Math.round(pl.posX || 0);
            state.herbForm.posY = Math.round(pl.posY || 0);
            state.herbForm.posZ = Math.round(pl.posZ || 0);
            updateHerbPreviewDom();
            return;
        }
        if (p.action === "adminVobPreview" && p.success) {
            state.vobForm.instance = pl.instance || state.vobForm.instance;
            state.vobForm.visual = pl.visual || state.vobForm.visual;
            state.vobForm.posX = Math.round(pl.posX || 0);
            state.vobForm.posY = Math.round(pl.posY || 0);
            state.vobForm.posZ = Math.round(pl.posZ || 0);
            state.vobForm.rotX = Math.round(pl.rotX || 0);
            state.vobForm.rotY = Math.round(pl.rotY || 0);
            state.vobForm.rotZ = Math.round(pl.rotZ || 0);
            updateVobPreviewDom();
            return;
        }
        if (p.action === "adminNpcPreview" && p.success) {
            var target = pl.mode === "npc" ? state.npcForm : state.humanCreator;
            target.posX = Math.round(pl.posX || 0);
            target.posY = Math.round(pl.posY || 0);
            target.posZ = Math.round(pl.posZ || 0);
            target.angle = Math.round(pl.angle || 0);
            if (pl.world) target.world = pl.world;
            updateNpcPreviewDom(pl.mode === "npc" ? "npc" : "human");
            return;
        }
        if (p.action === "npcPresetSave" && p.success) {
            state.npcView = "presets";
            state.npcEditor = defaultNpcEditor();
            send("npcPresetList");
            return;
        }
        if (p.action === "vanish" && p.success) {
            try { bridge.emit("phoenix:account:vanish", { vanished: !!pl.vanished }); } catch (e) {}
        }
        if (p.action === "saveCustom" && p.success) {
            send("schemes");
        }
        if (p.success) {
            setStatus(tFmt("admin.status.ok", p.action), "ok");
            if (p.action === "giveItem") { send("players"); if (state.giveTarget && state.giveTarget.cid) send("inv", { characterId: state.giveTarget.cid }); }
            if (p.action === "ban" || p.action === "unban") { send("players"); send("bans"); send("log", { limit: 100 }); }
            if (p.action === "npcSpawn" || p.action === "npcDelete" || p.action === "npcUpdate") send("npcList");
            if (p.action === "npcPresetSave" || p.action === "npcPresetDelete") send("npcPresetList");
            if (p.action === "herbSave" || p.action === "herbDelete") send("herbList");
            if (p.action === "vobSave" || p.action === "vobDelete") send("vobList");
            if (p.action === "houseSave" || p.action === "houseDelete") send("houseList");
            if (p.action === "kick" || p.action === "tpTo" || p.action === "tpHere" || p.action === "vanish") {
                if (activeTab === "log") send("log", { limit: 100 });
            }
        } else {
            setStatus(tFmt("admin.status.error", p.action, p.error || "?"), "error");
        }
    }

    bridge.on("phoenix:admin:response", onResponse);
    bridge.on("phoenix:account:identity", function (p) {
        isAdmin = !!(p && p.isAdmin);
        var btn = document.getElementById("escmenu-admin");
        if (btn) {
            if (isAdmin) btn.removeAttribute("hidden");
            else btn.setAttribute("hidden", "");
        }
    });

    function init() {
        loadRenderDebug();
        var btn = document.getElementById("escmenu-admin");
        if (btn && isAdmin) btn.removeAttribute("hidden");
        if (global.app && global.app.renderLangSwitcher) global.app.renderLangSwitcher();
        if (global.PhoenixI18n) global.PhoenixI18n.onChange(function () { buildTabs(); render(); });
    }
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
    else init();

    global.PhoenixAdminPanel = { open: open, close: close, isOpen: function () { return isOpen; } };
})(typeof window !== "undefined" ? window : globalThis);
