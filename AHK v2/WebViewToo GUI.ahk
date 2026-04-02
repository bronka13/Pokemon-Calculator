/*
    Title: WebViewToo GUI
    Version: 0.1
    Created: Mar 28, 2026
*/

#Include <WebViewToo>
#Include Sprite Setup.ahk
#Include <JSON>

;{ Functions
ArrayToCSV(arr) {
    str := ""
    for item in arr
        str .= item ","
    return RTrim(str, ",")
}
;}

pCalc := WebViewGui("+Resize",,)
pCalc.Navigate("file:///" A_ScriptDir "\..\WebViewGui\index.html")
pCalc.Show("w840 h640")
pCalc.DOMContentLoaded(OnLoaded)
pCalc.WebMessageReceived(OnJSMessage)

OnLoaded(wv, *) {
    try {
        tarID := pkmnDataAPI[ctx.tar.name].id
        meID := pkmnDataAPI[ctx.me.name].id
        tarSpriteURL := baseURL genURL[player.gen] gameURL[player.game] typeURL["front_default"] tarID ".png"
        meSpriteURL := baseURL genURL[player.gen] gameURL[player.game] typeURL["back_default"] meID ".png"
        pCalc.ExecuteScriptAsync("updateTarSprite('" tarSpriteURL "')")
        pCalc.ExecuteScriptAsync("updateMeSprite('" meSpriteURL "')")   
    }
}


OnJSMessage(wv, info) {
    try {
        rawJson := info.WebMessageAsJson
        data := JSON.Load(rawJson)
        action := data["action"]

        if (action == "UpdateGameContext") {
            if (data["game"] == "")
                return

            player.game := data["game"]
            player.gen := gameGen[data["game"]]

            listT := GetGuiTargetList()
            pCalc.ExecuteScriptAsync("updateTargetSelect('" ArrayToCSV(listT) "')")

            listB := GetGuiBallList()
            ballString := ArrayToCSV(listB)
            pCalc.ExecuteScriptAsync("updateBallSelect(`"" ballString "`")")

            listM := GetGuiMeList()
            pCalc.ExecuteScriptAsync("updateMeSelect('" ArrayToCSV(listM) "')")

            ; 3. Atualiza os Sprites Iniciais
            ; Target (Pega o primeiro da lista nova)
            idTar := pkmnDataAPI[listT[1]].id
            tarURL := baseURL genURL[player.gen] gameURL[player.game] typeURL["front_default"] idTar ".png"
            pCalc.ExecuteScriptAsync("updateTarSprite('" tarURL "')")

            ; Me (Pega o seu atual)
            idMe := pkmnDataAPI[ctx.me.name].id
            meURL := baseURL genURL[player.gen] gameURL[player.game] typeURL["back_default"] idMe ".png"
            pCalc.ExecuteScriptAsync("updateMeSprite('" meURL "')")
        }

        if (action == "UpdateSprite") {
            pkmnName := data["name"]

            if (pkmnName == "" || !pkmnDataAPI.Has(pkmnName))
                return

            id := pkmnDataAPI[pkmnName].id
            tarSpriteURL := baseURL genURL[player.gen] gameURL[player.game] typeURL["front_default"] id ".png"

            pCalc.ExecuteScriptAsync("updateTarSprite('" tarSpriteURL "')")
        }

        if (action == "RunThrow") {
            tarObj := target(data["tarName"], data["tarStatus"], {level: data["tarLvl"], gender: data["tarGender"]})
            meObj := me(data["myName"], data["myLvl"], data["myGender"])
            batObj := battle("single", data["encounter"])
            locObj := location(data["locName"], data["locType"], data["isLit"])

            global ctx := context(tarObj, meObj, batObj, locObj)

            ctx.tar.statsBattle["HP"] := Floor((ctx.tar.stats["HP"] * data["HPper"]) / 100)

            result := calcSelector[player.gen](data["ball"], ctx)

            wv.ExecuteScriptAsync("alert('" result "')")
        }


    } catch Error as e {
        MsgBox("Erro na linha: " e.Line "`nO que houve: " e.Message "`n`nJSON: " rawJson)
    }
}



