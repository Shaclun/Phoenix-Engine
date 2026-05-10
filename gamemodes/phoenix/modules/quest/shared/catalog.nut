phoenix.quest.Catalog <- {
	byCode = {}
}

phoenix.quest.register <- function (code, def) {
	if (code == null || code == "") return
	def.code <- code
	if (!("title" in def)) def.title <- code
	if (!("description" in def)) def.description <- ""
	if (!("type" in def)) def.type <- phoenix.quest.Type.Talk
	if (!("giverInstance" in def)) def.giverInstance <- ""
	if (!("payload" in def)) def.payload <- {}
	phoenix.quest.Catalog.byCode[code] <- def
}

phoenix.quest.find <- function (code) {
	if (code in phoenix.quest.Catalog.byCode) return phoenix.quest.Catalog.byCode[code]
	return null
}

phoenix.quest.all <- function () {
	local out = []
	foreach (c, q in phoenix.quest.Catalog.byCode) out.append(q)
	return out
}
