

phoenix.item.Quality.LABELS <- {
	[PhoenixItemQuality.Terrible]    = "Beznadziejny",
	[PhoenixItemQuality.Poor]        = "Kiepski",
	[PhoenixItemQuality.Common]      = "Zwykly",
	[PhoenixItemQuality.Fine]        = "Dobry",
	[PhoenixItemQuality.Exquisite]   = "Wysmienity",
	[PhoenixItemQuality.Magnificent] = "Wspanialy"
}

phoenix.item.Quality.COLORS <- {
	[PhoenixItemQuality.Terrible]    = "#7a7a7a",
	[PhoenixItemQuality.Poor]        = "#a0a0a0",
	[PhoenixItemQuality.Common]      = "#ffffff",
	[PhoenixItemQuality.Fine]        = "#5dd05d",
	[PhoenixItemQuality.Exquisite]   = "#5d9ce8",
	[PhoenixItemQuality.Magnificent] = "#e0a23c"
}

phoenix.item.Quality.MULTIPLIERS <- {
	[PhoenixItemQuality.Terrible]    = 0.65,
	[PhoenixItemQuality.Poor]        = 0.85,
	[PhoenixItemQuality.Common]      = 1.00,
	[PhoenixItemQuality.Fine]        = 1.10,
	[PhoenixItemQuality.Exquisite]   = 1.25,
	[PhoenixItemQuality.Magnificent] = 1.45
}

phoenix.item.Quality.ROLL_WEIGHTS <- {
	[PhoenixItemQuality.Terrible]    = 80,
	[PhoenixItemQuality.Poor]        = 200,
	[PhoenixItemQuality.Common]      = 460,
	[PhoenixItemQuality.Fine]        = 180,
	[PhoenixItemQuality.Exquisite]   = 65,
	[PhoenixItemQuality.Magnificent] = 15
}

phoenix.item.Quality.getMultiplier <- function(quality) {
	if (quality in phoenix.item.Quality.MULTIPLIERS)
		return phoenix.item.Quality.MULTIPLIERS[quality]
	return 1.0
}

phoenix.item.Quality.getLabel <- function(quality) {
	if (quality in phoenix.item.Quality.LABELS)
		return phoenix.item.Quality.LABELS[quality]
	return "?"
}

phoenix.item.Quality.getColor <- function(quality) {
	if (quality in phoenix.item.Quality.COLORS)
		return phoenix.item.Quality.COLORS[quality]
	return "#ffffff"
}

phoenix.item.Quality.roll <- function() {
	local total = 0
	foreach (_k, w in phoenix.item.Quality.ROLL_WEIGHTS) total += w
	if (total <= 0) return PhoenixItemQuality.Common
	local r = rand() % total
	local acc = 0
	foreach (k, w in phoenix.item.Quality.ROLL_WEIGHTS) {
		acc += w
		if (r < acc) return k
	}
	return PhoenixItemQuality.Common
}

phoenix.item.Quality.isValid <- function(quality) {
	return quality in phoenix.item.Quality.MULTIPLIERS
}
