
if (!("lerp" in getroottable())) {
	::lerp <- function (a, b, t) { return a + (b - a) * t }
}
if (!("clamp" in getroottable())) {
	::clamp <- function (x, lo, hi) {
		if (x < lo) return lo
		if (x > hi) return hi
		return x
	}
}
