phoenix.web.Json <- {
	function encode(value) {
		return phoenix.web.Json._enc(value)
	}

	function parse(text) {
		if (text == null || typeof text != "string") return null
		local state = { src = text, pos = 0 }
		phoenix.web.Json._skip(state)
		local result = phoenix.web.Json._parse(state)
		return result
	}

	function _enc(v) {
		if (v == null) return "null"
		local t = typeof v
		if (t == "bool") return v ? "true" : "false"
		if (t == "integer" || t == "float") return v.tostring()
		if (t == "string") return phoenix.web.Json._encStr(v)
		if (t == "array") {
			local out = "["
			for (local i = 0; i < v.len(); i++) {
				if (i > 0) out += ","
				out += phoenix.web.Json._enc(v[i])
			}
			return out + "]"
		}
		if (t == "table") {
			local out = "{"
			local first = true
			foreach (k, val in v) {
				if (!first) out += ","
				first = false
				out += phoenix.web.Json._encStr(k.tostring()) + ":" + phoenix.web.Json._enc(val)
			}
			return out + "}"
		}
		return "null"
	}

	function _encStr(s) {
		local out = "\""
		for (local i = 0; i < s.len(); i++) {
			local c = phoenix.web.Json._byteAt(s, i)
			if (c == '"') out += "\\\""
			else if (c == '\\') out += "\\\\"
			else if (c == '\n') out += "\\n"
			else if (c == '\r') out += "\\r"
			else if (c == '\t') out += "\\t"
			else if (c < 0x20) out += format("\\u%04x", c)
			else if (c < 0x80) out += s.slice(i, i + 1)
			else {
				local decoded = phoenix.web.Json._decodeUtf8At(s, i)
				if (decoded.next > i) {
					out += phoenix.web.Json._unicodeEscape(decoded.code)
					i = decoded.next - 1
				} else out += "?"
			}
		}
		return out + "\""
	}

	function _byteAt(s, index) {
		local value = s[index]
		if (value < 0) value += 256
		return value
	}

	function _decodeUtf8At(s, index) {
		local a = phoenix.web.Json._byteAt(s, index)
		if (a < 0x80) return { code = a, next = index + 1 }
		if (a >= 0xC2 && a <= 0xDF && index + 1 < s.len()) {
			local b = phoenix.web.Json._byteAt(s, index + 1)
			if (b >= 0x80 && b <= 0xBF) return { code = ((a & 0x1F) << 6) | (b & 0x3F), next = index + 2 }
		}
		if (a >= 0xE0 && a <= 0xEF && index + 2 < s.len()) {
			local b = phoenix.web.Json._byteAt(s, index + 1)
			local c = phoenix.web.Json._byteAt(s, index + 2)
			if (b >= 0x80 && b <= 0xBF && c >= 0x80 && c <= 0xBF) return { code = ((a & 0x0F) << 12) | ((b & 0x3F) << 6) | (c & 0x3F), next = index + 3 }
		}
		if (a >= 0xF0 && a <= 0xF4 && index + 3 < s.len()) {
			local b = phoenix.web.Json._byteAt(s, index + 1)
			local c = phoenix.web.Json._byteAt(s, index + 2)
			local d = phoenix.web.Json._byteAt(s, index + 3)
			if (b >= 0x80 && b <= 0xBF && c >= 0x80 && c <= 0xBF && d >= 0x80 && d <= 0xBF) return { code = ((a & 0x07) << 18) | ((b & 0x3F) << 12) | ((c & 0x3F) << 6) | (d & 0x3F), next = index + 4 }
		}
		return { code = 0x3F, next = index + 1 }
	}

	function _unicodeEscape(code) {
		if (code <= 0xFFFF) return format("\\u%04x", code)
		local value = code - 0x10000
		local high = 0xD800 + ((value >> 10) & 0x3FF)
		local low = 0xDC00 + (value & 0x3FF)
		return format("\\u%04x\\u%04x", high, low)
	}

	function _skip(s) {
		while (s.pos < s.src.len()) {
			local c = s.src[s.pos]
			if (c == ' ' || c == '\t' || c == '\n' || c == '\r') s.pos++
			else break
		}
	}

	function _parse(s) {
		phoenix.web.Json._skip(s)
		if (s.pos >= s.src.len()) return null
		local c = s.src[s.pos]
		if (c == '{') return phoenix.web.Json._parseObj(s)
		if (c == '[') return phoenix.web.Json._parseArr(s)
		if (c == '"') return phoenix.web.Json._parseStr(s)
		if (c == 't' || c == 'f') return phoenix.web.Json._parseBool(s)
		if (c == 'n') { s.pos += 4; return null }
		return phoenix.web.Json._parseNum(s)
	}

	function _parseObj(s) {
		local out = {}
		s.pos++
		phoenix.web.Json._skip(s)
		if (s.pos < s.src.len() && s.src[s.pos] == '}') { s.pos++; return out }
		while (s.pos < s.src.len()) {
			phoenix.web.Json._skip(s)
			local key = phoenix.web.Json._parseStr(s)
			phoenix.web.Json._skip(s)
			s.pos++
			local val = phoenix.web.Json._parse(s)
			out[key] <- val
			phoenix.web.Json._skip(s)
			if (s.pos < s.src.len() && s.src[s.pos] == ',') { s.pos++; continue }
			break
		}
		phoenix.web.Json._skip(s)
		if (s.pos < s.src.len()) s.pos++
		return out
	}

	function _parseArr(s) {
		local out = []
		s.pos++
		phoenix.web.Json._skip(s)
		if (s.pos < s.src.len() && s.src[s.pos] == ']') { s.pos++; return out }
		while (s.pos < s.src.len()) {
			out.push(phoenix.web.Json._parse(s))
			phoenix.web.Json._skip(s)
			if (s.pos < s.src.len() && s.src[s.pos] == ',') { s.pos++; continue }
			break
		}
		phoenix.web.Json._skip(s)
		if (s.pos < s.src.len()) s.pos++
		return out
	}

	function _parseStr(s) {
		s.pos++
		local out = ""
		while (s.pos < s.src.len()) {
			local c = s.src[s.pos]
			if (c == '"') { s.pos++; return out }
			if (c == '\\' && s.pos + 1 < s.src.len()) {
				local n = s.src[s.pos + 1]
				if (n == 'n') out += "\n"
				else if (n == 'r') out += "\r"
				else if (n == 't') out += "\t"
				else if (n == '"') out += "\""
				else if (n == '\\') out += "\\"
				else if (n == '/') out += "/"
				else out += s.src.slice(s.pos + 1, s.pos + 2)
				s.pos += 2
				continue
			}
			out += s.src.slice(s.pos, s.pos + 1)
			s.pos++
		}
		return out
	}

	function _parseBool(s) {
		if (s.src[s.pos] == 't') { s.pos += 4; return true }
		s.pos += 5
		return false
	}

	function _parseNum(s) {
		local start = s.pos
		local isFloat = false
		while (s.pos < s.src.len()) {
			local c = s.src[s.pos]
			if (c == '-' || c == '+' || (c >= '0' && c <= '9')) { s.pos++; continue }
			if (c == '.' || c == 'e' || c == 'E') { isFloat = true; s.pos++; continue }
			break
		}
		local num = s.src.slice(start, s.pos)
		return isFloat ? num.tofloat() : num.tointeger()
	}
}
