; Pokémon name normalizer
; Use: display := NormalizeName(rawName)

NormalizeName(apiName) {
    static special := Map(
        "nidoran-f",        "Nidoran♀",
        "nidoran-m",        "Nidoran♂",
        "mr-mime",          "Mr. Mime",
        "mr-mime-galar",    "Galarian Mr. Mime",
        "mime-jr",          "Mime Jr.",
        "farfetchd",        "Farfetch'd",
        "farfetchd-galar",  "Galarian Farfetch'd",
        "sirfetchd",        "Sirfetch'd",
        "ho-oh",            "Ho-Oh",
        "porygon-z",        "Porygon-Z",
        "jangmo-o",         "Jangmo-o",
        "hakamo-o",         "Hakamo-o",
        "kommo-o",          "Kommo-o",
        "kommo-o-totem",    "Totem Kommo-o",
        "type-null",        "Type: Null",
        "flabebe",          "Flabébé",
        "zygarde-10",       "Zygarde 10%",
        "zygarde-50",       "Zygarde 50%",
        "zygarde-complete", "Zygarde Complete")

    static regional := Map(
        "alola",  "Alolan",
        "galar",  "Galarian",
        "hisui",  "Hisuian",
        "paldea", "Paldean")

    if special.Has(apiName)
        return special[apiName]

    parts := StrSplit(apiName, "-")

    ; sufixo regional: "raichu-alola" → "Alolan Raichu"
    if parts.Length = 2 && regional.Has(parts[2]) {
        base := StrUpper(SubStr(parts[1], 1, 1)) SubStr(parts[1], 2)
        return regional[parts[2]] " " base
    }

    ; caso geral: capitaliza cada parte e une com espaço
    result := ""
    for part in parts
        result .= (result = "" ? "" : " ") StrUpper(SubStr(part, 1, 1)) SubStr(part, 2)
    return result
}