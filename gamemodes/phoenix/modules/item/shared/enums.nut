

enum PhoenixItemCategory {
	Unknown      = 0,
	Weapon1H     = 1,
	Weapon2H     = 2,
	Bow          = 3,
	Crossbow     = 4,
	Shield       = 5,
	Armor        = 6,
	Helmet       = 7,
	Amulet       = 8,
	Ring         = 9,
	Belt         = 10,
	Rune         = 11,
	Scroll       = 12,
	Potion       = 13,
	Food         = 14,
	Ammo         = 15,
	Material     = 16,
	Key          = 17,
	Document     = 18,
	Misc         = 19
}

enum PhoenixItemQuality {
	Terrible     = 0,
	Poor         = 1,
	Common       = 2,
	Fine         = 3,
	Exquisite    = 4,
	Magnificent  = 5
}

enum PhoenixDamageType {
	Edge   = 0,
	Blunt  = 1,
	Point  = 2,
	Fire   = 3,
	Magic  = 4
}

enum PhoenixItemSlot {
	None     = 0,
	MainHand = 1,
	OffHand  = 2,
	Ranged   = 3,
	Armor    = 4,
	Helmet   = 5,
	Amulet   = 6,
	Ring1    = 7,
	Ring2    = 8,
	Belt     = 9,
	Spell    = 10
}

enum PhoenixItemFlag {
	None         = 0,
	Stackable    = 1,
	NoDrop       = 2,
	NoTrade      = 4,
	NoSell       = 8,
	NoUpgrade    = 16,
	Quest        = 32,
	Soulbound    = 64
}

enum PhoenixItemPacket {
	Inventory    = 0,
	Add          = 1,
	Remove       = 2,
	Update       = 3,
	Equip        = 4,
	Unequip      = 5,
	UseRequest   = 6,
	UpgradeReq   = 7,
	UpgradeResult= 8
}

enum PhoenixInventoryOwner {
	Player    = 0,
	Chest     = 1,
	Vendor    = 2,
	Ground    = 3,
	Trade     = 4
}

phoenix.item.MAX_UPGRADE <- 9
