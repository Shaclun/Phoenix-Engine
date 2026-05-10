if (!("text" in phoenix)) phoenix.text <- {}

phoenix.text.Encoding <- {
	highBytes = "\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF"

	function byteAt(text, index) {
		local value = text[index]
		if (value < 0) value += 256
		return value
	}

	function byte(code) {
		if (code < 0) return ""
		if (code < 128) {
			try { return format("%c", code) } catch (e) { return "" }
		}
		if (code > 255) return ""
		local index = code - 128
		try { return phoenix.text.Encoding.highBytes.slice(index, index + 1) } catch (e2) {}
		return ""
	}

	function appendMapped(out, mapped, fallback) {
		if (mapped >= 0) return out + phoenix.text.Encoding.byte(mapped)
		return out + fallback
	}

	function toCp1250(text) {
		if (text == null) return ""
		local source = text.tostring()
		local out = ""
		local i = 0
		while (i < source.len()) {
			local a = phoenix.text.Encoding.byteAt(source, i)
			local b = (i + 1 < source.len()) ? phoenix.text.Encoding.byteAt(source, i + 1) : -1
			local mapped = -1

			if (a == 0xC3 && b == 0x93) mapped = 0xD3
			else if (a == 0xC3 && b == 0xB3) mapped = 0xF3
			else if (a == 0xC3 && b == 0x84) mapped = 0xC4
			else if (a == 0xC3 && b == 0xA4) mapped = 0xE4
			else if (a == 0xC3 && b == 0x96) mapped = 0xD6
			else if (a == 0xC3 && b == 0xB6) mapped = 0xF6
			else if (a == 0xC3 && b == 0x9C) mapped = 0xDC
			else if (a == 0xC3 && b == 0xBC) mapped = 0xFC
			else if (a == 0xC3 && b == 0x9F) mapped = 0xDF
			else if (a == 0xC4 && b == 0x84) mapped = 0xA5
			else if (a == 0xC4 && b == 0x85) mapped = 0xB9
			else if (a == 0xC4 && b == 0x86) mapped = 0xC6
			else if (a == 0xC4 && b == 0x87) mapped = 0xE6
			else if (a == 0xC4 && b == 0x98) mapped = 0xCA
			else if (a == 0xC4 && b == 0x99) mapped = 0xEA
			else if (a == 0xC5 && b == 0x81) mapped = 0xA3
			else if (a == 0xC5 && b == 0x82) mapped = 0xB3
			else if (a == 0xC5 && b == 0x83) mapped = 0xD1
			else if (a == 0xC5 && b == 0x84) mapped = 0xF1
			else if (a == 0xC5 && b == 0x9A) mapped = 0x8C
			else if (a == 0xC5 && b == 0x9B) mapped = 0x9C
			else if (a == 0xC5 && b == 0xB9) mapped = 0x8F
			else if (a == 0xC5 && b == 0xBA) mapped = 0x9F
			else if (a == 0xC5 && b == 0xBB) mapped = 0xAF
			else if (a == 0xC5 && b == 0xBC) mapped = 0xBF

			if (mapped >= 0) {
				out += phoenix.text.Encoding.byte(mapped)
				i += 2
			} else {
				out += source.slice(i, i + 1)
				i += 1
			}
		}
		return out
	}

	function toCp1252(text) {
		if (text == null) return ""
		local source = text.tostring()
		local out = ""
		local i = 0
		while (i < source.len()) {
			local a = phoenix.text.Encoding.byteAt(source, i)
			local b = (i + 1 < source.len()) ? phoenix.text.Encoding.byteAt(source, i + 1) : -1
			local mapped = -1
			if (a == 0xC3 && b >= 0x80 && b <= 0xBF) mapped = b + 0x40
			else if (a == 0xC2 && b >= 0x80 && b <= 0xBF) mapped = b
			if (mapped >= 0) {
				out += phoenix.text.Encoding.byte(mapped)
				i += 2
			} else {
				out += source.slice(i, i + 1)
				i += 1
			}
		}
		return out
	}

	function toCp1251(text) {
		if (text == null) return ""
		local source = text.tostring()
		local out = ""
		local i = 0
		while (i < source.len()) {
			local a = phoenix.text.Encoding.byteAt(source, i)
			local b = (i + 1 < source.len()) ? phoenix.text.Encoding.byteAt(source, i + 1) : -1
			local mapped = -1

			if (a == 0xD0 && b == 0x81) mapped = 0xA8
			else if (a == 0xD1 && b == 0x91) mapped = 0xB8
			else if (a == 0xD0 && b >= 0x90 && b <= 0xBF) mapped = b + 0x30
			else if (a == 0xD1 && b >= 0x80 && b <= 0x8F) mapped = b + 0x70
			else if (a == 0xD0 && b == 0x84) mapped = 0xAA
			else if (a == 0xD1 && b == 0x94) mapped = 0xBA
			else if (a == 0xD0 && b == 0x86) mapped = 0xB2
			else if (a == 0xD1 && b == 0x96) mapped = 0xB3
			else if (a == 0xD0 && b == 0x87) mapped = 0xAF
			else if (a == 0xD1 && b == 0x97) mapped = 0xBF
			else if (a == 0xD2 && b == 0x90) mapped = 0xA5
			else if (a == 0xD2 && b == 0x91) mapped = 0xB4

			if (mapped >= 0) {
				out += phoenix.text.Encoding.byte(mapped)
				i += 2
			} else {
				out += source.slice(i, i + 1)
				i += 1
			}
		}
		return out
	}

	function detectLang(text) {
		if (text == null) return "pl"
		local source = text.tostring()
		for (local i = 0; i + 1 < source.len(); i++) {
			local a = phoenix.text.Encoding.byteAt(source, i)
			if (a == 0xD0 || a == 0xD1 || a == 0xD2) return "ru"
		}
		return "pl"
	}

	function forLabel(text, lang = null) {
		if (text == null) return ""
		local code = lang != null ? lang.tostring() : phoenix.text.Encoding.detectLang(text)
		if (code == "ru") return phoenix.text.Encoding.toCp1251(text)
		if (code == "de") return phoenix.text.Encoding.toCp1252(text)
		return phoenix.text.Encoding.toCp1250(text)
	}
}