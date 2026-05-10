phoenix.character.Validator <- {
	MIN_NAME_LEN = 3
	MAX_NAME_LEN = 20
	NAME_PATTERN = "^[A-Za-z][A-Za-z'\\- ]+$"
	MAX_FACE = 255
	MAX_VOICE = 16

	function name(value) {
		if (typeof value != "string") return "phoenix.character.error.name.format"
		if (value.len() < MIN_NAME_LEN) return "phoenix.character.error.name.tooShort"
		if (value.len() > MAX_NAME_LEN) return "phoenix.character.error.name.tooLong"
		if (!regexp(NAME_PATTERN).match(value)) return "phoenix.character.error.name.format"
		return null
	}

	function gender(value) {
		if (value != PhoenixCharacterGender.Male && value != PhoenixCharacterGender.Female)
			return "phoenix.character.error.gender"
		return null
	}

	function klass(value) {
		switch (value) {
			case PhoenixCharacterClass.Paladin:
			case PhoenixCharacterClass.Mage:
			case PhoenixCharacterClass.Mercenary:
			case PhoenixCharacterClass.Hunter:
				return null
		}
		return "phoenix.character.error.klass"
	}

	function appearance(face, voice) {
		if (typeof face != "integer" || face < 0 || face > MAX_FACE)
			return "phoenix.character.error.face"
		if (typeof voice != "integer" || voice < 0 || voice > MAX_VOICE)
			return "phoenix.character.error.voice"
		return null
	}
}
