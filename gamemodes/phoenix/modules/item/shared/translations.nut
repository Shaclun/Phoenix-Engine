phoenix.item.Translations <- {}

phoenix.item.registerTranslations <- function (instance, labels, descriptions = null) {
	if (instance == null || instance == "") return
	local key = instance.toupper()
	local scheme = phoenix.item.find(key)
	if (scheme == null) return
	if (labels != null) {
		local l = { pl = "", en = "", de = "", ru = "" }
		if ("pl" in labels && labels.pl != null) l.pl = labels.pl.tostring()
		if ("en" in labels && labels.en != null) l.en = labels.en.tostring()
		if ("de" in labels && labels.de != null) l.de = labels.de.tostring()
		if ("ru" in labels && labels.ru != null) l.ru = labels.ru.tostring()
		scheme.labels = l
		if (l.pl != "") scheme.name = l.pl
	}
	if (descriptions != null) {
		local d = { pl = "", en = "", de = "", ru = "" }
		if ("pl" in descriptions && descriptions.pl != null) d.pl = descriptions.pl.tostring()
		if ("en" in descriptions && descriptions.en != null) d.en = descriptions.en.tostring()
		if ("de" in descriptions && descriptions.de != null) d.de = descriptions.de.tostring()
		if ("ru" in descriptions && descriptions.ru != null) d.ru = descriptions.ru.tostring()
		scheme.descriptions = d
		if (d.pl != "") scheme.description = d.pl
	}
}

phoenix.item.translateRow <- function (row, lang) {
	if (row == null) return ""
	local code = lang != null ? lang.tostring() : "pl"
	if (code == "en" && "en" in row && row.en != null && row.en != "") return row.en
	if (code == "de" && "de" in row && row.de != null && row.de != "") return row.de
	if (code == "ru" && "ru" in row && row.ru != null && row.ru != "") return row.ru
	if ("pl" in row && row.pl != null && row.pl != "") return row.pl
	return ""
}

phoenix.item.labelFor <- function (instance, lang) {
	if (instance == null || instance == "") return ""
	local s = phoenix.item.find(instance)
	if (s == null) return instance
	try { return s.labelFor(lang) } catch (e) {}
	return s.name != null && s.name != "" ? s.name : instance
}

phoenix.item.descriptionFor <- function (instance, lang) {
	if (instance == null || instance == "") return ""
	local s = phoenix.item.find(instance)
	if (s == null) return ""
	try { return s.descriptionFor(lang) } catch (e) {}
	return s.description != null ? s.description : ""
}
