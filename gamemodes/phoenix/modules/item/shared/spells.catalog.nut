phoenix.item.SpellsCatalog <- {}

phoenix.item.SpellsCatalog.entries <- {
	LIGHT            = { circle = 1, manaCost = 5,   kind = "light",  label = "Swiatlo" },
	PALLIGHT         = { circle = 1, manaCost = 5,   kind = "light",  label = "Swiatlo Paladyna" },
	LIGHTHEAL        = { circle = 1, manaCost = 10,  kind = "heal",   label = "Male leczenie",     hp = 60 },
	PALLIGHTHEAL     = { circle = 1, manaCost = 12,  kind = "heal",   label = "Swiete leczenie",   hp = 70 },
	MEDIUMHEAL       = { circle = 3, manaCost = 30,  kind = "heal",   label = "Srednie leczenie",  hp = 180 },
	PALMEDIUMHEAL    = { circle = 3, manaCost = 35,  kind = "heal",   label = "Srednie swiete",    hp = 200 },
	FULLHEAL         = { circle = 5, manaCost = 80,  kind = "heal",   label = "Pelne leczenie",    hp = 9999 },
	PALFULLHEAL      = { circle = 5, manaCost = 90,  kind = "heal",   label = "Pelne swiete",      hp = 9999 },
	ZAP              = { circle = 1, manaCost = 5,   kind = "damage", label = "Iskra",             damage = 25 },
	FIREBOLT         = { circle = 1, manaCost = 12,  kind = "damage", label = "Pocisk Ognia",      damage = 55 },
	PALHOLYBOLT      = { circle = 1, manaCost = 14,  kind = "damage", label = "Swiety Pocisk",     damage = 70 },
	ICEBOLT          = { circle = 2, manaCost = 14,  kind = "damage", label = "Pocisk Lodu",       damage = 65 },
	INSTANTFIREBALL  = { circle = 2, manaCost = 25,  kind = "damage", label = "Kula Ognia",        damage = 110 },
	THUNDERBALL      = { circle = 3, manaCost = 30,  kind = "damage", label = "Kula Blyskawic",    damage = 130 },
	HARMUNDEAD       = { circle = 4, manaCost = 35,  kind = "damage", label = "Razenie Nieumarych",damage = 200 },
	PALREPELEVIL     = { circle = 3, manaCost = 35,  kind = "damage", label = "Odpedzenie Zla",    damage = 220 },
	CHARGEFIREBALL   = { circle = 4, manaCost = 45,  kind = "damage", label = "Naladowana Kula",   damage = 200 },
	LIGHTNINGFLASH   = { circle = 4, manaCost = 60,  kind = "damage", label = "Blyskawica",        damage = 260 },
	PALDESTROYEVIL   = { circle = 6, manaCost = 70,  kind = "damage", label = "Niszcz Zlo",        damage = 350 },
	WINDFIST         = { circle = 2, manaCost = 18,  kind = "aoe",    label = "Piesc Wiatru",      damage = 50 },
	ICECUBE          = { circle = 3, manaCost = 22,  kind = "aoe",    label = "Szescian Lodu",     damage = 65 },
	FIRESTORM        = { circle = 3, manaCost = 38,  kind = "aoe",    label = "Burza Ognia",       damage = 90 },
	ICEWAVE          = { circle = 5, manaCost = 55,  kind = "aoe",    label = "Fala Lodu",         damage = 130 },
	PYROKINESIS      = { circle = 5, manaCost = 60,  kind = "aoe",    label = "Pirokineza",        damage = 150 },
	FIRERAIN         = { circle = 6, manaCost = 90,  kind = "aoe",    label = "Deszcz Ognia",      damage = 200 },
	BREATHOFDEATH    = { circle = 6, manaCost = 110, kind = "aoe",    label = "Oddech Smierci",    damage = 240 },
	MASSDEATH        = { circle = 6, manaCost = 140, kind = "aoe",    label = "Masowa Smierc",     damage = 320 },
	MASTEROFDISASTER = { circle = 6, manaCost = 180, kind = "aoe",    label = "Mistrz Zniszczenia",damage = 400 },
	FEAR             = { circle = 3, manaCost = 25,  kind = "aoe",    label = "Strach" },
	SLEEP            = { circle = 2, manaCost = 25,  kind = "aoe",    label = "Sen" },
	SHRINK           = { circle = 6, manaCost = 30,  kind = "damage", label = "Pomniejszenie" },
	SUMGOBSKEL       = { circle = 1, manaCost = 20,  kind = "summon", label = "Szkielet Goblina" },
	SUMWOLF          = { circle = 2, manaCost = 30,  kind = "summon", label = "Wilk" },
	SUMSKEL          = { circle = 3, manaCost = 50,  kind = "summon", label = "Szkielet" },
	SUMGOL           = { circle = 4, manaCost = 80,  kind = "summon", label = "Golem" },
	SUMDEMON         = { circle = 5, manaCost = 120, kind = "summon", label = "Demon" },
	ARMYOFDARKNESS   = { circle = 6, manaCost = 150, kind = "summon", label = "Armia Ciemnosci" }
}

phoenix.item.SpellsCatalog.find <- function (key) {
	if (key == null) return null
	local up = key.tostring().toupper()
	if (up in phoenix.item.SpellsCatalog.entries) return phoenix.item.SpellsCatalog.entries[up]
	return null
}

phoenix.item.SpellsCatalog.requiredLevel <- function (circle) {
	if (circle == null || circle <= 0) return 0
	local c = circle.tointeger()
	if (c < 1) return 0
	if (c > 6) c = 6
	return c * 10
}
