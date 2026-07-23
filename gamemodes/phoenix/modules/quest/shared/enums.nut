phoenix.quest.DefinitionStatus <- {
	Draft = "draft",
	Published = "published",
	Archived = "archived"
}
phoenix.quest.RevisionStatus <- {
	Draft = "draft",
	Published = "published"
}
phoenix.quest.Status <- {
	Active = "active",
	ReadyToTurnIn = "ready_to_turn_in",
	RewardPending = "reward_pending",
	Completed = "completed",
	Failed = "failed",
	Cancelled = "cancelled"
}
phoenix.quest.ObjectiveType <- {
	Talk = "talk",
	Kill = "kill",
	Collect = "collect",
	Deliver = "deliver",
	Reach = "reach",
	Interact = "interact",
	CustomEvent = "custom_event"
}
phoenix.quest.RewardType <- {
	Experience = "experience",
	Currency = "currency",
	Item = "item",
	Statistic = "statistic",
	Flag = "flag"
}
phoenix.quest.NpcRole <- {
	Giver = "giver",
	TurnIn = "turn_in",
	TalkTarget = "talk_target",
	InteractTarget = "interact_target"
}
phoenix.quest.NpcRefType <- {
	Spawn = "spawn",
	Preset = "preset",
	Instance = "instance",
	Tag = "tag"
}
phoenix.quest.Error <- {
	InvalidRequest = "INVALID_REQUEST",
	Forbidden = "FORBIDDEN",
	NotFound = "NOT_FOUND",
	Archived = "ARCHIVED",
	QuestInUse = "QUEST_IN_USE",
	LegacyMapped = "LEGACY_MAPPED",
	NotArchived = "NOT_ARCHIVED",
	ValidationFailed = "VALIDATION_FAILED",
	StaleVersion = "STALE_VERSION",
	NotAvailable = "NOT_AVAILABLE",
	InvalidTransition = "INVALID_TRANSITION",
	NpcOutOfRange = "NPC_OUT_OF_RANGE",
	RewardPending = "REWARD_PENDING",
	Internal = "INTERNAL_ERROR"
}
phoenix.quest.Type <- phoenix.quest.ObjectiveType