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
    var ADMIN_LAYOUT_KEY = "phoenix:admin-layout:v1";
    var adminLayout = { leftWidth: null, rightWidth: null, modals: {} };
    var adminResize = null;

    function adminClamp(value, min, max) {
        return Math.max(min, Math.min(max, value));
    }

    function loadAdminLayout() {
        try {
            var stored = JSON.parse(localStorage.getItem(ADMIN_LAYOUT_KEY) || "{}");
            if (isFinite(+stored.leftWidth)) adminLayout.leftWidth = +stored.leftWidth;
            if (isFinite(+stored.rightWidth)) adminLayout.rightWidth = +stored.rightWidth;
            if (stored.modals && typeof stored.modals === "object") adminLayout.modals = stored.modals;
        } catch (e) {}
    }

    function saveAdminLayout() {
        try { localStorage.setItem(ADMIN_LAYOUT_KEY, JSON.stringify(adminLayout)); } catch (e) {}
    }

    function applyAdminColumns() {
        var root = document.getElementById("phoenix-adminpanel");
        if (!root) return;
        var maxLeft = Math.max(220, Math.min(520, window.innerWidth - 720));
        var left = adminLayout.leftWidth == null ? 286 : adminClamp(adminLayout.leftWidth, 180, maxLeft);
        var maxRight = Math.max(420, window.innerWidth - left - 260);
        var right = adminLayout.rightWidth == null ? adminClamp(window.innerWidth * 0.39, 560, 760) : adminClamp(adminLayout.rightWidth, 380, maxRight);
        adminLayout.leftWidth = left;
        adminLayout.rightWidth = right;
        root.style.setProperty("--adm-left-panel-width", Math.round(left) + "px");
        root.style.setProperty("--adm-right-panel-width", Math.round(right) + "px");
    }

    function adminModalKey(element) {
        return element.classList.contains("adm-modal__panel--db") ? "database" : "dialog";
    }

    function applyAdminModal(element) {
        var saved = adminLayout.modals[adminModalKey(element)];
        if (!saved) return;
        var width = adminClamp(+saved.width || 560, 320, Math.max(320, window.innerWidth - 40));
        var height = adminClamp(+saved.height || 240, 160, Math.max(160, window.innerHeight - 40));
        element.style.width = Math.round(width) + "px";
        element.style.height = Math.round(height) + "px";
    }

    function applyAdminModals() {
        document.querySelectorAll(".adm-modal__panel").forEach(applyAdminModal);
    }

    function startAdminResize(event) {
        var handle = event.target.closest("[data-admin-resize]");
        if (handle) {
            var mode = handle.dataset.adminResize;
            adminResize = { mode: mode, startX: event.clientX, startY: event.clientY, width: mode === "left" ? adminLayout.leftWidth : adminLayout.rightWidth };
        } else {
            var modal = event.target.closest(".adm-modal__panel");
            if (!modal) return;
            var rect = modal.getBoundingClientRect();
            if (event.clientX < rect.right - 18 || event.clientY < rect.bottom - 18) return;
            adminResize = { mode: "modal", element: modal, key: adminModalKey(modal), startX: event.clientX, startY: event.clientY, width: rect.width, height: rect.height };
        }
        event.preventDefault();
        event.stopPropagation();
        document.body.classList.add("adm-is-resizing");
    }

    function moveAdminResize(event) {
        if (!adminResize) return;
        var dx = event.clientX - adminResize.startX;
        var dy = event.clientY - adminResize.startY;
        if (adminResize.mode === "left") {
            adminLayout.leftWidth = adminResize.width + dx;
            applyAdminColumns();
        } else if (adminResize.mode === "right") {
            adminLayout.rightWidth = adminResize.width - dx;
            applyAdminColumns();
        } else {
            var width = adminClamp(adminResize.width + dx, 320, Math.max(320, window.innerWidth - 40));
            var height = adminClamp(adminResize.height + dy, 160, Math.max(160, window.innerHeight - 40));
            adminLayout.modals[adminResize.key] = { width: width, height: height };
            applyAdminModal(adminResize.element);
        }
        event.preventDefault();
    }

    function stopAdminResize() {
        if (!adminResize) return;
        adminResize = null;
        document.body.classList.remove("adm-is-resizing");
        saveAdminLayout();
    }

    function initAdminResize() {
        loadAdminLayout();
        applyAdminColumns();
        applyAdminModals();
        document.addEventListener("mousedown", startAdminResize, true);
        window.addEventListener("mousemove", moveAdminResize);
        window.addEventListener("mouseup", stopAdminResize);
        window.addEventListener("blur", stopAdminResize);
        window.addEventListener("resize", function () { applyAdminColumns(); applyAdminModals(); });
        if (document.body && global.MutationObserver) new MutationObserver(applyAdminModals).observe(document.body, { childList: true, subtree: true });
    }

    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initAdminResize);
    else initAdminResize();

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
        { id: "craft",   labelKey: "admin.tab.craft",   fallback: "Crafty" },
        { id: "spawns",  labelKey: "admin.tab.spawns",  fallback: "Lobby/Spawny" },
        { id: "bestiary", labelKey: "admin.tab.bestiary", fallback: "Bestiariusz" },
        { id: "quests", labelKey: "admin.tab.quests", fallback: "Quest Maker" },
        { id: "db",      labelKey: "admin.tab.db",      fallback: "Baza danych" },
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
        itemRenderConfig: {},
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
        npcRoutine: { spawnId: 0, enabled: 1, loop: 1, nodes: [] },
        npcRoutineSelected: -1,
        npcRoutineGhostActive: false,
        npcRoutineGhostPos: { x: 0, y: 0, z: 0 },
        npcSpawnEdit: null,
        status: null,
        craftRecipes: [],
        craftStations: [],
        craftEditorId: 0,
        craftEditor: null,
        craftFilter: "",
        craftStationVob: "",
        craftStationPicked: {},
        craftView: "list",
        dbTables: [],
        dbActiveTable: "",
        dbSchema: { table: "", columns: [] },
        dbRows: { table: "", rows: [], total: 0, offset: 0, limit: 100 },
        dbFilter: "",
        dbInsertDraft: null,
        dbEditing: null,
        spawnConfig: { lobbyCameras: [], characterDefaultSpawn: null, characterScenarios: [] },
        spawnConfigLoaded: false,
        spawnGhost: { active: false, mode: "spawn", x: 0, y: 0, z: 0, angle: 0, camPitch: 0, camRoll: 0, world: "", target: null },
        bestiaryRender: {},
        bestiaryFilter: "",
        bestiarySelected: "",
        questDefinitions: [],
        questSelected: 0,
        questEditor: null,
        questCatalog: { npcs: [], presets: [], items: [], objectiveTypes: [], rewardTypes: [], npcRefTypes: [], npcRoles: [], conditionTypes: [], conditionOperators: [], eventTypes: [] },
        questValidation: null,
        questLegacyReport: []
    };

    function defaultQuestEditor() {
        return {
            id: 0,
            code: "NEW_QUEST",
            status: "draft",
            lockVersion: 0,
            content: {
                metadata: { title: "Nowe zadanie", description: "" },
                availability: null,
                startStageKey: "start",
                npcBindings: [],
                stages: [{ key: "start", title: "Pierwszy etap", type: "objectives", objectiveMode: "all", objectives: [], transitions: [], terminal: "success" }],
                dialogGraphs: [],
                rewards: []
            }
        };
    }

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

    function hydrateHumanCreatorFromSpawn(sp) {
        var base = defaultHumanCreator();
        base.instance = sp.instance || base.instance;
        base.name = sp.name || "";
        base.tag = sp.tag || "human";
        base.respawnSec = +sp.respawnSec || 0;
        base.hostile = +sp.hostile || 0;
        base.hp = +sp.hp || 0;
        base.level = +sp.level || 0;
        base.strength = +sp.strength || 0;
        base.dexterity = +sp.dexterity || 0;
        base.idleAnimation = sp.idleAnimation || "S_STAND";
        base.aggroRadius = +sp.aggroRadius || 900;
        base.baseExperience = +sp.baseExperience || 0;
        base.teacherSkills = sp.teacherSkills || "";
        base.teachCost = +sp.teachCost || 100;
        base.merchantItems = sp.merchantItems || "";
        base.weapon = sp.weapon || "";
        base.armor = sp.armor || "";
        base.ranged = sp.ranged || "";
        base.bodyModel = sp.bodyModel || base.bodyModel;
        base.bodyTex = sp.bodyTex == null ? base.bodyTex : +sp.bodyTex;
        base.headModel = sp.headModel || base.headModel;
        base.headTex = sp.headTex == null ? base.headTex : +sp.headTex;
        base.fatness = sp.fatness == null ? 0 : +sp.fatness;
        base.voice = +sp.voice || 0;
        base.posX = +sp.posX || 0;
        base.posY = +sp.posY || 0;
        base.posZ = +sp.posZ || 0;
        base.angle = +sp.angle || 0;
        base.world = sp.world || "";
        var bm = String(base.bodyModel || "").toUpperCase();
        if (bm.indexOf("BABE") >= 0) { base.gender = 0; }
        else { base.gender = 1; }
        state.humanCreator = base;
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
        return { instance: "", name: "", visual: "", vobId: "", filter: "", posX: 0, posY: 0, posZ: 0, rotX: 0, rotY: 0, rotZ: 0, world: "", interactive: 0, noCollision: 0, craftInteraction: 0, step: 50 };
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
            cameraMode: h.cameraMode || "orbital"
        };
        if (h.weapon) payload.weapon = h.weapon;
        if (h.armor)  payload.armor  = h.armor;
        if (h.ranged) payload.ranged = h.ranged;
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

    function humanEquipPayload(slot) {
        var h = state.humanCreator;
        var payload = { mode: "human", instance: h.instance };
        payload[slot] = h[slot] || "";
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
        if (activeTab === "quests") { send("questList"); send("questCatalog"); send("npcCatalog"); send("bestiaryRenderList"); send("schemes"); send("itemRenderList"); }
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
                var prevTab = activeTab;
                if (prevTab === "npc" && tab.id !== "npc") {
                    if (state.humanCreator.preview || state.npcForm.preview || state.npcView === "spawn-edit") {
                        send("adminNpcPreviewStop", {});
                        state.humanCreator.preview = 0;
                        state.npcForm.preview = 0;
                        if (state.npcView === "spawn-edit") {
                            state.npcSpawnEdit = null;
                            state.npcEditingId = 0;
                            state.npcView = "active";
                        }
                    }
                }
                activeTab = tab.id;
                buildTabs();
                if (tab.id === "log") send("log", { limit: 100 });
                if (tab.id === "bans") send("bans");
                if (tab.id === "items") { send("players"); send("schemes"); send("itemRenderList"); }
                if (tab.id === "inv") send("players");
                if (tab.id === "npc") { send("npcCatalog"); send("npcList"); send("npcPresetList"); send("herbCatalog"); send("herbList"); }
                if (tab.id === "herbs") { send("herbCatalog"); send("herbList"); }
                if (tab.id === "vobs") { requestVobCatalog(); send("vobList"); }
                if (tab.id === "houses") send("houseList");
                if (tab.id === "craft") { send("craftingList"); send("schemes"); requestVobCatalog(); send("vobList"); }
                if (tab.id === "spawns") send("spawnConfigGet");
                if (tab.id === "bestiary") { send("npcCatalog"); send("bestiaryRenderList"); }
                if (tab.id === "quests") { send("questList"); send("questCatalog"); send("npcCatalog"); send("bestiaryRenderList"); send("schemes"); send("itemRenderList"); }
                if (tab.id === "db") send("dbTables");
                render();
            });
            tabsEl.appendChild(b);
        });
    }

    function captureQuestRenderState() {
        if (activeTab !== "quests" || !body) return null;
        var snapshot = { body: body.scrollTop, scrolls: {}, details: {} };
        body.querySelectorAll("[data-quest-scroll]").forEach(function (element) { snapshot.scrolls[element.dataset.questScroll] = element.scrollTop; });
        body.querySelectorAll("details[data-quest-details]").forEach(function (element) { snapshot.details[element.dataset.questDetails] = element.open; });
        var raw = body.querySelector("[data-q-json]");
        if (raw) snapshot.json = { scrollTop: raw.scrollTop, start: raw.selectionStart, end: raw.selectionEnd };
        var focused = document.activeElement;
        if (focused && body.contains(focused) && focused.matches("[data-quest-objective-picker-filter]")) snapshot.focus = { kind: focused.dataset.kind, start: focused.selectionStart, end: focused.selectionEnd };
        return snapshot;
    }

    function restoreQuestRenderState(snapshot) {
        if (!snapshot || activeTab !== "quests" || !body) return;
        var apply = function () {
            body.scrollTop = snapshot.body || 0;
            body.querySelectorAll("[data-quest-scroll]").forEach(function (element) {
                var key = element.dataset.questScroll;
                if (key in snapshot.scrolls) element.scrollTop = snapshot.scrolls[key];
            });
            body.querySelectorAll("details[data-quest-details]").forEach(function (element) {
                var key = element.dataset.questDetails;
                if (key in snapshot.details) element.open = snapshot.details[key];
            });
            var raw = body.querySelector("[data-q-json]");
            if (raw && snapshot.json) {
                raw.scrollTop = snapshot.json.scrollTop || 0;
                try { raw.setSelectionRange(snapshot.json.start, snapshot.json.end); } catch (e) {}
            }
            if (snapshot.focus) {
                var focused = body.querySelector('[data-quest-objective-picker-filter][data-kind="' + snapshot.focus.kind + '"]');
                if (focused) {
                    focused.focus();
                    try { focused.setSelectionRange(snapshot.focus.start, snapshot.focus.end); } catch (e) {}
                }
            }
        };
        apply();
        if (global.requestAnimationFrame) global.requestAnimationFrame(apply);
        else setTimeout(apply, 0);
    }

    function render(force) {
        if (!body || !isOpen) return;
        if (!force && isEditingField()) {
            renderPending = true;
            return;
        }
        var questRenderState = captureQuestRenderState();
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
        else if (activeTab === "craft") html = renderCraft();
        else if (activeTab === "spawns") html = renderSpawnConfig();
        else if (activeTab === "bestiary") html = renderBestiaryRender();
        else if (activeTab === "quests") html = renderQuestMaker();
        else if (activeTab === "db") html = renderDatabase();
        else if (activeTab === "debug") html = renderDebug();
        else if (activeTab === "log") html = renderLog();

        if (state.status) {
            html += '<div class="adm-status' + (state.status.kind ? " is-" + state.status.kind : "") + '">' +
                escapeHtml(state.status.text) + "</div>";
        }
        body.innerHTML = html;
        bindHandlers();
        if (activeTab === "items" || activeTab === "npc" || activeTab === "vobs" || activeTab === "craft" || activeTab === "bestiary" || activeTab === "quests") populateItemMeshes();
        restoreQuestRenderState(questRenderState);
    }

    function renderQuestMaker() {
        var editor = state.questEditor;
        var list = state.questDefinitions || [];
        var html = '<div class="adm-section adm-quest-maker">';
        html += '<div class="adm-toolbar"><button class="adm-btn adm-btn--primary" data-action="quest-new">Nowy quest</button><button class="adm-btn" data-action="quest-refresh">Odśwież</button><button class="adm-btn" data-action="quest-legacy-report">Raport legacy</button><span class="adm-muted">Draft → walidacja → publikacja niezmiennej rewizji</span></div>';
        html += '<div class="adm-quest-layout"><aside class="adm-quest-list">';
        if (!list.length) html += '<div class="adm-empty">Brak definicji questów.</div>';
        list.forEach(function (entry) {
            var active = editor && +editor.id === +entry.id;
            html += '<button class="adm-quest-entry' + (active ? ' is-active' : '') + '" data-action="quest-select" data-id="' + (+entry.id || 0) + '"><strong>' + escapeHtml(entry.title || entry.code) + '</strong><small>' + escapeHtml(entry.code) + ' · ' + escapeHtml(entry.status) + ' · v' + (+entry.lockVersion || 0) + '</small></button>';
        });
        html += '</aside><section class="adm-quest-editor">';
        if (!editor) {
            html += '<div class="adm-empty">Wybierz quest albo utwórz nowy draft.</div>';
        } else {
            var contentText = "";
            try { contentText = JSON.stringify(editor.content || {}, null, 2); } catch (e) { contentText = "{}"; }
            html += '<div class="adm-grid adm-grid--2"><label class="adm-field"><span>Kod</span><input id="quest-code" value="' + escapeHtml(editor.code || "") + '" maxlength="64"></label><label class="adm-field"><span>Status</span><input value="' + escapeHtml(editor.status || "draft") + '" disabled></label></div>';
            html += '<label class="adm-field"><span>Definicja questa</span><textarea id="quest-json" class="adm-quest-json" spellcheck="false">' + escapeHtml(contentText) + '</textarea></label>';
            html += '<div class="adm-toolbar"><button class="adm-btn" data-action="quest-format">Formatuj JSON</button><button class="adm-btn" data-action="quest-validate">Waliduj</button><button class="adm-btn adm-btn--primary" data-action="quest-save">Zapisz draft</button>';
            if (+editor.id > 0) html += '<button class="adm-btn" data-action="quest-clone">Klonuj</button><button class="adm-btn adm-btn--success" data-action="quest-publish">Publikuj</button><button class="adm-btn adm-btn--danger" data-action="quest-archive">Archiwizuj</button>';
            html += '</div>';
            if (state.questValidation) {
                var issues = (state.questValidation.errors || []).concat(state.questValidation.warnings || []);
                html += '<div class="adm-quest-validation ' + (state.questValidation.valid ? 'is-valid' : 'is-invalid') + '"><strong>' + (state.questValidation.valid ? 'Definicja poprawna' : 'Definicja zawiera błędy') + '</strong>';
                issues.forEach(function (issue) { html += '<div><code>' + escapeHtml(issue.path || "") + '</code><span>' + escapeHtml(issue.message || issue.code || "") + '</span></div>'; });
                html += '</div>';
            }
            html += '<div class="adm-quest-help"><strong>Kanoniczne sekcje</strong><span>metadata, availability, startStageKey, npcBindings, stages, dialogGraphs, rewards</span><strong>Typy celów</strong><span>' + escapeHtml((state.questCatalog.objectiveTypes || []).join(", ")) + '</span><strong>Typy nagród</strong><span>' + escapeHtml((state.questCatalog.rewardTypes || []).join(", ")) + '</span></div>';
        }
        html += '</section></div>';
        var legacy = state.questLegacyReport || [];
        if (legacy.length) {
            html += '<section class="adm-quest-validation"><strong>Raport legacy</strong>';
            legacy.forEach(function (entry) {
                html += '<div><code>' + escapeHtml(entry.code || "") + '</code><span>' + escapeHtml(entry.convertible ? ("gotowy · stany: " + (+entry.stateCount || 0)) : (entry.reasons || []).join(", ")) + '</span>';
                if (entry.convertible && !entry.mappedDefinitionId) html += '<button class="adm-btn" data-action="quest-legacy-convert" data-id="' + (+entry.id || 0) + '">Utwórz draft</button>';
                else if (entry.mappedDefinitionId) html += '<small>draft #' + (+entry.mappedDefinitionId || 0) + '</small>';
                html += '</div>';
            });
            html += '</section>';
        }
        html += '</div>';
        return html;
    }

    function questEditorPayload() {
        if (!state.questEditor) return null;
        var codeEl = body.querySelector("#quest-code");
        var jsonEl = body.querySelector("#quest-json");
        var content;
        try { content = JSON.parse(jsonEl ? jsonEl.value : "{}"); }
        catch (e) { setStatus("Nieprawidłowy JSON: " + e.message, "error"); return null; }
        state.questEditor.code = codeEl ? codeEl.value.trim().toUpperCase() : state.questEditor.code;
        state.questEditor.content = content;
        return { id: +state.questEditor.id || 0, code: state.questEditor.code, lockVersion: +state.questEditor.lockVersion || 0, content: content, requestId: String(Date.now()) };
    }

    function handleQuestAction(action, el) {
        if (action === "quest-refresh") { send("questList"); send("questCatalog"); return; }
        if (action === "quest-legacy-report") { send("questLegacyReport"); return setStatus("Analizowanie danych legacy", ""); }
        if (action === "quest-legacy-convert") {
            var legacyId = +el.dataset.id || 0;
            openConfirmModal({
                title: "Konwersja legacy",
                message: "Zostanie utworzony nieopublikowany draft. Dane legacy pozostaną bez zmian.",
                okLabel: "Utwórz draft",
                danger: false,
                onConfirm: function () { send("questLegacyConvert", { legacyId: legacyId, confirm: true, requestId: String(Date.now()) }); }
            });
            return;
        }
        if (action === "quest-new") { state.questEditor = defaultQuestEditor(); state.questSelected = 0; state.questValidation = null; render(true); return; }
        if (action === "quest-select") { state.questSelected = +el.dataset.id || 0; send("questGet", { id: state.questSelected }); return; }
        if (action === "quest-format") { var formatted = questEditorPayload(); if (formatted) render(true); return; }
        var payload = questEditorPayload();
        if (!payload) return;
        if (action === "quest-validate") { payload.publishing = false; send("questValidate", payload); return; }
        if (action === "quest-save") { send("questSave", payload); return setStatus("Zapisywanie draftu", ""); }
        if (action === "quest-clone") {
            var cloneCode = (payload.code || "QUEST").slice(0, 52) + "_COPY_" + String(Date.now()).slice(-6);
            send("questClone", { sourceId: payload.id, code: cloneCode, requestId: payload.requestId });
            return setStatus("Klonowanie questa", "");
        }
        if (action === "quest-publish") { send("questPublish", { id: payload.id, lockVersion: payload.lockVersion, requestId: payload.requestId }); return setStatus("Publikowanie rewizji", ""); }
        if (action === "quest-archive") {
            openConfirmModal({
                title: "Archiwizacja questa",
                message: "Quest przestanie być dostępny do rozpoczęcia. Aktywne stany postaci zachowają opublikowaną rewizję.",
                okLabel: "Archiwizuj",
                danger: true,
                onConfirm: function () {
                    send("questArchive", { id: payload.id, lockVersion: payload.lockVersion, requestId: payload.requestId, confirm: true });
                    setStatus("Archiwizowanie questa", "");
                }
            });
        }
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

    function renderSpawnConfig() {
        var cfg = state.spawnConfig || { lobbyCameras: [], characterDefaultSpawn: null, characterScenarios: [], characterCreateCamera: null, characterSelectCamera: null };
        var ghost = state.spawnGhost;
        var html = '<div class="adm-section adm-section--spawns">';
        html += '<h3>Lobby i punkty startowe</h3>';

        if (ghost && ghost.active) {
            html += renderSpawnGhostEditor();
        } else {
            html += '<p class="adm-muted">Kliknij ikonę 📍 obok wybranego punktu, żeby otworzyć edytor 3D ze znacznikiem w grze. Strzałka pokazuje kierunek, w którym patrzy kamera/postać.</p>';
        }

        html += '<div class="adm-section adm-section--inline">';
        html += '<div class="adm-db-header"><h4>Kamery tła lobby (' + (cfg.lobbyCameras || []).length + ')</h4>';
        html += '<div class="adm-db-actions">';
        html += '<button class="adm-btn" data-action="spawnconfig-add-lobby">+ Z mojej pozycji</button>';
        html += '<button class="adm-btn" data-action="spawnconfig-new-lobby">📍 Nowa + Edytor 3D</button>';
        html += '<button class="adm-btn adm-btn--primary" data-action="spawnconfig-save-lobby">Zapisz lobby</button>';
        html += '</div></div>';
        html += '<p class="adm-muted">Te kamery rotują w tle podczas logowania.</p>';
        if (!(cfg.lobbyCameras || []).length) {
            html += '<div class="adm-empty">Brak kamer — używane są wbudowane defaults. Stań tam gdzie chcesz mieć kamerę i kliknij „+ Z mojej pozycji”, potem dopracuj kąt edytorem 3D.</div>';
        } else {
            html += '<div class="adm-spawn-cards">';
            (cfg.lobbyCameras || []).forEach(function (spot, idx) {
                var isEditing = ghost && ghost.active && ghost.target && ghost.target.kind === "lobby" && +ghost.target.idx === idx;
                html += renderSpawnCameraCard("lobby", idx, spot, isEditing);
            });
            html += '</div>';
        }
        html += '</div>';

        var selectCam = cfg.characterSelectCamera || { x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0 };
        var selectEditing = ghost && ghost.active && ghost.target && ghost.target.kind === "select";
        html += '<div class="adm-section adm-section--inline' + (selectEditing ? " is-editing" : "") + '">';
        html += '<div class="adm-db-header"><h4>Kamera ekranu wyboru postaci</h4>';
        html += '<div class="adm-db-actions">';
        if (selectEditing) {
            html += '<button class="adm-btn adm-btn--primary" data-action="spawnconfig-ghost-stop">✓ Gotowe</button>';
        } else {
            html += '<button class="adm-btn" data-action="spawnconfig-ghost-edit-select">📍 Edytor 3D</button>';
            html += '<button class="adm-btn" data-action="spawnconfig-add-select">⌖ Z mojej pozycji</button>';
        }
        html += '<button class="adm-btn adm-btn--primary" data-action="spawnconfig-save-select">Zapisz</button>';
        html += '</div></div>';
        html += '<p class="adm-muted">Statyczna kamera oraz pozycja w której pojawia się hero, kiedy gracz przegląda swoje postacie. Pozostaw zera, żeby użyć rotacji lobby.</p>';
        html += renderCameraGrid("selectcam", selectCam);
        html += '</div>';

        var createCam = cfg.characterCreateCamera || { x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0 };
        var createEditing = ghost && ghost.active && ghost.target && ghost.target.kind === "create";
        html += '<div class="adm-section adm-section--inline' + (createEditing ? " is-editing" : "") + '">';
        html += '<div class="adm-db-header"><h4>Pozycja kreatora postaci</h4>';
        html += '<div class="adm-db-actions">';
        if (createEditing) {
            html += '<button class="adm-btn adm-btn--primary" data-action="spawnconfig-ghost-stop">✓ Gotowe</button>';
        } else {
            html += '<button class="adm-btn" data-action="spawnconfig-ghost-edit-create">📍 Edytor 3D</button>';
            html += '<button class="adm-btn" data-action="spawnconfig-add-create">⌖ Z mojej pozycji</button>';
        }
        html += '<button class="adm-btn adm-btn--primary" data-action="spawnconfig-save-create">Zapisz</button>';
        html += '</div></div>';
        html += '<p class="adm-muted">Miejsce, w którym staje hero podczas tworzenia nowej postaci. Kreator używa orbitalnej kamery wokół postaci — pola rot* są ignorowane.</p>';
        html += renderCameraGrid("createcam", createCam);
        html += '</div>';

        var def = cfg.characterDefaultSpawn || { world: "NEWWORLD.ZEN", x: 870.118, y: -96.2501, z: -1848.33, angle: 65.1225 };
        var defEditing = ghost && ghost.active && ghost.target && ghost.target.kind === "default";
        html += '<div class="adm-section adm-section--inline' + (defEditing ? " is-editing" : "") + '">';
        html += '<div class="adm-db-header"><h4>Domyślny punkt respawnu / startu postaci</h4>';
        html += '<div class="adm-db-actions">';
        if (defEditing) {
            html += '<button class="adm-btn adm-btn--primary" data-action="spawnconfig-ghost-stop">✓ Gotowe</button>';
        } else {
            html += '<button class="adm-btn" data-action="spawnconfig-ghost-edit-default">📍 Edytor 3D</button>';
            html += '<button class="adm-btn" data-action="spawnconfig-add-default">⌖ Z mojej pozycji</button>';
        }
        html += '<button class="adm-btn adm-btn--primary" data-action="spawnconfig-save-default">Zapisz</button>';
        html += '</div></div>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>Świat<input class="adm-input" data-spawn-def="world" value="' + escapeHtml(def.world || "NEWWORLD.ZEN") + '"></label>';
        html += '<label>X<input class="adm-input" type="number" step="0.1" data-spawn-def="x" value="' + (+def.x || 0) + '"></label>';
        html += '<label>Y<input class="adm-input" type="number" step="0.1" data-spawn-def="y" value="' + (+def.y || 0) + '"></label>';
        html += '<label>Z<input class="adm-input" type="number" step="0.1" data-spawn-def="z" value="' + (+def.z || 0) + '"></label>';
        html += '<label>Kąt<input class="adm-input" type="number" step="0.1" data-spawn-def="angle" value="' + (+def.angle || 0) + '"></label>';
        html += '</div></div>';

        var scenarios = cfg.characterScenarios || [];
        html += '<div class="adm-section adm-section--inline">';
        html += '<div class="adm-db-header"><h4>Alternatywne punkty startowe (' + scenarios.length + ')</h4>';
        html += '<div class="adm-db-actions">';
        html += '<button class="adm-btn" data-action="spawnconfig-add-scenario">+ Z mojej pozycji</button>';
        html += '<button class="adm-btn" data-action="spawnconfig-new-scenario">📍 Nowy + Edytor 3D</button>';
        html += '<button class="adm-btn adm-btn--primary" data-action="spawnconfig-save-scenarios">Zapisz scenariusze</button>';
        html += '</div></div>';
        if (!scenarios.length) {
            html += '<div class="adm-empty">Brak alternatywnych punktów. Pierwszy zalogowany dostaje domyślny.</div>';
        } else {
            html += '<div class="adm-spawn-cards">';
            scenarios.forEach(function (sc, idx) {
                var isEditing = ghost && ghost.active && ghost.target && ghost.target.kind === "scenario" && +ghost.target.idx === idx;
                html += renderSpawnSpotCard("scenario", idx, sc, isEditing);
            });
            html += '</div>';
        }
        html += '</div>';

        html += renderHudPortraitConfig(cfg);

        html += '</div>';
        return html;
    }

    function defaultHudPortrait() { return { rotX: 1.5708, rotY: 3.1416, rotZ: 0, scale: 4.6, light: 2.4, head: "Hum_Head_Pony" }; }
    function parseHudPortrait(raw) {
        var out = defaultHudPortrait();
        if (!raw) return out;
        try {
            var obj = JSON.parse(raw);
            if (obj && typeof obj === "object") {
                if (typeof obj.rotX === "number") out.rotX = obj.rotX;
                if (typeof obj.rotY === "number") out.rotY = obj.rotY;
                if (typeof obj.rotZ === "number") out.rotZ = obj.rotZ;
                if (typeof obj.scale === "number") out.scale = obj.scale;
                if (typeof obj.light === "number") out.light = obj.light;
                if (typeof obj.head === "string" && obj.head) out.head = obj.head;
            }
        } catch (e) {}
        return out;
    }

    function renderHudPortraitConfig(cfg) {
        var raw = (cfg && cfg.hudPortrait) ? String(cfg.hudPortrait) : "";
        var hp = parseHudPortrait(raw);
        var headOptions = ["Hum_Head_Pony", "Hum_Head_Bald", "Hum_Head_Thief", "Hum_Head_Psionic", "Hum_Head_Fighter", "Hum_Head_FatBald", "Hum_Head_Babe", "Hum_Head_Babe1", "Hum_Head_Babe2"];
        var visual = (hp.head || "Hum_Head_Pony") + ".MMB";

        var html = '<div class="adm-section adm-section--inline">';
        html += '<div class="adm-db-header"><h4>HUD · render portretu (romb)</h4>';
        html += '<div class="adm-db-actions">';
        html += '<button class="adm-btn" data-action="hudportrait-reset">Reset domyślny</button>';
        html += '<button class="adm-btn adm-btn--primary" data-action="hudportrait-save">Zapisz</button>';
        html += '</div></div>';
        html += '<p class="adm-muted">Te same wartości co w bestiariuszu — ustaw głowę żeby pasowała do rombu w lewym górnym rogu HUD.</p>';

        html += '<div class="adm-render-debug">';
        html += '<div class="adm-render-debug__preview" style="width:200px;height:200px;">';
        html += '<gothic-render width="180" height="180" rot-x="' + hp.rotX + '" rot-y="' + hp.rotY + '" rot-z="' + hp.rotZ + '" scale="' + hp.scale + '" light-intensity="' + hp.light + '" visual="' + escapeHtml(visual) + '"></gothic-render>';
        html += '</div>';
        html += '<div class="adm-render-debug__body">';
        html += '<p>Podgląd głowy: <b>' + escapeHtml(hp.head) + '</b></p>';
        html += '<label>Model do podglądu<select class="adm-input" data-hudportrait="head">';
        headOptions.forEach(function (h) {
            html += '<option value="' + escapeHtml(h) + '"' + (h === hp.head ? ' selected' : '') + '>' + escapeHtml(h) + '</option>';
        });
        html += '</select></label>';
        html += '<div class="adm-render-debug__grid">';
        html += renderHudPortraitSlider("rotX", "rot-x", -3.142, 3.142, 0.01, hp.rotX);
        html += renderHudPortraitSlider("rotY", "rot-y", -3.142, 3.142, 0.01, hp.rotY);
        html += renderHudPortraitSlider("rotZ", "rot-z", -3.142, 3.142, 0.01, hp.rotZ);
        html += renderHudPortraitSlider("scale", "scale", 0.5, 12, 0.05, hp.scale);
        html += renderHudPortraitSlider("light", "light", 0.2, 5, 0.05, hp.light);
        html += '</div>';
        html += '<div class="adm-render-debug__values">rot-x=' + (+hp.rotX).toFixed(3) + ' rot-y=' + (+hp.rotY).toFixed(3) + ' rot-z=' + (+hp.rotZ).toFixed(3) + ' scale=' + (+hp.scale).toFixed(2) + ' light=' + (+hp.light).toFixed(2) + '</div>';
        html += '</div></div>';

        html += '</div>';
        return html;
    }

    function renderHudPortraitSlider(key, label, min, max, step, value) {
        return '<label class="adm-render-debug__control"><span>' + escapeHtml(label) + '</span><input type="range" min="' + min + '" max="' + max + '" step="' + step + '" data-hudportrait="' + key + '" value="' + value + '"><b>' + (+value).toFixed(key === "scale" || key === "light" ? 2 : 3) + '</b></label>';
    }

    function renderCameraGrid(prefix, cam) {
        var html = '<div class="adm-grid adm-grid--3">';
        ["x","y","z","rotX","rotY","rotZ"].forEach(function (f) {
            var label = f === "rotX" ? "Pitch (góra/dół)" : (f === "rotY" ? "Yaw (kierunek)" : (f === "rotZ" ? "Roll (przechył)" : f.toUpperCase()));
            html += '<label>' + label + '<input class="adm-input" type="number" step="0.1" data-spawn-' + prefix + '="' + f + '" value="' + (Math.round((+cam[f] || 0) * 10) / 10) + '"></label>';
        });
        html += '</div>';
        return html;
    }

    function renderSpawnCameraCard(kind, idx, spot, isEditing) {
        var html = '<div class="adm-spawn-card' + (isEditing ? " is-editing" : "") + '">';
        html += '<div class="adm-spawn-card__head">';
        html += '<span class="adm-spawn-card__title">Kamera #' + (idx + 1) + '</span>';
        html += '<div class="adm-spawn-card__actions">';
        if (isEditing) {
            html += '<button class="adm-btn adm-btn--mini adm-btn--primary" data-action="spawnconfig-ghost-stop">✓ Gotowe</button>';
        } else {
            html += '<button class="adm-btn adm-btn--mini" data-action="spawnconfig-ghost-edit-' + kind + '" data-idx="' + idx + '" title="Edytor 3D">📍</button>';
        }
        html += '<button class="adm-btn adm-btn--mini adm-btn--danger" data-action="spawnconfig-remove-' + kind + '" data-idx="' + idx + '" title="Usuń">🗑</button>';
        html += '</div></div>';
        html += '<div class="adm-grid adm-grid--3">';
        ["x","y","z","rotY","rotX","rotZ"].forEach(function (f) {
            var label = f === "rotX" ? "Pitch" : (f === "rotY" ? "Yaw" : (f === "rotZ" ? "Roll" : f.toUpperCase()));
            html += '<label>' + label + '<input class="adm-input" type="number" step="0.1" data-spawn-' + kind + '-idx="' + idx + '" data-spawn-' + kind + '-field="' + f + '" value="' + (Math.round((+spot[f] || 0) * 10) / 10) + '"></label>';
        });
        html += '</div>';
        html += '</div>';
        return html;
    }

    function renderSpawnSpotCard(kind, idx, spot, isEditing) {
        var html = '<div class="adm-spawn-card' + (isEditing ? " is-editing" : "") + '">';
        html += '<div class="adm-spawn-card__head">';
        html += '<span class="adm-spawn-card__title">Punkt #' + (idx + 1) + '</span>';
        html += '<div class="adm-spawn-card__actions">';
        if (isEditing) {
            html += '<button class="adm-btn adm-btn--mini adm-btn--primary" data-action="spawnconfig-ghost-stop">✓ Gotowe</button>';
        } else {
            html += '<button class="adm-btn adm-btn--mini" data-action="spawnconfig-ghost-edit-' + kind + '" data-idx="' + idx + '" title="Edytor 3D">📍</button>';
        }
        html += '<button class="adm-btn adm-btn--mini adm-btn--danger" data-action="spawnconfig-remove-' + kind + '" data-idx="' + idx + '" title="Usuń">🗑</button>';
        html += '</div></div>';
        html += '<div class="adm-grid adm-grid--2">';
        html += '<label>X<input class="adm-input" type="number" step="0.1" data-spawn-' + kind + '-idx="' + idx + '" data-spawn-' + kind + '-field="x" value="' + (Math.round((+spot.x || 0) * 10) / 10) + '"></label>';
        html += '<label>Y<input class="adm-input" type="number" step="0.1" data-spawn-' + kind + '-idx="' + idx + '" data-spawn-' + kind + '-field="y" value="' + (Math.round((+spot.y || 0) * 10) / 10) + '"></label>';
        html += '<label>Z<input class="adm-input" type="number" step="0.1" data-spawn-' + kind + '-idx="' + idx + '" data-spawn-' + kind + '-field="z" value="' + (Math.round((+spot.z || 0) * 10) / 10) + '"></label>';
        html += '<label>Kąt<input class="adm-input" type="number" step="0.1" data-spawn-' + kind + '-idx="' + idx + '" data-spawn-' + kind + '-field="angle" value="' + (Math.round((+spot.angle || 0) * 10) / 10) + '"></label>';
        html += '</div>';
        html += '</div>';
        return html;
    }

    function renderSpawnGhostEditor() {
        var ghost = state.spawnGhost;
        var isLobby = ghost.mode === "lobby";
        var html = '<div class="adm-section adm-section--inline adm-spawn-editor">';
        html += '<div class="adm-db-header">';
        html += '<h4>Edytor 3D · ' + (isLobby ? 'kamera lobby' : 'punkt spawnu') + (ghost.target ? ' · #' + ((+ghost.target.idx) + 1) : '') + '</h4>';
        html += '<div class="adm-db-actions">';
        html += '<button class="adm-btn adm-btn--primary" data-action="spawnconfig-ghost-apply">✓ Zastosuj</button>';
        html += '<button class="adm-btn" data-action="spawnconfig-ghost-stop">Anuluj</button>';
        html += '</div></div>';
        html += '<p class="adm-muted">W grze: <b>WSAD</b>=ruch, <b>Q/E</b>=góra/dół, <b>←/→</b>=obrót strzałki';
        if (isLobby) html += ', <b>↑/↓</b>=pitch kamery, <b>PgUp/PgDn</b>=roll kamery';
        html += '. Trzymaj <b>Shift</b>=szybciej, <b>Ctrl</b>=wolniej.</p>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>X<input class="adm-input" type="number" step="0.1" data-spawn-ghost="x" value="' + (Math.round(ghost.x * 10) / 10) + '"></label>';
        html += '<label>Y<input class="adm-input" type="number" step="0.1" data-spawn-ghost="y" value="' + (Math.round(ghost.y * 10) / 10) + '"></label>';
        html += '<label>Z<input class="adm-input" type="number" step="0.1" data-spawn-ghost="z" value="' + (Math.round(ghost.z * 10) / 10) + '"></label>';
        html += '<label>Yaw (kierunek)<input class="adm-input" type="number" step="1" data-spawn-ghost="angle" value="' + (Math.round(ghost.angle * 10) / 10) + '"></label>';
        if (isLobby) {
            html += '<label>Camera Pitch<input class="adm-input" type="number" step="1" data-spawn-ghost="camPitch" value="' + (Math.round(ghost.camPitch * 10) / 10) + '"></label>';
            html += '<label>Camera Roll<input class="adm-input" type="number" step="1" data-spawn-ghost="camRoll" value="' + (Math.round(ghost.camRoll * 10) / 10) + '"></label>';
        }
        html += '</div>';
        html += '<div class="adm-spawn-nudge">';
        html += '<div class="adm-spawn-nudge__row"><span>Pozycja:</span>';
        [["x-","-X"],["x+","+X"],["y+","+Y"],["y-","-Y"],["z-","-Z"],["z+","+Z"]].forEach(function (b) {
            html += '<button class="adm-btn adm-btn--mini" data-action="spawnconfig-ghost-nudge" data-axis="' + b[0] + '">' + b[1] + '</button>';
        });
        html += '</div>';
        html += '<div class="adm-spawn-nudge__row"><span>Kierunek:</span>';
        html += '<button class="adm-btn adm-btn--mini" data-action="spawnconfig-ghost-nudge" data-axis="a-">↺ -15°</button>';
        html += '<button class="adm-btn adm-btn--mini" data-action="spawnconfig-ghost-nudge" data-axis="a+">↻ +15°</button>';
        html += '</div>';
        if (isLobby) {
            html += '<div class="adm-spawn-nudge__row"><span>Kamera:</span>';
            html += '<button class="adm-btn adm-btn--mini" data-action="spawnconfig-ghost-nudge" data-axis="pitch-">Pitch -</button>';
            html += '<button class="adm-btn adm-btn--mini" data-action="spawnconfig-ghost-nudge" data-axis="pitch+">Pitch +</button>';
            html += '<button class="adm-btn adm-btn--mini" data-action="spawnconfig-ghost-nudge" data-axis="roll-">Roll -</button>';
            html += '<button class="adm-btn adm-btn--mini" data-action="spawnconfig-ghost-nudge" data-axis="roll+">Roll +</button>';
            html += '</div>';
        }
        html += '</div>';
        html += '</div>';
        return html;
    }

    function renderBestiaryRender() {
        var catalog = state.npcCatalog || [];
        var monsters = catalog.filter(function (e) {
            var inst = String(e.instance || "").toUpperCase();
            return window.PhoenixNpcVisuals && PhoenixNpcVisuals.get(inst);
        });
        var filter = (state.bestiaryFilter || "").toLowerCase();
        if (filter) {
            monsters = monsters.filter(function (e) {
                return String(e.instance || "").toLowerCase().indexOf(filter) >= 0
                    || String(e.label || "").toLowerCase().indexOf(filter) >= 0;
            });
        }
        var selected = state.bestiarySelected || "";
        var selCfg = state.bestiaryRender[selected.toUpperCase()] || { rotX: 0.158, rotY: -0.853, rotZ: 0, scaleValue: 1.5, lightIntensity: 2.3 };
        var html = '<div class="adm-section"><h3>Render bestiariusza · ' + monsters.length + ' potworów</h3>';
        html += '<p class="adm-muted">Ustaw kąty i skalę dla każdego potwora osobno. Konfiguracja jest rozsyłana do wszystkich klientów po zapisie.</p>';
        html += renderBestiaryDebug(selected, selCfg);
        html += '<div class="adm-toolbar">';
        html += '<input type="text" class="adm-search" data-role="bestiary-filter" value="' + escapeHtml(state.bestiaryFilter) + '" placeholder="Filtruj potwory">';
        html += '</div>';
        html += '<div class="adm-itemgrid" data-role="itemgrid">';
        monsters.forEach(function (m) {
            var inst = String(m.instance || "").toUpperCase();
            var visual = PhoenixNpcVisuals.get(inst) || "";
            var label = m.label || inst;
            var sel = selected === inst ? " is-selected" : "";
            html += '<div class="adm-itemcell' + sel + '" data-action="bestiary-pick" data-instance="' + escapeHtml(inst) + '" data-visual="' + escapeHtml(visual) + '" data-preview-visual="' + escapeHtml(visual) + '" title="' + escapeHtml(label) + '">';
            html += '<div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(label.slice(0, 18)) + '</span></div>';
            html += '<span class="adm-itemcell__cat">' + escapeHtml(inst) + '</span>';
            html += '</div>';
        });
        html += '</div></div>';
        return html;
    }

    function renderBestiaryDebug(instance, cfg) {
        var visual = instance && window.PhoenixNpcVisuals ? PhoenixNpcVisuals.get(instance) : "";
        var html = '<div class="adm-render-debug">';
        html += '<div class="adm-render-debug__preview">';
        if (visual) {
            html += '<gothic-render width="180" height="220" rot-x="' + cfg.rotX + '" rot-y="' + cfg.rotY + '" rot-z="' + cfg.rotZ + '" scale="' + cfg.scaleValue + '" light-intensity="' + cfg.lightIntensity + '" visual="' + escapeHtml(visual) + '"></gothic-render>';
        } else {
            html += '<div class="adm-render-debug__empty">Wybierz potwora z gridu</div>';
        }
        html += '</div><div class="adm-render-debug__body"><h4>Bestiary render</h4>';
        html += '<p><b>' + escapeHtml(instance || "—") + '</b>' + (visual ? ' <small>[' + escapeHtml(visual) + ']</small>' : '') + '</p>';
        html += '<div class="adm-render-debug__grid">';
        html += renderBestiarySlider("rotX", "rot-x", -3.142, 3.142, 0.01, cfg.rotX);
        html += renderBestiarySlider("rotY", "rot-y", -3.142, 3.142, 0.01, cfg.rotY);
        html += renderBestiarySlider("rotZ", "rot-z", -3.142, 3.142, 0.01, cfg.rotZ);
        html += renderBestiarySlider("scaleValue", "scale", 0.2, 3, 0.05, cfg.scaleValue);
        html += renderBestiarySlider("lightIntensity", "light", 0.2, 5, 0.05, cfg.lightIntensity);
        html += '</div>';
        html += '<div class="adm-render-debug__values">rot-x=' + (+cfg.rotX).toFixed(3) + ' rot-y=' + (+cfg.rotY).toFixed(3) + ' rot-z=' + (+cfg.rotZ).toFixed(3) + ' scale=' + (+cfg.scaleValue).toFixed(2) + ' light=' + (+cfg.lightIntensity).toFixed(2) + '</div>';
        html += '<div class="adm-toolbar"><button class="adm-btn adm-btn--primary" data-action="bestiary-save"' + (instance ? '' : ' disabled') + '>Zapisz dla ' + escapeHtml(instance || "—") + '</button>';
        html += '<button class="adm-btn" data-action="bestiary-reset">Reset domyślny</button></div>';
        html += '</div></div>';
        return html;
    }

    function renderBestiarySlider(key, label, min, max, step, value) {
        return '<label class="adm-render-debug__control"><span>' + escapeHtml(label) + '</span><input type="range" min="' + min + '" max="' + max + '" step="' + step + '" data-bestiary-debug="' + key + '" value="' + value + '"><b>' + (+value).toFixed(key === "scaleValue" || key === "lightIntensity" ? 2 : 3) + '</b></label>';
    }

    function renderDatabase() {
        var tables = state.dbTables || [];
        var active = state.dbActiveTable || "";
        var schema = state.dbSchema && state.dbSchema.table === active ? state.dbSchema : { table: active, columns: [] };
        var rowsView = state.dbRows && state.dbRows.table === active ? state.dbRows : { table: active, rows: [], total: 0, offset: 0, limit: 100 };
        var html = '<div class="adm-section adm-section--db">';
        html += '<h3>' + escapeHtml(t("admin.tab.db", "Baza danych")) + '</h3>';
        html += '<div class="adm-db-layout">';

        html += '<aside class="adm-db-sidebar"><h4>Tabele (' + tables.length + ')</h4>';
        html += '<input class="adm-search" data-role="db-table-filter" value="' + escapeHtml(state.dbFilter || "") + '" placeholder="Filtruj tabele">';
        html += '<div class="adm-db-tables">';
        var filter = (state.dbFilter || "").toLowerCase();
        tables.forEach(function (tab) {
            var name = String(tab.name || "");
            if (filter && name.toLowerCase().indexOf(filter) < 0) return;
            var sel = name === active ? " is-selected" : "";
            html += '<button type="button" class="adm-btn adm-btn--ghost' + sel + '" data-action="db-table-pick" data-table="' + escapeHtml(name) + '">' + escapeHtml(name) + ' <small>(' + (tab.rowCount || 0) + ')</small></button>';
        });
        html += '</div></aside>';

        html += '<div class="adm-db-main">';
        if (!active) {
            html += '<div class="adm-empty">Wybierz tabelę z listy po lewej.</div>';
        } else {
            var pkColumn = dbPrimaryKey(schema.columns);
            var canEdit = active.indexOf("phoenix_") === 0;
            html += '<div class="adm-db-header">';
            html += '<div><h4>' + escapeHtml(active) + '</h4><small>' + (rowsView.total || 0) + ' wierszy · ' + (schema.columns || []).length + ' kolumn</small></div>';
            html += '<div class="adm-db-actions">';
            html += '<button class="adm-btn" data-action="db-refresh" title="Odśwież">⟳ Odśwież</button>';
            if (canEdit) {
                html += '<button class="adm-btn adm-btn--primary" data-action="db-row-new">+ Dodaj wiersz</button>';
            } else {
                html += '<span class="adm-db-readonly">Tylko do odczytu (poza phoenix_*)</span>';
            }
            html += '</div></div>';

            html += '<div class="adm-db-grid">';
            html += '<table class="adm-table adm-table--db"><thead><tr>';
            if (canEdit && pkColumn) html += '<th class="adm-db-action-col">Akcje</th>';
            schema.columns.forEach(function (c) {
                var keyHint = String(c.keyType || "") === "PRI" ? ' <span class="adm-db-pk">PK</span>' : '';
                html += '<th title="' + escapeHtml(c.type || "") + '">' + escapeHtml(c.name) + keyHint + '</th>';
            });
            html += '</tr></thead><tbody>';
            (rowsView.rows || []).forEach(function (row, rowIdx) {
                var pkValue = pkColumn ? row[pkColumn] : null;
                html += '<tr>';
                if (canEdit && pkColumn) {
                    html += '<td class="adm-db-action-col">';
                    html += '<button class="adm-btn adm-btn--mini" data-action="db-row-edit" data-row="' + rowIdx + '" title="Edytuj">✎</button>';
                    html += '<button class="adm-btn adm-btn--mini adm-btn--danger" data-action="db-row-delete" data-row="' + rowIdx + '" title="Usuń">🗑</button>';
                    html += '</td>';
                }
                schema.columns.forEach(function (c) {
                    var raw = row[c.name];
                    var display = raw == null ? '<span class="adm-db-null">NULL</span>' : escapeHtml(String(raw));
                    var rawStr = raw == null ? "" : String(raw);
                    var truncated = rawStr.length > 80 ? escapeHtml(rawStr.slice(0, 80)) + '…' : display;
                    html += '<td title="' + escapeHtml(rawStr) + '">' + truncated + '</td>';
                });
                html += '</tr>';
            });
            if (!(rowsView.rows || []).length) {
                var span = (schema.columns || []).length + (canEdit && pkColumn ? 1 : 0);
                html += '<tr><td colspan="' + span + '"><div class="adm-empty">Brak danych</div></td></tr>';
            }
            html += '</tbody></table>';
            html += '</div>';

            var pageSize = rowsView.limit || 100;
            var page = Math.floor((rowsView.offset || 0) / pageSize);
            var totalPages = Math.max(1, Math.ceil((rowsView.total || 0) / pageSize));
            html += '<div class="adm-toolbar adm-db-pager">';
            html += '<button class="adm-btn" data-action="db-page-prev"' + (page <= 0 ? ' disabled' : '') + '>← Poprzednia</button>';
            html += '<span>Strona <b>' + (page + 1) + '</b> / ' + totalPages + '</span>';
            html += '<button class="adm-btn" data-action="db-page-next"' + (page + 1 >= totalPages ? ' disabled' : '') + '>Następna →</button>';
            html += '</div>';

            if (state.dbInsertDraft && state.dbInsertDraft.table === active) {
                html += renderDbInsertModal(schema.columns);
            }
            if (state.dbEditing && state.dbEditing.table === active) {
                html += renderDbEditModal(schema.columns, rowsView.rows || []);
            }
        }
        html += '</div>';

        html += '</div></div>';
        return html;
    }

    function renderDbEditModal(columns, rows) {
        var ed = state.dbEditing;
        var pkColumn = ed.pkColumn;
        var sourceRow = rows.filter(function (r) { return String(r[pkColumn]) === String(ed.pkValue); })[0] || {};
        var html = '<div class="adm-modal adm-modal--db" data-db-modal-bg>';
        html += '<div class="adm-modal__backdrop" data-action="db-row-cancel"></div>';
        html += '<div class="adm-modal__panel adm-modal__panel--db">';
        html += '<div class="adm-modal__head"><h3>Edytuj wiersz · <code>' + escapeHtml(ed.table) + ' #' + escapeHtml(String(ed.pkValue)) + '</code></h3></div>';
        html += '<div class="adm-modal__body"><div class="adm-grid adm-grid--db-edit">';
        columns.forEach(function (c) {
            var raw = sourceRow[c.name];
            var draft = ed.values[c.name];
            var value = draft != null ? draft : (raw == null ? "" : String(raw));
            var readonly = c.name === pkColumn;
            var typ = String(c.type || "").toLowerCase();
            var inputType = "text";
            if (typ.indexOf("int") >= 0 || typ.indexOf("bigint") >= 0 || typ.indexOf("decimal") >= 0 || typ.indexOf("float") >= 0 || typ.indexOf("double") >= 0) inputType = "number";
            html += '<label class="adm-db-field"><span><b>' + escapeHtml(c.name) + '</b> <small>' + escapeHtml(c.type || "") + (readonly ? " · PK" : "") + '</small></span>';
            if (typ.indexOf("text") >= 0 || (typ.indexOf("varchar") >= 0 && parseInt(typ.replace(/\D+/g, "")) >= 256)) {
                html += '<textarea class="adm-input" data-db-edit="' + escapeHtml(c.name) + '" rows="4"' + (readonly ? ' readonly' : '') + '>' + escapeHtml(value) + '</textarea>';
            } else {
                html += '<input class="adm-input" type="' + inputType + '" data-db-edit="' + escapeHtml(c.name) + '" value="' + escapeHtml(value) + '"' + (readonly ? ' readonly' : '') + '>';
            }
            html += '</label>';
        });
        html += '</div></div>';
        html += '<div class="adm-modal__actions">';
        html += '<button class="adm-btn" data-action="db-row-cancel">Anuluj</button>';
        html += '<button class="adm-btn adm-btn--primary" data-action="db-row-save">Zapisz zmiany</button>';
        html += '</div>';
        html += '</div></div>';
        return html;
    }

    function renderDbInsertModal(columns) {
        var draft = state.dbInsertDraft || { values: {} };
        var html = '<div class="adm-modal adm-modal--db" data-db-modal-bg>';
        html += '<div class="adm-modal__backdrop" data-action="db-row-insert-cancel"></div>';
        html += '<div class="adm-modal__panel adm-modal__panel--db">';
        html += '<div class="adm-modal__head"><h3>Nowy wiersz · <code>' + escapeHtml(draft.table || "") + '</code></h3></div>';
        html += '<div class="adm-modal__body"><div class="adm-grid adm-grid--db-edit">';
        columns.forEach(function (c) {
            if (String(c.extra || "").toLowerCase().indexOf("auto_increment") >= 0) return;
            var v = draft.values[c.name] != null ? draft.values[c.name] : "";
            var typ = String(c.type || "").toLowerCase();
            var inputType = "text";
            if (typ.indexOf("int") >= 0 || typ.indexOf("decimal") >= 0 || typ.indexOf("float") >= 0 || typ.indexOf("double") >= 0) inputType = "number";
            html += '<label class="adm-db-field"><span><b>' + escapeHtml(c.name) + '</b> <small>' + escapeHtml(c.type || "") + '</small></span>';
            if (typ.indexOf("text") >= 0) {
                html += '<textarea class="adm-input" data-db-insert="' + escapeHtml(c.name) + '" rows="3">' + escapeHtml(String(v)) + '</textarea>';
            } else {
                html += '<input class="adm-input" type="' + inputType + '" data-db-insert="' + escapeHtml(c.name) + '" value="' + escapeHtml(String(v)) + '">';
            }
            html += '</label>';
        });
        html += '</div></div>';
        html += '<div class="adm-modal__actions">';
        html += '<button class="adm-btn" data-action="db-row-insert-cancel">Anuluj</button>';
        html += '<button class="adm-btn adm-btn--primary" data-action="db-row-insert">Zapisz</button>';
        html += '</div>';
        html += '</div></div>';
        return html;
    }

    function dbPrimaryKey(columns) {
        for (var i = 0; i < (columns || []).length; i++) {
            if (String(columns[i].keyType || "") === "PRI") return columns[i].name;
        }
        return null;
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
        var d = currentItemRenderEdit();
        var value = d[key];
        return '<label class="adm-render-debug__control"><span>' + escapeHtml(label) + '</span><input type="range" min="' + min + '" max="' + max + '" step="' + step + '" data-render-debug="' + key + '" value="' + value + '"><b>' + (+value).toFixed(key === "scale" || key === "light" ? 2 : 3) + '</b></label>';
    }

    function defaultItemRender() {
        return { rotX: RENDER_DEBUG_DEFAULTS.rotX, rotY: RENDER_DEBUG_DEFAULTS.rotY, rotZ: RENDER_DEBUG_DEFAULTS.rotZ, scale: RENDER_DEBUG_DEFAULTS.scale, light: RENDER_DEBUG_DEFAULTS.light };
    }

    function itemRenderForInstance(instance) {
        if (!instance) return null;
        var key = String(instance).toUpperCase();
        return state.itemRenderConfig[key] || null;
    }

    function currentItemRenderEdit() {
        var inst = state.selectedScheme ? String(state.selectedScheme).toUpperCase() : "";
        if (!inst) return state.itemRenderDebug;
        if (!state.itemRenderConfig[inst]) {
            state.itemRenderConfig[inst] = { rotX: state.itemRenderDebug.rotX, rotY: state.itemRenderDebug.rotY, rotZ: state.itemRenderDebug.rotZ, scale: state.itemRenderDebug.scale, light: state.itemRenderDebug.light };
        }
        return state.itemRenderConfig[inst];
    }

    function renderItemRenderDebug() {
        var sch = state.selectedScheme ? state.schemesById[state.selectedScheme] : null;
        var title = sch ? itemName(sch) : "Wybierz item z grida";
        var visual = sch && sch.visual ? sch.visual : "";
        var d = currentItemRenderEdit();
        var instUp = sch ? String(sch.instance).toUpperCase() : "";
        var hasOverride = instUp && state.itemRenderConfig[instUp] && state.itemRenderConfig[instUp].__saved === true;
        var html = '<div class="adm-render-debug">';
        html += '<div class="adm-render-debug__preview">';
        if (visual) {
            html += '<gothic-render width="180" height="180" rot-x="' + d.rotX + '" rot-y="' + d.rotY + '" rot-z="' + d.rotZ + '" scale="' + d.scale + '" light-intensity="' + d.light + '" visual="' + escapeHtml(visual) + '"></gothic-render>';
        } else {
            html += '<div class="adm-render-debug__empty">Brak visuala</div>';
        }
        html += '</div><div class="adm-render-debug__body"><h4>Render debug' + (sch ? ' · per-item' : ' · globalny') + '</h4><p><b>' + escapeHtml(title) + '</b>' + (sch ? ' <small>[' + escapeHtml(sch.instance) + ']</small>' : '') + (hasOverride ? ' <span class="adm-pill" style="background:#3a5234;color:#d8e6c7;padding:1px 6px;border-radius:6px;font-size:10px">zapisano</span>' : '') + '</p>';
        html += '<div class="adm-render-debug__grid">' + renderDebugSlider("rotX", "rot-x", -3.142, 3.142, 0.01) + renderDebugSlider("rotY", "rot-y", -3.142, 3.142, 0.01) + renderDebugSlider("rotZ", "rot-z", -3.142, 3.142, 0.01) + renderDebugSlider("scale", "scale", 0.2, 3, 0.05) + renderDebugSlider("light", "light", 0.2, 3, 0.05) + '</div>';
        html += '<div class="adm-render-debug__values">rot-x=' + (+d.rotX).toFixed(3) + ' rot-y=' + (+d.rotY).toFixed(3) + ' rot-z=' + (+d.rotZ).toFixed(3) + ' scale=' + (+d.scale).toFixed(2) + ' light=' + (+d.light).toFixed(2) + '</div>';
        if (sch) {
            html += '<div class="adm-toolbar">';
            html += '<button class="adm-btn adm-btn--primary" data-action="item-render-save">Zapisz dla ' + escapeHtml(sch.instance) + '</button>';
            html += '<button class="adm-btn" data-action="item-render-reset">Reset domyślny</button>';
            if (hasOverride) html += '<button class="adm-btn adm-btn--danger" data-action="item-render-delete">Usuń override z DB</button>';
            html += '</div>';
        }
        html += '</div></div>';
        return html;
    }

    var meshQueue = {
        pending: [], active: 0, gen: 0,
        schedule: function (cell, visual) { this.pending.push({ gen: this.gen, cell: cell, visual: visual }); this._tick(); },
        reset: function () { this.gen++; this.pending.length = 0; },
        _tick: function () {
            var self = this;
            while (self.active < 4 && self.pending.length) {
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
            var inst = cell.dataset.instance ? String(cell.dataset.instance).toUpperCase() : "";
            var isBestiaryCell = cell.dataset.action === "bestiary-pick" || cell.dataset.previewKind === "monster";
            var rotX, rotY, rotZ, sc, lt;
            if (isBestiaryCell && inst && state.bestiaryRender[inst]) {
                var b = state.bestiaryRender[inst];
                rotX = b.rotX; rotY = b.rotY; rotZ = b.rotZ; sc = b.scaleValue; lt = b.lightIntensity;
            } else if (isBestiaryCell) {
                rotX = 0.158; rotY = -0.853; rotZ = 0; sc = 1.5; lt = 2.3;
            } else {
                var rcfg = inst && state.itemRenderConfig[inst] ? state.itemRenderConfig[inst] : null;
                rotX = rcfg ? rcfg.rotX : state.itemRenderDebug.rotX;
                rotY = rcfg ? rcfg.rotY : state.itemRenderDebug.rotY;
                rotZ = rcfg ? rcfg.rotZ : state.itemRenderDebug.rotZ;
                sc = rcfg ? rcfg.scale : state.itemRenderDebug.scale;
                lt = rcfg ? rcfg.light : state.itemRenderDebug.light;
            }
            el.setAttribute("rot-x", String(rotX)); el.setAttribute("rot-y", String(rotY)); el.setAttribute("rot-z", String(rotZ));
            el.setAttribute("scale", String(sc)); el.setAttribute("light-intensity", String(lt));
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
        var cells = body.querySelectorAll(".adm-itemcell");
        cells.forEach(function (cell) {
            var v = cell.dataset.previewVisual || cell.dataset.visual;
            if (!v) return;
            meshQueue.schedule(cell, v);
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
        var html = '<div class="adm-section">';
        html += '<div class="adm-tabs adm-tabs--sub">';
        var subTabs = [
            ["catalog", t("admin.npc.subtab.catalog")],
            ["human", t("admin.npc.subtab.human")],
            ["presets", t("admin.npc.subtab.presets")],
            ["editor",  t("admin.npc.subtab.editor")],
            ["active",  tFmt("admin.npc.subtab.active", spawns.length)]
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
        else if (view === "routine") html += renderNpcRoutine();
        else if (view === "spawn-edit") html += renderNpcSpawnEditor();
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

    function updateHumanEquipPickerDom(slot) {
        if (!body || activeTab !== "npc" || state.npcView !== "human") return;
        var h = state.humanCreator;
        var selected = h[slot] || "";
        var sch = selected ? state.schemesById[selected] : null;
        var labelKey = HUMAN_EQUIP_LABELS[slot] || "";
        var title = sch ? itemName(sch) : t("admin.npc.human.none");
        var toggle = body.querySelector('[data-action="human-equip-toggle"][data-slot="' + slot + '"]');
        if (toggle) {
            toggle.innerHTML = '<b>' + escapeHtml(t(labelKey)) + '</b><br><small>' + escapeHtml(title) + (selected ? ' [' + escapeHtml(selected) + ']' : '') + '</small>';
        }
        var picker = toggle ? toggle.parentElement : null;
        if (picker) {
            var grid = picker.querySelector(".adm-itemgrid");
            if (grid) {
                grid.parentNode.removeChild(grid);
            }
        }
    }

    var HUMAN_EQUIP_LABELS = {
        weapon: "admin.npc.human.weapon",
        ranged: "admin.npc.human.ranged",
        armor: "admin.npc.human.armor"
    };

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
        var currentVisualUpper = String(form.visual || "").toUpperCase();
        var craftRecipesForVisual = 0;
        if (currentVisualUpper) {
            (state.craftStations || []).forEach(function (s) {
                if (String(s.visual || "").toUpperCase() === currentVisualUpper) craftRecipesForVisual += (s.recipeIds || []).length;
            });
        }
        html += '<label>' + escapeHtml(t("admin.vobs.field.interactive")) + '<select class="adm-input" data-vob="interactive"><option value="0"' + (+form.interactive ? '' : ' selected') + '>' + escapeHtml(t("admin.common.no")) + '</option><option value="1"' + (+form.interactive ? ' selected' : '') + '>' + escapeHtml(t("admin.common.yes")) + '</option></select></label>';
        html += '<label>Kolizja<select class="adm-input" data-vob="collision"><option value="1"' + (+form.noCollision ? '' : ' selected') + '>Tak</option><option value="0"' + (+form.noCollision ? ' selected' : '') + '>Nie</option></select></label>';
        html += '<label>Interakcja craftu<select class="adm-input" data-vob="craft"><option value="0"' + (+form.craftInteraction ? '' : ' selected') + '>Nie</option><option value="1"' + (+form.craftInteraction ? ' selected' : '') + '>Tak</option></select><small style="color:#8b7550">' + (currentVisualUpper ? ('Receptury dla tego modelu: ' + craftRecipesForVisual) : 'Wybierz najpierw model') + '</small></label>';
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

    function routineGhostPayload() {
        return {
            spawnId: state.npcRoutine.spawnId,
            visual: "ITMI_HOLYHAMMER.3DS",
            nodes: (state.npcRoutine.nodes || []).map(function (n) {
                return {
                    type: n.type || "waypoint",
                    x: +n.x || 0, y: +n.y || 0, z: +n.z || 0
                };
            })
        };
    }

    function syncRoutineGhost() {
        if (state.npcRoutineGhostActive) send("adminRoutineGhostSync", routineGhostPayload());
    }

    function spawnEditPreviewPayload() {
        var ed = state.npcSpawnEdit || {};
        var isHuman = ed.kind === "humanoid" || ed.kind === "npc" || ed.kind === "merchant" || ed.kind === "guard";
        return {
            mode: isHuman ? "human" : "npc",
            instance: ed.instance || "",
            kind: ed.kind || "monster",
            posX: +ed.posX || 0, posY: +ed.posY || 0, posZ: +ed.posZ || 0,
            angle: +ed.angle || 0,
            scaleX: +ed.scaleX || 1, scaleY: +ed.scaleY || 1, scaleZ: +ed.scaleZ || 1,
            fatness: +ed.fatness || 0,
            bodyModel: ed.bodyModel || "", bodyTex: +ed.bodyTex,
            headModel: ed.headModel || "", headTex: +ed.headTex,
            cameraMode: "orbital",
            world: ed.world || ""
        };
    }

    function syncSpawnEditPreview() {
        if (state.npcView === "spawn-edit" && state.npcSpawnEdit) {
            send("adminNpcPreviewUpdate", spawnEditPreviewPayload());
        }
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
        var spawnLabelKey = state.npcEditingId > 0 ? "admin.common.save" : "admin.npc.human.spawn";
        var spawnLabel = state.npcEditingId > 0 ? t("admin.common.save") : t("admin.npc.human.spawn");
        var toolbar = '<div class="adm-toolbar">';
        if (state.npcEditingId > 0) {
            toolbar += '<button class="adm-btn" data-action="human-edit-cancel">' + escapeHtml(t("admin.npc.btn.cancel")) + '</button>';
        }
        toolbar += '<button class="adm-btn" data-action="human-preview">' + escapeHtml(t(h.preview ? "admin.npc.human.previewUpdate" : "admin.npc.human.previewStart")) + '</button>';
        toolbar += '<button class="adm-btn" data-action="human-preview-stop">' + escapeHtml(t("admin.npc.human.previewStop")) + '</button>';
        if (state.npcEditingId === 0) {
            toolbar += '<button class="adm-btn" data-action="human-reset">' + escapeHtml(t("admin.common.reset")) + '</button>';
        }
        toolbar += '<button class="adm-btn adm-btn--primary" data-action="human-spawn">' + escapeHtml(spawnLabel) + '</button>';
        toolbar += '</div>';
        html += toolbar;
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

    function renderNpcSpawnEditor() {
        var ed = state.npcSpawnEdit;
        if (!ed) return '<div class="adm-empty">' + escapeHtml(t("admin.npc.spawnEdit.empty")) + '</div>';
        var html = '<div class="adm-toolbar">';
        html += '<button class="adm-btn" data-action="npc-edit-back">← ' + escapeHtml(t("admin.npc.btn.backToList")) + '</button>';
        html += '<span class="adm-toolbar__sep"></span>';
        html += '<strong>' + escapeHtml(t("admin.npc.spawnEdit.title")) + '</strong>&nbsp;<code>' + escapeHtml(ed.instance || "") + ' #' + ed.id + '</code>';
        html += '</div>';

        html += '<div class="adm-grid adm-grid--2">';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.section.identity")) + '</h4>';
        html += '<label>' + escapeHtml(t("admin.npc.field.label")) + '<input class="adm-input" data-sf="name" value="' + escapeHtml(ed.name || "") + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.instance")) + '<input class="adm-input" data-sf="instance" value="' + escapeHtml(ed.instance || "") + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.kind")) + '<select class="adm-input" data-sf="kind">';
        [["monster", t("admin.npc.kind.monster")], ["npc", t("admin.npc.kind.npc")], ["humanoid", t("admin.npc.cat.humanoid")], ["merchant", t("admin.npc.cat.merchant")], ["guard", t("admin.npc.cat.guard")]].forEach(function (k) {
            var s = (ed.kind || "") === k[0] ? " selected" : "";
            html += '<option value="' + k[0] + '"' + s + '>' + escapeHtml(k[1]) + '</option>';
        });
        html += '</select></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.hostile")) + '<select class="adm-input" data-sf="hostile">';
        [["0", "—"], ["1", "✓ " + t("admin.npc.field.hostile")]].forEach(function (h) {
            var s = String(ed.hostile) === h[0] ? " selected" : "";
            html += '<option value="' + h[0] + '"' + s + '>' + escapeHtml(h[1]) + '</option>';
        });
        html += '</select></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.respawn")) + '<input class="adm-input" type="number" min="0" data-sf="respawnSec" value="' + (ed.respawnSec || 0) + '"></label>';
        html += '<label>Tag<input class="adm-input" data-sf="tag" value="' + escapeHtml(ed.tag || "") + '"></label>';
        html += '</div>';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.section.behavior")) + '</h4>';
        html += '<label>' + escapeHtml(t("admin.npc.field.idleAnimation")) + '<input class="adm-input" data-sf="idleAnimation" value="' + escapeHtml(ed.idleAnimation || "") + '"></label>';
        html += '<div class="adm-grid adm-grid--2">';
        html += '<label>' + escapeHtml(t("admin.npc.field.aggroRadius")) + '<input class="adm-input" type="number" min="0" data-sf="aggroRadius" value="' + (ed.aggroRadius || 0) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.attackRange")) + '<input class="adm-input" type="number" min="0" data-sf="attackRange" value="' + (ed.attackRange || 0) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.attackDamage")) + '<input class="adm-input" type="number" min="0" data-sf="attackDamage" value="' + (ed.attackDamage || 0) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.walkSpeed")) + '<input class="adm-input" type="number" min="0" data-sf="walkSpeed" value="' + (ed.walkSpeed || 0) + '"></label>';
        html += '<label>Bazowy EXP<input class="adm-input" type="number" min="0" data-sf="baseExperience" value="' + (ed.baseExperience || 0) + '"></label>';
        html += '</div>';
        html += '</div>';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.col.pos")) + '</h4>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>X<input class="adm-input" type="number" data-sf="posX" value="' + (ed.posX || 0) + '"></label>';
        html += '<label>Y<input class="adm-input" type="number" data-sf="posY" value="' + (ed.posY || 0) + '"></label>';
        html += '<label>Z<input class="adm-input" type="number" data-sf="posZ" value="' + (ed.posZ || 0) + '"></label>';
        html += '</div>';
        html += '<label>' + escapeHtml(t("admin.houses.heading")) + '<input class="adm-input" type="number" data-sf="angle" value="' + (ed.angle || 0) + '"></label>';
        html += '<div class="adm-toolbar" style="margin-top:8px">';
        html += '<button class="adm-btn" data-action="npc-edit-capture-pos">⌖ ' + escapeHtml(t("admin.npc.spawnEdit.capturePos")) + '</button>';
        html += '</div>';
        html += '<p class="adm-hint">' + escapeHtml(t("admin.npc.spawnEdit.controls")) + '</p>';
        html += '</div>';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.section.stats")) + '</h4>';
        html += '<div class="adm-grid adm-grid--2">';
        html += '<label>' + escapeHtml(t("admin.npc.field.hp")) + '<input class="adm-input" type="number" min="0" data-sf="hp" value="' + (ed.hp || 0) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.level")) + '<input class="adm-input" type="number" min="0" data-sf="level" value="' + (ed.level || 0) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.strength")) + '<input class="adm-input" type="number" min="0" data-sf="strength" value="' + (ed.strength || 0) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.dexterity")) + '<input class="adm-input" type="number" min="0" data-sf="dexterity" value="' + (ed.dexterity || 0) + '"></label>';
        html += '</div>';
        html += '</div>';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.section.visual")) + '</h4>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>' + escapeHtml(t("admin.npc.field.scaleX")) + '<input class="adm-input" type="number" step="0.05" min="0.1" max="5" data-sf="scaleX" value="' + (ed.scaleX || 1) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.scaleY")) + '<input class="adm-input" type="number" step="0.05" min="0.1" max="5" data-sf="scaleY" value="' + (ed.scaleY || 1) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.scaleZ")) + '<input class="adm-input" type="number" step="0.05" min="0.1" max="5" data-sf="scaleZ" value="' + (ed.scaleZ || 1) + '"></label>';
        html += '</div>';
        html += '<label>' + escapeHtml(t("admin.npc.field.fatness")) + '<input class="adm-input" type="number" step="0.1" min="-1" max="3" data-sf="fatness" value="' + (ed.fatness || 0) + '"></label>';
        html += '<div class="adm-grid adm-grid--2">';
        html += '<label>' + escapeHtml(t("admin.npc.field.bodyModel")) + '<input class="adm-input" data-sf="bodyModel" value="' + escapeHtml(ed.bodyModel || "") + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.bodyTex")) + '<input class="adm-input" type="number" data-sf="bodyTex" value="' + (ed.bodyTex == null ? -1 : ed.bodyTex) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.headModel")) + '<input class="adm-input" data-sf="headModel" value="' + escapeHtml(ed.headModel || "") + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.headTex")) + '<input class="adm-input" type="number" data-sf="headTex" value="' + (ed.headTex == null ? -1 : ed.headTex) + '"></label>';
        html += '<label>' + escapeHtml(t("admin.npc.field.voice")) + '<input class="adm-input" type="number" min="0" max="20" data-sf="voice" value="' + (ed.voice || 0) + '"></label>';
        html += '</div>';
        html += '</div>';

        html += '</div>';

        html += '<div class="adm-toolbar">';
        html += '<button class="adm-btn adm-btn--primary" data-action="npc-edit-save">' + escapeHtml(t("admin.common.save")) + '</button>';
        html += '<button class="adm-btn" data-action="npc-edit-back">' + escapeHtml(t("admin.npc.btn.cancel")) + '</button>';
        html += '</div>';
        return html;
    }

    function renderNpcRoutine() {
        var r = state.npcRoutine || { spawnId: 0, enabled: 1, loop: 1, nodes: [] };
        var sel = state.npcRoutineSelected == null ? -1 : state.npcRoutineSelected;
        var spawn = (state.npcSpawns || []).filter(function (s) { return s.id === r.spawnId; })[0];
        var spawnLabel = spawn ? (spawn.name || spawn.instance) + " #" + spawn.id : "#" + r.spawnId;
        var ghostOn = !!state.npcRoutineGhostActive;
        var html = '<div class="adm-toolbar">';
        html += '<button class="adm-btn" data-action="npc-routine-back">← ' + escapeHtml(t("admin.npc.btn.backToList")) + '</button>';
        html += '<span class="adm-toolbar__sep"></span>';
        html += '<strong>' + escapeHtml(t("admin.npc.routine.editing")) + '</strong>&nbsp;<code>' + escapeHtml(spawnLabel) + '</code>';
        html += '</div>';

        html += '<div class="adm-grid adm-grid--2">';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.routine.settings")) + '</h4>';
        html += '<label class="adm-check"><input type="checkbox" data-rf="enabled"' + (r.enabled ? " checked" : "") + '> ' + escapeHtml(t("admin.npc.routine.enabled")) + '</label>';
        html += '<label class="adm-check"><input type="checkbox" data-rf="loop"' + (r.loop ? " checked" : "") + '> ' + escapeHtml(t("admin.npc.routine.loop")) + '</label>';
        html += '<div class="adm-toolbar" style="margin-top:8px">';
        html += '<button class="adm-btn adm-btn--primary" data-action="npc-routine-save">' + escapeHtml(t("admin.npc.routine.save")) + '</button>';
        html += '<button class="adm-btn adm-btn--danger" data-action="npc-routine-delete">' + escapeHtml(t("admin.npc.routine.delete")) + '</button>';
        html += '</div>';
        html += '</div>';

        html += '<div class="adm-section adm-section--inline"><h4>' + escapeHtml(t("admin.npc.routine.builder")) + '</h4>';
        html += '<div class="adm-toolbar">';
        if (!ghostOn) {
            html += '<button class="adm-btn adm-btn--primary" data-action="npc-routine-ghost-start">' + escapeHtml(t("admin.npc.routine.startBuilder")) + '</button>';
        } else {
            html += '<button class="adm-btn" data-action="npc-routine-ghost-stop">' + escapeHtml(t("admin.npc.routine.stopBuilder")) + '</button>';
            html += '<button class="adm-btn adm-btn--primary" data-action="npc-routine-add-waypoint">+ ' + escapeHtml(t("admin.npc.routine.type.waypoint")) + '</button>';
            html += '<button class="adm-btn" data-action="npc-routine-add-wait">+ ' + escapeHtml(t("admin.npc.routine.type.wait")) + '</button>';
        }
        html += '</div>';
        html += '<p class="adm-hint">' + escapeHtml(t(ghostOn ? "admin.npc.routine.hintActive" : "admin.npc.routine.hintInactive")) + '</p>';
        html += '</div>';

        html += '</div>';

        html += '<div class="adm-section"><h4>' + escapeHtml(t("admin.npc.routine.nodes")) + ' (' + r.nodes.length + ')</h4>';
        if (!r.nodes.length) {
            html += '<div class="adm-empty">' + escapeHtml(t("admin.npc.routine.empty")) + '</div>';
        } else {
            html += '<div class="adm-table-wrap"><table class="adm-table"><thead><tr>' +
                '<th>#</th>' +
                '<th>' + escapeHtml(t("admin.npc.routine.col.type")) + '</th>' +
                '<th>' + escapeHtml(t("admin.npc.routine.col.pos")) + '</th>' +
                '<th>' + escapeHtml(t("admin.npc.routine.col.wait")) + '</th>' +
                '<th>' + escapeHtml(t("admin.npc.routine.col.animation")) + '</th>' +
                '<th>' + escapeHtml(t("admin.npc.routine.col.walkMode")) + '</th>' +
                '<th>' + escapeHtml(t("admin.npc.routine.col.label")) + '</th>' +
                '<th></th>' +
                '</tr></thead><tbody>';
            r.nodes.forEach(function (n, idx) {
                var typeKey = "admin.npc.routine.type." + (n.type || "waypoint");
                var posTxt = n.type === "wait"
                    ? "—"
                    : '<input class="adm-input adm-input--xs" type="number" data-nf="x" data-nidx="' + idx + '" value="' + Math.round(n.x || 0) + '">' +
                      '<input class="adm-input adm-input--xs" type="number" data-nf="y" data-nidx="' + idx + '" value="' + Math.round(n.y || 0) + '">' +
                      '<input class="adm-input adm-input--xs" type="number" data-nf="z" data-nidx="' + idx + '" value="' + Math.round(n.z || 0) + '">';
                html += "<tr>";
                html += "<td><b>" + String.fromCharCode(65 + idx) + "</b></td>";
                html += "<td>" + escapeHtml(t(typeKey)) + "</td>";
                html += "<td>" + posTxt + "</td>";
                html += '<td><input class="adm-input adm-input--sm" type="number" min="0" step="100" value="' + (n.waitMs || 0) + '" data-nf="waitMs" data-nidx="' + idx + '"></td>';
                html += '<td><select class="adm-input adm-input--sm" data-nf="animation" data-nidx="' + idx + '">';
                var anims = [
                    ["", "—"],
                    ["S_STAND", t("admin.npc.anim.idle.stand")],
                    ["T_STAND_2_EAT", t("admin.npc.anim.idle.eat")],
                    ["T_1HPARADE_0", t("admin.npc.anim.idle.parade")],
                    ["T_FISTPARADEJUMPB", t("admin.npc.anim.idle.fistparade")],
                    ["T_STAND_2_SIT", t("admin.npc.routine.anim.sit")],
                    ["T_STAND_2_SLEEP", t("admin.npc.routine.anim.sleep")],
                    ["T_STAND_2_PEE", t("admin.npc.routine.anim.pee")],
                    ["T_STAND_2_LGUARD", t("admin.npc.routine.anim.guard")],
                    ["T_PLUNDER", t("admin.npc.routine.anim.plunder")]
                ];
                anims.forEach(function (a) {
                    var selAn = (n.animation || "") === a[0] ? " selected" : "";
                    html += '<option value="' + escapeHtml(a[0]) + '"' + selAn + '>' + escapeHtml(a[1]) + '</option>';
                });
                html += '</select></td>';
                html += '<td><select class="adm-input adm-input--sm" data-nf="walkMode" data-nidx="' + idx + '">';
                [["walk", t("admin.npc.routine.walkMode.walk")], ["run", t("admin.npc.routine.walkMode.run")]].forEach(function (m) {
                    var s = (n.walkMode || "walk") === m[0] ? " selected" : "";
                    html += '<option value="' + m[0] + '"' + s + '>' + escapeHtml(m[1]) + '</option>';
                });
                html += '</select></td>';
                html += '<td><input class="adm-input adm-input--sm" type="text" value="' + escapeHtml(n.label || "") + '" data-nf="label" data-nidx="' + idx + '" placeholder="' + escapeHtml(t("admin.npc.routine.labelPh")) + '"></td>';
                html += '<td><div class="adm-actions">';
                if (idx > 0) html += '<button class="adm-btn adm-btn--sm" data-action="npc-routine-move-up" data-idx="' + idx + '">↑</button>';
                if (idx < r.nodes.length - 1) html += '<button class="adm-btn adm-btn--sm" data-action="npc-routine-move-down" data-idx="' + idx + '">↓</button>';
                if (n.type !== "wait") html += '<button class="adm-btn adm-btn--sm" data-action="npc-routine-recapture" data-idx="' + idx + '" title="' + escapeHtml(t("admin.npc.routine.recapture")) + '">⌖</button>';
                html += '<button class="adm-btn adm-btn--sm adm-btn--danger" data-action="npc-routine-remove" data-idx="' + idx + '">✕</button>';
                html += "</div></td></tr>";
            });
            html += "</tbody></table></div>";
        }
        html += "</div>";
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
                '<td><div class="adm-actions">' +
                '<button class="adm-btn" data-action="npc-edit" data-id="' + s.id + '">' + escapeHtml(t("admin.npc.btn.edit")) + '</button>' +
                '<button class="adm-btn" data-action="npc-routine-edit" data-id="' + s.id + '">' + escapeHtml(t("admin.npc.btn.routine")) + '</button>' +
                '<button class="adm-btn adm-btn--danger" data-action="npc-delete" data-id="' + s.id + '">' + escapeHtml(t("admin.npc.btn.deleteSpawn")) + '</button>' +
                '</div></td></tr>';
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
        if (activeTab === "craft") bindCraftHandlers();
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
        body.querySelectorAll("[data-spawn-ghost]").forEach(function (el) {
            el.addEventListener("change", function () {
                if (!state.spawnGhost) return;
                var key = el.dataset.spawnGhost;
                var v = parseFloat(el.value) || 0;
                state.spawnGhost[key] = v;
                send("adminSpawnGhostSync", {
                    x: state.spawnGhost.x, y: state.spawnGhost.y, z: state.spawnGhost.z,
                    angle: state.spawnGhost.angle,
                    camPitch: state.spawnGhost.camPitch, camRoll: state.spawnGhost.camRoll,
                    mode: state.spawnGhost.mode
                });
            });
        });
        body.querySelectorAll("[data-render-debug]").forEach(function (el) {
            el.addEventListener("input", function () {
                var key = el.dataset.renderDebug;
                var val = parseFloat(el.value) || 0;
                if (state.selectedScheme) {
                    var k = String(state.selectedScheme).toUpperCase();
                    if (!state.itemRenderConfig[k]) state.itemRenderConfig[k] = { rotX: state.itemRenderDebug.rotX, rotY: state.itemRenderDebug.rotY, rotZ: state.itemRenderDebug.rotZ, scale: state.itemRenderDebug.scale, light: state.itemRenderDebug.light };
                    state.itemRenderConfig[k][key] = val;
                } else {
                    state.itemRenderDebug[key] = val;
                    saveRenderDebug();
                }
                render();
            });
        });
        body.querySelectorAll("[data-bestiary-debug]").forEach(function (el) {
            el.addEventListener("input", function () {
                if (!state.bestiarySelected) return;
                var key = state.bestiarySelected.toUpperCase();
                if (!state.bestiaryRender[key]) state.bestiaryRender[key] = { rotX: 0.158, rotY: -0.853, rotZ: 0, scaleValue: 1.5, lightIntensity: 2.3 };
                state.bestiaryRender[key][el.dataset.bestiaryDebug] = parseFloat(el.value) || 0;
                render();
            });
        });
        body.querySelectorAll("[data-hudportrait]").forEach(function (el) {
            var ev = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(ev, function () {
                var raw = state.spawnConfig && state.spawnConfig.hudPortrait ? state.spawnConfig.hudPortrait : "";
                var hp = parseHudPortrait(raw);
                var key = el.dataset.hudportrait;
                if (key === "head") hp.head = String(el.value || hp.head);
                else hp[key] = parseFloat(el.value) || 0;
                if (!state.spawnConfig) state.spawnConfig = {};
                state.spawnConfig.hudPortrait = JSON.stringify(hp);
                render();
            });
        });
        var bf = body.querySelector("[data-role='bestiary-filter']");
        if (bf) bf.addEventListener("input", debounce(function () {
            state.bestiaryFilter = bf.value;
            render();
            var f = body.querySelector("[data-role='bestiary-filter']");
            if (f) { f.focus(); f.setSelectionRange(f.value.length, f.value.length); }
        }, 120));
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
        body.querySelectorAll("[data-rf]").forEach(function (el) {
            el.addEventListener("change", function () {
                var k = el.dataset.rf;
                var v = el.type === "checkbox" ? (el.checked ? 1 : 0) : el.value;
                state.npcRoutine[k] = v;
            });
        });
        body.querySelectorAll("[data-sf]").forEach(function (el) {
            var ev = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(ev, function () {
                if (!state.npcSpawnEdit) return;
                var k = el.dataset.sf;
                var v = el.value;
                if (el.type === "number") v = parseFloat(v) || 0;
                if (k === "instance" && typeof v === "string") v = v.trim().toUpperCase();
                if (k === "hostile") v = parseInt(v, 10) || 0;
                state.npcSpawnEdit[k] = v;
                syncSpawnEditPreview();
            });
        });
        body.querySelectorAll("[data-nf]").forEach(function (el) {
            var ev = el.tagName === "SELECT" ? "change" : "input";
            el.addEventListener(ev, function () {
                var k = el.dataset.nf;
                var idx = parseInt(el.dataset.nidx, 10);
                if (isNaN(idx) || !state.npcRoutine.nodes[idx]) return;
                var v = el.value;
                if (el.type === "number") v = parseFloat(v) || 0;
                state.npcRoutine.nodes[idx][k] = v;
                if (k === "x" || k === "y" || k === "z") syncRoutineGhost();
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
                } else if (k === "collision") {
                    state.vobForm.noCollision = (+v === 0) ? 1 : 0;
                } else if (k === "craft") {
                    state.vobForm.craftInteraction = +v || 0;
                    if (state.vobForm.craftInteraction) state.vobForm.interactive = 1;
                    render();
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
        var dbFilterEl = body.querySelector("[data-role='db-table-filter']");
        if (dbFilterEl) dbFilterEl.addEventListener("input", debounce(function () {
            state.dbFilter = dbFilterEl.value;
            render();
            var f = body.querySelector("[data-role='db-table-filter']");
            if (f) { f.focus(); f.setSelectionRange(f.value.length, f.value.length); }
        }, 120));
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
        var instance = cell.dataset.instance || "";
        state.selectedScheme = instance;
        if (activeTab === "items") {
            updateItemSelectionDom(instance, cell);
        } else {
            render();
        }
    }

    function updateItemSelectionDom(instance, clickedCell) {
        if (!body) return;
        var grid = body.querySelector("[data-role='itemgrid']");
        if (grid) {
            grid.querySelectorAll(".adm-itemcell.is-selected").forEach(function (c) { c.classList.remove("is-selected"); });
            if (clickedCell) clickedCell.classList.add("is-selected");
        }
        var sch = instance ? state.schemesById[instance] : null;
        var nm = sch ? itemName(sch) : "";
        var pickEl = body.querySelector(".adm-form .adm-pick");
        if (pickEl) {
            if (sch) {
                pickEl.classList.remove("adm-pick--empty");
                pickEl.innerHTML = '<b style="color:#f0d785">' + escapeHtml(nm) + '</b>' +
                    ' <span style="color:#8a7c5a;font-size:11px">[' + escapeHtml(sch.instance) + ']</span>';
            } else {
                pickEl.classList.add("adm-pick--empty");
                pickEl.textContent = t("admin.items.pickBelow");
            }
        }
        var bindInput = body.querySelector("input[data-bind='selectedScheme']");
        if (bindInput && document.activeElement !== bindInput) {
            bindInput.value = instance || "";
        }
        var visual = sch && sch.visual ? sch.visual : "";
        var rd = body.querySelector(".adm-render-debug .adm-render-debug__preview");
        if (rd) {
            var existing = rd.querySelector("gothic-render");
            var d = currentItemRenderEdit();
            if (visual) {
                if (existing) {
                    if (existing.getAttribute("visual") !== visual) existing.setAttribute("visual", visual);
                    existing.setAttribute("rot-x", d.rotX);
                    existing.setAttribute("rot-y", d.rotY);
                    existing.setAttribute("rot-z", d.rotZ);
                    existing.setAttribute("scale", d.scale);
                    existing.setAttribute("light-intensity", d.light);
                } else {
                    rd.innerHTML = '<gothic-render width="180" height="180" rot-x="' + d.rotX + '" rot-y="' + d.rotY + '" rot-z="' + d.rotZ + '" scale="' + d.scale + '" light-intensity="' + d.light + '" visual="' + escapeHtml(visual) + '"></gothic-render>';
                }
            } else {
                rd.innerHTML = '<div class="adm-render-debug__empty">Brak visuala</div>';
            }
        }
        var title = sch ? itemName(sch) : "Wybierz item z grida";
        var titleEl = body.querySelector(".adm-render-debug .adm-render-debug__body p");
        if (titleEl) {
            var instUp2 = sch ? String(sch.instance).toUpperCase() : "";
            var hasOverride2 = instUp2 && state.itemRenderConfig[instUp2] && state.itemRenderConfig[instUp2].__saved === true;
            titleEl.innerHTML = '<b>' + escapeHtml(title) + '</b>' + (sch ? ' <small>[' + escapeHtml(sch.instance) + ']</small>' : '') + (hasOverride2 ? ' <span class="adm-pill" style="background:#3a5234;color:#d8e6c7;padding:1px 6px;border-radius:6px;font-size:10px">zapisano</span>' : '');
        }
        var dEdit = currentItemRenderEdit();
        body.querySelectorAll(".adm-render-debug input[data-render-debug]").forEach(function (inp) {
            var k = inp.dataset.renderDebug;
            if (dEdit[k] != null) {
                inp.value = dEdit[k];
                var lbl = inp.parentElement && inp.parentElement.querySelector("b");
                if (lbl) lbl.textContent = (+dEdit[k]).toFixed(k === "scale" || k === "light" ? 2 : 3);
            }
        });
        var valuesEl = body.querySelector(".adm-render-debug .adm-render-debug__values");
        if (valuesEl) {
            valuesEl.textContent = "rot-x=" + (+dEdit.rotX).toFixed(3) + " rot-y=" + (+dEdit.rotY).toFixed(3) + " rot-z=" + (+dEdit.rotZ).toFixed(3) + " scale=" + (+dEdit.scale).toFixed(2) + " light=" + (+dEdit.light).toFixed(2);
        }
        var toolbar = body.querySelector(".adm-render-debug .adm-render-debug__body .adm-toolbar");
        if (toolbar) {
            if (sch) {
                var instUpT = String(sch.instance).toUpperCase();
                var hasOverrideT = state.itemRenderConfig[instUpT] && state.itemRenderConfig[instUpT].__saved === true;
                var html = '<button class="adm-btn adm-btn--primary" data-action="item-render-save">Zapisz dla ' + escapeHtml(sch.instance) + '</button>';
                html += '<button class="adm-btn" data-action="item-render-reset">Reset domyślny</button>';
                if (hasOverrideT) html += '<button class="adm-btn adm-btn--danger" data-action="item-render-delete">Usuń override z DB</button>';
                toolbar.innerHTML = html;
            } else {
                toolbar.innerHTML = "";
            }
        } else if (sch) {
            renderPending = true;
            render();
        }
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
        if (a && a.indexOf("quest-") === 0) {
            handleQuestAction(a, el);
            return;
        }
        if (a && a.indexOf("craft") === 0) {
            handleCraftAction(a, el);
            return;
        }
        if (a && a.indexOf("db-") === 0) {
            handleDbAction(a, el);
            return;
        }
        if (a && a.indexOf("spawnconfig-") === 0) {
            handleSpawnConfigAction(a, el);
            return;
        }
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
        if (a === "bestiary-pick") {
            state.bestiarySelected = String(el.dataset.instance || "").toUpperCase();
            return render();
        }
        if (a === "bestiary-save") {
            var inst = state.bestiarySelected;
            if (!inst) return setStatus("Wybierz potwora", "error");
            var cfg = state.bestiaryRender[inst.toUpperCase()] || { rotX: 0.158, rotY: -0.853, rotZ: 0, scaleValue: 1.5, lightIntensity: 2.3 };
            send("bestiaryRenderSave", {
                instance: inst,
                rotX: cfg.rotX, rotY: cfg.rotY, rotZ: cfg.rotZ,
                scaleValue: cfg.scaleValue,
                lightIntensity: cfg.lightIntensity
            });
            return setStatus("Zapisuję " + inst, "");
        }
        if (a === "bestiary-reset") {
            if (!state.bestiarySelected) return;
            state.bestiaryRender[state.bestiarySelected.toUpperCase()] = { rotX: 0.158, rotY: -0.853, rotZ: 0, scaleValue: 1.5, lightIntensity: 2.3 };
            return render();
        }
        if (a === "hudportrait-save") {
            var rawHp = state.spawnConfig && state.spawnConfig.hudPortrait ? state.spawnConfig.hudPortrait : "";
            var hpVal = parseHudPortrait(rawHp);
            var payloadHp = JSON.stringify({ rotX: hpVal.rotX, rotY: hpVal.rotY, rotZ: hpVal.rotZ, scale: hpVal.scale, light: hpVal.light });
            send("spawnConfigSave", { configKey: "hudPortrait", payload: payloadHp });
            return setStatus("Zapisuję HUD portret", "");
        }
        if (a === "hudportrait-reset") {
            if (!state.spawnConfig) state.spawnConfig = {};
            state.spawnConfig.hudPortrait = JSON.stringify(defaultHudPortrait());
            return render();
        }
        if (a === "item-render-save") {
            if (!state.selectedScheme) return setStatus("Wybierz item z grida", "error");
            var k = String(state.selectedScheme).toUpperCase();
            var cfg = state.itemRenderConfig[k] || { rotX: state.itemRenderDebug.rotX, rotY: state.itemRenderDebug.rotY, rotZ: state.itemRenderDebug.rotZ, scale: state.itemRenderDebug.scale, light: state.itemRenderDebug.light };
            send("itemRenderSave", {
                instance: k,
                rotX: cfg.rotX, rotY: cfg.rotY, rotZ: cfg.rotZ,
                scaleValue: cfg.scale,
                lightIntensity: cfg.light
            });
            return setStatus("Zapisuję " + k, "");
        }
        if (a === "item-render-reset") {
            if (!state.selectedScheme) return;
            var rk = String(state.selectedScheme).toUpperCase();
            state.itemRenderConfig[rk] = { rotX: RENDER_DEBUG_DEFAULTS.rotX, rotY: RENDER_DEBUG_DEFAULTS.rotY, rotZ: RENDER_DEBUG_DEFAULTS.rotZ, scale: RENDER_DEBUG_DEFAULTS.scale, light: RENDER_DEBUG_DEFAULTS.light };
            return render();
        }
        if (a === "item-render-delete") {
            if (!state.selectedScheme) return;
            var dk = String(state.selectedScheme).toUpperCase();
            send("itemRenderDelete", { instance: dk });
            delete state.itemRenderConfig[dk];
            return setStatus("Usuwam override " + dk, "");
        }
        if (a === "npc-view") {
            var prevView = state.npcView;
            state.npcView = el.dataset.view || "presets";
            if (prevView !== state.npcView) {
                if (prevView === "human" && state.humanCreator.preview) {
                    state.humanCreator.preview = 0;
                    send("adminNpcPreviewStop", {});
                }
                if (prevView === "catalog" && state.npcForm.preview) {
                    state.npcForm.preview = 0;
                    send("adminNpcPreviewStop", {});
                }
                if (prevView === "spawn-edit") {
                    send("adminNpcPreviewStop", {});
                    state.npcSpawnEdit = null;
                    state.npcEditingId = 0;
                }
            }
            if (state.npcView === "active") send("npcList");
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
        if (a === "human-edit-cancel") {
            send("adminNpcPreviewStop", {});
            state.humanCreator = defaultHumanCreator();
            state.humanCreator.preview = 0;
            state.npcEditingId = 0;
            state.npcView = "active";
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
            var pickedInstance = el.dataset.instance || "";
            state.humanCreator[pickSlot] = pickedInstance;
            state.humanPickSlot = "";
            if (state.humanCreator.preview) {
                send("adminNpcPreviewUpdate", humanEquipPayload(pickSlot));
            }
            updateHumanEquipPickerDom(pickSlot);
            return;
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
            var metadataJson = JSON.stringify({ equipment: equipment, weapon: hc.weapon || "", armor: hc.armor || "", ranged: hc.ranged || "", expReward: +hc.baseExperience || 0, animation: hc.idleAnimation || "", merchantItems: hc.merchantItems || "" });
            if (state.npcEditingId > 0) {
                var fields = {
                    name: hc.name || "",
                    instance: hc.instance,
                    tag: hc.tag || "",
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
                    posX: +hc.posX || 0,
                    posY: +hc.posY || 0,
                    posZ: +hc.posZ || 0,
                    angle: +hc.angle || 0,
                    metadata: metadataJson
                };
                send("npcUpdate", { id: state.npcEditingId, fields: fields });
                send("adminNpcPreviewStop", {});
                state.humanCreator.preview = 0;
                var editingId = state.npcEditingId;
                state.npcEditingId = 0;
                state.humanCreator = defaultHumanCreator();
                state.npcView = "active";
                return setStatus(tFmt("admin.npc.spawnEdit.saving", "#" + editingId), "");
            }
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
                metadata: metadataJson
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
        if (a === "npc-edit") {
            var sid3 = +el.dataset.id;
            var sp = (state.npcSpawns || []).filter(function (x) { return +x.id === sid3; })[0];
            if (!sp) return setStatus(t("admin.npc.spawnEdit.notFound"), "error");
            hydrateHumanCreatorFromSpawn(sp);
            state.npcEditingId = sid3;
            state.humanPickSlot = "";
            state.humanCreator.preview = 1;
            state.npcView = "human";
            if (!state.schemes.length) send("schemes");
            send("adminNpcPreviewStart", humanPayload(true));
            return render();
        }
        if (a === "npc-edit-back") {
            send("adminNpcPreviewStop", {});
            state.npcSpawnEdit = null;
            state.npcView = "active";
            send("npcList");
            return render();
        }
        if (a === "npc-edit-capture-pos") {
            send("npcRoutineCapturePos", { purpose: "spawn-edit" });
            return setStatus(t("admin.status.capturingPos"), "");
        }
        if (a === "npc-edit-save") {
            var ed = state.npcSpawnEdit;
            if (!ed || !ed.id) return;
            var fields = {};
            ["name","instance","kind","hostile","respawnSec","tag","idleAnimation","aggroRadius","attackRange","attackDamage","walkSpeed","baseExperience","posX","posY","posZ","angle","hp","level","strength","dexterity","scaleX","scaleY","scaleZ","fatness","bodyModel","bodyTex","headModel","headTex","voice"].forEach(function (k) {
                if (ed[k] != null) fields[k] = ed[k];
            });
            send("adminNpcPreviewStop", {});
            send("npcUpdate", { id: ed.id, fields: fields });
            return setStatus(t("admin.npc.spawnEdit.saving"), "");
        }
        if (a === "npc-edit-nudge") {
            send("adminNpcPreviewNudge", { axis: el.dataset.axis, delta: +el.dataset.delta || 0 });
            return;
        }
        if (a === "npc-routine-edit") {
            var sid = +el.dataset.id;
            state.npcRoutine = { spawnId: sid, enabled: 1, loop: 1, nodes: [] };
            state.npcRoutineSelected = -1;
            state.npcRoutineGhostActive = false;
            state.npcView = "routine";
            send("npcRoutineGet", { spawnId: sid });
            return render();
        }
        if (a === "npc-routine-back") {
            if (state.npcRoutineGhostActive) {
                send("adminRoutineGhostStop", {});
                state.npcRoutineGhostActive = false;
            }
            state.npcView = "active";
            send("npcList");
            return render();
        }
        if (a === "npc-routine-ghost-start") {
            state.npcRoutineGhostActive = true;
            send("adminRoutineGhostStart", routineGhostPayload());
            setStatus(t("admin.npc.routine.builderOn"), "ok");
            return render();
        }
        if (a === "npc-routine-ghost-stop") {
            state.npcRoutineGhostActive = false;
            send("adminRoutineGhostStop", {});
            return render();
        }
        if (a === "npc-routine-add-waypoint") {
            if (!state.npcRoutineGhostActive) {
                state.npcRoutineGhostActive = true;
                send("adminRoutineGhostStart", routineGhostPayload());
            }
            var ghost = state.npcRoutineGhostPos || {};
            state.npcRoutine.nodes.push({
                type: "waypoint",
                x: ghost.x || 0, y: ghost.y || 0, z: ghost.z || 0, angle: 0,
                waitMs: 0, animation: "", walkMode: "walk", label: ""
            });
            syncRoutineGhost();
            return render();
        }
        if (a === "npc-routine-add-wait") {
            state.npcRoutine.nodes.push({ type: "wait", x: 0, y: 0, z: 0, angle: 0, waitMs: 3000, animation: "S_STAND", walkMode: "walk", label: "" });
            syncRoutineGhost();
            return render();
        }
        if (a === "npc-routine-remove") {
            var idx = +el.dataset.idx;
            state.npcRoutine.nodes.splice(idx, 1);
            syncRoutineGhost();
            return render();
        }
        if (a === "npc-routine-move-up") {
            var idx = +el.dataset.idx;
            if (idx > 0) {
                var tmp = state.npcRoutine.nodes[idx - 1];
                state.npcRoutine.nodes[idx - 1] = state.npcRoutine.nodes[idx];
                state.npcRoutine.nodes[idx] = tmp;
                syncRoutineGhost();
            }
            return render();
        }
        if (a === "npc-routine-move-down") {
            var idx = +el.dataset.idx;
            if (idx < state.npcRoutine.nodes.length - 1) {
                var tmp = state.npcRoutine.nodes[idx + 1];
                state.npcRoutine.nodes[idx + 1] = state.npcRoutine.nodes[idx];
                state.npcRoutine.nodes[idx] = tmp;
                syncRoutineGhost();
            }
            return render();
        }
        if (a === "npc-routine-recapture") {
            if (!state.npcRoutineGhostActive) {
                state.npcRoutineGhostActive = true;
                send("adminRoutineGhostStart", routineGhostPayload());
            }
            var ghost2 = state.npcRoutineGhostPos || {};
            var ridx = +el.dataset.idx;
            var rn = state.npcRoutine.nodes[ridx];
            if (rn) { rn.x = ghost2.x || 0; rn.y = ghost2.y || 0; rn.z = ghost2.z || 0; }
            syncRoutineGhost();
            return render();
        }
        if (a === "npc-routine-save") {
            var rr = state.npcRoutine;
            if (!rr.spawnId) return setStatus(t("admin.npc.routine.noSpawn"), "error");
            send("npcRoutineSave", { spawnId: rr.spawnId, enabled: rr.enabled ? 1 : 0, loop: rr.loop ? 1 : 0, nodes: rr.nodes });
            return setStatus(t("admin.npc.routine.saving"), "");
        }
        if (a === "npc-routine-delete") {
            var rr2 = state.npcRoutine;
            if (!rr2.spawnId) return;
            send("npcRoutineDelete", { spawnId: rr2.spawnId });
            return setStatus(t("admin.npc.routine.deleting"), "");
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
            state.vobForm = { instance: "", name: vs.name || "", visual: vs.visual || "", vobId: vs.vobId || "", filter: state.vobForm.filter || "", posX: Math.round(vs.x || 0), posY: Math.round(vs.y || 0), posZ: Math.round(vs.z || 0), rotX: Math.round(vs.rotX || 0), rotY: Math.round(vs.rotY || 0), rotZ: Math.round(vs.rotZ || 0), world: vs.world || "", interactive: vs.interactive ? 1 : 0, noCollision: vs.noCollision ? 1 : 0, craftInteraction: vs.craftInteraction ? 1 : 0, step: state.vobForm.step || 50 };
            send("adminVobPreviewStart", vobPreviewPayload(true));
            return render();
        }
        if (a === "vob-save-here" || a === "vob-save-pos") {
            var vf = state.vobForm;
            if (!vf.visual && !vf.instance) return setStatus(t("admin.status.pickInstance"), "error");
            var vPayload = { instance: vf.instance || "", visual: vf.visual || "", name: vf.name || "", vobId: vf.vobId || "", interactive: +vf.interactive || 0, noCollision: +vf.noCollision || 0, craftInteraction: +vf.craftInteraction || 0, rotX: +vf.rotX || 0, rotY: +vf.rotY || 0, rotZ: +vf.rotZ || 0 };
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

    function openConfirmModal(opts) {
        opts = opts || {};
        var title = opts.title || "Potwierdź";
        var message = opts.message || "Czy na pewno?";
        var okLabel = opts.okLabel || "OK";
        var cancelLabel = opts.cancelLabel || "Anuluj";
        var danger = opts.danger !== false;
        var html = '<h3 class="adm-modal__title">' + escapeHtml(title) + '</h3>';
        html += '<p class="adm-modal__sub">' + escapeHtml(message) + '</p>';
        html += '<div class="adm-modal__actions">';
        html += '<button class="adm-btn" data-mclose>' + escapeHtml(cancelLabel) + '</button>';
        html += '<button class="adm-btn ' + (danger ? "adm-btn--danger" : "adm-btn--primary") + '" data-mok>' + escapeHtml(okLabel) + '</button>';
        html += '</div>';
        openModal(html, function (pnl) {
            var ok = pnl.querySelector("[data-mok]");
            try { ok.focus(); } catch (e) {}
            pnl.querySelector("[data-mclose]").addEventListener("click", function () { closeModal(); if (opts.onCancel) opts.onCancel(); });
            ok.addEventListener("click", function () {
                closeModal();
                if (opts.onConfirm) opts.onConfirm();
            });
            var keyHandler = function (e) {
                if (e.key === "Enter") { e.preventDefault(); ok.click(); }
                else if (e.key === "Escape") { e.preventDefault(); closeModal(); if (opts.onCancel) opts.onCancel(); }
            };
            pnl.addEventListener("keydown", keyHandler);
        });
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
        if (p.action === "questList" && p.success) { state.questDefinitions = pl.entries || []; return render(true); }
        if (p.action === "questCatalog" && p.success) { state.questCatalog = pl; return render(true); }
        if (p.action === "questLegacyReport" && p.success) { state.questLegacyReport = pl.entries || []; setStatus("Raport legacy gotowy", "ok"); return render(true); }
        if (p.action === "questLegacyConvert" && p.success) {
            send("questLegacyReport");
            send("questList");
            if (+pl.id > 0) send("questGet", { id: +pl.id });
            return setStatus(pl.alreadyConverted ? "Quest był już przekonwertowany" : "Utworzono draft z danych legacy", "ok");
        }
        if (p.action === "questGet" && p.success) {
            state.questEditor = {
                id: +pl.id || 0,
                code: pl.code || "",
                status: pl.status || "draft",
                lockVersion: +pl.lockVersion || 0,
                content: pl.draftContent || pl.publishedContent || {}
            };
            state.questSelected = state.questEditor.id;
            state.questValidation = null;
            return render(true);
        }
        if (p.action === "questValidate") {
            state.questValidation = pl;
            setStatus(p.success ? "Definicja jest poprawna" : "Definicja wymaga poprawy", p.success ? "ok" : "error");
            return render(true);
        }
        if (p.action === "questSave" && p.success) {
            if (!state.questEditor) state.questEditor = defaultQuestEditor();
            state.questEditor.id = +pl.id || state.questEditor.id;
            state.questEditor.lockVersion = +pl.lockVersion || state.questEditor.lockVersion;
            state.questSelected = state.questEditor.id;
            state.questValidation = pl.validation || null;
            send("questList");
            send("questGet", { id: state.questEditor.id });
            return setStatus("Draft zapisany", "ok");
        }
        if (p.action === "questClone" && p.success) {
            state.questSelected = +pl.id || 0;
            send("questList");
            if (state.questSelected) send("questGet", { id: state.questSelected });
            return setStatus("Quest sklonowany", "ok");
        }
        if ((p.action === "questPublish" || p.action === "questArchive") && p.success) {
            send("questList");
            if (state.questEditor && state.questEditor.id) send("questGet", { id: state.questEditor.id });
            return setStatus(p.action === "questPublish" ? "Quest opublikowany" : "Quest zarchiwizowany", "ok");
        }
        if (p.action.indexOf("quest") === 0 && !p.success) {
            if (pl && (pl.errors || pl.warnings)) state.questValidation = pl;
            setStatus("Operacja questa nie powiodła się: " + (p.error || "unknown"), "error");
            return render(true);
        }
        if (p.action === "players" && p.success) { state.players = pl.players || []; return render(); }
        if (p.action === "schemes" && p.success) {
            var chunkCount = pl.chunkCount || 1;
            var chunkIndex = pl.chunkIndex || 0;
            if (chunkIndex === 0) state._schemeBuf = [];
            if (!state._schemeBuf) state._schemeBuf = [];
            (pl.schemes || []).forEach(function (s) { state._schemeBuf.push(s); });
            if (chunkIndex + 1 < chunkCount) return;
            state.schemes = state._schemeBuf;
            state._schemeBuf = null;
            state.schemesById = {};
            state.schemes.forEach(function (s) { state.schemesById[s.instance] = s; });
            if (activeTab === "craft") render(true);
            else render();
            return;
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
        if (p.action === "bestiaryRenderList" && p.success) {
            state.bestiaryRender = {};
            (pl.entries || []).forEach(function (e) {
                if (!e || !e.instance) return;
                state.bestiaryRender[String(e.instance).toUpperCase()] = {
                    rotX: +e.rotX || 0,
                    rotY: +e.rotY || 0,
                    rotZ: +e.rotZ || 0,
                    scaleValue: +e.scaleValue || 1.5,
                    lightIntensity: +e.lightIntensity || 2.3
                };
            });
            return render();
        }
        if (p.action === "bestiaryRenderSave" && p.success) {
            return setStatus("Zapisano render bestiariusza", "ok");
        }
        if (p.action === "itemRenderList" && p.success) {
            state.itemRenderConfig = {};
            (pl.entries || []).forEach(function (e) {
                if (!e || !e.instance) return;
                state.itemRenderConfig[String(e.instance).toUpperCase()] = {
                    rotX: +e.rotX || 0,
                    rotY: +e.rotY || 0,
                    rotZ: +e.rotZ || 0,
                    scale: +e.scaleValue || 1.4,
                    light: +e.lightIntensity || 2.85,
                    __saved: true
                };
            });
            return render();
        }
        if (p.action === "itemRenderSave" && p.success) {
            if (pl && pl.instance) {
                var sk = String(pl.instance).toUpperCase();
                state.itemRenderConfig[sk] = {
                    rotX: +pl.rotX || 0,
                    rotY: +pl.rotY || 0,
                    rotZ: +pl.rotZ || 0,
                    scale: +pl.scaleValue || 1.4,
                    light: +pl.lightIntensity || 2.85,
                    __saved: true
                };
                render();
            }
            return setStatus("Zapisano render itemu", "ok");
        }
        if (p.action === "itemRenderDelete" && p.success) {
            if (pl && pl.instance) {
                delete state.itemRenderConfig[String(pl.instance).toUpperCase()];
                render();
            }
            return setStatus("Usunięto override", "ok");
        }
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
        if (p.action === "craftingList" && p.success) {
            state.craftRecipes = pl.recipes || [];
            state.craftStations = pl.stations || [];
            return render();
        }
        if (p.action === "dbTables" && p.success) {
            state.dbTables = pl.tables || [];
            return render();
        }
        if (p.action === "dbTableSchema" && p.success) {
            state.dbSchema = { table: pl.table || "", columns: pl.columns || [] };
            return render();
        }
        if (p.action === "dbRows" && p.success) {
            state.dbRows = { table: pl.table || "", rows: pl.rows || [], total: pl.total || 0, offset: pl.offset || 0, limit: pl.limit || 100 };
            return render();
        }
        if ((p.action === "dbRowUpdate" || p.action === "dbRowInsert" || p.action === "dbRowDelete") && p.success) {
            if (state.dbActiveTable) {
                send("dbRows", { table: state.dbActiveTable, limit: state.dbRows.limit || 100, offset: state.dbRows.offset || 0 });
            }
            setStatus(t("admin.status.ok", p.action), "ok");
            return;
        }
        if (p.action === "spawnConfigGet" && p.success) {
            var parsed = parseSpawnConfigPayload(pl);
            state.spawnConfig = parsed;
            state.spawnConfigLoaded = true;
            return render();
        }
        if (p.action === "spawnConfigSave" && p.success) {
            setStatus("Config zapisany i rozesłany do graczy", "ok");
            send("spawnConfigGet");
            return;
        }
        if (p.action === "spawnConfigCapture" && p.success) {
            applySpawnCapture(pl);
            var post = state.spawnConfigPostCapture;
            state.spawnConfigPostCapture = null;
            if (post === "lobby") {
                var arr = state.spawnConfig.lobbyCameras || [];
                var idx = arr.length - 1;
                if (idx >= 0) {
                    var spot = arr[idx];
                    startGhostEditor("lobby", { idx: idx }, "lobby", spot.x, spot.y, spot.z, spot.rotY, spot.rotX, spot.rotZ);
                    return;
                }
            } else if (post === "scenario") {
                var sarr = state.spawnConfig.characterScenarios || [];
                var sidx = sarr.length - 1;
                if (sidx >= 0) {
                    var sc = sarr[sidx];
                    startGhostEditor("scenario", { idx: sidx }, "spawn", sc.x, sc.y, sc.z, sc.angle, 0, 0);
                    return;
                }
            }
            return render(true);
        }
        if (p.action === "adminSpawnGhost" && p.success) {
            if (state.spawnGhost && state.spawnGhost.active) {
                state.spawnGhost.x = +pl.posX || 0;
                state.spawnGhost.y = +pl.posY || 0;
                state.spawnGhost.z = +pl.posZ || 0;
                state.spawnGhost.angle = +pl.angle || 0;
                state.spawnGhost.camPitch = +pl.camPitch || 0;
                state.spawnGhost.camRoll = +pl.camRoll || 0;
                if (pl.world) state.spawnGhost.world = pl.world;
                updateSpawnGhostDom();
            }
            return;
        }
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
            if (state.npcView === "spawn-edit" && state.npcSpawnEdit) {
                state.npcSpawnEdit.posX = Math.round(pl.posX || 0);
                state.npcSpawnEdit.posY = Math.round(pl.posY || 0);
                state.npcSpawnEdit.posZ = Math.round(pl.posZ || 0);
                state.npcSpawnEdit.angle = Math.round(pl.angle || 0);
                if (pl.world) state.npcSpawnEdit.world = pl.world;
                ["posX","posY","posZ","angle"].forEach(function (k) {
                    var inp = body.querySelector('[data-sf="' + k + '"]');
                    if (inp) inp.value = state.npcSpawnEdit[k];
                });
                return;
            }
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
        if (p.action === "npcRoutineGet" && p.success) {
            var rr = pl.routine || { spawnId: pl.spawnId || 0, enabled: 1, loop: 1, nodes: [] };
            state.npcRoutine = {
                spawnId: rr.spawnId || pl.spawnId || 0,
                enabled: rr.enabled == null ? 1 : rr.enabled,
                loop: rr.loop == null ? 1 : rr.loop,
                nodes: rr.nodes || []
            };
            if (state.npcRoutineGhostActive) send("adminRoutineGhostSync", routineGhostPayload());
            return render();
        }
        if (p.action === "adminRoutineGhost" && p.success) {
            state.npcRoutineGhostPos = { x: pl.posX || 0, y: pl.posY || 0, z: pl.posZ || 0 };
            return;
        }
        if (p.action === "npcRoutineCapturePos" && p.success) {
            if (state.npcView === "spawn-edit" && state.npcSpawnEdit) {
                state.npcSpawnEdit.posX = pl.x || 0;
                state.npcSpawnEdit.posY = pl.y || 0;
                state.npcSpawnEdit.posZ = pl.z || 0;
                state.npcSpawnEdit.angle = pl.angle || 0;
                return render();
            }
            if (state.npcRoutineSelected != null && state.npcRoutineSelected >= 0) {
                var n = state.npcRoutine.nodes[state.npcRoutineSelected];
                if (n) { n.x = pl.x || 0; n.y = pl.y || 0; n.z = pl.z || 0; n.angle = pl.angle || 0; }
                state.npcRoutineSelected = -1;
            } else {
                state.npcRoutine.nodes.push({
                    type: "waypoint",
                    x: pl.x || 0, y: pl.y || 0, z: pl.z || 0, angle: pl.angle || 0,
                    waitMs: 0, animation: "", walkMode: "walk", label: ""
                });
            }
            syncRoutineGhost();
            return render();
        }
        if (p.action === "npcRoutineSave" && p.success) {
            setStatus(t("admin.npc.routine.saved"), "ok");
            return;
        }
        if (p.action === "npcRoutineDelete" && p.success) {
            if (state.npcRoutineGhostActive) {
                send("adminRoutineGhostStop", {});
                state.npcRoutineGhostActive = false;
            }
            state.npcRoutine = { spawnId: 0, enabled: 1, loop: 1, nodes: [] };
            state.npcView = "active";
            send("npcList");
            return render();
        }
        if (p.action === "npcUpdate" && p.success) {
            if (state.npcEditingId && (!pl || +pl.id === +state.npcEditingId)) {
                state.npcEditingId = 0;
                state.humanCreator = defaultHumanCreator();
                state.humanCreator.preview = 0;
                state.npcView = "active";
            }
            if (state.npcView === "spawn-edit") {
                state.npcSpawnEdit = null;
                state.npcView = "active";
            }
            send("npcList");
            setStatus(t("admin.npc.spawnEdit.saved"), "ok");
            return render();
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
            if (p.action === "craftingSave" || p.action === "craftingDelete") send("craftingList");
            if (p.action === "kick" || p.action === "tpTo" || p.action === "tpHere" || p.action === "vanish") {
                if (activeTab === "log") send("log", { limit: 100 });
            }
        } else {
            setStatus(tFmt("admin.status.error", p.action, p.error || "?"), "error");
        }
    }

    var questBaseResponse = onResponse;
    var questBaseBindHandlers = bindHandlers;
    var questBaseClose = close;
    var questDiscardBypass = false;
    var questKeyCounter = 0;
    state.questList = { filter: "", status: "", offset: 0, limit: 20, total: 0 };
    state.questUi = { mode: "form", rawText: "", baseline: "", dirty: false, submitted: "", validationFingerprint: "", expectedGetId: 0, filterTimer: null, pickerTimer: null, catalogTimer: null, catalogStatus: "loading", catalogError: "", catalogRetries: 0, npcFilter: "", picker: null, itemFilter: "", monsterFilter: "" };

    function questCopy(value) {
        try { return JSON.parse(JSON.stringify(value)); } catch (e) { return {}; }
    }

    function questNormalizeContent(content) {
        var value = content && typeof content === "object" && !Array.isArray(content) ? content : {};
        if (!value.metadata || typeof value.metadata !== "object" || Array.isArray(value.metadata)) value.metadata = { title: "", description: "" };
        if (!Array.isArray(value.npcBindings)) value.npcBindings = [];
        if (!Array.isArray(value.stages)) value.stages = [];
        if (!Array.isArray(value.dialogGraphs)) value.dialogGraphs = [];
        if (!Array.isArray(value.rewards)) value.rewards = [];
        value.stages.forEach(function (stage) {
            if (!Array.isArray(stage.objectives)) stage.objectives = [];
            if (!Array.isArray(stage.transitions)) stage.transitions = [];
            if (!Array.isArray(stage.markerBindings)) stage.markerBindings = [];
        });
        value.dialogGraphs.forEach(function (graph) {
            if (!Array.isArray(graph.nodes)) graph.nodes = [];
            graph.nodes.forEach(function (node) {
                if (!Array.isArray(node.choices)) node.choices = [];
                node.choices.forEach(function (choice) { if (!Array.isArray(choice.actions)) choice.actions = []; });
            });
        });
        return value;
    }

    function questSimpleAvailability(value) {
        var result = { advanced: false, levelEnabled: false, level: 1, questEnabled: false, questCode: "" };
        if (value == null) return result;
        if (!value || typeof value !== "object" || Array.isArray(value)) { result.advanced = true; return result; }
        var conditions = value.type === "all" && Array.isArray(value.conditions) ? value.conditions : [value];
        if (value.type === "all" && !conditions.length) { result.advanced = true; return result; }
        conditions.forEach(function (condition) {
            if (!condition || typeof condition !== "object" || Array.isArray(condition)) { result.advanced = true; return; }
            if (condition.type === "level" && (condition.operator || "gte") === "gte" && !result.levelEnabled && Number.isFinite(Number(condition.value))) {
                result.levelEnabled = true;
                result.level = Math.max(1, Math.floor(Number(condition.value)));
                return;
            }
            if (condition.type === "quest" && (condition.status || "completed") === "completed" && !result.questEnabled && typeof condition.code === "string") {
                result.questEnabled = true;
                result.questCode = condition.code.toUpperCase();
                return;
            }
            result.advanced = true;
        });
        return result;
    }

    function questBuildAvailability(model) {
        var conditions = [];
        if (model.levelEnabled) conditions.push({ type: "level", operator: "gte", value: Math.max(1, Math.floor(Number(model.level) || 1)) });
        if (model.questEnabled) conditions.push({ type: "quest", code: String(model.questCode || "").trim().toUpperCase(), status: "completed" });
        if (!conditions.length) return null;
        return conditions.length === 1 ? conditions[0] : { type: "all", conditions: conditions };
    }

    function questAvailabilityEditor(content, editor) {
        var availability = questSimpleAvailability(content.availability);
        var disabled = availability.advanced ? " disabled" : "";
        var levelDisabled = availability.advanced || !availability.levelEnabled ? " disabled" : "";
        var questDisabled = availability.advanced || !availability.questEnabled ? " disabled" : "";
        var codes = (state.questDefinitions || []).filter(function (entry) { return +entry.id !== +editor.id && entry.code; }).sort(function (left, right) {
            if (left.status === right.status) return String(left.code).localeCompare(String(right.code));
            return left.status === "published" ? -1 : right.status === "published" ? 1 : 0;
        });
        var options = codes.map(function (entry) { return '<option value="' + escapeHtml(String(entry.code).toUpperCase()) + '">' + escapeHtml(entry.title || entry.code) + '</option>'; }).join("");
        var html = '<section class="adm-quest-card adm-quest-requirements"><header><div><strong>Wymagania rozpoczęcia</strong><small>Bez wymagań, minimalny poziom, ukończenie innego questa albo oba warunki.</small></div></header>';
        if (availability.advanced) html += '<div class="adm-quest-requirements__advanced"><strong>Zaawansowane warunki są zachowane</strong><span>Ten układ zawiera warunki, których prosty formularz nie może bezpiecznie zmienić. Użyj trybu JSON.</span><button class="adm-btn" data-action="quest-mode-json">Otwórz JSON</button></div>';
        html += '<div class="adm-grid adm-grid--2"><label class="adm-check"><input type="checkbox" data-q-availability="levelEnabled"' + (availability.levelEnabled ? " checked" : "") + disabled + '> Wymagaj minimalnego poziomu</label><label class="adm-field"><span>Minimalny poziom</span><input type="number" min="1" step="1" data-q-availability="level" value="' + availability.level + '"' + levelDisabled + '></label><label class="adm-check"><input type="checkbox" data-q-availability="questEnabled"' + (availability.questEnabled ? " checked" : "") + disabled + '> Wymagaj ukończenia innego questa</label><label class="adm-field"><span>Kod ukończonego questa</span><input list="quest-prerequisite-codes" data-q-availability="questCode" value="' + escapeHtml(availability.questCode) + '" placeholder="QUEST_CODE"' + questDisabled + '><datalist id="quest-prerequisite-codes">' + options + '</datalist></label></div>';
        if (!availability.levelEnabled && !availability.questEnabled && !availability.advanced) html += '<span class="adm-muted">Brak wymagań — każdy gracz może rozpocząć quest.</span>';
        return html + '</section>';
    }

    function questFingerprint() {
        if (!state.questEditor) return "";
        var content = state.questEditor.content || {};
        if (state.questUi.mode === "json") {
            try { content = JSON.parse(state.questUi.rawText || "{}"); } catch (e) { return "invalid:" + state.questUi.rawText; }
        }
        try { return JSON.stringify({ code: String(state.questEditor.code || "").trim().toUpperCase(), content: content }); } catch (e) { return "invalid"; }
    }

    function questPrepareEditor(editor, isNew) {
        editor.content = questNormalizeContent(questCopy(editor.content || {}));
        state.questEditor = editor;
        state.questUi.mode = "form";
        state.questUi.rawText = JSON.stringify(editor.content, null, 2);
        state.questUi.baseline = isNew ? "" : questFingerprint();
        state.questUi.dirty = !!isNew;
        state.questUi.submitted = "";
        state.questUi.validationFingerprint = "";
        state.questValidation = null;
    }

    function questDirty(value) {
        state.questUi.dirty = value == null ? questFingerprint() !== state.questUi.baseline : !!value;
        if (state.questUi.dirty) {
            state.questValidation = null;
            state.questUi.validationFingerprint = "";
        }
        var badge = body && body.querySelector("[data-quest-dirty]");
        if (badge) {
            badge.textContent = state.questUi.dirty ? "Niezapisane zmiany" : "Zapisano";
            badge.className = "adm-quest-dirty " + (state.questUi.dirty ? "is-dirty" : "is-saved");
        }
    }

    function questRequestList() {
        var list = state.questList;
        send("questList", { offset: list.offset, limit: list.limit, filter: list.filter, status: list.status });
    }

    function questStableKey(prefix) {
        questKeyCounter += 1;
        return prefix + "_" + Date.now().toString(36) + "_" + questKeyCounter.toString(36);
    }

    function questSelectOptions(values, selected, labeler) {
        var current = String(selected == null ? "" : selected);
        var found = false;
        var html = "";
        (values || []).forEach(function (value) {
            var raw = typeof value === "object" ? value.value : value;
            var text = labeler ? labeler(value) : raw;
            raw = String(raw == null ? "" : raw);
            if (raw === current) found = true;
            html += '<option value="' + escapeHtml(raw) + '"' + (raw === current ? " selected" : "") + '>' + escapeHtml(text == null ? raw : text) + '</option>';
        });
        if (current && !found) html += '<option value="' + escapeHtml(current) + '" selected>' + escapeHtml(current + " · brak w katalogu") + '</option>';
        return html;
    }

    function questNpcReferences(refType, current) {
        var catalog = state.questCatalog || {};
        var values = [];
        var seen = {};
        function append(value, label) {
            var key = String(value == null ? "" : value);
            if (!key || seen[key]) return;
            seen[key] = true;
            values.push({ value: key, label: label || key });
        }
        if (refType === "spawn") (catalog.npcs || []).forEach(function (npc) { append(npc.spawnId, (npc.label || npc.name || npc.instance || "NPC") + " · spawn #" + npc.spawnId + (npc.world ? " · " + npc.world : "")); });
        else if (refType === "preset") (catalog.presets || []).forEach(function (preset) { append(preset.id, (preset.label || preset.code || preset.instance || "Preset") + " · #" + preset.id); });
        else if (refType === "instance") (catalog.npcs || []).forEach(function (npc) { append(npc.instance, npc.instance + (npc.name ? " · " + npc.name : "")); });
        else if (refType === "tag") (catalog.npcs || []).forEach(function (npc) { append(npc.tag, npc.tag + (npc.name ? " · " + npc.name : "")); });
        if (current && !seen[String(current)]) values.push({ value: String(current), label: String(current) + " · brak w katalogu" });
        return values;
    }

    function questItemCatalog() {
        var catalog = state.questCatalog || {};
        if (catalog.items && catalog.items.length) return catalog.items;
        return (state.schemes || []).filter(function (scheme) { return scheme && scheme.instance; }).map(function (scheme) { return { instance: String(scheme.instance || "").toUpperCase(), name: scheme.name || scheme.instance, category: scheme.category, visual: scheme.visual || "" }; });
    }

    function questItemEntry(instance) {
        var value = String(instance || "").toUpperCase();
        var items = questItemCatalog();
        for (var i = 0; i < items.length; i += 1) if (String(items[i].instance || "").toUpperCase() === value) return items[i];
        return null;
    }

    function questItemLabel(instance) {
        var entry = questItemEntry(instance);
        return entry ? (entry.name || entry.label || entry.instance) : String(instance || "");
    }

    function questObjectiveReference(config) {
        var value = config && typeof config === "object" ? config : {};
        if (value.refType || value.refValue) return { refType: String(value.refType || ""), refValue: String(value.refValue || "") };
        if (value.spawnId != null) return { refType: "spawn", refValue: String(value.spawnId) };
        if (value.presetId != null) return { refType: "preset", refValue: String(value.presetId) };
        if (value.instance != null) return { refType: "instance", refValue: String(value.instance) };
        if (value.tag != null) return { refType: "tag", refValue: String(value.tag) };
        return { refType: "", refValue: "" };
    }

    function questNpcTargetLabel(config) {
        var reference = questObjectiveReference(config);
        var entries = questNpcReferences(reference.refType, reference.refValue);
        for (var i = 0; i < entries.length; i += 1) if (String(entries[i].value) === reference.refValue) return entries[i].label;
        return reference.refValue;
    }

    function questBindingLabel(binding) {
        if (!binding) return "";
        return questNpcTargetLabel({ refType: binding.refType, refValue: binding.refValue }) || binding.key || "";
    }

    function questStageDeliveryBinding(stage) {
        if (!stage || !Array.isArray(stage.markerBindings) || !state.questEditor || !state.questEditor.content) return null;
        var key = "";
        for (var i = 0; i < stage.markerBindings.length; i += 1) {
            if ((stage.markerBindings[i].markerType || "continue") === "continue" && stage.markerBindings[i].bindingKey) { key = stage.markerBindings[i].bindingKey; break; }
        }
        if (!key) return null;
        var bindings = state.questEditor.content.npcBindings || [];
        for (var j = 0; j < bindings.length; j += 1) if (bindings[j].key === key) return bindings[j];
        return null;
    }

    function questDefaultObjectiveConfig(type) {
        if (type === "collect" || type === "deliver") return { instance: "" };
        if (type === "reach") return { zoneKey: questStableKey("zone"), world: "", x: 0, y: 0, z: 0, radius: 250 };
        if (type === "custom_event") return { eventName: state.questCatalog.eventTypes && state.questCatalog.eventTypes[0] ? state.questCatalog.eventTypes[0] : "" };
        if (type === "interact") return { targetKey: "" };
        var giver = state.questEditor && state.questEditor.content ? questFindBinding(state.questEditor.content, "giver") : null;
        if (giver && type === "talk") return { refType: giver.refType, refValue: giver.refValue };
        if (type === "kill") return { refType: "instance", refValue: "" };
        var refType = state.questCatalog.npcRefTypes && state.questCatalog.npcRefTypes[0] ? state.questCatalog.npcRefTypes[0] : "spawn";
        return { refType: refType, refValue: "" };
    }

    function questDefaultReward(type) {
        var reward = { key: questStableKey("reward"), type: type };
        if (type === "flag") reward.value = "1";
        else reward.amount = 1;
        var items = questItemCatalog();
        if (type === "item") reward.instance = items[0] ? items[0].instance : "";
        if (type === "statistic") reward.stat = "strength";
        return reward;
    }

    function questItemOptions(selected) {
        var items = questItemCatalog();
        var label = items.length ? "Wybierz przedmiot…" : "Brak przedmiotów w katalogu";
        return '<option value="">' + label + '</option>' + questSelectOptions(items.map(function (item) { return { value: item.instance, label: (item.name || item.label || item.instance) + " · " + item.instance }; }), selected, function (item) { return item.label; });
    }

    function questIssuesFor(prefix, entityKey) {
        var validation = state.questValidation || {};
        var issues = (validation.errors || []).concat(validation.warnings || []);
        return issues.filter(function (issue) {
            var path = String(issue.path || "");
            var key = String(issue.entityKey || "");
            return path.indexOf(prefix) === 0 || (entityKey && key === String(entityKey));
        });
    }

    function questIssueClass(prefix, entityKey) {
        var issues = questIssuesFor(prefix, entityKey);
        for (var i = 0; i < issues.length; i += 1) if (issues[i].severity !== "warning") return " has-error";
        return "";
    }

    function questObjectiveTargetState(objective, stage) {
        var type = String(objective && objective.type || "");
        var config = objective && objective.config && typeof objective.config === "object" ? objective.config : {};
        var required = Math.max(1, +(objective && objective.required) || 1);
        var suffix = required > 1 ? " × " + required : "";
        var reference = questObjectiveReference(config);
        var refValue = reference.refValue;
        var refLabel = questNpcTargetLabel(config);
        if (type === "talk") return refValue ? { valid: true, summary: "Porozmawiaj z: " + refLabel + suffix, message: "" } : { valid: false, summary: "Nie wybrano rozmówcy", message: "Wybierz NPC w polu „Z kim porozmawiać?”." };
        if (type === "kill") return refValue ? { valid: true, summary: "Zabij: " + refLabel + suffix, message: "" } : { valid: false, summary: "Nie wybrano przeciwnika", message: "Wybierz moba w polu „Kogo zabić?”." };
        if (type === "collect" || type === "deliver") {
            var instance = String(config.instance || "").toUpperCase();
            var item = questItemEntry(instance);
            if (!instance) return { valid: false, summary: "Nie wybrano przedmiotu", message: "Wybierz przedmiot w polu „Co " + (type === "collect" ? "zebrać" : "dostarczyć") + "?”." };
            if (questItemCatalog().length && !item) return { valid: false, summary: instance + suffix, message: "Wybranego przedmiotu nie ma w aktualnym katalogu." };
            if (type === "collect") return { valid: true, summary: "Zbierz: " + questItemLabel(instance) + suffix, message: "" };
            var binding = questStageDeliveryBinding(stage);
            if (!binding) return { valid: false, summary: "Dostarcz: " + questItemLabel(instance) + suffix, message: "Wybierz NPC w polu „Komu dostarczyć?”." };
            return { valid: true, summary: "Dostarcz: " + questItemLabel(instance) + suffix + " do " + questBindingLabel(binding), message: "" };
        }
        if (type === "reach") {
            var numeric = ["x", "y", "z", "radius"].every(function (field) { return typeof config[field] === "number" && isFinite(config[field]); });
            var valid = !!String(config.zoneKey || "") && numeric && +config.radius > 0;
            var summary = "Dotrzyj: " + (String(config.world || "") || "bieżący świat") + ", X " + (config.x == null ? "—" : config.x) + ", Y " + (config.y == null ? "—" : config.y) + ", Z " + (config.z == null ? "—" : config.z) + ", promień " + (config.radius == null ? "—" : config.radius);
            return valid ? { valid: true, summary: summary, message: "" } : { valid: false, summary: summary, message: "Uzupełnij klucz strefy, współrzędne i dodatni promień w sekcji „Dokąd dotrzeć?”." };
        }
        if (type === "interact") return config.targetKey || refValue ? { valid: true, summary: "Interakcja: " + (config.targetKey || refLabel), message: "" } : { valid: false, summary: "Nie wybrano celu interakcji", message: "Uzupełnij klucz albo referencję celu interakcji." };
        if (type === "custom_event") return config.eventName ? { valid: true, summary: "Zdarzenie: " + config.eventName + suffix, message: "" } : { valid: false, summary: "Nie wybrano zdarzenia", message: "Wybierz zarejestrowane zdarzenie." };
        return { valid: false, summary: "Nieznany typ celu", message: "Wybierz obsługiwany typ celu." };
    }

    function questValidationSummary() {
        if (!state.questValidation) return "";
        var validation = state.questValidation;
        var issues = (validation.errors || []).concat(validation.warnings || []);
        var html = '<div class="adm-quest-validation adm-quest-validation--summary ' + (validation.valid ? 'is-valid' : 'is-invalid') + '"><strong>' + (validation.valid ? 'Definicja gotowa do publikacji' : 'Draft zapisany, ale wymaga uzupełnienia') + '</strong>';
        if (!issues.length) html += '<span>Nie znaleziono problemów.</span>';
        issues.forEach(function (issue) { html += '<div><code>' + escapeHtml(issue.path || "") + '</code><span>' + escapeHtml(issue.message || issue.code || "") + '</span></div>'; });
        return html + '</div>';
    }

    function questBindingEditor(binding, index) {
        var refType = binding.refType || (state.questCatalog.npcRefTypes || ["spawn"])[0] || "spawn";
        var html = '<article class="adm-quest-card' + questIssueClass("npcBindings[" + index + "]") + '"><header><strong>' + escapeHtml(binding.key || "Binding NPC") + '</strong><button class="adm-btn adm-btn--danger" data-action="quest-remove-binding" data-index="' + index + '">Usuń</button></header>';
        html += '<div class="adm-grid adm-grid--2"><label class="adm-field"><span>Klucz</span><input value="' + escapeHtml(binding.key || "") + '" disabled></label>';
        html += '<label class="adm-field"><span>Rola</span><select data-q-binding="' + index + '" data-field="role">' + questSelectOptions(state.questCatalog.npcRoles || [], binding.role || "giver", questNpcRoleLabel) + '</select></label>';
        html += '<label class="adm-field"><span>Typ referencji</span><select data-q-binding="' + index + '" data-field="refType">' + questSelectOptions(state.questCatalog.npcRefTypes || [], refType, questNpcRefLabel) + '</select></label>';
        html += '<label class="adm-field"><span>NPC</span><select data-q-binding="' + index + '" data-field="refValue">' + questSelectOptions(questNpcReferences(refType, binding.refValue), binding.refValue, function (entry) { return entry.label; }) + '</select></label>';
        html += '<label class="adm-field"><span>Offset markera</span><input type="number" step="1" data-q-binding="' + index + '" data-field="markerOffset" value="' + (+binding.markerOffset || 165) + '"></label></div></article>';
        return html;
    }

    function questFindBinding(content, role) {
        for (var i = 0; i < content.npcBindings.length; i += 1) if (content.npcBindings[i].role === role) return content.npcBindings[i];
        return null;
    }

    function questNpcCatalogEditor(content) {
        var catalog = state.questCatalog || {};
        var npcs = catalog.npcs || [];
        var giver = questFindBinding(content, "giver");
        var turnIn = questFindBinding(content, "turn_in");
        var filter = String(state.questUi.npcFilter || "").toLowerCase();
        var filtered = npcs.filter(function (npc) {
            if (!filter) return true;
            return [npc.spawnId, npc.label, npc.name, npc.instance, npc.world, npc.tag, npc.kind].join(" ").toLowerCase().indexOf(filter) >= 0;
        });
        var html = '<section class="adm-quest-section adm-quest-step"><header><div><span class="adm-quest-step__number">2</span><strong>Wybierz NPC</strong><small>Kliknij rolę przy postaci. NPC pochodzą bezpośrednio z bazy serwera.</small></div><button class="adm-btn" data-action="quest-retry-catalog">Odśwież NPC</button></header>';
        html += '<div class="adm-quest-role-summary"><div><span>Zleceniodawca</span><strong>' + escapeHtml(giver ? questNpcReferences(giver.refType, giver.refValue).filter(function (entry) { return String(entry.value) === String(giver.refValue); }).map(function (entry) { return entry.label; })[0] || giver.refValue : "Nie wybrano") + '</strong></div><div><span>NPC oddania</span><strong>' + escapeHtml(turnIn ? questNpcReferences(turnIn.refType, turnIn.refValue).filter(function (entry) { return String(entry.value) === String(turnIn.refValue); }).map(function (entry) { return entry.label; })[0] || turnIn.refValue : "Nie wybrano") + '</strong></div></div>';
        if (state.questUi.catalogStatus === "loading" && !npcs.length) html += '<div class="adm-quest-catalog-state"><strong>Ładowanie NPC z bazy…</strong><span>Lista pojawi się automatycznie, gdy serwer zakończy przygotowanie katalogu.</span></div>';
        else if (state.questUi.catalogStatus === "error" && !npcs.length) html += '<div class="adm-quest-catalog-state is-error"><strong>Nie udało się pobrać NPC</strong><span>' + escapeHtml(state.questUi.catalogError || "Brak odpowiedzi serwera") + '</span><button class="adm-btn" data-action="quest-retry-catalog">Spróbuj ponownie</button></div>';
        else if (!npcs.length) html += '<div class="adm-quest-catalog-state"><strong>Brak NPC w bazie</strong><span>Najpierw dodaj NPC w zakładce NPC panelu administratora, a następnie odśwież katalog.</span></div>';
        else {
            html += '<div class="adm-quest-catalog-tools"><input class="adm-search" data-quest-npc-filter value="' + escapeHtml(state.questUi.npcFilter || "") + '" placeholder="Szukaj po nazwie, instancji, ID, świecie lub tagu"><span data-quest-npc-count>' + filtered.length + ' / ' + npcs.length + ' NPC</span></div><div class="adm-quest-npc-grid" data-quest-scroll="npc-catalog">';
            npcs.forEach(function (npc) {
                var search = [npc.spawnId, npc.label, npc.name, npc.instance, npc.world, npc.tag, npc.kind].join(" ").toLowerCase();
                var isGiver = giver && giver.refType === "spawn" && String(giver.refValue) === String(npc.spawnId);
                var isTurnIn = turnIn && turnIn.refType === "spawn" && String(turnIn.refValue) === String(npc.spawnId);
                html += '<article class="adm-quest-npc" data-quest-npc-card data-search="' + escapeHtml(search) + '"' + (filter && search.indexOf(filter) < 0 ? " hidden" : "") + '><div><strong>' + escapeHtml(npc.label || npc.name || npc.instance || "NPC") + '</strong><small>#' + (+npc.spawnId || 0) + ' · ' + escapeHtml(npc.instance || "") + '</small><span>' + escapeHtml((npc.world || "brak świata") + (npc.tag ? " · tag: " + npc.tag : "")) + '</span></div><div class="adm-actions"><button class="adm-btn' + (isGiver ? " is-active" : "") + '" data-action="quest-use-npc" data-role="giver" data-spawn-id="' + (+npc.spawnId || 0) + '">' + (isGiver ? "Wybrany zleceniodawca" : "Ustaw jako zleceniodawcę") + '</button><button class="adm-btn' + (isTurnIn ? " is-active" : "") + '" data-action="quest-use-npc" data-role="turn_in" data-spawn-id="' + (+npc.spawnId || 0) + '">' + (isTurnIn ? "Wybrany do oddania" : "Ustaw do oddania") + '</button></div></article>';
            });
            html += '</div>';
        }
        html += '<details class="adm-quest-advanced" data-quest-details="advanced-bindings"><summary>Zaawansowane powiązania NPC</summary><div class="adm-toolbar"><button class="adm-btn" data-action="quest-add-binding">Dodaj powiązanie preset / instancja / tag</button></div>';
        if (!content.npcBindings.length) html += '<div class="adm-empty">Brak przypisanych NPC.</div>';
        content.npcBindings.forEach(function (binding, index) { html += questBindingEditor(binding, index); });
        return html + '</details></section>';
    }

    function questMonsterCatalog() {
        var out = [];
        var seen = {};
        var supplemental = {};
        (state.npcCatalog || []).forEach(function (entry) {
            var instance = String(entry.instance || "").toUpperCase();
            if (instance && !(instance in supplemental)) supplemental[instance] = entry;
        });
        function append(entry) {
            var instance = String(entry && entry.instance || "").toUpperCase();
            if (!instance || seen[instance]) return;
            var extra = supplemental[instance] || {};
            var visual = entry.visual || extra.visual || "";
            if (!visual && global.PhoenixNpcVisuals) visual = PhoenixNpcVisuals.get(instance) || "";
            seen[instance] = true;
            out.push({ instance: instance, label: entry.label || entry.name || extra.label || extra.name || instance, visual: visual });
        }
        ((state.questCatalog || {}).npcs || []).forEach(append);
        (state.npcCatalog || []).forEach(append);
        return out;
    }

    function questPickerOpen(kind, stageIndex, objectiveIndex) {
        var picker = state.questUi.picker;
        return picker && picker.kind === kind && +picker.stage === stageIndex && +picker.objective === objectiveIndex;
    }

    function questObjectivePicker(objective, stageIndex, objectiveIndex) {
        var kind = objective.type === "kill" ? "monster" : (objective.type === "collect" || objective.type === "deliver" ? "item" : "");
        if (!kind || !questPickerOpen(kind, stageIndex, objectiveIndex)) return "";
        var config = objective.config || {};
        var filter = String(kind === "monster" ? state.questUi.monsterFilter : state.questUi.itemFilter).trim().toLowerCase();
        var source = kind === "monster" ? questMonsterCatalog() : questItemCatalog();
        var rows = source.filter(function (entry) { return !filter || [entry.instance, entry.label, entry.name].join(" ").toLowerCase().indexOf(filter) >= 0; }).slice(0, 160);
        var selected = kind === "monster" ? String(questObjectiveReference(config).refValue || "").toUpperCase() : String(config.instance || "").toUpperCase();
        var html = '<section class="adm-quest-picker"><header><strong>' + (kind === "monster" ? "Kogo zabić? Wybierz moba" : (objective.type === "deliver" ? "Co dostarczyć? Wybierz przedmiot" : "Co zebrać? Wybierz przedmiot")) + '</strong><button class="adm-btn" data-action="quest-close-picker">Zamknij</button></header><div class="adm-quest-catalog-tools"><input class="adm-search" data-quest-objective-picker-filter data-kind="' + kind + '" value="' + escapeHtml(kind === "monster" ? state.questUi.monsterFilter : state.questUi.itemFilter) + '" placeholder="Szukaj po nazwie lub instancji"><span data-quest-picker-count>' + rows.length + ' wyników</span></div><div class="adm-itemgrid adm-quest-picker-grid" data-role="itemgrid" data-quest-scroll="picker-' + stageIndex + '-' + objectiveIndex + '">';
        rows.forEach(function (entry) {
            var instance = String(entry.instance || "").toUpperCase();
            var label = entry.label || entry.name || instance;
            var visual = entry.visual || "";
            html += '<button type="button" class="adm-itemcell' + (selected === instance ? " is-selected" : "") + '" data-action="' + (kind === "monster" ? "quest-pick-objective-monster" : "quest-pick-objective-item") + '" data-stage="' + stageIndex + '" data-index="' + objectiveIndex + '" data-instance="' + escapeHtml(instance) + '" data-visual="' + escapeHtml(visual) + '" data-preview-kind="' + kind + '" data-search="' + escapeHtml((label + " " + instance).toLowerCase()) + '" title="' + escapeHtml(label) + '"><div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(String(label).slice(0, 18)) + '</span></div><span class="adm-itemcell__cat">' + escapeHtml(instance) + '</span></button>';
        });
        if (!source.length) html += '<div class="adm-empty">' + (kind === "monster" ? "Brak mobów w katalogu NPC. Dodaj NPC lub odśwież katalog." : "Brak przedmiotów w katalogu. Poczekaj na wczytanie schematów lub odśwież panel.") + '</div>';
        else if (!rows.length) html += '<div class="adm-empty">Brak wyników dla podanego filtra.</div>';
        return html + '</div></section>';
    }

    function questObjectiveConfig(objective, stageIndex, objectiveIndex) {
        var type = objective.type || "talk";
        var config = objective.config && typeof objective.config === "object" ? objective.config : (objective.config = {});
        var attr = ' data-q-objective-config="' + stageIndex + ':' + objectiveIndex + '"';
        var stage = state.questEditor.content.stages[stageIndex];
        if (type === "collect" || type === "deliver") {
            var itemTitle = type === "deliver" ? "Co dostarczyć?" : "Co zebrać?";
            var html = '<strong class="adm-quest-config-title">' + itemTitle + '</strong><div class="adm-grid adm-grid--2"><label class="adm-field"><span>Przedmiot</span><select' + attr + ' data-field="instance">' + questItemOptions(config.instance || "") + '</select></label><button class="adm-btn adm-quest-picker-button" data-action="quest-open-picker" data-kind="item" data-stage="' + stageIndex + '" data-index="' + objectiveIndex + '">Wybierz przedmiot z podglądu</button></div>';
            if (!questItemCatalog().length) html += '<div class="adm-quest-catalog-state"><strong>Katalog przedmiotów jest pusty</strong><span>Schematy przedmiotów nie zostały jeszcze wczytane albo serwer nie zwrócił żadnych pozycji.</span></div>';
            if (type === "deliver") {
                var delivery = questStageDeliveryBinding(stage);
                var bindingEntries = (state.questEditor.content.npcBindings || []).map(function (binding) { return { value: binding.key, label: questNpcRoleLabel(binding.role) + " · " + questBindingLabel(binding) }; });
                html += '<label class="adm-field"><span>Komu dostarczyć?</span><select data-q-deliver-binding="' + stageIndex + '"><option value="">Wybierz NPC odbierającego przedmioty…</option>' + questSelectOptions(bindingEntries, delivery ? delivery.key : "", function (entry) { return entry.label; }) + '</select></label>';
            }
            return html;
        }
        if (type === "reach") {
            function numberValue(field, fallback) { return config[field] == null || config[field] === "" ? fallback : config[field]; }
            return '<strong class="adm-quest-config-title">Dokąd dotrzeć?</strong><div class="adm-grid adm-grid--3"><label class="adm-field"><span>Świat</span><input' + attr + ' data-field="world" value="' + escapeHtml(config.world || "") + '" placeholder="Puste = bieżący świat"></label><label class="adm-field"><span>X</span><input type="number" step="0.1"' + attr + ' data-field="x" value="' + escapeHtml(numberValue("x", 0)) + '"></label><label class="adm-field"><span>Y</span><input type="number" step="0.1"' + attr + ' data-field="y" value="' + escapeHtml(numberValue("y", 0)) + '"></label><label class="adm-field"><span>Z</span><input type="number" step="0.1"' + attr + ' data-field="z" value="' + escapeHtml(numberValue("z", 0)) + '"></label><label class="adm-field"><span>Promień</span><input type="number" min="1" step="1"' + attr + ' data-field="radius" value="' + escapeHtml(numberValue("radius", 250)) + '"></label><label class="adm-field"><span>Klucz strefy</span><input' + attr + ' data-field="zoneKey" value="' + escapeHtml(config.zoneKey || "") + '" placeholder="Unikalny klucz strefy"></label></div>';
        }
        if (type === "custom_event") return '<strong class="adm-quest-config-title">Jakie zdarzenie wykonać?</strong><label class="adm-field"><span>Zarejestrowany event</span><select' + attr + ' data-field="eventName">' + questSelectOptions(state.questCatalog.eventTypes || [], config.eventName || "") + '</select></label>';
        if (type === "interact") return '<strong class="adm-quest-config-title">Z czym wejść w interakcję?</strong><label class="adm-field"><span>Klucz celu interakcji</span><input' + attr + ' data-field="targetKey" value="' + escapeHtml(config.targetKey || "") + '"></label>';
        var reference = questObjectiveReference(config);
        var refType = reference.refType || (type === "kill" ? "instance" : (state.questCatalog.npcRefTypes || ["spawn"])[0] || "spawn");
        var references = questNpcReferences(refType, reference.refValue);
        var title = type === "kill" ? "Kogo zabić?" : "Z kim porozmawiać?";
        var placeholder = type === "kill" ? "Wybierz moba…" : "Wybierz NPC…";
        var pickerButton = type === "kill" ? '<button class="adm-btn adm-quest-picker-button" data-action="quest-open-picker" data-kind="monster" data-stage="' + stageIndex + '" data-index="' + objectiveIndex + '">Wybierz moba z podglądu</button>' : "";
        return '<strong class="adm-quest-config-title">' + title + '</strong><div class="adm-grid adm-grid--2"><label class="adm-field"><span>' + title + '</span><select' + attr + ' data-field="refValue"><option value="">' + placeholder + '</option>' + questSelectOptions(references, reference.refValue, function (entry) { return entry.label; }) + '</select></label>' + pickerButton + '</div><details class="adm-quest-advanced"><summary>Zaawansowany typ referencji NPC</summary><label class="adm-field"><span>Typ referencji</span><select' + attr + ' data-field="refType">' + questSelectOptions(state.questCatalog.npcRefTypes || [], refType, questNpcRefLabel) + '</select></label></details>';
    }

    function questObjectiveLabel(type) {
        return ({ talk: "Porozmawiaj z NPC", kill: "Zabij NPC", collect: "Zbierz przedmioty", deliver: "Dostarcz przedmioty", reach: "Dotrzyj do miejsca", interact: "Wejdź w interakcję", custom_event: "Zdarzenie niestandardowe" })[type] || type;
    }

    function questRewardLabel(type) {
        return ({ experience: "Doświadczenie", currency: "Waluta", item: "Przedmiot", statistic: "Statystyka", flag: "Flaga postaci" })[type] || type;
    }

    function questNpcRoleLabel(role) {
        return ({ giver: "Zleceniodawca", turn_in: "NPC oddania", talk_target: "Cel rozmowy", interact_target: "Cel interakcji" })[role] || role;
    }

    function questNpcRefLabel(type) {
        return ({ spawn: "Konkretny NPC z bazy", preset: "Preset NPC", instance: "Instancja", tag: "Tag" })[type] || type;
    }

    function questStatisticLabel(stat) {
        return ({ strength: "Siła", dexterity: "Zręczność", learnPoints: "Punkty nauki", hpMax: "Maksymalne zdrowie", manaMax: "Maksymalna mana" })[stat] || stat;
    }

    function questObjectiveModeLabel(mode) {
        return ({ all: "Wszystkie cele", any: "Dowolny cel" })[mode] || mode;
    }

    function questMarkerLabel(type) {
        return ({ continue: "Kontynuacja", turn_in: "Oddanie questa" })[type] || type;
    }

    function questObjectiveEditor(objective, stageIndex, objectiveIndex) {
        var path = "stages[" + stageIndex + "].objectives[" + objectiveIndex + "]";
        var stage = state.questEditor.content.stages[stageIndex];
        var target = questObjectiveTargetState(objective, stage);
        var issues = questIssuesFor(path, objective.key);
        var amountLabel = ({ talk: "Liczba rozmów", kill: "Ilu przeciwników zabić?", collect: "Ile zebrać?", deliver: "Ile dostarczyć?", reach: "Liczba wejść do strefy" })[objective.type] || "Wymagana ilość";
        var html = '<article class="adm-quest-subcard' + questIssueClass(path, objective.key) + '"><header><strong>' + escapeHtml(objective.label || objective.key || "Cel") + '</strong><button class="adm-btn adm-btn--danger" data-action="quest-remove-objective" data-stage="' + stageIndex + '" data-index="' + objectiveIndex + '">Usuń</button></header>';
        html += '<div class="adm-quest-target-state' + (target.valid ? "" : " is-invalid") + '"><strong>' + escapeHtml(target.summary) + '</strong>' + (target.message ? '<span>' + escapeHtml(target.message) + '</span>' : '') + '</div>';
        html += '<div class="adm-grid adm-grid--3"><label class="adm-field"><span>Klucz</span><input value="' + escapeHtml(objective.key || "") + '" disabled></label><label class="adm-field"><span>Typ</span><select data-q-objective="' + stageIndex + ':' + objectiveIndex + '" data-field="type">' + questSelectOptions(state.questCatalog.objectiveTypes || [], objective.type || "talk", questObjectiveLabel) + '</select></label><label class="adm-field"><span>' + amountLabel + '</span><input type="number" min="1" data-q-objective="' + stageIndex + ':' + objectiveIndex + '" data-field="required" value="' + Math.max(1, +objective.required || 1) + '"></label><label class="adm-field adm-field--wide"><span>Opis dla gracza</span><input data-q-objective="' + stageIndex + ':' + objectiveIndex + '" data-field="label" value="' + escapeHtml(objective.label || "") + '"></label><label class="adm-check"><input type="checkbox" data-q-objective="' + stageIndex + ':' + objectiveIndex + '" data-field="visible"' + (objective.visible === false ? "" : " checked") + '> Widoczny w dzienniku</label></div>';
        html += '<div class="adm-quest-config">' + questObjectiveConfig(objective, stageIndex, objectiveIndex) + '</div>' + questObjectivePicker(objective, stageIndex, objectiveIndex);
        if (issues.length) {
            html += '<div class="adm-quest-inline-issues">';
            issues.forEach(function (issue) { html += '<span>' + escapeHtml(issue.message || issue.code || "") + '</span>'; });
            html += '</div>';
        }
        return html + '</article>';
    }

    function questStageEditor(stage, index, content) {
        var html = '<article class="adm-quest-card adm-quest-stage' + questIssueClass("stages[" + index + "]", stage.key) + '"><header><div><span>Etap ' + (index + 1) + '</span><strong>' + escapeHtml(stage.title || stage.key || "Etap") + '</strong></div><div class="adm-actions"><button class="adm-btn" data-action="quest-move-stage" data-index="' + index + '" data-dir="-1">↑</button><button class="adm-btn" data-action="quest-move-stage" data-index="' + index + '" data-dir="1">↓</button><button class="adm-btn adm-btn--danger" data-action="quest-remove-stage" data-index="' + index + '">Usuń</button></div></header>';
        html += '<div class="adm-grid adm-grid--3"><label class="adm-field"><span>Klucz</span><input value="' + escapeHtml(stage.key || "") + '" disabled></label><label class="adm-field"><span>Nazwa etapu</span><input data-q-stage="' + index + '" data-field="title" value="' + escapeHtml(stage.title || "") + '"></label><label class="adm-field"><span>Tryb celów</span><select data-q-stage="' + index + '" data-field="objectiveMode">' + questSelectOptions(["all", "any"], stage.objectiveMode || "all", questObjectiveModeLabel) + '</select></label><label class="adm-field"><span>Zakończenie</span><select data-q-stage="' + index + '" data-field="terminal">' + questSelectOptions([{ value: "", label: "Przejście do etapu" }, { value: "success", label: "Sukces" }, { value: "failure", label: "Porażka" }], stage.terminal || "", function (entry) { return entry.label; }) + '</select></label><label class="adm-field"><span>NPC oddania</span><select data-q-stage="' + index + '" data-field="turnInBindingKey"><option value="">Bez oddania u NPC</option>' + questSelectOptions(content.npcBindings.filter(function (binding) { return binding.role === "giver" || binding.role === "turn_in"; }).map(function (binding) { return { value: binding.key, label: questNpcRoleLabel(binding.role) + " · " + questBindingLabel(binding) }; }), stage.turnInBindingKey || "", function (entry) { return entry.label; }) + '</select></label><label class="adm-check"><input type="checkbox" data-q-stage="' + index + '" data-field="allowCycle"' + (stage.allowCycle ? " checked" : "") + '> Zezwól na cykl</label></div>';
        html += '<section class="adm-quest-group"><header><strong>Cele</strong><div class="adm-actions"><button class="adm-btn" data-action="quest-add-objective-type" data-stage="' + index + '" data-type="talk">Rozmowa</button><button class="adm-btn" data-action="quest-add-objective-type" data-stage="' + index + '" data-type="kill">Polowanie</button><button class="adm-btn" data-action="quest-add-objective-type" data-stage="' + index + '" data-type="collect">Zbieranie</button><button class="adm-btn" data-action="quest-add-objective-type" data-stage="' + index + '" data-type="deliver">Dostarczenie</button><button class="adm-btn" data-action="quest-add-objective-type" data-stage="' + index + '" data-type="reach">Dotarcie</button></div></header>';
        if (!stage.objectives.length) html += '<div class="adm-empty">Brak celów w etapie.</div>';
        stage.objectives.forEach(function (objective, objectiveIndex) { html += questObjectiveEditor(objective, index, objectiveIndex); });
        html += '</section><section class="adm-quest-group"><header><strong>Przejścia</strong><button class="adm-btn" data-action="quest-add-transition" data-stage="' + index + '">Dodaj przejście</button></header>';
        stage.transitions.forEach(function (transition, transitionIndex) { html += '<div class="adm-quest-row"><code>' + escapeHtml(transition.key || "transition") + '</code><select data-q-transition="' + index + ':' + transitionIndex + '" data-field="target">' + questSelectOptions(content.stages.map(function (candidate) { return candidate.key; }), transition.target || "") + '</select><button class="adm-btn adm-btn--danger" data-action="quest-remove-transition" data-stage="' + index + '" data-index="' + transitionIndex + '">Usuń</button></div>'; });
        if (!stage.transitions.length) html += '<div class="adm-muted">Etap terminalny nie wymaga przejść.</div>';
        html += '</section><section class="adm-quest-group"><header><strong>Znaczniki nad NPC aktywnego etapu</strong><small>„!” nad zleceniodawcą jest automatyczny. Tutaj ustawiasz „?” dla rozmowy w trakcie.</small><button class="adm-btn" data-action="quest-add-marker" data-stage="' + index + '"' + (content.npcBindings.length ? "" : " disabled") + '>Dodaj marker</button></header>';
        stage.markerBindings.forEach(function (marker, markerIndex) { html += '<div class="adm-quest-row"><select data-q-marker="' + index + ':' + markerIndex + '" data-field="bindingKey">' + questSelectOptions(content.npcBindings.map(function (binding) { return binding.key; }), marker.bindingKey || "") + '</select><select data-q-marker="' + index + ':' + markerIndex + '" data-field="markerType">' + questSelectOptions(["continue", "turn_in"], marker.markerType || "continue", questMarkerLabel) + '</select><button class="adm-btn adm-btn--danger" data-action="quest-remove-marker" data-stage="' + index + '" data-index="' + markerIndex + '">Usuń</button></div>'; });
        html += '</section></article>';
        return html;
    }

    function questRewardChoiceGroup() {
        var rewards = state.questEditor && state.questEditor.content ? state.questEditor.content.rewards || [] : [];
        for (var i = 0; i < rewards.length; i += 1) if (rewards[i].choiceGroup) return rewards[i].choiceGroup;
        return "reward_choice";
    }

    function questRewardEditor(reward, index) {
        var type = reward.type || "experience";
        var choice = !!reward.choiceGroup;
        var html = '<article class="adm-quest-subcard' + questIssueClass("rewards[" + index + "]") + '"><header><strong>' + escapeHtml(reward.label || reward.key || "Nagroda") + '</strong><button class="adm-btn adm-btn--danger" data-action="quest-remove-reward" data-index="' + index + '">Usuń</button></header><div class="adm-grid adm-grid--3">';
        html += '<label class="adm-field"><span>Klucz</span><input value="' + escapeHtml(reward.key || "") + '" disabled></label><label class="adm-field"><span>Typ</span><select data-q-reward="' + index + '" data-field="type">' + questSelectOptions(state.questCatalog.rewardTypes || [], type, questRewardLabel) + '</select></label>';
        if (type !== "flag") html += '<label class="adm-field"><span>Ilość</span><input type="number" min="1" data-q-reward="' + index + '" data-field="amount" value="' + Math.max(1, +reward.amount || 1) + '"></label>';
        if (type === "item") html += '<label class="adm-field"><span>Przedmiot</span><select data-q-reward="' + index + '" data-field="instance">' + questItemOptions(reward.instance || "") + '</select></label>';
        if (type === "statistic") html += '<label class="adm-field"><span>Statystyka</span><select data-q-reward="' + index + '" data-field="stat">' + questSelectOptions(["strength", "dexterity", "learnPoints", "hpMax", "manaMax"], reward.stat || "strength", questStatisticLabel) + '</select></label>';
        if (type === "flag") html += '<label class="adm-field"><span>Wartość flagi</span><input data-q-reward="' + index + '" data-field="value" value="' + escapeHtml(reward.value == null ? "1" : reward.value) + '"></label>';
        html += '<label class="adm-check"><input type="checkbox" data-q-reward-choice="' + index + '"' + (choice ? " checked" : "") + '> Gracz wybiera ten wariant</label>';
        if (choice) html += '<label class="adm-field"><span>Nazwa wariantu dla gracza</span><input data-q-reward="' + index + '" data-field="label" value="' + escapeHtml(reward.label || "") + '" placeholder="Np. Miecz albo złoto"></label>';
        html += '</div></article>';
        return html;
    }

    function questDialogModeLabel(mode) {
        return ({ start: "Przed rozpoczęciem", continue: "W trakcie questa", turn_in: "Przy oddaniu" })[mode] || mode;
    }

    function questDialogActionEditor(action, graphIndex, nodeIndex, choiceIndex, actionIndex) {
        var path = graphIndex + ":" + nodeIndex + ":" + choiceIndex + ":" + actionIndex;
        var type = action.type || "deliver";
        var html = '<div class="adm-quest-dialog-action"><select data-q-dialog-action="' + path + '" data-field="type">' + questSelectOptions([{ value: "deliver", label: "Odbierz przedmioty" }, { value: "setFlag", label: "Ustaw flagę" }, { value: "event", label: "Wywołaj zdarzenie" }], type, function (entry) { return entry.label; }) + '</select>';
        if (type === "deliver") html += '<select data-q-dialog-action="' + path + '" data-field="instance">' + questItemOptions(action.instance || "") + '</select><input type="number" min="1" data-q-dialog-action="' + path + '" data-field="amount" value="' + Math.max(1, +action.amount || 1) + '" title="Ilość">';
        if (type === "setFlag") html += '<input data-q-dialog-action="' + path + '" data-field="key" value="' + escapeHtml(action.key || "") + '" placeholder="Klucz flagi"><input data-q-dialog-action="' + path + '" data-field="value" value="' + escapeHtml(action.value == null ? "1" : action.value) + '" placeholder="Wartość">';
        if (type === "event") html += '<select data-q-dialog-action="' + path + '" data-field="eventName">' + questSelectOptions(state.questCatalog.eventTypes || [], action.eventName || "") + '</select>';
        return html + '<button class="adm-btn adm-btn--danger" data-action="quest-remove-dialog-action" data-graph="' + graphIndex + '" data-node="' + nodeIndex + '" data-choice="' + choiceIndex + '" data-index="' + actionIndex + '">Usuń</button></div>';
    }

    function questDialogChoiceEditor(choice, graph, graphIndex, nodeIndex, choiceIndex) {
        var path = graphIndex + ":" + nodeIndex + ":" + choiceIndex;
        var html = '<article class="adm-quest-dialog-choice"><div class="adm-grid adm-grid--2"><label class="adm-field"><span>Odpowiedź gracza</span><input data-q-dialog-choice="' + path + '" data-field="text" value="' + escapeHtml(choice.text || "") + '" placeholder="Np. Zajmę się tym."></label><label class="adm-field"><span>Po odpowiedzi</span><select data-q-dialog-choice="' + path + '" data-field="target"><option value="">Zakończ dialog i wykonaj etap</option>' + questSelectOptions(graph.nodes.map(function (node) { return node.key; }), choice.target || "") + '</select></label></div><div class="adm-quest-dialog-choice__head"><code>' + escapeHtml(choice.key || "choice") + '</code><div><button class="adm-btn" data-action="quest-add-dialog-action" data-graph="' + graphIndex + '" data-node="' + nodeIndex + '" data-choice="' + choiceIndex + '">Dodaj akcję</button><button class="adm-btn adm-btn--danger" data-action="quest-remove-dialog-choice" data-graph="' + graphIndex + '" data-node="' + nodeIndex + '" data-index="' + choiceIndex + '">Usuń odpowiedź</button></div></div>';
        (choice.actions || []).forEach(function (action, actionIndex) { html += questDialogActionEditor(action, graphIndex, nodeIndex, choiceIndex, actionIndex); });
        return html + '</article>';
    }

    function questDialogNodeEditor(node, graph, graphIndex, nodeIndex) {
        var path = graphIndex + ":" + nodeIndex;
        var html = '<article class="adm-quest-subcard adm-quest-dialog-node"><header><strong>Wypowiedź ' + (nodeIndex + 1) + '</strong><div class="adm-actions"><code>' + escapeHtml(node.key || "node") + '</code><button class="adm-btn adm-btn--danger" data-action="quest-remove-dialog-node" data-graph="' + graphIndex + '" data-index="' + nodeIndex + '">Usuń</button></div></header><div class="adm-grid adm-grid--2"><label class="adm-field"><span>Mówi</span><select data-q-dialog-node="' + path + '" data-field="speaker">' + questSelectOptions([{ value: "npc", label: "NPC" }, { value: "player", label: "Gracz" }], node.speaker || "npc", function (entry) { return entry.label; }) + '</select></label><label class="adm-field adm-field--wide"><span>Tekst wypowiedzi</span><textarea data-q-dialog-node="' + path + '" data-field="text" placeholder="Treść dialogu">' + escapeHtml(node.text || "") + '</textarea></label></div><section class="adm-quest-group"><header><strong>Opcje odpowiedzi</strong><button class="adm-btn" data-action="quest-add-dialog-choice" data-graph="' + graphIndex + '" data-node="' + nodeIndex + '">Dodaj odpowiedź</button></header>';
        if (!(node.choices || []).length) html += '<div class="adm-empty">Dodaj odpowiedź kończącą dialog albo prowadzącą do kolejnej wypowiedzi.</div>';
        (node.choices || []).forEach(function (choice, choiceIndex) { html += questDialogChoiceEditor(choice, graph, graphIndex, nodeIndex, choiceIndex); });
        return html + '</section></article>';
    }

    function questDialogGraphEditor(graph, graphIndex, content) {
        var bindingEntries = content.npcBindings.map(function (binding) { return { value: binding.key, label: questNpcRoleLabel(binding.role) + " · " + binding.key }; });
        var html = '<article class="adm-quest-card adm-quest-dialog-graph' + questIssueClass("dialogGraphs[" + graphIndex + "]") + '"><header><div><span>Dialog ' + (graphIndex + 1) + '</span><strong>' + escapeHtml(questDialogModeLabel(graph.mode || "start")) + '</strong></div><button class="adm-btn adm-btn--danger" data-action="quest-remove-dialog" data-index="' + graphIndex + '">Usuń dialog</button></header><div class="adm-grid adm-grid--3"><label class="adm-field"><span>Klucz</span><input value="' + escapeHtml(graph.key || "") + '" disabled></label><label class="adm-field"><span>NPC dialogu</span><select data-q-dialog-graph="' + graphIndex + '" data-field="bindingKey">' + questSelectOptions(bindingEntries, graph.bindingKey || "", function (entry) { return entry.label; }) + '</select></label><label class="adm-field"><span>Moment dialogu</span><select data-q-dialog-graph="' + graphIndex + '" data-field="mode">' + questSelectOptions(["start", "continue", "turn_in"], graph.mode || "start", questDialogModeLabel) + '</select></label><label class="adm-field"><span>Pierwsza wypowiedź</span><select data-q-dialog-graph="' + graphIndex + '" data-field="startNodeKey">' + questSelectOptions((graph.nodes || []).map(function (node) { return node.key; }), graph.startNodeKey || "") + '</select></label></div><section class="adm-quest-group"><header><strong>Przebieg rozmowy</strong><button class="adm-btn" data-action="quest-add-dialog-node" data-graph="' + graphIndex + '">Dodaj wypowiedź</button></header>';
        (graph.nodes || []).forEach(function (node, nodeIndex) { html += questDialogNodeEditor(node, graph, graphIndex, nodeIndex); });
        return html + '</section></article>';
    }

    function questDialogEditor(content) {
        var html = '<section class="adm-quest-section adm-quest-step"><header><div><span class="adm-quest-step__number">D</span><strong>Dialogi i odpowiedzi</strong><small>Opcja z pustym przejściem kończy rozmowę i rozpoczyna, kontynuuje albo oddaje quest.</small></div><div class="adm-actions"><button class="adm-btn" data-action="quest-add-dialog" data-mode="start">Dialog startowy</button><button class="adm-btn" data-action="quest-add-dialog" data-mode="continue">Dialog w trakcie</button><button class="adm-btn" data-action="quest-add-dialog" data-mode="turn_in">Dialog oddania</button></div></header>';
        if (!content.dialogGraphs.length) html += '<div class="adm-empty">Dialogi są opcjonalne. Bez nich wybór questa u NPC wykona akcję od razu.</div>';
        content.dialogGraphs.forEach(function (graph, graphIndex) { html += questDialogGraphEditor(graph, graphIndex, content); });
        return html + '</section>';
    }

    function questGraphOverview(content) {
        var html = '<div class="adm-quest-flow">';
        content.stages.forEach(function (stage, index) {
            var targets = (stage.transitions || []).map(function (transition) { return transition.target; }).filter(Boolean);
            html += '<div class="adm-quest-flow__node' + (stage.key === content.startStageKey ? " is-start" : "") + (stage.terminal ? " is-terminal" : "") + '"><span>' + (index + 1) + '</span><strong>' + escapeHtml(stage.title || stage.key) + '</strong><small>' + escapeHtml(stage.key) + (stage.terminal ? " · " + stage.terminal : targets.length ? " → " + targets.join(", ") : "") + '</small></div>';
        });
        return html + '</div>';
    }

    function questStructuredEditor(editor) {
        var content = questNormalizeContent(editor.content);
        var basicsReady = !!String(editor.code || "").trim() && !!String(content.metadata.title || "").trim();
        var npcReady = !!questFindBinding(content, "giver");
        var stagesReady = content.stages.length > 0 && content.stages.every(function (stage) { return Array.isArray(stage.objectives) && stage.objectives.length > 0 && stage.objectives.every(function (objective) { return questObjectiveTargetState(objective, stage).valid; }); });
        var saved = +editor.id > 0 && !state.questUi.dirty;
        var validated = saved && state.questValidation && state.questValidation.valid && state.questUi.validationFingerprint === questFingerprint();
        var html = '<div class="adm-quest-structured"><div class="adm-quest-wizard"><span class="' + (basicsReady ? "is-ready" : "") + '"><b>1</b> Podstawy</span><span class="' + (npcReady ? "is-ready" : "") + '"><b>2</b> NPC</span><span class="' + (stagesReady ? "is-ready" : "") + '"><b>3</b> Cele</span><span class="is-ready"><b>4</b> Nagrody opcjonalne</span><span class="' + (validated ? "is-ready" : saved ? "is-pending" : "") + '"><b>5</b> ' + (validated ? "Gotowy do publikacji" : saved ? "Wymaga walidacji" : "Zapis i publikacja") + '</span></div>';
        html += '<section class="adm-quest-card adm-quest-step"><header><div><span class="adm-quest-step__number">1</span><strong>Podstawowe informacje</strong><small>Nazwa i opis widoczne dla gracza.</small></div></header><div class="adm-grid adm-grid--2"><label class="adm-field"><span>Tytuł questa</span><input data-q-meta="title" value="' + escapeHtml(content.metadata.title || "") + '" placeholder="Np. Zaginiona dostawa"></label><label class="adm-field"><span>Etap początkowy</span><select data-q-root="startStageKey">' + questSelectOptions(content.stages.map(function (stage) { return stage.key; }), content.startStageKey || "") + '</select></label><label class="adm-field adm-field--wide"><span>Opis dla gracza</span><textarea data-q-meta="description" placeholder="Krótko wyjaśnij, czego dotyczy zadanie">' + escapeHtml(content.metadata.description || "") + '</textarea></label></div></section>';
        html += questAvailabilityEditor(content, editor);
        html += questNpcCatalogEditor(content);
        html += questDialogEditor(content);
        html += '<section class="adm-quest-section adm-quest-step"><header><div><span class="adm-quest-step__number">3</span><strong>Etapy i cele</strong><small>Dodaj czynności, które gracz musi wykonać. Dla prostego questa wystarczy jeden etap.</small></div><button class="adm-btn" data-action="quest-add-stage">Dodaj kolejny etap</button></header>' + questGraphOverview(content);
        content.stages.forEach(function (stage, index) { html += questStageEditor(stage, index, content); });
        html += '</section><section class="adm-quest-section adm-quest-step"><header><div><span class="adm-quest-step__number">4</span><strong>Nagrody</strong><small>Dodaj doświadczenie, walutę, przedmiot, statystykę albo flagę.</small></div><button class="adm-btn" data-action="quest-add-reward">Dodaj nagrodę</button></header>';
        if (!content.rewards.length) html += '<div class="adm-empty">Brak nagród. Możesz zapisać quest bez nagrody albo dodać ją przyciskiem powyżej.</div>';
        content.rewards.forEach(function (reward, index) { html += questRewardEditor(reward, index); });
        var warningCount = state.questValidation && state.questValidation.warnings ? state.questValidation.warnings.length : 0;
        html += '</section><section class="adm-quest-card adm-quest-step adm-quest-finish"><div class="adm-quest-step__number">5</div><div><strong>Zapisz, sprawdź i opublikuj</strong><span>' + (validated ? "Definicja przeszła pełną walidację publikacyjną i jest gotowa." : saved ? "Draft zapisany. Użyj „Waliduj przed publikacją”, aby sprawdzić NPC i zasoby." : "Najpierw zapisz draft, następnie wykonaj pełną walidację publikacyjną.") + '</span>' + (warningCount ? '<label class="adm-check"><input type="checkbox" data-q-acknowledge-warnings' + (content.acknowledgeWarnings ? " checked" : "") + '> Rozumiem i akceptuję ' + warningCount + ' ostrzeżeń publikacji</label>' : '') + '</div></section><section class="adm-quest-card adm-quest-advanced-note"><strong>Tryb zaawansowany</strong><span>Warunki, grafy dialogów, akcje i niestandardowe pola możesz edytować w JSON. Przełączenie nie usuwa danych formularza.</span><button class="adm-btn" data-action="quest-mode-json">Otwórz JSON</button></section></div>';
        return html;
    }

    renderQuestMaker = function () {
        var editor = state.questEditor;
        var list = state.questDefinitions || [];
        var paging = state.questList;
        var from = paging.total ? paging.offset + 1 : 0;
        var to = Math.min(paging.total, paging.offset + paging.limit);
        var html = '<div class="adm-section adm-quest-maker"><div class="adm-toolbar"><button class="adm-btn adm-btn--primary" data-action="quest-new">Nowy quest</button><button class="adm-btn" data-action="quest-refresh">Odśwież</button><button class="adm-btn" data-action="quest-legacy-report">Raport legacy</button><span class="adm-muted">Draft → walidacja → publikacja niezmiennej rewizji</span></div><div class="adm-quest-layout"><aside class="adm-quest-list" data-quest-scroll="definition-list"><div class="adm-quest-list__filters"><input class="adm-search" data-quest-list-filter value="' + escapeHtml(paging.filter) + '" placeholder="Szukaj kodu lub tytułu"><select data-quest-list-status><option value="">Wszystkie statusy</option>' + questSelectOptions(["draft", "published", "archived"], paging.status) + '</select></div>';
        if (!list.length) html += '<div class="adm-empty">Brak definicji questów.</div>';
        list.forEach(function (entry) { var active = editor && +editor.id === +entry.id; html += '<button class="adm-quest-entry' + (active ? ' is-active' : '') + '" data-action="quest-select" data-id="' + (+entry.id || 0) + '"><strong>' + escapeHtml(entry.title || entry.code) + '</strong><small>' + escapeHtml(entry.code) + ' · ' + escapeHtml(entry.status) + ' · v' + (+entry.lockVersion || 0) + '</small></button>'; });
        html += '<div class="adm-quest-pager"><button class="adm-btn" data-action="quest-page-prev"' + (paging.offset <= 0 ? " disabled" : "") + '>←</button><span>' + from + '–' + to + ' / ' + paging.total + '</span><button class="adm-btn" data-action="quest-page-next"' + (paging.offset + paging.limit >= paging.total ? " disabled" : "") + '>→</button></div></aside><section class="adm-quest-editor" data-quest-scroll="editor">';
        if (!editor) html += '<div class="adm-empty">Wybierz quest albo utwórz nowy draft.</div>';
        else {
            var isArchived = editor.status === "archived";
            html += '<div class="adm-quest-editor__head"><div class="adm-grid adm-grid--2"><label class="adm-field"><span>Kod</span><input data-q-code value="' + escapeHtml(editor.code || "") + '" maxlength="64"></label><label class="adm-field"><span>Status</span><input value="' + escapeHtml(editor.status || "draft") + ' · lock v' + (+editor.lockVersion || 0) + '" disabled></label></div><div class="adm-quest-mode"><button class="adm-btn' + (state.questUi.mode === "form" ? " is-active" : "") + '" data-action="quest-mode-form">Formularz</button><button class="adm-btn' + (state.questUi.mode === "json" ? " is-active" : "") + '" data-action="quest-mode-json">JSON</button><span data-quest-dirty class="adm-quest-dirty ' + (state.questUi.dirty ? "is-dirty" : "is-saved") + '">' + (state.questUi.dirty ? "Niezapisane zmiany" : "Zapisano") + '</span></div></div>';
            html += questValidationSummary();
            if (isArchived) html += '<div class="adm-quest-archived"><strong>To jest archiwalna definicja</strong><span>Nie można zmieniać ani ponownie publikować jej pod tym samym ID. Bieżące zmiany możesz zapisać jako nowy, niezależny draft.</span></div>';
            if (state.questUi.mode === "json") html += '<label class="adm-field"><span>Kanoniczna definicja JSON</span><textarea data-q-json data-quest-scroll="json" class="adm-quest-json" spellcheck="false">' + escapeHtml(state.questUi.rawText || JSON.stringify(editor.content || {}, null, 2)) + '</textarea></label>';
            else html += questStructuredEditor(editor);
            var canValidate = !isArchived && +editor.id > 0 && !state.questUi.dirty;
            var canPublish = canValidate && state.questValidation && state.questValidation.valid && state.questUi.validationFingerprint === questFingerprint();
            html += '<div class="adm-toolbar adm-quest-actions">' + (state.questUi.mode === "json" ? '<button class="adm-btn" data-action="quest-format">Formatuj JSON</button>' : '') + '<button class="adm-btn" data-action="quest-validate"' + (canValidate ? "" : " disabled") + '>Waliduj przed publikacją</button><button class="adm-btn adm-btn--primary" data-action="' + (isArchived ? "quest-save-archived-copy" : "quest-save") + '">' + (isArchived ? "Zapisz zmiany jako nowy draft" : "Zapisz draft") + '</button>';
            if (+editor.id > 0 && !isArchived) html += '<button class="adm-btn" data-action="quest-clone">Klonuj</button><button class="adm-btn adm-btn--success" data-action="quest-publish"' + (canPublish ? "" : " disabled") + '>Publikuj</button><button class="adm-btn adm-btn--danger" data-action="quest-archive">Archiwizuj</button>';
            if (+editor.id > 0 && isArchived) html += '<button class="adm-btn adm-btn--danger" data-action="quest-delete">Usuń definicję</button>';
            html += '</div>';
        }
        html += '</section></div>';
        var legacy = state.questLegacyReport || [];
        if (legacy.length) {
            html += '<section class="adm-quest-validation"><strong>Raport legacy</strong>';
            legacy.forEach(function (entry) { html += '<div><code>' + escapeHtml(entry.code || "") + '</code><span>' + escapeHtml(entry.convertible ? ("gotowy do utworzenia draftu · istniejący postęp nie będzie migrowany: " + (+entry.stateCount || 0) + " stanów") : (entry.reasons || []).join(", ")) + '</span>' + (entry.convertible && !entry.mappedDefinitionId ? '<button class="adm-btn" data-action="quest-legacy-convert" data-id="' + (+entry.id || 0) + '">Utwórz draft</button>' : entry.mappedDefinitionId ? '<small>draft #' + (+entry.mappedDefinitionId || 0) + '</small>' : '') + '</div>'; });
            html += '</section>';
        }
        return html + '</div>';
    };

    function questSyncEditor() {
        if (!state.questEditor) return false;
        var code = body.querySelector("[data-q-code]");
        if (code) state.questEditor.code = code.value.trim().toUpperCase();
        if (state.questUi.mode === "json") {
            var raw = body.querySelector("[data-q-json]");
            if (raw) state.questUi.rawText = raw.value;
            try { state.questEditor.content = questNormalizeContent(JSON.parse(state.questUi.rawText || "{}")); }
            catch (e) { setStatus("Nieprawidłowy JSON: " + e.message, "error"); return false; }
        }
        return true;
    }

    questEditorPayload = function () {
        if (!questSyncEditor()) return null;
        return { id: +state.questEditor.id || 0, code: state.questEditor.code, lockVersion: +state.questEditor.lockVersion || 0, content: questCopy(state.questEditor.content), requestId: String(Date.now()) };
    };

    function questGuardDiscard(callback) {
        if (!state.questUi.dirty) { callback(); return; }
        openConfirmModal({ title: "Niezapisane zmiany", message: "Opuszczenie edytora odrzuci niezapisane zmiany questa.", okLabel: "Odrzuć zmiany", danger: true, onConfirm: function () { state.questUi.dirty = false; callback(); } });
    }

    function questEnsureDeliverMarkers(content) {
        var binding = questFindBinding(content, "turn_in") || questFindBinding(content, "giver");
        content.stages.forEach(function (stage) {
            var hasDeliver = stage.objectives.some(function (objective) { return objective.type === "deliver"; });
            if (!hasDeliver || stage.markerBindings.some(function (entry) { return (entry.markerType || "continue") === "continue" && entry.bindingKey; })) return;
            if (binding) stage.markerBindings.push({ bindingKey: binding.key, markerType: "continue" });
        });
    }

    function questDialogDefaultAction(type) {
        if (type === "setFlag") return { type: "setFlag", key: questStableKey("flag"), value: "1" };
        if (type === "event") return { type: "event", eventName: state.questCatalog.eventTypes && state.questCatalog.eventTypes[0] ? state.questCatalog.eventTypes[0] : "" };
        return { type: "deliver", instance: "", amount: 1 };
    }

    function questBlockUnsaved(operation) {
        if (!state.questUi.dirty) return false;
        setStatus("Najpierw zapisz draft, aby " + operation + ".", "error");
        return true;
    }

    handleQuestAction = function (action, el) {
        if (action === "quest-refresh") { questRequestList(); state.questUi.catalogStatus = "loading"; state.questUi.catalogError = ""; state.questUi.catalogRetries = 0; send("questCatalog"); render(true); return; }
        if (action === "quest-page-prev") { state.questList.offset = Math.max(0, state.questList.offset - state.questList.limit); questRequestList(); return; }
        if (action === "quest-page-next") { if (state.questList.offset + state.questList.limit < state.questList.total) state.questList.offset += state.questList.limit; questRequestList(); return; }
        if (action === "quest-legacy-report") { send("questLegacyReport"); return setStatus("Analizowanie danych legacy", ""); }
        if (action === "quest-legacy-convert") {
            var legacyId = +el.dataset.id || 0;
            openConfirmModal({ title: "Konwersja legacy", message: "Zostanie utworzony nieopublikowany draft. Dane legacy pozostaną bez zmian.", okLabel: "Utwórz draft", danger: false, onConfirm: function () { send("questLegacyConvert", { legacyId: legacyId, confirm: true, requestId: String(Date.now()) }); } });
            return;
        }
        if (action === "quest-new") { questGuardDiscard(function () { var fresh = defaultQuestEditor(); questPrepareEditor(fresh, true); state.questSelected = 0; render(true); }); return; }
        if (action === "quest-select") {
            var selectedId = +el.dataset.id || 0;
            if (state.questEditor && +state.questEditor.id === selectedId) return;
            questGuardDiscard(function () { state.questSelected = selectedId; state.questUi.expectedGetId = selectedId; send("questGet", { id: selectedId }); });
            return;
        }
        if (!state.questEditor) return;
        var content = state.questEditor.content;
        if (action === "quest-mode-json") { if (state.questUi.mode !== "json") { state.questUi.rawText = JSON.stringify(content || {}, null, 2); state.questUi.mode = "json"; render(true); } return; }
        if (action === "quest-mode-form") { if (state.questUi.mode === "json" && !questSyncEditor()) return; state.questUi.mode = "form"; render(true); return; }
        if (action === "quest-use-npc") {
            var spawnId = +el.dataset.spawnId || 0;
            var role = el.dataset.role === "turn_in" ? "turn_in" : "giver";
            if (!spawnId) return;
            var binding = questFindBinding(content, role);
            if (!binding) {
                var key = role === "giver" ? "giver" : "turn_in";
                var occupied = content.npcBindings.some(function (entry) { return entry.key === key; });
                if (occupied) key = questStableKey(key);
                binding = { key: key, role: role, refType: "spawn", refValue: String(spawnId), markerOffset: 165 };
                content.npcBindings.push(binding);
            } else {
                binding.refType = "spawn";
                binding.refValue = String(spawnId);
            }
            if (role === "giver" && content.stages.length) {
                var firstStage = content.stages[0];
                if (firstStage.objectives.length === 0) firstStage.objectives.push({ key: questStableKey("objective"), type: "talk", required: 1, visible: true, label: "Porozmawiaj ze zleceniodawcą", config: { refType: "spawn", refValue: String(spawnId) } });
                else firstStage.objectives.forEach(function (objective) { if (objective.type === "talk" && objective.label === "Porozmawiaj ze zleceniodawcą") objective.config = { refType: "spawn", refValue: String(spawnId) }; });
            }
            if (role === "turn_in" && content.stages.length) {
                var turnInStage = null;
                for (var turnInIndex = content.stages.length - 1; turnInIndex >= 0; turnInIndex -= 1) {
                    if (content.stages[turnInIndex].terminal === "success") { turnInStage = content.stages[turnInIndex]; break; }
                }
                (turnInStage || content.stages[content.stages.length - 1]).turnInBindingKey = binding.key;
            }
            questEnsureDeliverMarkers(content);
            questDirty(true);
            render(true);
            return;
        }
        if (action === "quest-retry-catalog") {
            clearTimeout(state.questUi.catalogTimer);
            state.questUi.catalogRetries = 0;
            state.questUi.catalogStatus = "loading";
            state.questUi.catalogError = "";
            send("questCatalog");
            render(true);
            return;
        }
        if (action === "quest-open-picker") {
            var picker = { kind: el.dataset.kind, stage: +el.dataset.stage, objective: +el.dataset.index };
            state.questUi.picker = questPickerOpen(picker.kind, picker.stage, picker.objective) ? null : picker;
            render(true);
            return;
        }
        if (action === "quest-close-picker") { state.questUi.picker = null; render(true); return; }
        if (action === "quest-pick-objective-item" || action === "quest-pick-objective-monster") {
            var pickedObjective = content.stages[+el.dataset.stage].objectives[+el.dataset.index];
            if (!pickedObjective.config) pickedObjective.config = {};
            if (action === "quest-pick-objective-item") pickedObjective.config.instance = el.dataset.instance;
            else { pickedObjective.config.refType = "instance"; pickedObjective.config.refValue = el.dataset.instance; }
            state.questUi.picker = null;
            questEnsureDeliverMarkers(content);
            questDirty(true);
            render(true);
            return;
        }
        if (action === "quest-add-dialog") {
            var dialogMode = el.dataset.mode || "start";
            var dialogBinding = dialogMode === "start" ? questFindBinding(content, "giver") : questFindBinding(content, "turn_in") || questFindBinding(content, "giver");
            if (!dialogBinding) return setStatus("Najpierw wybierz NPC zleceniodawcę albo NPC oddania.", "error");
            var duplicateDialog = content.dialogGraphs.some(function (graph) { return graph.bindingKey === dialogBinding.key && graph.mode === dialogMode; });
            if (duplicateDialog) return setStatus("Ten NPC posiada już dialog dla wybranego momentu questa.", "error");
            var dialogNodeKey = questStableKey("dialog_node");
            var dialogText = dialogMode === "start" ? "Mam dla ciebie zadanie." : dialogMode === "turn_in" ? "Czy wykonałeś zadanie?" : "Jak idzie zadanie?";
            var dialogChoiceText = dialogMode === "start" ? "Podejmuję się." : dialogMode === "turn_in" ? "Tak, zadanie wykonane." : "Kontynuuj.";
            content.dialogGraphs.push({ key: questStableKey("dialog"), bindingKey: dialogBinding.key, mode: dialogMode, startNodeKey: dialogNodeKey, nodes: [{ key: dialogNodeKey, speaker: "npc", text: dialogText, choices: [{ key: questStableKey("choice"), text: dialogChoiceText, target: "", actions: [] }] }] });
            if (dialogMode === "continue") content.stages.forEach(function (stage) {
                if (!stage.markerBindings.some(function (marker) { return marker.bindingKey === dialogBinding.key; })) stage.markerBindings.push({ bindingKey: dialogBinding.key, markerType: "continue" });
            });
            questDirty(true);
            render(true);
            return;
        }
        if (action === "quest-remove-dialog") { content.dialogGraphs.splice(+el.dataset.index, 1); questDirty(true); render(true); return; }
        if (action === "quest-add-dialog-node") {
            var dialogGraph = content.dialogGraphs[+el.dataset.graph];
            var newNodeKey = questStableKey("dialog_node");
            if (dialogGraph.nodes.length) {
                var previousNode = dialogGraph.nodes[dialogGraph.nodes.length - 1];
                var finalChoice = previousNode.choices.filter(function (choice) { return !choice.target; })[0];
                if (finalChoice) finalChoice.target = newNodeKey;
            }
            dialogGraph.nodes.push({ key: newNodeKey, speaker: "npc", text: "Nowa wypowiedź", choices: [{ key: questStableKey("choice"), text: "Kontynuuj", target: "", actions: [] }] });
            if (!dialogGraph.startNodeKey) dialogGraph.startNodeKey = newNodeKey;
            questDirty(true);
            render(true);
            return;
        }
        if (action === "quest-remove-dialog-node") {
            var removeGraph = content.dialogGraphs[+el.dataset.graph];
            var removedNode = removeGraph.nodes.splice(+el.dataset.index, 1)[0];
            removeGraph.nodes.forEach(function (node) { node.choices.forEach(function (choice) { if (choice.target === removedNode.key) choice.target = ""; }); });
            if (removeGraph.startNodeKey === removedNode.key) removeGraph.startNodeKey = removeGraph.nodes[0] ? removeGraph.nodes[0].key : "";
            questDirty(true);
            render(true);
            return;
        }
        if (action === "quest-add-dialog-choice") {
            content.dialogGraphs[+el.dataset.graph].nodes[+el.dataset.node].choices.push({ key: questStableKey("choice"), text: "Nowa odpowiedź", target: "", actions: [] });
            questDirty(true);
            render(true);
            return;
        }
        if (action === "quest-remove-dialog-choice") { content.dialogGraphs[+el.dataset.graph].nodes[+el.dataset.node].choices.splice(+el.dataset.index, 1); questDirty(true); render(true); return; }
        if (action === "quest-add-dialog-action") { content.dialogGraphs[+el.dataset.graph].nodes[+el.dataset.node].choices[+el.dataset.choice].actions.push(questDialogDefaultAction("deliver")); questDirty(true); render(true); return; }
        if (action === "quest-remove-dialog-action") { content.dialogGraphs[+el.dataset.graph].nodes[+el.dataset.node].choices[+el.dataset.choice].actions.splice(+el.dataset.index, 1); questDirty(true); render(true); return; }
        if (action === "quest-add-binding") { var bindingRefType = (state.questCatalog.npcRefTypes || ["spawn"])[0] || "spawn"; var bindingReferences = questNpcReferences(bindingRefType, ""); content.npcBindings.push({ key: questStableKey("npc"), role: "giver", refType: bindingRefType, refValue: bindingReferences.length ? bindingReferences[0].value : "", markerOffset: 165 }); questDirty(true); render(true); return; }
        if (action === "quest-remove-binding") {
            var removedBinding = content.npcBindings.splice(+el.dataset.index, 1)[0];
            if (removedBinding) {
                content.dialogGraphs = content.dialogGraphs.filter(function (graph) { return graph.bindingKey !== removedBinding.key; });
                content.stages.forEach(function (stage) {
                    if (stage.turnInBindingKey === removedBinding.key) stage.turnInBindingKey = "";
                    stage.markerBindings = stage.markerBindings.filter(function (marker) { return marker.bindingKey !== removedBinding.key; });
                });
            }
            questDirty(true);
            render(true);
            return;
        }
        if (action === "quest-add-stage") { var stageKey = questStableKey("stage"); content.stages.push({ key: stageKey, title: "Nowy etap", type: "objectives", objectiveMode: "all", objectives: [], transitions: [], markerBindings: [], terminal: "success" }); if (!content.startStageKey) content.startStageKey = stageKey; questDirty(true); render(true); return; }
        if (action === "quest-remove-stage") { if (content.stages.length <= 1) return setStatus("Quest musi posiadać co najmniej jeden etap.", "error"); var stageIndex = +el.dataset.index; var removed = content.stages[stageIndex].key; content.stages.splice(stageIndex, 1); if (content.startStageKey === removed) content.startStageKey = content.stages[0].key; questDirty(true); render(true); return; }
        if (action === "quest-move-stage") { var from = +el.dataset.index; var to = from + (+el.dataset.dir || 0); if (to >= 0 && to < content.stages.length) { var moved = content.stages.splice(from, 1)[0]; content.stages.splice(to, 0, moved); questDirty(true); render(true); } return; }
        if (action === "quest-add-objective" || action === "quest-add-objective-type") {
            var objectiveStageIndex = +el.dataset.stage;
            var objectiveStage = content.stages[objectiveStageIndex];
            var objectiveType = el.dataset.type || (state.questCatalog.objectiveTypes || ["talk"])[0] || "talk";
            objectiveStage.objectives.push({ key: questStableKey("objective"), type: objectiveType, required: 1, visible: true, label: questObjectiveLabel(objectiveType), config: questDefaultObjectiveConfig(objectiveType) });
            questEnsureDeliverMarkers(content);
            state.questUi.picker = objectiveType === "kill" ? { kind: "monster", stage: objectiveStageIndex, objective: objectiveStage.objectives.length - 1 } : (objectiveType === "collect" || objectiveType === "deliver" ? { kind: "item", stage: objectiveStageIndex, objective: objectiveStage.objectives.length - 1 } : null);
            questDirty(true);
            render(true);
            return;
        }
        if (action === "quest-remove-objective") { content.stages[+el.dataset.stage].objectives.splice(+el.dataset.index, 1); questDirty(true); render(true); return; }
        if (action === "quest-add-transition") { var transitionStage = content.stages[+el.dataset.stage]; transitionStage.transitions.push({ key: questStableKey("transition"), target: content.stages[0] ? content.stages[0].key : "" }); transitionStage.terminal = ""; questDirty(true); render(true); return; }
        if (action === "quest-remove-transition") { content.stages[+el.dataset.stage].transitions.splice(+el.dataset.index, 1); questDirty(true); render(true); return; }
        if (action === "quest-add-marker") {
            if (!content.npcBindings.length) return setStatus("Najpierw przypisz NPC, a dopiero potem dodaj marker.", "error");
            content.stages[+el.dataset.stage].markerBindings.push({ bindingKey: content.npcBindings[0].key, markerType: "continue" });
            questDirty(true);
            render(true);
            return;
        }
        if (action === "quest-remove-marker") { content.stages[+el.dataset.stage].markerBindings.splice(+el.dataset.index, 1); questDirty(true); render(true); return; }
        if (action === "quest-add-reward") { var rewardType = (state.questCatalog.rewardTypes || ["experience"])[0] || "experience"; content.rewards.push(questDefaultReward(rewardType)); questDirty(true); render(true); return; }
        if (action === "quest-remove-reward") { content.rewards.splice(+el.dataset.index, 1); questDirty(true); render(true); return; }
        if (action === "quest-format") { if (questSyncEditor()) { state.questUi.rawText = JSON.stringify(state.questEditor.content, null, 2); render(true); } return; }
        if (action === "quest-delete") {
            if (state.questEditor.status !== "archived" || +state.questEditor.id <= 0) return setStatus("Usunąć można wyłącznie zapisaną, zarchiwizowaną definicję.", "error");
            if (questBlockUnsaved("usunąć definicję")) return;
            openConfirmModal({
                title: "Nieodwracalne usunięcie questa",
                message: "Usunąć definicję „" + (content.metadata.title || state.questEditor.code) + "”? Operacja zostanie zablokowana, jeśli jakakolwiek postać posiada historię tego questa albo istnieje mapowanie legacy.",
                okLabel: "Usuń definicję",
                danger: true,
                onConfirm: function () {
                    send("questDelete", { id: +state.questEditor.id, lockVersion: +state.questEditor.lockVersion, confirm: true, requestId: String(Date.now()) });
                    setStatus("Usuwanie definicji questa", "");
                }
            });
            return;
        }
        if (action === "quest-save-archived-copy") {
            if (state.questEditor.status !== "archived" || !questSyncEditor()) return;
            var archivedBaseCode = String(state.questEditor.code || "QUEST").replace(/_COPY_[0-9]+$/, "").slice(0, 52);
            state.questEditor.id = 0;
            state.questEditor.lockVersion = 0;
            state.questEditor.status = "draft";
            state.questEditor.code = archivedBaseCode + "_COPY_" + String(Date.now()).slice(-6);
            state.questSelected = 0;
            state.questValidation = null;
            state.questUi.validationFingerprint = "";
            state.questUi.dirty = true;
            var archivedCopyPayload = { id: 0, code: state.questEditor.code, lockVersion: 0, content: questCopy(state.questEditor.content), requestId: String(Date.now()) };
            state.questUi.submitted = questFingerprint();
            send("questSave", archivedCopyPayload);
            render(true);
            return setStatus("Zapisywanie bieżących zmian jako nowego draftu", "");
        }
        if (action === "quest-clone") { if (questBlockUnsaved("sklonować questa")) return; var cloneCode = (state.questEditor.code || "QUEST").slice(0, 52) + "_COPY_" + String(Date.now()).slice(-6); send("questClone", { sourceId: +state.questEditor.id, code: cloneCode, requestId: String(Date.now()) }); return setStatus("Klonowanie questa", ""); }
        if (action === "quest-publish") {
            if (questBlockUnsaved("opublikować rewizję")) return;
            if (!state.questValidation || !state.questValidation.valid || state.questUi.validationFingerprint !== questFingerprint()) return setStatus("Najpierw wykonaj pełną walidację publikacyjną.", "error");
            openConfirmModal({
                title: "Publikacja questa",
                message: "Opublikować „" + (content.metadata.title || state.questEditor.code) + "”? Gracze będą mogli rozpocząć tę niezmienną rewizję.",
                okLabel: "Publikuj",
                danger: false,
                onConfirm: function () {
                    send("questPublish", { id: +state.questEditor.id, lockVersion: +state.questEditor.lockVersion, requestId: String(Date.now()) });
                    setStatus("Publikowanie rewizji", "");
                }
            });
            return;
        }
        if (action === "quest-archive") { if (questBlockUnsaved("zarchiwizować questa")) return; openConfirmModal({ title: "Archiwizacja questa", message: "Quest przestanie być dostępny do rozpoczęcia. Aktywne stany postaci zachowają opublikowaną rewizję.", okLabel: "Archiwizuj", danger: true, onConfirm: function () { send("questArchive", { id: +state.questEditor.id, lockVersion: +state.questEditor.lockVersion, requestId: String(Date.now()), confirm: true }); setStatus("Archiwizowanie questa", ""); } }); return; }
        var payload = questEditorPayload();
        if (!payload) return;
        if (action === "quest-validate") {
            if (questBlockUnsaved("zweryfikować publikację")) return;
            payload.publishing = true;
            state.questUi.submitted = questFingerprint();
            send("questValidate", payload);
            return setStatus("Sprawdzanie definicji, NPC i zasobów", "");
        }
        if (action === "quest-save") { state.questUi.submitted = questFingerprint(); send("questSave", payload); return setStatus("Zapisywanie draftu", ""); }
    };

    function questBindValue(selector, callback) {
        body.querySelectorAll(selector).forEach(function (element) {
            var eventName = element.type === "checkbox" || element.tagName === "SELECT" || element.type === "number" ? "change" : "input";
            element.addEventListener(eventName, function () { callback(element); questDirty(); });
        });
    }

    function bindQuestMakerHandlers() {
        var filter = body.querySelector("[data-quest-list-filter]");
        if (filter) filter.addEventListener("input", function () { state.questList.filter = filter.value; state.questList.offset = 0; clearTimeout(state.questUi.filterTimer); state.questUi.filterTimer = setTimeout(questRequestList, 250); });
        var status = body.querySelector("[data-quest-list-status]");
        if (status) status.addEventListener("change", function () { state.questList.status = status.value; state.questList.offset = 0; questRequestList(); });
        if (!state.questEditor) return;
        var npcFilter = body.querySelector("[data-quest-npc-filter]");
        if (npcFilter) npcFilter.addEventListener("input", function () {
            state.questUi.npcFilter = npcFilter.value;
            var needle = npcFilter.value.trim().toLowerCase();
            var visible = 0;
            body.querySelectorAll("[data-quest-npc-card]").forEach(function (card) {
                var match = !needle || String(card.dataset.search || "").indexOf(needle) >= 0;
                card.hidden = !match;
                if (match) visible += 1;
            });
            var count = body.querySelector("[data-quest-npc-count]");
            if (count) count.textContent = visible + " / " + (state.questCatalog.npcs || []).length + " NPC";
        });
        var pickerFilter = body.querySelector("[data-quest-objective-picker-filter]");
        if (pickerFilter) pickerFilter.addEventListener("input", function () {
            if (pickerFilter.dataset.kind === "monster") state.questUi.monsterFilter = pickerFilter.value;
            else state.questUi.itemFilter = pickerFilter.value;
            clearTimeout(state.questUi.pickerTimer);
            state.questUi.pickerTimer = setTimeout(function () { render(true); }, 220);
        });
        questBindValue("[data-q-code]", function (element) { state.questEditor.code = element.value.trim().toUpperCase(); });
        questBindValue("[data-q-meta]", function (element) { state.questEditor.content.metadata[element.dataset.qMeta] = element.value; });
        questBindValue("[data-q-root]", function (element) { state.questEditor.content[element.dataset.qRoot] = element.value; });
        questBindValue("[data-q-availability]", function (element) {
            var availability = questSimpleAvailability(state.questEditor.content.availability);
            if (availability.advanced) return;
            var field = element.dataset.qAvailability;
            if (field === "levelEnabled" || field === "questEnabled") availability[field] = element.checked;
            else if (field === "level") availability.level = Math.max(1, Math.floor(Number(element.value) || 1));
            else if (field === "questCode") availability.questCode = element.value.trim().toUpperCase();
            state.questEditor.content.availability = questBuildAvailability(availability);
            if (field === "levelEnabled" || field === "questEnabled") render(true);
        });
        questBindValue("[data-q-acknowledge-warnings]", function (element) { if (element.checked) state.questEditor.content.acknowledgeWarnings = true; else delete state.questEditor.content.acknowledgeWarnings; });
        questBindValue("[data-q-binding]", function (element) { var binding = state.questEditor.content.npcBindings[+element.dataset.qBinding]; var field = element.dataset.field; binding[field] = field === "markerOffset" ? (+element.value || 0) : element.value; if (field === "refType") { var references = questNpcReferences(element.value, ""); binding.refValue = references.length ? references[0].value : ""; render(true); } });
        questBindValue("[data-q-stage]", function (element) {
            var stage = state.questEditor.content.stages[+element.dataset.qStage];
            var field = element.dataset.field;
            stage[field] = element.type === "checkbox" ? element.checked : element.value;
            if (field === "terminal" && element.value) {
                stage.transitions = [];
                render(true);
            }
            if (field === "turnInBindingKey") questEnsureDeliverMarkers(state.questEditor.content);
        });
        questBindValue("[data-q-objective]", function (element) {
            var parts = element.dataset.qObjective.split(":");
            var stageIndex = +parts[0];
            var objectiveIndex = +parts[1];
            var objective = state.questEditor.content.stages[stageIndex].objectives[objectiveIndex];
            var field = element.dataset.field;
            objective[field] = element.type === "checkbox" ? element.checked : field === "required" ? Math.max(1, +element.value || 1) : element.value;
            if (field === "type") {
                objective.config = questDefaultObjectiveConfig(element.value);
                questEnsureDeliverMarkers(state.questEditor.content);
                state.questUi.picker = element.value === "kill" ? { kind: "monster", stage: stageIndex, objective: objectiveIndex } : (element.value === "collect" || element.value === "deliver" ? { kind: "item", stage: stageIndex, objective: objectiveIndex } : null);
                render(true);
            }
        });
        questBindValue("[data-q-objective-config]", function (element) {
            var parts = element.dataset.qObjectiveConfig.split(":");
            var objective = state.questEditor.content.stages[+parts[0]].objectives[+parts[1]];
            if (!objective.config) objective.config = {};
            var field = element.dataset.field;
            var previousReference = questObjectiveReference(objective.config);
            objective.config[field] = ["x", "y", "z", "radius"].indexOf(field) >= 0 ? Number(element.value) : element.value;
            if (field === "refValue" && !objective.config.refType) objective.config.refType = previousReference.refType || "spawn";
            if (field === "refType") {
                objective.config.refValue = "";
                render(true);
                return;
            }
            if (element.tagName === "SELECT" || element.type === "number") render(true);
        });
        questBindValue("[data-q-deliver-binding]", function (element) {
            var stage = state.questEditor.content.stages[+element.dataset.qDeliverBinding];
            var current = -1;
            for (var i = 0; i < stage.markerBindings.length; i += 1) if ((stage.markerBindings[i].markerType || "continue") === "continue") { current = i; break; }
            if (!element.value) {
                if (current >= 0) stage.markerBindings.splice(current, 1);
                render(true);
                return;
            }
            if (current >= 0) stage.markerBindings[current].bindingKey = element.value;
            else stage.markerBindings.push({ bindingKey: element.value, markerType: "continue" });
            render(true);
        });
        questBindValue("[data-q-dialog-graph]", function (element) { state.questEditor.content.dialogGraphs[+element.dataset.qDialogGraph][element.dataset.field] = element.value; });
        questBindValue("[data-q-dialog-node]", function (element) { var parts = element.dataset.qDialogNode.split(":"); state.questEditor.content.dialogGraphs[+parts[0]].nodes[+parts[1]][element.dataset.field] = element.value; });
        questBindValue("[data-q-dialog-choice]", function (element) { var parts = element.dataset.qDialogChoice.split(":"); var choice = state.questEditor.content.dialogGraphs[+parts[0]].nodes[+parts[1]].choices[+parts[2]]; choice[element.dataset.field] = element.value; });
        questBindValue("[data-q-dialog-action]", function (element) {
            var parts = element.dataset.qDialogAction.split(":");
            var choice = state.questEditor.content.dialogGraphs[+parts[0]].nodes[+parts[1]].choices[+parts[2]];
            var actionIndex = +parts[3];
            var field = element.dataset.field;
            if (field === "type") { choice.actions[actionIndex] = questDialogDefaultAction(element.value); render(true); return; }
            choice.actions[actionIndex][field] = field === "amount" ? Math.max(1, +element.value || 1) : element.value;
        });
        questBindValue("[data-q-transition]", function (element) { var parts = element.dataset.qTransition.split(":"); state.questEditor.content.stages[+parts[0]].transitions[+parts[1]][element.dataset.field] = element.value; });
        questBindValue("[data-q-marker]", function (element) { var parts = element.dataset.qMarker.split(":"); state.questEditor.content.stages[+parts[0]].markerBindings[+parts[1]][element.dataset.field] = element.value; });
        questBindValue("[data-q-reward-choice]", function (element) {
            var reward = state.questEditor.content.rewards[+element.dataset.qRewardChoice];
            if (element.checked) {
                reward.choiceGroup = questRewardChoiceGroup();
                if (!reward.label) reward.label = questRewardLabel(reward.type || "experience");
            } else {
                delete reward.choiceGroup;
                delete reward.label;
            }
            render(true);
        });
        questBindValue("[data-q-reward]", function (element) { var reward = state.questEditor.content.rewards[+element.dataset.qReward]; var field = element.dataset.field; var value = field === "amount" ? Math.max(1, +element.value || 1) : element.value; if (value === "" && (field === "choiceGroup" || field === "label")) delete reward[field]; else reward[field] = value; if (field === "type") { var key = reward.key; var choiceGroup = reward.choiceGroup; var label = reward.label; var replacement = questDefaultReward(value); replacement.key = key; if (choiceGroup) { replacement.choiceGroup = choiceGroup; replacement.label = label || questRewardLabel(value); } state.questEditor.content.rewards[+element.dataset.qReward] = replacement; render(true); } });
        var raw = body.querySelector("[data-q-json]");
        if (raw) raw.addEventListener("input", function () { state.questUi.rawText = raw.value; questDirty(); });
    }

    close = function () {
        if (state.questUi.dirty && activeTab === "quests") { questGuardDiscard(function () { questBaseClose(); }); return; }
        questBaseClose();
    };

    bindHandlers = function () {
        questBaseBindHandlers();
        if (activeTab === "quests") bindQuestMakerHandlers();
    };

    onResponse = function (p) {
        if (!p || !p.action || p.action.indexOf("quest") !== 0) return questBaseResponse(p);
        var pl = p.payload || {};
        if (p.action === "questList" && p.success) { state.questDefinitions = pl.entries || []; state.questList.total = +pl.total || 0; state.questList.offset = +pl.offset || 0; state.questList.limit = +pl.limit || state.questList.limit; return render(true); }
        if (p.action === "questCatalog") {
            clearTimeout(state.questUi.catalogTimer);
            if (p.success) {
                state.questCatalog = pl;
                state.questUi.catalogStatus = "ready";
                state.questUi.catalogError = "";
                state.questUi.catalogRetries = 0;
                return render(true);
            }
            state.questUi.catalogRetries += 1;
            if (p.error === "npcCatalogNotReady" && state.questUi.catalogRetries <= 8) {
                state.questUi.catalogStatus = "loading";
                state.questUi.catalogTimer = setTimeout(function () { send("questCatalog"); }, +pl.retryAfter || 1000);
            } else {
                state.questUi.catalogStatus = "error";
                state.questUi.catalogError = p.error === "npcCatalogNotReady" ? "Serwer nie zakończył przygotowania tabeli NPC." : "Błąd serwera: " + (p.error || "unknown");
            }
            return render(true);
        }
        if (p.action === "questLegacyReport" && p.success) { state.questLegacyReport = pl.entries || []; setStatus("Raport legacy gotowy", "ok"); return render(true); }
        if (p.action === "questLegacyConvert" && p.success) { send("questLegacyReport"); questRequestList(); if (+pl.id > 0) { state.questUi.expectedGetId = +pl.id; send("questGet", { id: +pl.id }); } return setStatus(pl.alreadyConverted ? "Quest był już przekonwertowany" : "Utworzono draft z danych legacy", "ok"); }
        if (p.action === "questGet" && p.success) {
            if (state.questUi.expectedGetId && +pl.id !== +state.questUi.expectedGetId) return;
            state.questUi.expectedGetId = 0;
            questPrepareEditor({ id: +pl.id || 0, code: pl.code || "", status: pl.status || "draft", lockVersion: +pl.lockVersion || 0, content: pl.draftContent || pl.publishedContent || {} }, false);
            state.questSelected = state.questEditor.id;
            return render(true);
        }
        if (p.action === "questValidate") {
            state.questValidation = pl;
            state.questUi.validationFingerprint = p.success && state.questUi.submitted === questFingerprint() ? state.questUi.submitted : "";
            state.questUi.submitted = "";
            setStatus(p.success ? "Definicja jest gotowa do publikacji" : "Definicja wymaga poprawy", p.success ? "ok" : "error");
            return render(true);
        }
        if (p.action === "questSave" && p.success) {
            if (!state.questEditor) return;
            state.questEditor.id = +pl.id || state.questEditor.id;
            state.questEditor.lockVersion = +pl.lockVersion || state.questEditor.lockVersion;
            state.questSelected = state.questEditor.id;
            state.questValidation = pl.validation || null;
            state.questUi.validationFingerprint = "";
            if (questFingerprint() === state.questUi.submitted) { state.questUi.baseline = state.questUi.submitted; state.questUi.dirty = false; }
            state.questUi.submitted = "";
            questRequestList();
            var blockers = state.questValidation && state.questValidation.errors ? state.questValidation.errors.length : 0;
            var saveMessage = state.questUi.dirty ? "Draft zapisany; w edytorze są nowsze zmiany" : blockers ? "Draft zapisany, ale wymaga uzupełnienia (" + blockers + ")" : "Draft zapisany";
            setStatus(saveMessage, blockers ? "" : "ok");
            return render(true);
        }
        if (p.action === "questClone" && p.success) { state.questSelected = +pl.id || 0; questRequestList(); if (state.questSelected) { state.questUi.expectedGetId = state.questSelected; send("questGet", { id: state.questSelected }); } return setStatus("Quest sklonowany", "ok"); }
        if ((p.action === "questPublish" || p.action === "questArchive") && p.success) { if (state.questEditor) { state.questEditor.lockVersion = +pl.lockVersion || state.questEditor.lockVersion; state.questEditor.status = p.action === "questPublish" ? "published" : "archived"; state.questUi.baseline = questFingerprint(); state.questUi.dirty = false; } questRequestList(); if (state.questEditor && state.questEditor.id) { state.questUi.expectedGetId = state.questEditor.id; send("questGet", { id: state.questEditor.id }); } return setStatus(p.action === "questPublish" ? "Quest opublikowany" : "Quest zarchiwizowany", "ok"); }
        if (p.action === "questDelete" && p.success) {
            state.questEditor = null;
            state.questSelected = 0;
            state.questValidation = null;
            state.questUi.baseline = "";
            state.questUi.dirty = false;
            state.questUi.submitted = "";
            state.questUi.validationFingerprint = "";
            questRequestList();
            setStatus("Definicja questa została usunięta", "ok");
            return render(true);
        }
        if (!p.success) {
            if (pl && (pl.errors || pl.warnings)) state.questValidation = pl;
            state.questUi.validationFingerprint = "";
            state.questUi.submitted = "";
            var errorMessage = p.error === "STALE_VERSION" ? "Konflikt wersji: inny administrator zmienił ten draft. Odśwież quest przed ponownym zapisem." : p.error === "ARCHIVED" ? "Ta definicja jest zarchiwizowana. Zapisz bieżące zmiany jako nowy draft." : p.error === "QUEST_IN_USE" ? "Nie można usunąć definicji: istnieje postęp lub historia postaci. Zachowaj zarchiwizowaną definicję." : p.error === "LEGACY_MAPPED" ? "Nie można usunąć definicji: jest powiązana z migracją legacy." : p.error === "NOT_ARCHIVED" ? "Najpierw zarchiwizuj quest, a dopiero potem usuń definicję." : "Operacja questa nie powiodła się: " + (p.error || "unknown");
            setStatus(errorMessage, "error");
            return render(true);
        }
    };

    document.addEventListener("click", function (event) {
        if (questDiscardBypass) { questDiscardBypass = false; return; }
        if (!state.questUi.dirty || activeTab !== "quests") return;
        var target = event.target.closest(".phoenix-adminpanel__close, .phoenix-adminpanel__tab");
        if (!target || target.classList.contains("is-active")) return;
        event.preventDefault();
        event.stopImmediatePropagation();
        questGuardDiscard(function () { questDiscardBypass = true; target.click(); });
    }, true);
    global.addEventListener("beforeunload", function (event) { if (!state.questUi.dirty) return; event.preventDefault(); event.returnValue = ""; });

    bridge.on("phoenix:admin:response", onResponse);
    bridge.on("phoenix:account:identity", function (p) {
        isAdmin = !!(p && p.isAdmin);
        var btn = document.getElementById("escmenu-admin");
        if (btn) {
            if (isAdmin) btn.removeAttribute("hidden");
            else btn.setAttribute("hidden", "");
        }
    });

    function renderCraft() {
        if (!state.schemes || state.schemes.length === 0) send("schemes");
        if (state.craftView === "editor") return renderCraftEditor();
        return renderCraftList();
    }

    function renderCraftList() {
        var list = state.craftRecipes || [];
        var q = (state.craftFilter || "").toLowerCase();
        var filtered = q ? list.filter(function (r) {
            return String(r.name || "").toLowerCase().indexOf(q) !== -1 ||
                String(r.resultInstance || "").toLowerCase().indexOf(q) !== -1;
        }) : list;
        var html = '<div class="adm-section">';
        html += '<div class="adm-toolbar">';
        html += '<input class="adm-input" type="search" placeholder="Szukaj receptury..." data-craft-filter value="' + escapeHtml(state.craftFilter || "") + '">';
        html += '<button class="adm-btn adm-btn--primary" data-action="craft-new">+ Nowa receptura</button>';
        html += '</div>';
        html += '<div class="adm-craft-list" data-role="itemgrid">';
        if (filtered.length === 0) {
            html += '<div class="adm-empty">Brak receptur. Dodaj nową.</div>';
        } else {
            filtered.forEach(function (r) {
                var ings = r.ingredients || [];
                var ingCount = ings.filter(function (i) { return i.role !== "tool"; }).length;
                var toolCount = ings.filter(function (i) { return i.role === "tool"; }).length;
                var outsCount = (r.outputs || []).length;
                var instanceUp = String(r.resultInstance || "").toUpperCase();
                var scheme = instanceUp ? state.schemesById[instanceUp] : null;
                var displayName = r.name && r.name !== r.resultInstance ? r.name : (scheme ? itemName(scheme) : instanceUp);
                if (!displayName) displayName = instanceUp || "?";
                var cardVisual = (scheme && scheme.visual) ? scheme.visual : (instanceUp + ".3DS");
                html += '<div class="adm-craft-card">';
                html += '<div class="adm-craft-card__visual adm-itemcell" data-instance="' + escapeHtml(instanceUp) + '" data-visual="' + escapeHtml(cardVisual) + '">';
                html += '<div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(displayName.slice(0, 14)) + '</span></div>';
                html += '</div>';
                html += '<div class="adm-craft-card__body">';
                html += '<h4>' + escapeHtml(displayName) + '</h4>';
                html += '<small>' + escapeHtml(instanceUp) + (r.resultAmount > 1 ? " x" + r.resultAmount : "") + ' · ' + escapeHtml(r.category || "") + '</small>';
                html += '<div class="adm-craft-card__meta">' + ingCount + ' skł. · ' + toolCount + ' narz. · ' + outsCount + ' dod. · ' + (+r.craftTimeMs || 0) + 'ms</div>';
                html += '</div>';
                html += '<div class="adm-craft-card__actions">';
                html += '<button class="adm-btn" data-action="craft-edit" data-id="' + (+r.id || 0) + '">Edytuj</button>';
                html += '<button class="adm-btn adm-btn--danger" data-action="craft-delete" data-id="' + (+r.id || 0) + '">Usuń</button>';
                html += '</div>';
                html += '</div>';
            });
        }
        html += '</div>';
        html += '</div>';
        return html;
    }

    function resolveSchemes() {
        return (state.schemes || []).filter(function (s) { return s && s.instance; });
    }

    function renderCraftEditor() {
        var ed = state.craftEditor || defaultCraftEditor();
        var html = '<div class="adm-section">';
        html += '<div class="adm-toolbar">';
        html += '<button class="adm-btn" data-action="craft-back">← Powrót</button>';
        html += '<span class="adm-craft-title">' + (ed.id > 0 ? "Edycja receptury #" + ed.id : "Nowa receptura") + '</span>';
        html += '</div>';

        html += '<div class="adm-craft-editor">';
        html += '<div class="adm-craft-editor__left">';
        if (ed.resultInstance) {
            var resultScheme = state.schemesById[ed.resultInstance];
            var resultLabel = resultScheme ? itemName(resultScheme) : ed.resultInstance;
            var resultVisual = (resultScheme && resultScheme.visual) ? resultScheme.visual : (ed.resultInstance + ".3DS");
            html += '<div class="adm-craft-preview adm-itemcell" data-instance="' + escapeHtml(ed.resultInstance) + '" data-visual="' + escapeHtml(resultVisual) + '">';
            html += '<div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(resultLabel.slice(0, 18)) + '</span></div>';
            html += '</div>';
            html += '<div class="adm-craft-preview__label"><strong>' + escapeHtml(resultLabel) + '</strong><small>' + escapeHtml(ed.resultInstance) + '</small></div>';
        } else {
            html += '<div class="adm-craft-preview adm-craft-preview--empty">Wybierz przedmiot</div>';
        }
        html += '<button class="adm-btn adm-btn--ghost" data-action="craft-pick-open" data-role="result">' + (ed.resultInstance ? "Zmień przedmiot" : "Wybierz przedmiot") + '</button>';
        html += '</div>';

        html += '<div class="adm-craft-editor__right">';
        html += '<div class="adm-grid adm-grid--2">';
        html += '<label>Nazwa <input class="adm-input" data-craft-f="name" value="' + escapeHtml(ed.name || "") + '" placeholder="np. Zwykły miecz"></label>';
        html += '<label>Kategoria <select class="adm-input" data-craft-f="category">' +
            ["misc", "weapon", "armor", "food", "potion", "alchemy", "smithing"].map(function (c) {
                return '<option value="' + c + '"' + (ed.category === c ? " selected" : "") + '>' + c + '</option>';
            }).join("") + '</select></label>';
        html += '</div>';
        html += '<div class="adm-grid adm-grid--3">';
        html += '<label>Ilość <input class="adm-input" type="number" min="1" data-craft-f="resultAmount" value="' + (ed.resultAmount || 1) + '"></label>';
        html += '<label>Czas (ms) <input class="adm-input" type="number" min="100" step="100" data-craft-f="craftTimeMs" value="' + (ed.craftTimeMs || 1500) + '"></label>';
        html += '<label>Wymagany lv <input class="adm-input" type="number" min="0" data-craft-f="requiredLevel" value="' + (ed.requiredLevel || 0) + '"></label>';
        html += '</div>';
        html += '<label>Opis <textarea class="adm-input" data-craft-f="description" rows="2">' + escapeHtml(ed.description || "") + '</textarea></label>';
        html += '</div>';
        html += '</div>';

        html += '<h4 class="adm-craft-section-title">Składniki (zużywane)</h4>';
        html += renderCraftIngredients(ed, "consume");
        html += '<button class="adm-btn" data-action="craft-pick-open" data-role="consume">+ Dodaj składnik</button>';

        html += '<h4 class="adm-craft-section-title">Narzędzia (wymagane, nie zużywane)</h4>';
        html += renderCraftIngredients(ed, "tool");
        html += '<button class="adm-btn" data-action="craft-pick-open" data-role="tool">+ Dodaj narzędzie</button>';

        html += '<h4 class="adm-craft-section-title">Dodatkowe produkty (bonusowe itemy obok głównego)</h4>';
        html += renderCraftOutputs(ed);
        html += '<button class="adm-btn" data-action="craft-pick-open" data-role="output">+ Dodaj dodatkowy produkt</button>';

        html += '<h4 class="adm-craft-section-title">Stacje / VOB-y otwierające tę recepturę</h4>';
        html += renderCraftEditorVobsSummary(ed);

        html += '<div class="adm-toolbar adm-craft-actions">';
        html += '<button class="adm-btn adm-btn--primary" data-action="craft-save">Zapisz recepturę</button>';
        html += '</div>';
        html += '</div>';

        if (state.craftPicker) {
            html += renderCraftPickerModal(state.craftPicker);
        }
        if (state.craftVobPickerOpen) {
            html += renderCraftVobPickerModal();
        }
        return html;
    }

    function renderCraftEditorVobsSummary(ed) {
        var picked = (ed.visuals || []).map(function (v) { return String(v).toUpperCase(); });
        var html = '<div class="adm-craft-vob-summary">';
        if (picked.length === 0) {
            html += '<div class="adm-empty">Brak przypisań. Dodaj typ VOB-a aby receptura była dostępna.</div>';
        } else {
            html += '<div class="adm-craft-vob-picked">';
            picked.forEach(function (v) {
                html += '<span class="adm-craft-vob-chip">' + escapeHtml(v) + ' <button class="adm-craft-vob-chip__x" data-action="craft-vob-remove" data-visual="' + escapeHtml(v) + '">×</button></span>';
            });
            html += '</div>';
        }
        html += '<button class="adm-btn adm-btn--ghost" data-action="craft-vob-picker-open">+ Wybierz typ VOB-a</button>';
        html += '</div>';
        return html;
    }

    function renderCraftPickerModal(mode) {
        var schemes = resolveSchemes();
        var filter = (state.craftPickerFilter || "").toLowerCase();
        var catFilter = +state.craftPickerCat || 0;
        var filtered = schemes.filter(function (s) {
            if (catFilter > 0 && (+s.category || 0) !== catFilter) return false;
            if (!filter) return true;
            var nm = itemName(s).toLowerCase();
            if (nm.indexOf(filter) !== -1) return true;
            if (String(s.instance || "").toLowerCase().indexOf(filter) !== -1) return true;
            return false;
        });
        var title = mode === "result" ? "Wybierz przedmiot wynikowy" : (mode === "tool" ? "Wybierz narzędzie" : "Wybierz składnik");

        var html = '<div class="adm-craft-modal" data-craft-modal-bg>';
        html += '<div class="adm-craft-modal__panel" data-craft-modal>';
        html += '<header class="adm-craft-modal__head"><h3>' + escapeHtml(title) + '</h3>';
        html += '<button class="adm-btn" data-action="craft-pick-close">✕</button></header>';
        html += '<div class="adm-craft-modal__tools">';
        html += '<input class="adm-input" type="search" placeholder="Szukaj..." data-craft-picker-filter value="' + escapeHtml(state.craftPickerFilter || "") + '">';
        html += '<select class="adm-input" data-craft-picker-cat>';
        html += '<option value="0">Wszystkie kategorie</option>';
        Object.keys(CATEGORY_LABELS).forEach(function (k) {
            var kk = +k;
            if (kk === 0) return;
            html += '<option value="' + kk + '"' + (catFilter === kk ? " selected" : "") + '>' + escapeHtml(CATEGORY_LABELS[k]) + '</option>';
        });
        html += '</select>';
        html += '</div>';
        html += '<div class="adm-craft-modal__body"><div class="adm-itemgrid" data-role="itemgrid">';
        filtered.slice(0, 400).forEach(function (s) {
            var nm = itemName(s);
            html += '<div class="adm-itemcell" data-action="craft-pick-choose" data-instance="' + escapeHtml(s.instance) +
                '" data-visual="' + escapeHtml(s.visual || "") + '" title="' + escapeHtml(nm) + '">';
            html += '<div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(nm.slice(0, 18)) + '</span></div>';
            html += '<span class="adm-itemcell__cat">' + escapeHtml(catLabel(s.category)) + '</span>';
            html += '</div>';
        });
        if (filtered.length === 0) html += '<div class="adm-empty">Brak wyników.</div>';
        html += '</div></div>';
        html += '</div></div>';
        return html;
    }

    function renderCraftVobPickerModal() {
        var catalog = state.vobCatalog || [];
        var filter = (state.craftVobPickerFilter || "").toLowerCase();
        var cat = state.craftVobPickerCat || "";
        var categories = {};
        catalog.forEach(function (v) { if (v.category) categories[v.category] = true; });
        var catList = Object.keys(categories).sort();
        var filtered = catalog.filter(function (v) {
            if (cat && String(v.category || "") !== cat) return false;
            if (!filter) return true;
            var a = String(v.visual || "").toLowerCase();
            var b = String(v.name || "").toLowerCase();
            var c = String(v.instance || "").toLowerCase();
            return a.indexOf(filter) !== -1 || b.indexOf(filter) !== -1 || c.indexOf(filter) !== -1;
        });
        var pickedUpper = ((state.craftEditor || {}).visuals || []).map(function (v) { return String(v).toUpperCase(); });
        var source = state.vobSource || "data.xml";

        var html = '<div class="adm-craft-modal" data-craft-modal-bg>';
        html += '<div class="adm-craft-modal__panel adm-craft-modal__panel--wide" data-craft-modal>';
        html += '<header class="adm-craft-modal__head"><h3>Wybierz typ VOB-a</h3>';
        html += '<button class="adm-btn" data-action="craft-vob-picker-close">✕</button></header>';
        html += '<div class="adm-craft-modal__tools">';
        html += '<div class="adm-tabs adm-tabs--sub adm-vob-source-tabs">';
        VOB_SOURCE_TABS.forEach(function (tab) {
            var active = source === tab.id ? " is-active" : "";
            html += '<button class="adm-tab' + active + '" data-action="craft-vob-source" data-src="' + escapeHtml(tab.id) + '">' + escapeHtml(t(tab.labelKey, tab.fallback)) + '</button>';
        });
        html += '</div>';
        html += '<input class="adm-input" type="search" placeholder="Szukaj modelu..." data-craft-vob-filter value="' + escapeHtml(state.craftVobPickerFilter || "") + '">';
        html += '<select class="adm-input" data-craft-vob-cat>';
        html += '<option value="">Wszystkie kategorie</option>';
        catList.forEach(function (c) {
            html += '<option value="' + escapeHtml(c) + '"' + (cat === c ? " selected" : "") + '>' + escapeHtml(c) + '</option>';
        });
        html += '</select>';
        html += '</div>';
        html += '<div class="adm-craft-modal__body"><div class="adm-itemgrid adm-vob-grid" data-role="vobgrid">';
        filtered.slice(0, 400).forEach(function (v) {
            var vis = String(v.visual || "").toUpperCase();
            var isPicked = pickedUpper.indexOf(vis) !== -1;
            var label = vobLabel(v);
            html += '<div class="adm-itemcell adm-vob-cell' + (isPicked ? " is-selected" : "") + '" data-action="craft-vob-toggle" data-visual="' + escapeHtml(v.visual || "") + '" data-preview-visual="' + escapeHtml(v.previewVisual || vobPreviewVisual(v.visual || "")) + '" title="' + escapeHtml(label) + '">';
            html += '<div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(label.slice(0, 18)) + '</span></div>';
            html += '<span class="adm-itemcell__cat">' + escapeHtml(v.category || v.source || "VOB") + '</span>';
            html += '<span class="adm-vob-cell__visual">' + escapeHtml(v.visual || "") + '</span>';
            html += '</div>';
        });
        if (filtered.length === 0) html += '<div class="adm-empty">Brak wyników w tym katalogu.</div>';
        html += '</div></div>';
        html += '<footer class="adm-craft-modal__foot"><button class="adm-btn adm-btn--primary" data-action="craft-vob-picker-close">Gotowe</button></footer>';
        html += '</div></div>';
        return html;
    }

    function renderCraftOutputs(ed) {
        var outs = ed.outputs || [];
        if (outs.length === 0) return '<div class="adm-empty">Brak. Główny produkt jest wystarczający.</div>';
        var html = '<div class="adm-craft-ing-list" data-role="itemgrid">';
        outs.forEach(function (o, idx) {
            var scheme = state.schemesById[o.instance];
            var label = scheme ? itemName(scheme) : o.instance;
            var vis = (scheme && scheme.visual) ? scheme.visual : (o.instance + ".3DS");
            html += '<div class="adm-craft-ing">';
            html += '<div class="adm-craft-ing__visual adm-itemcell" data-instance="' + escapeHtml(o.instance) + '" data-visual="' + escapeHtml(vis) + '">';
            html += '<div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(label.slice(0, 12)) + '</span></div>';
            html += '</div>';
            html += '<div class="adm-craft-ing__body">';
            html += '<strong>' + escapeHtml(label) + '</strong>';
            html += '<small>' + escapeHtml(o.instance) + '</small>';
            html += '</div>';
            html += '<input class="adm-input adm-input--sm" type="number" min="1" data-craft-out="' + idx + '" value="' + (o.amount || 1) + '">';
            html += '<button class="adm-btn adm-btn--danger" data-action="craft-out-remove" data-idx="' + idx + '">×</button>';
            html += '</div>';
        });
        html += '</div>';
        return html;
    }

    function renderCraftIngredients(ed, role) {
        var ings = (ed.ingredients || []).map(function (i, idx) { return { idx: idx, role: i.role, instance: i.instance, amount: i.amount }; });
        var filtered = ings.filter(function (i) { return i.role === role; });
        if (filtered.length === 0) return '<div class="adm-empty">Brak. Kliknij przycisk poniżej.</div>';
        var html = '<div class="adm-craft-ing-list" data-role="itemgrid">';
        filtered.forEach(function (i) {
            var scheme = state.schemesById[i.instance];
            var label = scheme ? itemName(scheme) : i.instance;
            var iVisual = (scheme && scheme.visual) ? scheme.visual : (i.instance + ".3DS");
            html += '<div class="adm-craft-ing">';
            html += '<div class="adm-craft-ing__visual adm-itemcell" data-instance="' + escapeHtml(i.instance) + '" data-visual="' + escapeHtml(iVisual) + '">';
            html += '<div class="adm-itemcell__fallback"><span class="adm-itemcell__label">' + escapeHtml(label.slice(0, 12)) + '</span></div>';
            html += '</div>';
            html += '<div class="adm-craft-ing__body">';
            html += '<strong>' + escapeHtml(label) + '</strong>';
            html += '<small>' + escapeHtml(i.instance) + '</small>';
            html += '</div>';
            html += '<input class="adm-input adm-input--sm" type="number" min="1" data-craft-ing="' + i.idx + '" data-field="amount" value="' + (i.amount || 1) + '">';
            html += '<button class="adm-btn adm-btn--danger" data-action="craft-ing-remove" data-idx="' + i.idx + '">×</button>';
            html += '</div>';
        });
        html += '</div>';
        return html;
    }

    function defaultCraftEditor() {
        return { id: 0, name: "", resultInstance: "", resultAmount: 1, category: "misc", craftTimeMs: 1500, requiredLevel: 0, description: "", ingredients: [], outputs: [], visuals: [] };
    }

    function findCraftRecipe(id) {
        var list = state.craftRecipes || [];
        var target = +id;
        for (var i = 0; i < list.length; i += 1) if (+list[i].id === target) return list[i];
        return null;
    }

    function cloneCraftRecipe(src) {
        var visuals = [];
        var srcId = +src.id;
        if (state.craftStations) {
            state.craftStations.forEach(function (s) {
                var rids = (s.recipeIds || []).map(function (x) { return +x; });
                if (rids.indexOf(srcId) !== -1 && s.visual) visuals.push(String(s.visual).toUpperCase());
            });
        }
        return {
            id: +src.id || 0, name: src.name || "", resultInstance: src.resultInstance || "",
            resultAmount: +src.resultAmount || 1, category: src.category || "misc",
            craftTimeMs: +src.craftTimeMs || 1500, requiredLevel: +src.requiredLevel || 0,
            description: src.description || "",
            ingredients: (src.ingredients || []).map(function (i) {
                return { role: i.role || "consume", instance: i.instance, amount: +i.amount || 1 };
            }),
            outputs: (src.outputs || []).map(function (o) {
                return { instance: o.instance, amount: +o.amount || 1 };
            }),
            visuals: visuals
        };
    }

    function handleSpawnConfigAction(action, el) {
        var cfg = state.spawnConfig;
        if (!cfg.lobbyCameras) cfg.lobbyCameras = [];
        if (!cfg.characterScenarios) cfg.characterScenarios = [];
        flushSpawnConfigInputs();

        if (action === "spawnconfig-add-lobby") { send("spawnConfigCapture", { purpose: "lobby" }); return; }
        if (action === "spawnconfig-add-default") { send("spawnConfigCapture", { purpose: "default" }); return; }
        if (action === "spawnconfig-add-scenario") { send("spawnConfigCapture", { purpose: "scenario" }); return; }
        if (action === "spawnconfig-add-create") { send("spawnConfigCapture", { purpose: "create" }); return; }
        if (action === "spawnconfig-add-select") { send("spawnConfigCapture", { purpose: "select" }); return; }

        if (action === "spawnconfig-new-lobby") {
            state.spawnConfigPostCapture = "lobby";
            send("spawnConfigCapture", { purpose: "lobby" });
            return;
        }
        if (action === "spawnconfig-new-scenario") {
            state.spawnConfigPostCapture = "scenario";
            send("spawnConfigCapture", { purpose: "scenario" });
            return;
        }

        if (action === "spawnconfig-ghost-edit-lobby") {
            var li = +el.dataset.idx;
            var spot = cfg.lobbyCameras[li];
            if (!spot) return;
            startGhostEditor("lobby", { idx: li }, "lobby", spot.x, spot.y, spot.z, spot.rotY, spot.rotX, spot.rotZ);
            return;
        }
        if (action === "spawnconfig-ghost-edit-create") {
            var c = cfg.characterCreateCamera || { x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0 };
            startGhostEditor("create", { idx: 0 }, "spawn", c.x, c.y, c.z, c.rotY, c.rotX, c.rotZ);
            return;
        }
        if (action === "spawnconfig-ghost-edit-select") {
            var s = cfg.characterSelectCamera || { x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0 };
            startGhostEditor("select", { idx: 0 }, "spawn", s.x, s.y, s.z, s.rotY, s.rotX, s.rotZ);
            return;
        }
        if (action === "spawnconfig-ghost-edit-default") {
            var def = cfg.characterDefaultSpawn || { x: 0, y: 0, z: 0, angle: 0 };
            startGhostEditor("default", { idx: 0 }, "spawn", def.x, def.y, def.z, def.angle, 0, 0);
            return;
        }
        if (action === "spawnconfig-ghost-edit-scenario") {
            var sci = +el.dataset.idx;
            var sc = cfg.characterScenarios[sci];
            if (!sc) return;
            startGhostEditor("scenario", { idx: sci }, "spawn", sc.x, sc.y, sc.z, sc.angle, 0, 0);
            return;
        }
        if (action === "spawnconfig-ghost-stop") {
            send("adminSpawnGhostStop", {});
            state.spawnGhost = { active: false, mode: "spawn", x: 0, y: 0, z: 0, angle: 0, camPitch: 0, camRoll: 0, world: "", target: null };
            return render(true);
        }
        if (action === "spawnconfig-ghost-apply") {
            applySpawnGhostToTarget();
            return render(true);
        }
        if (action === "spawnconfig-ghost-nudge") {
            send("adminSpawnGhostNudge", { axis: el.dataset.axis, step: 50 });
            return;
        }

        if (action === "spawnconfig-save-lobby") {
            send("spawnConfigSave", { configKey: "lobbyCameras", payload: JSON.stringify(cfg.lobbyCameras || []) });
            return;
        }
        if (action === "spawnconfig-save-default") {
            send("spawnConfigSave", { configKey: "characterDefaultSpawn", payload: JSON.stringify(cfg.characterDefaultSpawn || {}) });
            return;
        }
        if (action === "spawnconfig-save-scenarios") {
            send("spawnConfigSave", { configKey: "characterScenarios", payload: JSON.stringify(cfg.characterScenarios || []) });
            return;
        }
        if (action === "spawnconfig-save-create") {
            send("spawnConfigSave", { configKey: "characterCreateCamera", payload: JSON.stringify(cfg.characterCreateCamera || {}) });
            return;
        }
        if (action === "spawnconfig-save-select") {
            send("spawnConfigSave", { configKey: "characterSelectCamera", payload: JSON.stringify(cfg.characterSelectCamera || {}) });
            return;
        }

        if (action === "spawnconfig-remove-lobby") {
            var li2 = +el.dataset.idx;
            if (cfg.lobbyCameras[li2]) cfg.lobbyCameras.splice(li2, 1);
            send("spawnConfigSave", { configKey: "lobbyCameras", payload: JSON.stringify(cfg.lobbyCameras) });
            return render(true);
        }
        if (action === "spawnconfig-remove-scenario") {
            var si2 = +el.dataset.idx;
            if (cfg.characterScenarios[si2]) cfg.characterScenarios.splice(si2, 1);
            send("spawnConfigSave", { configKey: "characterScenarios", payload: JSON.stringify(cfg.characterScenarios) });
            return render(true);
        }
    }

    function startGhostEditor(kind, target, mode, x, y, z, angle, camPitch, camRoll) {
        state.spawnGhost = {
            active: true, mode: mode,
            x: +x || 0, y: +y || 0, z: +z || 0,
            angle: +angle || 0,
            camPitch: +camPitch || 0, camRoll: +camRoll || 0,
            world: "",
            target: { kind: kind, idx: target.idx }
        };
        var useHuman = (kind === "default" || kind === "scenario" || kind === "create" || kind === "select");
        send("adminSpawnGhostStart", {
            mode: mode,
            useHuman: useHuman,
            x: state.spawnGhost.x, y: state.spawnGhost.y, z: state.spawnGhost.z,
            angle: state.spawnGhost.angle,
            camPitch: state.spawnGhost.camPitch, camRoll: state.spawnGhost.camRoll
        });
        return render(true);
    }

    function applySpawnGhostToTarget() {
        var ghost = state.spawnGhost;
        if (!ghost || !ghost.target) return;
        var cfg = state.spawnConfig;
        var kind = ghost.target.kind;
        if (kind === "lobby") {
            var spot = cfg.lobbyCameras[ghost.target.idx];
            if (!spot) return;
            spot.x = ghost.x; spot.y = ghost.y; spot.z = ghost.z;
            spot.rotX = ghost.camPitch; spot.rotY = ghost.angle; spot.rotZ = ghost.camRoll;
        } else if (kind === "create") {
            cfg.characterCreateCamera = { x: ghost.x, y: ghost.y, z: ghost.z, rotX: ghost.camPitch, rotY: ghost.angle, rotZ: ghost.camRoll };
        } else if (kind === "select") {
            cfg.characterSelectCamera = { x: ghost.x, y: ghost.y, z: ghost.z, rotX: ghost.camPitch, rotY: ghost.angle, rotZ: ghost.camRoll };
        } else if (kind === "default") {
            cfg.characterDefaultSpawn = cfg.characterDefaultSpawn || {};
            cfg.characterDefaultSpawn.x = ghost.x;
            cfg.characterDefaultSpawn.y = ghost.y;
            cfg.characterDefaultSpawn.z = ghost.z;
            cfg.characterDefaultSpawn.angle = ghost.angle;
            if (ghost.world) cfg.characterDefaultSpawn.world = ghost.world;
        } else if (kind === "scenario") {
            var sc = cfg.characterScenarios[ghost.target.idx];
            if (!sc) return;
            sc.x = ghost.x; sc.y = ghost.y; sc.z = ghost.z; sc.angle = ghost.angle;
        }
    }

    function flushSpawnConfigInputs() {
        if (!body) return;
        var cfg = state.spawnConfig;
        body.querySelectorAll("[data-spawn-lobby-idx]").forEach(function (el) {
            var idx = +el.dataset.spawnLobbyIdx;
            var field = el.dataset.spawnLobbyField;
            if (cfg.lobbyCameras && cfg.lobbyCameras[idx]) {
                cfg.lobbyCameras[idx][field] = parseFloat(el.value) || 0;
            }
        });
        body.querySelectorAll("[data-spawn-scenario-idx]").forEach(function (el) {
            var idx = +el.dataset.spawnScenarioIdx;
            var field = el.dataset.spawnScenarioField;
            if (cfg.characterScenarios && cfg.characterScenarios[idx]) {
                cfg.characterScenarios[idx][field] = parseFloat(el.value) || 0;
            }
        });
        body.querySelectorAll("[data-spawn-def]").forEach(function (el) {
            if (!cfg.characterDefaultSpawn) cfg.characterDefaultSpawn = {};
            var key = el.dataset.spawnDef;
            if (key === "world") cfg.characterDefaultSpawn[key] = el.value;
            else cfg.characterDefaultSpawn[key] = parseFloat(el.value) || 0;
        });
        body.querySelectorAll("[data-spawn-createcam]").forEach(function (el) {
            if (!cfg.characterCreateCamera) cfg.characterCreateCamera = { x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0 };
            cfg.characterCreateCamera[el.dataset.spawnCreatecam] = parseFloat(el.value) || 0;
        });
        body.querySelectorAll("[data-spawn-selectcam]").forEach(function (el) {
            if (!cfg.characterSelectCamera) cfg.characterSelectCamera = { x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0 };
            cfg.characterSelectCamera[el.dataset.spawnSelectcam] = parseFloat(el.value) || 0;
        });
        body.querySelectorAll("[data-spawn-sc-idx]").forEach(function (el) {
            var idx = +el.dataset.spawnScIdx;
            var field = el.dataset.spawnScField;
            if (cfg.characterScenarios && cfg.characterScenarios[idx]) {
                cfg.characterScenarios[idx][field] = parseFloat(el.value) || 0;
            }
        });
    }

    function parseSpawnConfigPayload(pl) {
        var out = { lobbyCameras: [], characterDefaultSpawn: null, characterScenarios: [], characterCreateCamera: null, characterSelectCamera: null, hudPortrait: "" };
        if (!pl) return out;
        function tryParse(raw) { try { return raw ? JSON.parse(raw) : null; } catch (e) { return null; } }
        var lobby = tryParse(pl.lobbyCameras);
        if (Array.isArray(lobby)) out.lobbyCameras = lobby;
        var def = tryParse(pl.characterDefaultSpawn);
        if (def && typeof def === "object") out.characterDefaultSpawn = def;
        var scen = tryParse(pl.characterScenarios);
        if (Array.isArray(scen)) out.characterScenarios = scen;
        var cre = tryParse(pl.characterCreateCamera);
        if (cre && typeof cre === "object") out.characterCreateCamera = cre;
        var sel = tryParse(pl.characterSelectCamera);
        if (sel && typeof sel === "object") out.characterSelectCamera = sel;
        if (typeof pl.hudPortrait === "string") out.hudPortrait = pl.hudPortrait;
        return out;
    }

    function applySpawnCapture(pl) {
        if (!pl || !pl.purpose) return;
        var cfg = state.spawnConfig;
        if (pl.purpose === "lobby") {
            cfg.lobbyCameras = cfg.lobbyCameras || [];
            cfg.lobbyCameras.push({ x: pl.x, y: pl.y, z: pl.z, rotX: 20, rotY: pl.angle || 0, rotZ: 0 });
        } else if (pl.purpose === "default") {
            cfg.characterDefaultSpawn = { world: pl.world || "NEWWORLD.ZEN", x: pl.x, y: pl.y, z: pl.z, angle: pl.angle || 0 };
        } else if (pl.purpose === "scenario") {
            cfg.characterScenarios = cfg.characterScenarios || [];
            cfg.characterScenarios.push({ x: pl.x, y: pl.y, z: pl.z, angle: pl.angle || 0 });
        } else if (pl.purpose === "create") {
            cfg.characterCreateCamera = { x: pl.x, y: pl.y, z: pl.z, rotX: 20, rotY: pl.angle || 0, rotZ: 0 };
        } else if (pl.purpose === "select") {
            cfg.characterSelectCamera = { x: pl.x, y: pl.y, z: pl.z, rotX: 20, rotY: pl.angle || 0, rotZ: 0 };
        }
    }

    function updateSpawnGhostDom() {
        if (!body) return;
        var ghost = state.spawnGhost;
        ["x","y","z","angle","camPitch","camRoll"].forEach(function (key) {
            var el = body.querySelector('[data-spawn-ghost="' + key + '"]');
            if (!el || el === document.activeElement) return;
            var v = ghost[key];
            el.value = Math.round((+v || 0) * 10) / 10;
        });
    }

    function handleDbAction(action, el) {
        if (action === "db-table-pick") {
            var table = el.dataset.table || "";
            if (!table) return;
            state.dbActiveTable = table;
            state.dbRows = { table: table, rows: [], total: 0, offset: 0, limit: 100 };
            state.dbSchema = { table: table, columns: [] };
            state.dbInsertDraft = null;
            state.dbEditing = null;
            send("dbTableSchema", { table: table });
            send("dbRows", { table: table, limit: 100, offset: 0 });
            return render(true);
        }
        if (action === "db-refresh") {
            if (!state.dbActiveTable) return;
            send("dbRows", { table: state.dbActiveTable, limit: state.dbRows.limit || 100, offset: state.dbRows.offset || 0 });
            return;
        }
        if (action === "db-page-prev" || action === "db-page-next") {
            if (!state.dbActiveTable) return;
            var pageSize = state.dbRows.limit || 100;
            var newOffset = state.dbRows.offset || 0;
            newOffset += action === "db-page-prev" ? -pageSize : pageSize;
            if (newOffset < 0) newOffset = 0;
            send("dbRows", { table: state.dbActiveTable, limit: pageSize, offset: newOffset });
            return;
        }
        if (action === "db-row-edit") {
            var rowIdx = +el.dataset.row;
            var row = (state.dbRows.rows || [])[rowIdx];
            if (!row) return;
            var pkColumn = dbPrimaryKey(state.dbSchema.columns);
            if (!pkColumn) { setStatus("Brak klucza głównego — edycja niemożliwa", "error"); return; }
            state.dbEditing = { table: state.dbActiveTable, pkColumn: pkColumn, pkValue: row[pkColumn], values: {} };
            return render(true);
        }
        if (action === "db-row-cancel") {
            state.dbEditing = null;
            return render(true);
        }
        if (action === "db-row-save") {
            if (!state.dbEditing) return;
            var changes = {};
            (body.querySelectorAll("[data-db-edit]") || []).forEach(function (input) {
                changes[input.dataset.dbEdit] = input.value;
            });
            delete changes[state.dbEditing.pkColumn];
            send("dbRowUpdate", {
                table: state.dbEditing.table,
                pkColumn: state.dbEditing.pkColumn,
                pkValue: state.dbEditing.pkValue,
                changes: changes
            });
            state.dbEditing = null;
            return;
        }
        if (action === "db-row-delete") {
            var dRowIdx = +el.dataset.row;
            var dRow = (state.dbRows.rows || [])[dRowIdx];
            if (!dRow) return;
            var dPk = dbPrimaryKey(state.dbSchema.columns);
            if (!dPk) { setStatus("Brak klucza głównego — usuwanie niemożliwe", "error"); return; }
            openConfirmModal({
                title: "Usuń wiersz",
                message: "Usunąć wiersz " + dPk + "=" + dRow[dPk] + " z " + state.dbActiveTable + "?",
                okLabel: "Usuń",
                onConfirm: function () {
                    send("dbRowDelete", { table: state.dbActiveTable, pkColumn: dPk, pkValue: dRow[dPk] });
                }
            });
            return;
        }
        if (action === "db-row-new") {
            state.dbInsertDraft = { table: state.dbActiveTable, values: {} };
            return render(true);
        }
        if (action === "db-row-insert-cancel") {
            state.dbInsertDraft = null;
            return render(true);
        }
        if (action === "db-row-insert") {
            if (!state.dbInsertDraft) return;
            var values = {};
            (body.querySelectorAll("[data-db-insert]") || []).forEach(function (input) {
                if (input.value !== "") values[input.dataset.dbInsert] = input.value;
            });
            send("dbRowInsert", { table: state.dbInsertDraft.table, values: values });
            state.dbInsertDraft = null;
            return;
        }
    }

    function handleCraftAction(action, el) {
        console.log("[craft]", action, el ? el.dataset : null);
        if (action === "craft-new") { state.craftEditor = defaultCraftEditor(); state.craftView = "editor"; state.craftPicker = ""; return render(true); }
        if (action === "craft-back") { state.craftView = "list"; state.craftEditor = null; state.craftPicker = ""; return render(true); }
        if (action === "craft-edit") {
            var id = +el.dataset.id || 0;
            console.log("[craft] edit", id);
            var rec = findCraftRecipe(id);
            if (rec) {
                state.craftEditor = cloneCraftRecipe(rec);
                state.craftView = "editor";
                state.craftPicker = "";
                return render(true);
            }
            console.log("[craft] edit: recipe not found for id", id, "recipes:", state.craftRecipes);
            return;
        }
        if (action === "craft-delete") {
            var dId = +el.dataset.id || 0;
            console.log("[craft] delete", dId);
            if (!dId) return;
            openConfirmModal({
                title: "Usuń recepturę",
                message: "Usunąć recepturę #" + dId + "?",
                okLabel: "Usuń",
                onConfirm: function () { send("craftingDelete", { id: dId }); }
            });
            return;
        }
        if (action === "craft-pick-open") {
            state.craftPicker = el.dataset.role || "consume";
            state.craftPickerFilter = "";
            state.craftPickerCat = 0;
            return render(true);
        }
        if (action === "craft-pick-close") {
            state.craftPicker = "";
            state.craftVobPickerOpen = false;
            return render(true);
        }
        if (action === "craft-pick-choose") {
            var inst = String(el.dataset.instance || "").toUpperCase();
            var mode = state.craftPicker || "";
            if (!inst || !mode) return;
            if (!state.craftEditor) state.craftEditor = defaultCraftEditor();
            if (mode === "result") {
                state.craftEditor.resultInstance = inst;
                var schemePick = state.schemesById[inst];
                state.craftEditor.name = schemePick ? itemName(schemePick) : inst;
            } else if (mode === "output") {
                if (!state.craftEditor.outputs) state.craftEditor.outputs = [];
                state.craftEditor.outputs.push({ instance: inst, amount: 1 });
            } else {
                state.craftEditor.ingredients.push({ role: mode, instance: inst, amount: 1 });
            }
            state.craftPicker = "";
            return render(true);
        }
        if (action === "craft-out-remove") {
            var oIdx = +el.dataset.idx;
            if (state.craftEditor && state.craftEditor.outputs && !isNaN(oIdx)) {
                state.craftEditor.outputs.splice(oIdx, 1);
                return render(true);
            }
            return;
        }
        if (action === "craft-vob-picker-open") {
            state.craftVobPickerOpen = true;
            state.craftVobPickerFilter = "";
            state.craftVobPickerCat = "";
            state.vobCategory = "";
            state.vobPage = 0;
            state.vobForm.filter = "";
            requestVobCatalog();
            return render(true);
        }
        if (action === "craft-vob-picker-close") {
            state.craftVobPickerOpen = false;
            return render(true);
        }
        if (action === "craft-vob-source") {
            state.vobSource = el.dataset.src || "data.xml";
            state.vobPage = 0;
            state.vobCategory = "";
            state.craftVobPickerCat = "";
            requestVobCatalog();
            return render(true);
        }
        if (action === "craft-ing-remove") {
            var idx = +el.dataset.idx;
            if (state.craftEditor && !isNaN(idx)) {
                state.craftEditor.ingredients.splice(idx, 1);
                return render(true);
            }
            return;
        }
        if (action === "craft-save") {
            if (!state.craftEditor) return;
            if (!state.craftEditor.resultInstance) { setStatus("Wybierz przedmiot wynikowy", "error"); return; }
            if (!state.craftEditor.name) {
                var scheme = state.schemesById[state.craftEditor.resultInstance];
                state.craftEditor.name = scheme ? itemName(scheme) : state.craftEditor.resultInstance;
            }
            send("craftingSave", state.craftEditor);
            state.craftView = "list";
            state.craftEditor = null;
            state.craftPicker = "";
            return render(true);
        }
        if (action === "craft-vob-toggle") {
            var vis = String(el.dataset.visual || "").toUpperCase();
            if (!vis || !state.craftEditor) return;
            if (!state.craftEditor.visuals) state.craftEditor.visuals = [];
            var pos = state.craftEditor.visuals.map(function (x) { return String(x).toUpperCase(); }).indexOf(vis);
            if (pos !== -1) state.craftEditor.visuals.splice(pos, 1);
            else state.craftEditor.visuals.push(vis);
            return render(true);
        }
        if (action === "craft-vob-remove") {
            var visR = String(el.dataset.visual || "").toUpperCase();
            if (!visR || !state.craftEditor || !state.craftEditor.visuals) return;
            var posR = state.craftEditor.visuals.map(function (x) { return String(x).toUpperCase(); }).indexOf(visR);
            if (posR !== -1) state.craftEditor.visuals.splice(posR, 1);
            return render(true);
        }
    }

    function bindCraftHandlers() {
        var filter = body.querySelector("[data-craft-filter]");
        if (filter) {
            filter.addEventListener("input", function () {
                state.craftFilter = filter.value;
                var list = body.querySelector(".adm-craft-list");
                if (list) list.outerHTML = renderCraftList().replace(/.*<div class="adm-craft-list">/, '<div class="adm-craft-list">').replace(/<\/div>\s*<\/div>$/, "</div>");
            });
        }
        var picker = body.querySelector("[data-craft-picker-filter]");
        if (picker) {
            picker.addEventListener("input", function () {
                state.craftPickerFilter = picker.value;
                render(true);
            });
        }
        var pickerCat = body.querySelector("[data-craft-picker-cat]");
        if (pickerCat) {
            pickerCat.addEventListener("change", function () {
                state.craftPickerCat = +pickerCat.value || 0;
                render(true);
            });
        }
        var vobFilter = body.querySelector("[data-craft-vob-filter]");
        if (vobFilter) {
            var vobFilterDebounce = null;
            vobFilter.addEventListener("input", function () {
                state.craftVobPickerFilter = vobFilter.value;
                state.vobForm.filter = vobFilter.value;
                state.vobPage = 0;
                clearTimeout(vobFilterDebounce);
                vobFilterDebounce = setTimeout(function () { requestVobCatalog(); render(true); }, 200);
            });
        }
        var vobCat = body.querySelector("[data-craft-vob-cat]");
        if (vobCat) {
            vobCat.addEventListener("change", function () {
                state.craftVobPickerCat = vobCat.value;
                state.vobCategory = vobCat.value;
                state.vobPage = 0;
                requestVobCatalog();
                render(true);
            });
        }
        body.querySelectorAll("[data-craft-modal-bg]").forEach(function (bg) {
            bg.addEventListener("click", function (ev) {
                if (ev.target !== bg) return;
                state.craftPicker = "";
                state.craftVobPickerOpen = false;
                render(true);
            });
        });
        body.querySelectorAll("[data-craft-f]").forEach(function (el) {
            var evName = el.tagName === "TEXTAREA" || el.type === "text" || el.type === "search" ? "input" : "change";
            el.addEventListener(evName, function () {
                if (!state.craftEditor) state.craftEditor = defaultCraftEditor();
                var k = el.dataset.craftF;
                var v = el.value;
                if (k === "resultAmount" || k === "craftTimeMs" || k === "requiredLevel") v = +v || 0;
                state.craftEditor[k] = v;
            });
        });
        body.querySelectorAll("[data-craft-ing]").forEach(function (el) {
            el.addEventListener("change", function () {
                var idx = +el.dataset.craftIng;
                var field = el.dataset.field;
                if (!state.craftEditor || !state.craftEditor.ingredients[idx]) return;
                var val = el.value;
                if (field === "amount") val = Math.max(1, +val || 1);
                state.craftEditor.ingredients[idx][field] = val;
            });
        });
        body.querySelectorAll("[data-craft-out]").forEach(function (el) {
            el.addEventListener("change", function () {
                var idx = +el.dataset.craftOut;
                if (!state.craftEditor || !state.craftEditor.outputs || !state.craftEditor.outputs[idx]) return;
                state.craftEditor.outputs[idx].amount = Math.max(1, +el.value || 1);
            });
        });
    }

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
