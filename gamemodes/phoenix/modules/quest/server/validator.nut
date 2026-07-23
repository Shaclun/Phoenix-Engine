phoenix.quest.Validator <- {
	function result() {
		return { valid = true, errors = [], warnings = [] }
	}

	function issue(result, path, entityKey, code, message, warning = false) {
		local entry = { path = path, entityKey = entityKey, code = code, message = message, severity = warning ? "warning" : "error" }
		if (warning) result.warnings.append(entry)
		else {
			result.errors.append(entry)
			result.valid = false
		}
	}

	function hasValue(tableValue, key) {
		return tableValue != null && typeof tableValue == "table" && key in tableValue && tableValue[key] != null
	}

	function objectiveTypeAllowed(typeName) {
		foreach (key, value in phoenix.quest.ObjectiveType) if (value == typeName) return true
		return typeName in phoenix.quest.Registry.objectives
	}

	function conditionOperatorAllowed(operator, equalityOnly = false) {
		local allowed = equalityOnly ? ["eq", "ne"] : ["eq", "ne", "gt", "gte", "lt", "lte"]
		foreach (value in allowed) if (value == operator) return true
		return false
	}

	function validateCondition(condition, path, result, depth = 0, counter = null) {
		if (condition == null) return
		if (counter == null) counter = { count = 0 }
		counter.count += 1
		if (counter.count > phoenix.quest.Schema.Limits.Conditions) {
			phoenix.quest.Validator.issue(result, path, "", "TOO_MANY_CONDITIONS", "Przekroczono limit warunków")
			return
		}
		if (depth > phoenix.quest.Schema.Limits.ConditionDepth) {
			phoenix.quest.Validator.issue(result, path, "", "CONDITION_DEPTH_EXCEEDED", "Przekroczono maksymalną głębokość warunków")
			return
		}
		if (!phoenix.quest.Schema.isTable(condition)) {
			phoenix.quest.Validator.issue(result, path, "", "INVALID_CONDITION", "Warunek musi być obiektem")
			return
		}
		local typeName = phoenix.quest.Validator.hasValue(condition, "type") ? condition.type.tostring() : ""
		if (typeName == "all" || typeName == "any") {
			local children = "conditions" in condition ? condition.conditions : null
			if (!phoenix.quest.Schema.isArray(children) || children.len() < 1) {
				phoenix.quest.Validator.issue(result, path + ".conditions", "", "CONDITION_CHILDREN_REQUIRED", "Warunek logiczny wymaga co najmniej jednego elementu")
				return
			}
			if (children.len() > phoenix.quest.Schema.Limits.ConditionChildren) phoenix.quest.Validator.issue(result, path + ".conditions", "", "TOO_MANY_CONDITION_CHILDREN", "Przekroczono limit elementów warunku")
			for (local index = 0; index < children.len() && index < phoenix.quest.Schema.Limits.ConditionChildren; index += 1) phoenix.quest.Validator.validateCondition(children[index], path + ".conditions[" + index + "]", result, depth + 1, counter)
			return
		}
		if (typeName == "not") {
			if (!("condition" in condition) || condition.condition == null) phoenix.quest.Validator.issue(result, path + ".condition", "", "NOT_CONDITION_REQUIRED", "Warunek not wymaga jednego elementu")
			else phoenix.quest.Validator.validateCondition(condition.condition, path + ".condition", result, depth + 1, counter)
			return
		}
		if (!(typeName in phoenix.quest.Registry.conditions)) {
			phoenix.quest.Validator.issue(result, path + ".type", "", "UNKNOWN_CONDITION_TYPE", "Nieznany typ warunku")
			return
		}
		local operator = phoenix.quest.Validator.hasValue(condition, "operator") ? condition.operator.tostring() : ((typeName == "flag") ? "eq" : "gte")
		if (typeName == "level" || typeName == "race" || typeName == "class" || typeName == "strength" || typeName == "dexterity" || typeName == "magicLevel") {
			if (!("value" in condition) || (typeof condition.value != "integer" && typeof condition.value != "float")) phoenix.quest.Validator.issue(result, path + ".value", "", "CONDITION_NUMBER_REQUIRED", "Warunek wymaga wartości liczbowej")
			if (!phoenix.quest.Validator.conditionOperatorAllowed(operator)) phoenix.quest.Validator.issue(result, path + ".operator", "", "INVALID_CONDITION_OPERATOR", "Nieobsługiwany operator warunku")
			return
		}
		if (typeName == "item") {
			if (!phoenix.quest.Validator.hasValue(condition, "instance") || phoenix.item.find(condition.instance.tostring().toupper()) == null) phoenix.quest.Validator.issue(result, path + ".instance", "", "ITEM_NOT_FOUND", "Przedmiot warunku nie istnieje")
			if ("amount" in condition && phoenix.quest.Schema.integer(condition.amount, 0) < 1) phoenix.quest.Validator.issue(result, path + ".amount", "", "INVALID_CONDITION_AMOUNT", "Ilość przedmiotu musi być dodatnia")
			if (!phoenix.quest.Validator.conditionOperatorAllowed(operator)) phoenix.quest.Validator.issue(result, path + ".operator", "", "INVALID_CONDITION_OPERATOR", "Nieobsługiwany operator warunku")
			return
		}
		if (typeName == "flag") {
			if (!phoenix.quest.Validator.hasValue(condition, "key") || !phoenix.quest.Schema.isKey(condition.key)) phoenix.quest.Validator.issue(result, path + ".key", "", "INVALID_FLAG_KEY", "Warunek flagi wymaga poprawnego klucza")
			if (!phoenix.quest.Validator.conditionOperatorAllowed(operator, true)) phoenix.quest.Validator.issue(result, path + ".operator", "", "INVALID_CONDITION_OPERATOR", "Flaga obsługuje operatory eq i ne")
			return
		}
		if (typeName == "quest") {
			if (!phoenix.quest.Validator.hasValue(condition, "code") || !phoenix.quest.Schema.isKey(condition.code)) phoenix.quest.Validator.issue(result, path + ".code", "", "INVALID_QUEST_CODE", "Warunek questa wymaga poprawnego kodu")
			local status = phoenix.quest.Validator.hasValue(condition, "status") ? condition.status.tostring() : phoenix.quest.Status.Completed
			local statusAllowed = status == phoenix.quest.Status.Active || status == phoenix.quest.Status.ReadyToTurnIn || status == phoenix.quest.Status.RewardPending || status == phoenix.quest.Status.Completed || status == phoenix.quest.Status.Failed || status == phoenix.quest.Status.Cancelled
			if (!statusAllowed) phoenix.quest.Validator.issue(result, path + ".status", "", "INVALID_QUEST_STATUS", "Nieobsługiwany status questa w warunku")
		}
	}

	function validate(content, publishing = false) {
		local result = phoenix.quest.Validator.result()
		if (!phoenix.quest.Schema.isTable(content)) {
			phoenix.quest.Validator.issue(result, "content", "", "CONTENT_REQUIRED", "Definicja musi być obiektem")
			return result
		}
		local metadata = ("metadata" in content) ? content.metadata : null
		if (!phoenix.quest.Schema.isTable(metadata)) phoenix.quest.Validator.issue(result, "metadata", "", "METADATA_REQUIRED", "Brak metadanych")
		else {
			local title = phoenix.quest.Validator.hasValue(metadata, "title") ? metadata.title.tostring() : ""
			if (title.len() < 1 || title.len() > phoenix.quest.Schema.Limits.Title) phoenix.quest.Validator.issue(result, "metadata.title", "", "INVALID_TITLE", "Tytuł ma nieprawidłową długość")
			local description = phoenix.quest.Validator.hasValue(metadata, "description") ? metadata.description.tostring() : ""
			if (description.len() > phoenix.quest.Schema.Limits.Description) phoenix.quest.Validator.issue(result, "metadata.description", "", "DESCRIPTION_TOO_LONG", "Opis przekracza dozwolony limit")
		}
		phoenix.quest.Validator.validateCondition(("availability" in content) ? content.availability : null, "availability", result)
		local stages = ("stages" in content) ? content.stages : null
		if (!phoenix.quest.Schema.isArray(stages) || stages.len() < 1) {
			phoenix.quest.Validator.issue(result, "stages", "", "STAGES_REQUIRED", "Quest wymaga co najmniej jednego etapu")
			return result
		}
		if (stages.len() > phoenix.quest.Schema.Limits.Stages) phoenix.quest.Validator.issue(result, "stages", "", "TOO_MANY_STAGES", "Przekroczono limit etapów")
		local stageMap = {}
		local objectiveKeys = {}
		local startKey = phoenix.quest.Validator.hasValue(content, "startStageKey") ? content.startStageKey.tostring() : ""

		foreach (index, stage in stages) {
			local path = "stages[" + index + "]"
			if (!phoenix.quest.Schema.isTable(stage)) {
				phoenix.quest.Validator.issue(result, path, "", "INVALID_STAGE", "Etap musi być obiektem")
				continue
			}
			local key = phoenix.quest.Validator.hasValue(stage, "key") ? stage.key.tostring() : ""
			if (!phoenix.quest.Schema.isKey(key)) {
				phoenix.quest.Validator.issue(result, path + ".key", key, "INVALID_STAGE_KEY", "Nieprawidłowy klucz etapu")
				continue
			}
			if (key in stageMap) {
				phoenix.quest.Validator.issue(result, path + ".key", key, "DUPLICATE_STAGE_KEY", "Klucz etapu nie jest unikalny")
				continue
			}
			stageMap[key] <- stage
			local objectives = ("objectives" in stage) ? stage.objectives : []
			if (!phoenix.quest.Schema.isArray(objectives)) phoenix.quest.Validator.issue(result, path + ".objectives", key, "INVALID_OBJECTIVES", "Cele muszą być tablicą")
			else {
				if (objectives.len() < 1) phoenix.quest.Validator.issue(result, path + ".objectives", key, "OBJECTIVES_REQUIRED", "Etap wymaga co najmniej jednego celu")
				if (objectives.len() > phoenix.quest.Schema.Limits.ObjectivesPerStage) phoenix.quest.Validator.issue(result, path + ".objectives", key, "TOO_MANY_OBJECTIVES", "Przekroczono limit celów")
				foreach (objectiveIndex, objective in objectives) {
					local objectivePath = path + ".objectives[" + objectiveIndex + "]"
					if (!phoenix.quest.Schema.isTable(objective)) { phoenix.quest.Validator.issue(result, objectivePath, key, "INVALID_OBJECTIVE", "Cel musi być obiektem"); continue }
					local objectiveKey = phoenix.quest.Validator.hasValue(objective, "key") ? objective.key.tostring() : ""
					if (!phoenix.quest.Schema.isKey(objectiveKey)) phoenix.quest.Validator.issue(result, objectivePath + ".key", objectiveKey, "INVALID_OBJECTIVE_KEY", "Nieprawidłowy klucz celu")
					else if (objectiveKey in objectiveKeys) phoenix.quest.Validator.issue(result, objectivePath + ".key", objectiveKey, "DUPLICATE_OBJECTIVE_KEY", "Klucz celu nie jest unikalny w queście")
					else objectiveKeys[objectiveKey] <- true
					phoenix.quest.Validator.validateObjective(objective, objectivePath, objectiveKey, result)
				}
			}
		}
		if (startKey == "" || !(startKey in stageMap)) phoenix.quest.Validator.issue(result, "startStageKey", startKey, "INVALID_START_STAGE", "Etap początkowy nie istnieje")

		local terminalCount = 0
		foreach (key, stage in stageMap) {
			local terminal = phoenix.quest.Validator.hasValue(stage, "terminal") ? stage.terminal.tostring() : ""
			if (terminal == "success" || terminal == "failure") terminalCount += 1
			else if (terminal != "") phoenix.quest.Validator.issue(result, "stages." + key + ".terminal", key, "INVALID_TERMINAL", "Nieznany typ zakończenia")
			phoenix.quest.Validator.validateCondition(("turnInCondition" in stage) ? stage.turnInCondition : null, "stages." + key + ".turnInCondition", result)
			local transitions = ("transitions" in stage) ? stage.transitions : []
			if (!phoenix.quest.Schema.isArray(transitions)) { phoenix.quest.Validator.issue(result, "stages." + key + ".transitions", key, "INVALID_TRANSITIONS", "Przejścia muszą być tablicą"); continue }
			if (terminal != "" && transitions.len() > 0) phoenix.quest.Validator.issue(result, "stages." + key + ".transitions", key, "TERMINAL_HAS_TRANSITIONS", "Etap końcowy nie może posiadać przejść")
			local transitionKeys = {}
			foreach (transitionIndex, transition in transitions) {
				local transitionPath = "stages." + key + ".transitions[" + transitionIndex + "]"
				if (!phoenix.quest.Schema.isTable(transition)) { phoenix.quest.Validator.issue(result, transitionPath, key, "INVALID_TRANSITION", "Przejście musi być obiektem"); continue }
				local transitionKey = phoenix.quest.Validator.hasValue(transition, "key") ? transition.key.tostring() : ""
				if (!phoenix.quest.Schema.isKey(transitionKey)) phoenix.quest.Validator.issue(result, transitionPath + ".key", key, "INVALID_TRANSITION_KEY", "Przejście wymaga stabilnego klucza")
				else if (transitionKey in transitionKeys) phoenix.quest.Validator.issue(result, transitionPath + ".key", key, "DUPLICATE_TRANSITION_KEY", "Klucz przejścia nie jest unikalny w etapie")
				else transitionKeys[transitionKey] <- true
				local target = phoenix.quest.Validator.hasValue(transition, "target") ? transition.target.tostring() : ""
				if (!(target in stageMap)) phoenix.quest.Validator.issue(result, transitionPath + ".target", key, "MISSING_TRANSITION_TARGET", "Cel przejścia nie istnieje")
				phoenix.quest.Validator.validateCondition(("condition" in transition) ? transition.condition : null, transitionPath + ".condition", result)
			}
			if (terminal == "" && transitions.len() == 0) phoenix.quest.Validator.issue(result, "stages." + key, key, "DEAD_END_STAGE", "Etap nie ma zakończenia ani przejścia")
		}
		if (terminalCount < 1) phoenix.quest.Validator.issue(result, "stages", "", "TERMINAL_REQUIRED", "Quest wymaga co najmniej jednego zakończenia")
		if (startKey in stageMap) {
			phoenix.quest.Validator.validateReachability(stageMap, startKey, result)
			phoenix.quest.Validator.validateTerminalPaths(stageMap, result)
			phoenix.quest.Validator.validateStageCycles(stageMap, result)
		}
		phoenix.quest.Validator.validateNpcBindings(content, result)
		phoenix.quest.Validator.validateStageBindings(content, stageMap, result)
		phoenix.quest.Validator.validateDialogs(content, result)
		phoenix.quest.Validator.validateRewards(content, result)
		if (publishing) phoenix.quest.Validator.validateNpcReferences(content, result)
		if (publishing && result.warnings.len() > 0 && !("acknowledgeWarnings" in content && content.acknowledgeWarnings == true)) {
			phoenix.quest.Validator.issue(result, "acknowledgeWarnings", "", "WARNINGS_NOT_ACKNOWLEDGED", "Ostrzeżenia publikacji wymagają potwierdzenia")
		}
		return result
	}

	function validateReachability(stageMap, startKey, result) {
		local visited = {}
		local queue = [startKey]
		while (queue.len() > 0) {
			local key = queue.remove(0)
			if (key in visited || !(key in stageMap)) continue
			visited[key] <- true
			local stage = stageMap[key]
			local transitions = ("transitions" in stage && phoenix.quest.Schema.isArray(stage.transitions)) ? stage.transitions : []
			foreach (transition in transitions) {
				if (phoenix.quest.Validator.hasValue(transition, "target")) queue.append(transition.target.tostring())
			}
		}
		foreach (key, stage in stageMap) {
			if (!(key in visited)) phoenix.quest.Validator.issue(result, "stages." + key, key, "UNREACHABLE_STAGE", "Etap jest nieosiągalny")
		}
	}

	function validateTerminalPaths(stageMap, result) {
		local reverse = {}
		local reachable = {}
		local queue = []
		foreach (key, stage in stageMap) {
			reverse[key] <- []
			local terminal = phoenix.quest.Validator.hasValue(stage, "terminal") ? stage.terminal.tostring() : ""
			if (terminal == "success" || terminal == "failure") queue.append(key)
		}
		foreach (key, stage in stageMap) {
			local transitions = ("transitions" in stage && phoenix.quest.Schema.isArray(stage.transitions)) ? stage.transitions : []
			foreach (transition in transitions) if (phoenix.quest.Validator.hasValue(transition, "target") && transition.target.tostring() in reverse) reverse[transition.target.tostring()].append(key)
		}
		while (queue.len() > 0) {
			local key = queue.remove(0)
			if (key in reachable) continue
			reachable[key] <- true
			foreach (previous in reverse[key]) queue.append(previous)
		}
		foreach (key, stage in stageMap) if (!(key in reachable)) phoenix.quest.Validator.issue(result, "stages." + key, key, "NO_TERMINAL_PATH", "Etap nie prowadzi do zakończenia")
	}

	function walkStageCycle(key, stageMap, visited, visiting, reported, result) {
		if (key in visiting) return
		visiting[key] <- true
		local stage = stageMap[key]
		local transitions = ("transitions" in stage && phoenix.quest.Schema.isArray(stage.transitions)) ? stage.transitions : []
		foreach (transition in transitions) {
			if (!phoenix.quest.Validator.hasValue(transition, "target")) continue
			local target = transition.target.tostring()
			if (!(target in stageMap)) continue
			if (target in visiting) {
				local allowed = ("allowCycle" in stage && stage.allowCycle == true) || ("allowCycle" in stageMap[target] && stageMap[target].allowCycle == true)
				local cycleKey = key + ":" + target
				if (!allowed && !(cycleKey in reported)) {
					reported[cycleKey] <- true
					phoenix.quest.Validator.issue(result, "stages." + key + ".transitions", key, "DISALLOWED_STAGE_CYCLE", "Cykl etapów wymaga jawnego allowCycle")
				}
			} else if (!(target in visited)) phoenix.quest.Validator.walkStageCycle(target, stageMap, visited, visiting, reported, result)
		}
		visiting.rawdelete(key)
		visited[key] <- true
	}

	function validateStageCycles(stageMap, result) {
		local visited = {}
		local visiting = {}
		local reported = {}
		foreach (key, stage in stageMap) if (!(key in visited)) phoenix.quest.Validator.walkStageCycle(key, stageMap, visited, visiting, reported, result)
	}

	function validateObjectiveReference(config, path, objectiveKey, result) {
		if ("refType" in config || "refValue" in config) {
			local refType = phoenix.quest.Validator.hasValue(config, "refType") ? config.refType.tostring() : ""
			local refValue = phoenix.quest.Validator.hasValue(config, "refValue") ? config.refValue.tostring() : ""
			local refAllowed = false
			foreach (name, value in phoenix.quest.NpcRefType) if (value == refType) refAllowed = true
			if (!refAllowed) phoenix.quest.Validator.issue(result, path + ".refType", objectiveKey, "INVALID_OBJECTIVE_NPC_REF_TYPE", "Cel posiada nieznany typ referencji NPC")
			if (refValue == "") phoenix.quest.Validator.issue(result, path + ".refValue", objectiveKey, "OBJECTIVE_REFERENCE_REQUIRED", "Cel wymaga referencji NPC")
			else if ((refType == phoenix.quest.NpcRefType.Spawn || refType == phoenix.quest.NpcRefType.Preset) && phoenix.quest.Schema.integer(refValue, 0, 1) <= 0) phoenix.quest.Validator.issue(result, path + ".refValue", objectiveKey, "INVALID_OBJECTIVE_NPC_REFERENCE", "Cel wymaga dodatniego identyfikatora NPC")
			return
		}
		if ("spawnId" in config) {
			if (config.spawnId == null || phoenix.quest.Schema.integer(config.spawnId, 0, 1) <= 0) phoenix.quest.Validator.issue(result, path + ".spawnId", objectiveKey, "INVALID_OBJECTIVE_NPC_REFERENCE", "Cel wymaga dodatniego identyfikatora spawnu")
			return
		}
		if ("presetId" in config) {
			if (config.presetId == null || phoenix.quest.Schema.integer(config.presetId, 0, 1) <= 0) phoenix.quest.Validator.issue(result, path + ".presetId", objectiveKey, "INVALID_OBJECTIVE_NPC_REFERENCE", "Cel wymaga dodatniego identyfikatora presetu")
			return
		}
		if ("instance" in config) {
			if (config.instance == null || config.instance.tostring() == "") phoenix.quest.Validator.issue(result, path + ".instance", objectiveKey, "OBJECTIVE_REFERENCE_REQUIRED", "Cel wymaga instancji NPC")
			return
		}
		if ("tag" in config) {
			if (config.tag == null || config.tag.tostring() == "") phoenix.quest.Validator.issue(result, path + ".tag", objectiveKey, "OBJECTIVE_REFERENCE_REQUIRED", "Cel wymaga tagu NPC")
			return
		}
		phoenix.quest.Validator.issue(result, path, objectiveKey, "OBJECTIVE_REFERENCE_REQUIRED", "Cel wymaga referencji NPC")
	}

	function validateObjective(objective, path, objectiveKey, result) {
		local typeName = phoenix.quest.Validator.hasValue(objective, "type") ? objective.type.tostring() : ""
		if (!phoenix.quest.Validator.objectiveTypeAllowed(typeName)) { phoenix.quest.Validator.issue(result, path + ".type", objectiveKey, "UNKNOWN_OBJECTIVE_TYPE", "Nieznany typ celu"); return }
		local required = phoenix.quest.Validator.hasValue(objective, "required") ? phoenix.quest.Schema.integer(objective.required, 1) : 1
		if (required < 1) phoenix.quest.Validator.issue(result, path + ".required", objectiveKey, "INVALID_OBJECTIVE_REQUIRED", "Wymagana ilość musi być dodatnia")
		local config = "config" in objective && phoenix.quest.Schema.isTable(objective.config) ? objective.config : objective
		if (typeName == phoenix.quest.ObjectiveType.Talk || typeName == phoenix.quest.ObjectiveType.Kill) phoenix.quest.Validator.validateObjectiveReference(config, path + ".config", objectiveKey, result)
		else if (typeName == phoenix.quest.ObjectiveType.Collect || typeName == phoenix.quest.ObjectiveType.Deliver) {
			if (!("instance" in config) || config.instance == null || config.instance.tostring() == "") phoenix.quest.Validator.issue(result, path + ".config.instance", objectiveKey, "ITEM_INSTANCE_REQUIRED", "Cel wymaga instancji przedmiotu")
			else if (phoenix.item.find(config.instance.tostring().toupper()) == null) phoenix.quest.Validator.issue(result, path + ".config.instance", objectiveKey, "ITEM_NOT_FOUND", "Instancja przedmiotu nie istnieje")
		}
		else if (typeName == phoenix.quest.ObjectiveType.Reach) {
			if (!("zoneKey" in config) || !phoenix.quest.Schema.isKey(config.zoneKey)) phoenix.quest.Validator.issue(result, path + ".config.zoneKey", objectiveKey, "ZONE_KEY_REQUIRED", "Cel dotarcia wymaga klucza strefy")
			foreach (field in ["x", "y", "z", "radius"]) if (!(field in config) || (typeof config[field] != "integer" && typeof config[field] != "float")) phoenix.quest.Validator.issue(result, path + ".config." + field, objectiveKey, "INVALID_ZONE_FIELD", "Strefa wymaga liczbowego pola " + field)
			if ("radius" in config && (typeof config.radius == "integer" || typeof config.radius == "float") && config.radius.tofloat() <= 0.0) phoenix.quest.Validator.issue(result, path + ".config.radius", objectiveKey, "INVALID_ZONE_RADIUS", "Promień strefy musi być dodatni")
		}
		else if (typeName == phoenix.quest.ObjectiveType.Interact) {
			if (!phoenix.quest.Validator.hasValue(config, "targetKey") || config.targetKey.tostring() == "") phoenix.quest.Validator.validateObjectiveReference(config, path + ".config", objectiveKey, result)
		}
		else if (typeName == phoenix.quest.ObjectiveType.CustomEvent) {
			local eventName = "eventName" in config && config.eventName != null ? config.eventName.tostring() : ""
			if (!phoenix.quest.Schema.isKey(eventName) || !(eventName in phoenix.quest.Registry.events)) phoenix.quest.Validator.issue(result, path + ".config.eventName", objectiveKey, "CUSTOM_EVENT_NOT_REGISTERED", "Custom event nie jest zarejestrowany")
		}
	}

	function validateRewards(content, result) {
		local rewards = "rewards" in content ? content.rewards : []
		if (!phoenix.quest.Schema.isArray(rewards)) { phoenix.quest.Validator.issue(result, "rewards", "", "INVALID_REWARDS", "Nagrody muszą być tablicą"); return }
		local keys = {}
		local choiceGroup = ""
		local choiceCount = 0
		foreach (index, reward in rewards) {
			local path = "rewards[" + index + "]"
			if (!phoenix.quest.Schema.isTable(reward)) { phoenix.quest.Validator.issue(result, path, "", "INVALID_REWARD", "Nagroda musi być obiektem"); continue }
			local key = phoenix.quest.Validator.hasValue(reward, "key") ? reward.key.tostring() : ""
			local typeName = phoenix.quest.Validator.hasValue(reward, "type") ? reward.type.tostring() : ""
			if (!phoenix.quest.Schema.isKey(key)) phoenix.quest.Validator.issue(result, path + ".key", key, "INVALID_REWARD_KEY", "Nagroda wymaga stabilnego klucza")
			else if (key in keys) phoenix.quest.Validator.issue(result, path + ".key", key, "DUPLICATE_REWARD_KEY", "Klucz nagrody nie jest unikalny")
			else keys[key] <- true
			if ("choiceGroup" in reward && reward.choiceGroup != null && reward.choiceGroup.tostring() != "") {
				local group = reward.choiceGroup.tostring()
				choiceCount += 1
				if (!phoenix.quest.Schema.isKey(group)) phoenix.quest.Validator.issue(result, path + ".choiceGroup", key, "INVALID_REWARD_CHOICE_GROUP", "Grupa wyboru ma nieprawidłowy klucz")
				else if (choiceGroup != "" && choiceGroup != group) phoenix.quest.Validator.issue(result, path + ".choiceGroup", key, "MULTIPLE_REWARD_CHOICE_GROUPS", "Quest może posiadać jedną grupę wyboru nagrody")
				else choiceGroup = group
				if (!("label" in reward) || reward.label == null || reward.label.tostring() == "") phoenix.quest.Validator.issue(result, path + ".label", key, "REWARD_CHOICE_LABEL_REQUIRED", "Wariant nagrody wymaga etykiety")
			}
			if (!(typeName in phoenix.quest.Registry.rewards)) { phoenix.quest.Validator.issue(result, path + ".type", key, "UNKNOWN_REWARD_TYPE", "Nieznany typ nagrody"); continue }
			if (typeName == phoenix.quest.RewardType.Experience || typeName == phoenix.quest.RewardType.Currency || typeName == phoenix.quest.RewardType.Item || typeName == phoenix.quest.RewardType.Statistic) {
				if (!("amount" in reward) || phoenix.quest.Schema.integer(reward.amount, 0) <= 0) phoenix.quest.Validator.issue(result, path + ".amount", key, "INVALID_REWARD_AMOUNT", "Ilość nagrody musi być dodatnia")
			}
			if (typeName == phoenix.quest.RewardType.Item && (!("instance" in reward) || reward.instance == null || phoenix.item.find(reward.instance.tostring().toupper()) == null)) phoenix.quest.Validator.issue(result, path + ".instance", key, "REWARD_ITEM_NOT_FOUND", "Przedmiot nagrody nie istnieje")
			if (typeName == phoenix.quest.RewardType.Statistic) {
				local stat = "stat" in reward && reward.stat != null ? reward.stat.tostring() : ""
				if (stat != "strength" && stat != "dexterity" && stat != "learnPoints" && stat != "hpMax" && stat != "manaMax") phoenix.quest.Validator.issue(result, path + ".stat", key, "INVALID_REWARD_STAT", "Nieobsługiwana statystyka nagrody")
			}
			if (typeName == phoenix.quest.RewardType.Flag && (!("key" in reward) || !phoenix.quest.Schema.isKey(reward.key))) phoenix.quest.Validator.issue(result, path + ".key", key, "INVALID_FLAG_KEY", "Nagroda flagi wymaga klucza")
		}
		if (choiceCount == 1) phoenix.quest.Validator.issue(result, "rewards", choiceGroup, "REWARD_CHOICE_REQUIRES_OPTIONS", "Grupa wyboru wymaga co najmniej dwóch wariantów")
		if (choiceCount > 0) {
			local hasTurnIn = false
			local stages = "stages" in content && phoenix.quest.Schema.isArray(content.stages) ? content.stages : []
			foreach (stage in stages) if (phoenix.quest.Schema.isTable(stage) && "terminal" in stage && stage.terminal == "success" && "turnInBindingKey" in stage && stage.turnInBindingKey != null && stage.turnInBindingKey.tostring() != "") hasTurnIn = true
			if (!hasTurnIn) phoenix.quest.Validator.issue(result, "rewards", choiceGroup, "REWARD_CHOICE_REQUIRES_TURN_IN", "Wybór nagrody wymaga końcowego oddania u NPC")
		}
	}

	function validateNpcBindings(content, result) {
		local bindings = ("npcBindings" in content) ? content.npcBindings : []
		if (!phoenix.quest.Schema.isArray(bindings)) { phoenix.quest.Validator.issue(result, "npcBindings", "", "INVALID_NPC_BINDINGS", "Bindingi NPC muszą być tablicą"); return }
		local keys = {}
		foreach (index, binding in bindings) {
			local path = "npcBindings[" + index + "]"
			if (!phoenix.quest.Schema.isTable(binding)) { phoenix.quest.Validator.issue(result, path, "", "INVALID_NPC_BINDING", "Binding NPC musi być obiektem"); continue }
			local key = phoenix.quest.Validator.hasValue(binding, "key") ? binding.key.tostring() : ""
			local role = phoenix.quest.Validator.hasValue(binding, "role") ? binding.role.tostring() : ""
			local refType = phoenix.quest.Validator.hasValue(binding, "refType") ? binding.refType.tostring() : ""
			local refValue = phoenix.quest.Validator.hasValue(binding, "refValue") ? binding.refValue.tostring() : ""
			if (!phoenix.quest.Schema.isKey(key)) phoenix.quest.Validator.issue(result, path + ".key", key, "INVALID_BINDING_KEY", "Nieprawidłowy klucz bindingu")
			else if (key in keys) phoenix.quest.Validator.issue(result, path + ".key", key, "DUPLICATE_BINDING_KEY", "Klucz bindingu nie jest unikalny")
			else keys[key] <- true
			local roleAllowed = false
			foreach (name, value in phoenix.quest.NpcRole) if (value == role) roleAllowed = true
			if (!roleAllowed) phoenix.quest.Validator.issue(result, path + ".role", key, "INVALID_NPC_ROLE", "Nieznana rola NPC")
			local refAllowed = false
			foreach (name, value in phoenix.quest.NpcRefType) if (value == refType) refAllowed = true
			if (!refAllowed) phoenix.quest.Validator.issue(result, path + ".refType", key, "INVALID_NPC_REF_TYPE", "Nieznany typ referencji NPC")
			if (refValue == "") phoenix.quest.Validator.issue(result, path + ".refValue", key, "NPC_REF_REQUIRED", "Brak referencji NPC")
			if ("markerOffset" in binding && binding.markerOffset != null && typeof binding.markerOffset != "integer" && typeof binding.markerOffset != "float") phoenix.quest.Validator.issue(result, path + ".markerOffset", key, "INVALID_MARKER_OFFSET", "Offset markera musi być liczbą")
		}
	}

	function validateStageBindings(content, stageMap, result) {
		local bindingsByKey = {}
		local bindings = ("npcBindings" in content && phoenix.quest.Schema.isArray(content.npcBindings)) ? content.npcBindings : []
		foreach (binding in bindings) if (phoenix.quest.Schema.isTable(binding) && "key" in binding) bindingsByKey[binding.key.tostring()] <- binding
		foreach (stageKey, stage in stageMap) {
			if ("turnInBindingKey" in stage && stage.turnInBindingKey != null && stage.turnInBindingKey.tostring() != "") {
				local bindingKey = stage.turnInBindingKey.tostring()
				if (!(bindingKey in bindingsByKey)) phoenix.quest.Validator.issue(result, "stages." + stageKey + ".turnInBindingKey", stageKey, "MISSING_TURN_IN_BINDING", "Binding NPC oddania nie istnieje")
				else {
					local role = phoenix.quest.Validator.hasValue(bindingsByKey[bindingKey], "role") ? bindingsByKey[bindingKey].role.tostring() : ""
					if (role != phoenix.quest.NpcRole.TurnIn && role != phoenix.quest.NpcRole.Giver) phoenix.quest.Validator.issue(result, "stages." + stageKey + ".turnInBindingKey", stageKey, "INVALID_TURN_IN_ROLE", "Oddanie wymaga NPC w roli turn_in albo giver")
				}
			}
			if ("markerBindings" in stage && phoenix.quest.Schema.isArray(stage.markerBindings)) foreach (index, marker in stage.markerBindings) {
				local markerPath = "stages." + stageKey + ".markerBindings[" + index + "]"
				if (!phoenix.quest.Schema.isTable(marker) || !("bindingKey" in marker) || !(marker.bindingKey.tostring() in bindingsByKey)) phoenix.quest.Validator.issue(result, markerPath, stageKey, "MISSING_MARKER_BINDING", "Binding markera nie istnieje")
				local markerType = phoenix.quest.Validator.hasValue(marker, "markerType") ? marker.markerType.tostring() : "continue"
				if (markerType != "continue" && markerType != "turn_in") phoenix.quest.Validator.issue(result, markerPath + ".markerType", stageKey, "INVALID_MARKER_TYPE", "Nieobsługiwany typ markera")
			}
		}
	}

	function validateNpcReferences(content, result) {
		local bindings = ("npcBindings" in content && phoenix.quest.Schema.isArray(content.npcBindings)) ? content.npcBindings : []
		foreach (index, binding in bindings) {
			if (!phoenix.quest.Schema.isTable(binding) || !("refType" in binding) || !("refValue" in binding)) continue
			local refType = binding.refType.tostring()
			local refValue = binding.refValue.tostring()
			local path = "npcBindings[" + index + "].refValue"
			local bindingKey = ("key" in binding) ? binding.key.tostring() : ""
			if (refType == phoenix.quest.NpcRefType.Preset) {
				local presetId = phoenix.quest.Schema.integer(refValue, 0, 1)
				local found = false
				try {
					foreach (id, preset in phoenix.npc.Preset.cache) if (id.tointeger() == presetId || ("id" in preset && preset.id.tointeger() == presetId)) found = true
				} catch (error) {}
				if (!found) phoenix.quest.Validator.issue(result, path, bindingKey, "NPC_REFERENCE_NOT_FOUND", "Preset NPC nie istnieje")
				continue
			}
			if (refType == phoenix.quest.NpcRefType.Spawn) {
				local spawnId = phoenix.quest.Schema.integer(refValue, 0, 1)
				local rows = ORM.engine.execute("SELECT COUNT(*) AS total FROM `phoenix_npc_spawns` WHERE `id`=" + spawnId)
				if (rows == null || rows.len() == 0 || rows[0].total.tointeger() != 1) phoenix.quest.Validator.issue(result, path, bindingKey, "NPC_REFERENCE_NOT_FOUND", "Spawn NPC nie istnieje")
				continue
			}
			if (refType == phoenix.quest.NpcRefType.Instance || refType == phoenix.quest.NpcRefType.Tag) {
				local column = refType == phoenix.quest.NpcRefType.Instance ? "instance" : "tag"
				local rows = ORM.engine.execute("SELECT COUNT(*) AS total FROM `phoenix_npc_spawns` WHERE `" + column + "`='" + phoenix.quest.Repository.escape(refValue) + "'")
				local total = rows != null && rows.len() > 0 ? rows[0].total.tointeger() : 0
				if (total == 0) phoenix.quest.Validator.issue(result, path, bindingKey, "NPC_REFERENCE_NOT_FOUND", "Referencja NPC nie istnieje")
				else if (total > 1) phoenix.quest.Validator.issue(result, path, bindingKey, "NPC_REFERENCE_AMBIGUOUS", "Referencja NPC wskazuje więcej niż jeden spawn")
			}
		}
	}

	function walkDialogCycle(key, nodeMap, graph, path, visited, visiting, reported, result) {
		if (key in visiting || !(key in nodeMap)) return
		visiting[key] <- true
		local node = nodeMap[key]
		local choices = ("choices" in node && phoenix.quest.Schema.isArray(node.choices)) ? node.choices : []
		foreach (choice in choices) {
			if (!phoenix.quest.Schema.isTable(choice) || !phoenix.quest.Validator.hasValue(choice, "target") || choice.target.tostring() == "") continue
			local target = choice.target.tostring()
			if (!(target in nodeMap)) continue
			if (target in visiting) {
				local allowed = ("allowCycle" in graph && graph.allowCycle == true) || ("allowCycle" in node && node.allowCycle == true) || ("allowCycle" in choice && choice.allowCycle == true) || ("allowCycle" in nodeMap[target] && nodeMap[target].allowCycle == true)
				local cycleKey = key + ":" + target
				if (!allowed && !(cycleKey in reported)) {
					reported[cycleKey] <- true
					phoenix.quest.Validator.issue(result, path + ".nodes." + key + ".choices", key, "DISALLOWED_DIALOG_CYCLE", "Cykl dialogu wymaga jawnego allowCycle")
				}
			} else if (!(target in visited)) phoenix.quest.Validator.walkDialogCycle(target, nodeMap, graph, path, visited, visiting, reported, result)
		}
		visiting.rawdelete(key)
		visited[key] <- true
	}

	function validateDialogCycles(graph, nodeMap, path, result) {
		local visited = {}
		local visiting = {}
		local reported = {}
		foreach (key, node in nodeMap) if (!(key in visited)) phoenix.quest.Validator.walkDialogCycle(key, nodeMap, graph, path, visited, visiting, reported, result)
	}

	function validateDialogs(content, result) {
		local graphs = ("dialogGraphs" in content) ? content.dialogGraphs : []
		if (!phoenix.quest.Schema.isArray(graphs)) { phoenix.quest.Validator.issue(result, "dialogGraphs", "", "INVALID_DIALOG_GRAPHS", "Grafy dialogów muszą być tablicą"); return }
		local graphKeys = {}
		local graphRoutes = {}
		local bindingMap = {}
		local bindings = ("npcBindings" in content && phoenix.quest.Schema.isArray(content.npcBindings)) ? content.npcBindings : []
		foreach (binding in bindings) if (phoenix.quest.Schema.isTable(binding) && "key" in binding) bindingMap[binding.key.tostring()] <- binding
		foreach (graphIndex, graph in graphs) {
			local path = "dialogGraphs[" + graphIndex + "]"
			if (!phoenix.quest.Schema.isTable(graph)) { phoenix.quest.Validator.issue(result, path, "", "INVALID_DIALOG_GRAPH", "Graf dialogu musi być obiektem"); continue }
			local graphKey = phoenix.quest.Validator.hasValue(graph, "key") ? graph.key.tostring() : ""
			if (!phoenix.quest.Schema.isKey(graphKey)) phoenix.quest.Validator.issue(result, path + ".key", graphKey, "INVALID_DIALOG_GRAPH_KEY", "Graf dialogu wymaga stabilnego klucza")
			else if (graphKey in graphKeys) phoenix.quest.Validator.issue(result, path + ".key", graphKey, "DUPLICATE_DIALOG_GRAPH_KEY", "Klucz grafu dialogu nie jest unikalny")
			else graphKeys[graphKey] <- true
			local bindingKey = phoenix.quest.Validator.hasValue(graph, "bindingKey") ? graph.bindingKey.tostring() : ""
			if (!(bindingKey in bindingMap)) phoenix.quest.Validator.issue(result, path + ".bindingKey", graphKey, "MISSING_DIALOG_BINDING", "Binding NPC grafu dialogu nie istnieje")
			local mode = phoenix.quest.Validator.hasValue(graph, "mode") ? graph.mode.tostring() : ""
			if (mode != "start" && mode != "continue" && mode != "turn_in") phoenix.quest.Validator.issue(result, path + ".mode", graphKey, "INVALID_DIALOG_MODE", "Nieobsługiwany tryb grafu dialogu")
			else if (bindingKey in bindingMap) {
				local role = phoenix.quest.Validator.hasValue(bindingMap[bindingKey], "role") ? bindingMap[bindingKey].role.tostring() : ""
				if (mode == "start" && role != phoenix.quest.NpcRole.Giver) phoenix.quest.Validator.issue(result, path + ".bindingKey", graphKey, "INVALID_DIALOG_BINDING_ROLE", "Dialog startowy wymaga NPC w roli giver")
				if (mode == "turn_in" && role != phoenix.quest.NpcRole.Giver && role != phoenix.quest.NpcRole.TurnIn) phoenix.quest.Validator.issue(result, path + ".bindingKey", graphKey, "INVALID_DIALOG_BINDING_ROLE", "Dialog oddania wymaga NPC w roli giver albo turn_in")
			}
			local routeKey = bindingKey + ":" + mode
			if (bindingKey != "" && mode != "") {
				if (routeKey in graphRoutes) phoenix.quest.Validator.issue(result, path, graphKey, "DUPLICATE_DIALOG_ROUTE", "NPC może posiadać tylko jeden dialog dla danego momentu questa")
				else graphRoutes[routeKey] <- true
			}
			local nodes = ("nodes" in graph) ? graph.nodes : []
			if (!phoenix.quest.Schema.isArray(nodes) || nodes.len() < 1) { phoenix.quest.Validator.issue(result, path + ".nodes", "", "DIALOG_NODES_REQUIRED", "Graf dialogu wymaga węzłów"); continue }
			if (nodes.len() > phoenix.quest.Schema.Limits.DialogNodes) phoenix.quest.Validator.issue(result, path + ".nodes", "", "TOO_MANY_DIALOG_NODES", "Przekroczono limit węzłów dialogu")
			local nodeMap = {}
			foreach (nodeIndex, node in nodes) {
				local nodePath = path + ".nodes[" + nodeIndex + "]"
				if (!phoenix.quest.Schema.isTable(node)) { phoenix.quest.Validator.issue(result, nodePath, "", "INVALID_DIALOG_NODE", "Węzeł dialogu musi być obiektem"); continue }
				local key = phoenix.quest.Validator.hasValue(node, "key") ? node.key.tostring() : ""
				if (!phoenix.quest.Schema.isKey(key)) phoenix.quest.Validator.issue(result, nodePath + ".key", key, "INVALID_DIALOG_NODE_KEY", "Nieprawidłowy klucz węzła")
				else if (key in nodeMap) phoenix.quest.Validator.issue(result, nodePath + ".key", key, "DUPLICATE_DIALOG_NODE_KEY", "Klucz węzła nie jest unikalny")
				else nodeMap[key] <- node
				local speaker = phoenix.quest.Validator.hasValue(node, "speaker") ? node.speaker.tostring() : "npc"
				if (speaker != "npc" && speaker != "player") phoenix.quest.Validator.issue(result, nodePath + ".speaker", key, "INVALID_DIALOG_SPEAKER", "Mówca musi być npc albo player")
				if (phoenix.quest.Validator.hasValue(node, "text") && node.text.tostring().len() > phoenix.quest.Schema.Limits.Description) phoenix.quest.Validator.issue(result, nodePath + ".text", key, "DIALOG_TEXT_TOO_LONG", "Tekst dialogu przekracza limit")
			}
			local start = phoenix.quest.Validator.hasValue(graph, "startNodeKey") ? graph.startNodeKey.tostring() : ""
			if (!(start in nodeMap)) phoenix.quest.Validator.issue(result, path + ".startNodeKey", start, "INVALID_DIALOG_START", "Początkowy węzeł dialogu nie istnieje")
			foreach (key, node in nodeMap) {
				local choices = []
				if ("choices" in node && !phoenix.quest.Schema.isArray(node.choices)) phoenix.quest.Validator.issue(result, path + ".nodes." + key + ".choices", key, "INVALID_DIALOG_CHOICES", "Odpowiedzi dialogowe muszą być tablicą")
				else if ("choices" in node) choices = node.choices
				if (choices.len() < 1) phoenix.quest.Validator.issue(result, path + ".nodes." + key + ".choices", key, "DIALOG_CHOICES_REQUIRED", "Wypowiedź dialogowa wymaga co najmniej jednej odpowiedzi")
				local choiceKeys = {}
				foreach (choiceIndex, choice in choices) {
					local choicePath = path + ".nodes." + key + ".choices[" + choiceIndex + "]"
					if (!phoenix.quest.Schema.isTable(choice)) { phoenix.quest.Validator.issue(result, choicePath, key, "INVALID_DIALOG_CHOICE", "Odpowiedź dialogowa musi być obiektem"); continue }
					local choiceKey = phoenix.quest.Validator.hasValue(choice, "key") ? choice.key.tostring() : ""
					if (!phoenix.quest.Schema.isKey(choiceKey)) phoenix.quest.Validator.issue(result, choicePath + ".key", key, "INVALID_DIALOG_CHOICE_KEY", "Nieprawidłowy klucz odpowiedzi")
					else if (choiceKey in choiceKeys) phoenix.quest.Validator.issue(result, choicePath + ".key", key, "DUPLICATE_DIALOG_CHOICE_KEY", "Klucz odpowiedzi nie jest unikalny")
					else choiceKeys[choiceKey] <- true
					if (phoenix.quest.Validator.hasValue(choice, "text") && choice.text.tostring().len() > phoenix.quest.Schema.Limits.Title) phoenix.quest.Validator.issue(result, choicePath + ".text", key, "DIALOG_CHOICE_TEXT_TOO_LONG", "Tekst odpowiedzi przekracza limit")
					local target = phoenix.quest.Validator.hasValue(choice, "target") ? choice.target.tostring() : ""
					if (target != "" && !(target in nodeMap)) phoenix.quest.Validator.issue(result, choicePath + ".target", key, "MISSING_DIALOG_TARGET", "Cel odpowiedzi nie istnieje")
					phoenix.quest.Validator.validateCondition(("condition" in choice) ? choice.condition : null, choicePath + ".condition", result)
					local actions = []
					if ("actions" in choice && !phoenix.quest.Schema.isArray(choice.actions)) phoenix.quest.Validator.issue(result, choicePath + ".actions", key, "INVALID_DIALOG_ACTIONS", "Akcje dialogowe muszą być tablicą")
					else if ("actions" in choice) actions = choice.actions
					foreach (actionIndex, action in actions) {
						local actionPath = choicePath + ".actions[" + actionIndex + "]"
						if (!phoenix.quest.Schema.isTable(action)) { phoenix.quest.Validator.issue(result, actionPath, key, "INVALID_DIALOG_ACTION", "Akcja dialogowa musi być obiektem"); continue }
						local actionType = phoenix.quest.Validator.hasValue(action, "type") ? action.type.tostring() : ""
						if (actionType != "event" && actionType != "setFlag" && actionType != "deliver") phoenix.quest.Validator.issue(result, actionPath, key, "UNKNOWN_DIALOG_ACTION", "Nieznana akcja dialogowa")
						if (actionType == "event") {
							local eventName = phoenix.quest.Validator.hasValue(action, "eventName") ? action.eventName.tostring() : ""
							if (!phoenix.quest.Schema.isKey(eventName) || !(eventName in phoenix.quest.Registry.events)) phoenix.quest.Validator.issue(result, actionPath + ".eventName", key, "CUSTOM_EVENT_NOT_REGISTERED", "Event akcji nie jest zarejestrowany")
						}
						if (actionType == "setFlag" && (!phoenix.quest.Validator.hasValue(action, "key") || !phoenix.quest.Schema.isKey(action.key))) phoenix.quest.Validator.issue(result, actionPath + ".key", key, "FLAG_KEY_REQUIRED", "Akcja flagi wymaga klucza")
						if (actionType == "deliver") {
							if (!phoenix.quest.Validator.hasValue(action, "instance") || action.instance.tostring() == "") phoenix.quest.Validator.issue(result, actionPath + ".instance", key, "DELIVER_INSTANCE_REQUIRED", "Akcja dostarczenia wymaga przedmiotu")
							else if (phoenix.item.find(action.instance.tostring().toupper()) == null) phoenix.quest.Validator.issue(result, actionPath + ".instance", key, "ITEM_NOT_FOUND", "Instancja przedmiotu nie istnieje")
							if ("amount" in action && phoenix.quest.Schema.integer(action.amount, 0) <= 0) phoenix.quest.Validator.issue(result, actionPath + ".amount", key, "INVALID_DELIVER_AMOUNT", "Ilość dostarczanego przedmiotu musi być dodatnia")
						}
					}
				}
			}
			if (start in nodeMap) {
				local visited = {}
				local queue = [start]
				while (queue.len() > 0) {
					local key = queue.remove(0)
					if (key in visited || !(key in nodeMap)) continue
					visited[key] <- true
					local choices = ("choices" in nodeMap[key] && phoenix.quest.Schema.isArray(nodeMap[key].choices)) ? nodeMap[key].choices : []
					foreach (choice in choices) if (phoenix.quest.Schema.isTable(choice) && phoenix.quest.Validator.hasValue(choice, "target") && choice.target.tostring() != "") queue.append(choice.target.tostring())
				}
				foreach (key, node in nodeMap) if (!(key in visited)) phoenix.quest.Validator.issue(result, path + ".nodes." + key, key, "UNREACHABLE_DIALOG_NODE", "Węzeł dialogu jest nieosiągalny")
			}
			phoenix.quest.Validator.validateDialogCycles(graph, nodeMap, path, result)
		}
	}
}