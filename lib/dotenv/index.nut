local function stripQuotes(str) {
  local len = str.len()

  if (len < 2) return str

  local first = str[0]
  local last = str[len - 1]

  if (first == last && ('"' == first || '\'' == first)) return str.slice(1, len - 1)

  return str
}

dotenv <- {
  _vars = {}
}

dotenv.get <- function(name) {
  return name in dotenv._vars ? dotenv._vars[name] : null
}

dotenv.getAll <- function() {
  return clone(dotenv._vars)
}

dotenv.init <- function(config = {}) {
  local fileName = "fileName" in config ? config.fileName : ".env"
  local verbose = "verbose" in config ? config.verbose : false

  try {
    local file = file(fileName, "r")

    local line = null
    local i = 1

    while (line = file.read()) {
      local pos = line.find("=")

      if (pos == null) {
        if (line[0] != '#' && verbose) {
          print("dotenv: Ignoring ill-formed assignment on line " + i + ": '" + line + "'")
        }
      } else {
        local name = strip(line.slice(0, pos))
        local value = stripQuotes(strip(line.slice(pos + 1)))
        dotenv._vars[name] <- value
      }

      ++i
    }

    file.close()
  } catch(e) {
    if (verbose) print("dotenv: File '" + fileName + "' not found")
  }
}
