/*
    Title: pCalc — AutoHotkey GUI
    Version: 1
    Created: Mar 27, 2026
*/


;{ GUI
PkmnCalc := Gui()
PkmnCalc.MarginX := 20, PkmnCalc.MarginY := 20

;{ Lists
guiGameList := [
    "red", "blue", "yellow",
    "gold", "silver", "crystal",
    "ruby", "sapphire", "emerald", "firered", "leafgreen", "colosseum", "xd",
    "diamond", "pearl", "platinum", "heartgold", "soulsilver",
    "black", "white", "black-2", "white-2",
    "x", "y", "omega-ruby", "alpha-sapphire",
    "sun", "moon", "ultra-sun", "ultra-moon",
]
guiStatusList := ["", "Paralyzed", "Poisoned", "Asleep", "Frozen", "Burned"]
guiGenderList := ["male", "female"]
guiEncounterList := ["grass", "tall grass", "surfing", "fishing", "underwater", "cave"]
guiLocationTypeList := ["route", "cave", "forest", "town", "building"]
genBalls := Map(
    1, gen1.balls,
    2, gen2.balls,
    3, gen3.balls,
    4, gen4.balls,
    5, gen5.balls,
    6, gen6.balls,
    7, gen7.balls)
calcSelector := Map(
    1, (ball, ctx) => gen1.Print(ball, ctx),
    2, (ball, ctx) => gen2.Print(ball, ctx),
    3, (ball, ctx) => gen3.Print(ball, ctx),
    4, (ball, ctx) => gen4.Print(ball, ctx),
    5, (ball, ctx) => gen5.Print(ball, ctx),
    6, (ball, ctx) => gen6.Print(ball, ctx),
    7, (ball, ctx) => gen7.Print(ball, ctx))
simSelector := Map(
    1, (ball, ctx) => gen1.Capture(ball, ctx),
    2, (ball, ctx) => gen2.Capture(ball, ctx),
    3, (ball, ctx) => gen3.Capture(ball, ctx),
    4, (ball, ctx) => gen4.Capture(ball, ctx),
    5, (ball, ctx) => gen5.Capture(ball, ctx),
    6, (ball, ctx) => gen6.Capture(ball, ctx),
    7, (ball, ctx) => gen7.Capture(ball, ctx))
;}

;{ Functions
GetGuiTargetList() {
    list := []
    for k, v in pkmnDataAPI {
        if (pkmnDataAPI[k].games.Has(player.game) && pkmnDataAPI[k].id < 10000)
            list.Push(k)
    }
    return list
}
GetGuiMeList() {
    list := []
    for k, v in pkmnDataAPI {
        if (pkmnDataAPI[k].generation <= player.gen && pkmnDataAPI[k].id < 10000)
            list.Push(k)
    }
    return list
}
GetGuiBallList() {
    list := []
    for k, v in genBalls[player.gen]
        list.Push(k)
    return list
}
;}

;{ GUI Elements
; Game Selector
PkmnCalc.Add("Text", "xm y+20", "Game:")
guiGame := PkmnCalc.Add("DDL", "x+10 yp-4", guiGameList)
guiGame.OnEvent("Change", UpdateGame)
UpdateGame(ctrl, *) {
    player.game := ctrl.Text
    player.gen := gameGen[player.game]

    guiTarget.Delete()
    guiTarget.Add(GetGuiTargetList())
    guiTarget.Choose(1)

    guiBall.Delete()
    guiBall.Add(GetGuiBallList())
    guiBall.Choose("Poké Ball")

    guiMyName.Delete()
    guiMyName.Add(GetGuiMeList())
    guiMyName.Choose("bulbasaur")
}

; Target Selector
PkmnCalc.Add("Text", "xm", "Target:")
guiTarget := PkmnCalc.Add("ComboBox", "x+10 yp-4", GetGuiTargetList())
    ; Level
    PkmnCalc.Add("Text", "xm", "Level:")
    guiTargetLevel := PkmnCalc.Add("Edit", "x+10 yp-4 w30 Right number Limit3 Range1-100", Random(1,50))
    ; Status
    PkmnCalc.Add("Text", "xm", "Status:")
    guiTargetStatus := PkmnCalc.Add("DDL", "x+10 yp-4 Choose1", guiStatusList)
    ; HPcur
    PkmnCalc.Add("Text", "xm", "Current HP:")
    guiHPper := PkmnCalc.Add("Slider", "x+10 yp-4 w150 Center Range1-100 ToolTip", "100")
    ; Gender
    PkmnCalc.Add("Text", "xm", "Gender:")
    guiTargetGender := PkmnCalc.Add("DDL", "x+10 yp-4 Choose1", guiGenderList)

; Me Selector
PkmnCalc.Add("Text", "xm", "Your Pokémon:")
guiMyName := PkmnCalc.Add("ComboBox", "x+10 yp-4", GetGuiMeList())
    ; Level
    PkmnCalc.Add("Text", "xm", "Level:")
    guiMyLevel := PkmnCalc.Add("Edit", "x+10 yp-4 w30 Right number Limit3 Range1-100", Random(1,50))
    ; Gender
    PkmnCalc.Add("Text", "xm", "Gender:")
    guiMyGender := PkmnCalc.Add("DDL", "x+10 yp-4 Choose1", guiGenderList)

; Battle Selector
PkmnCalc.Add("Text", "xm", "Encounter type:")
guiEncounter := PkmnCalc.Add("DDL", "x+10 yp-4 Choose1", guiEncounterList)
; Location Selector
PkmnCalc.Add("Text", "xm", "Location:")
guiLocationName := PkmnCalc.Add("Edit", "x+10 yp-4", "Leave as is if unimportant")
    ; Type
    PkmnCalc.Add("Text", "xm", "Type:")
    guiLocationType := PkmnCalc.Add("DDL", "x+10 yp-4 Choose1", guiLocationTypeList)
    ; Lit?
    guiLocationLit := PkmnCalc.Add("CheckBox", "xm Checked", "Is it lit?")

; Ball Selector
PkmnCalc.Add("Text", "xm", "Ball:")
guiBall := PkmnCalc.Add("DDL", "x+10 yp-4 Choose1", GetGuiBallList())
; Throw Button
guiThrowPokeBall(*) {
    global ctx
    ctx := context(
        target(guiTarget.Text, guiTargetStatus.Text, {level: guiTargetLevel.Value, gender: guiTargetGender.Text}),
        me(guiMyName.Text, guiMyLevel.Value, guiMyGender.Text),
        battle("single", guiEncounter.Text),
        location(guiLocationName.Text, guiLocationType.Text, guiLocationLit.Value)
    )
    ctx.tar.statsBattle["HP"] := Floor((ctx.tar.stats["HP"] * guiHPper.Value) / 100)
    calcSelector[player.gen](guiBall.Text, ctx)
}
guiThrow := PkmnCalc.Add("Button",, "Throw!")
guiThrow.OnEvent("Click", guiThrowPokeBall)
; Simulate Button
guiSimulateChances(*) {
    global ctx
    ctx := context(
        target(guiTarget.Text, guiTargetStatus.Text, {level: guiTargetLevel.Value, gender: guiTargetGender.Text}),
        me(guiMyName.Text, guiMyLevel.Value, guiMyGender.Text),
        battle("single", guiEncounter.Text),
        location(guiLocationName.Text, guiLocationType.Text, guiLocationLit.Value)
    )
    ctx.tar.statsBattle["HP"] := Floor(ctx.tar.stats["HP"] * guiHPper.Value / 100)
    sim.Print(guiBall.Text, ctx, simSelector[player.gen])
}
guiSimulate := PkmnCalc.Add("Button", "yp", "Simulate")
guiSimulate.OnEvent("Click", guiSimulateChances)


PkmnCalc.Show()
;}
;}