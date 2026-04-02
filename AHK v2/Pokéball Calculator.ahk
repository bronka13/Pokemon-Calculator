/*
    Pokéball Capture Calculator
    Version: 1
    Created: Mar 20, 2026
*/

;{ Headers
#Requires AutoHotkey v2+
#SingleInstance Force
;}

;{ Libraries
#Include <JSON> ; https://github.com/G33kDude/cJson.ahk
;}

;{ Functions
MergeMaps(m1, m2) {
    result := Map()
    for key, value in m1
            result[key] := value
    for key, value in m2
            result[key] := value
    return result
}
SubtractMaps(m1, m2) {
    result := Map()
    for key, value in m1
        if (!m2.Has(key)) {
            result[key] := value
        }
    return result
}
RoundDS(x) {
    return Round(x*4096)/4096
}
FloorDS(x) {
    return Floor(x*4096)/4096
}
GetCatchRate(name) {
    gen := player.gen
    game := player.game

    data := CatchRates[gen]

    ; base
    c := data["base"][name]

    ; override by gen
    if (data.Has("gen") && data["gen"].Has(name))
        c := data["gen"][name]

    ; override by game
    if (data.Has("games") && data["games"].Has(game))
        if data["games"][game].Has(name)
            c := data["games"][game][name]

    return c
}
HasFlag(flag, default := false) {
    gen := player.gen
    game := player.game

    try return player.gameFlags[gen][game][flag]
    catch
        return default 
}
;}

;{ Modules
#Include Datasets.ahk
#Include Class Objects.ahk
#Include Calculators.ahk
#Include AHK GUI.ahk
#Include WebViewToo GUI.ahk
;}

SavePokemon(tar) {
    if player.gen = 1 {
        line := tar.name "," tar.gender "," tar.level "," tar.shiny
        . tar.ability "," tar.nature ","
        . tar.IVs["HP"] "," tar.IVs["Atk"] "," tar.IVs["Def"] ","
        . tar.IVs["Spe"] "," tar.IVs["Spc"]
        . tar.date        
    } else {
        line := tar.name "," tar.gender "," tar.level "," tar.shiny
        . tar.ability "," tar.nature ","
        . tar.IVs["HP"] "," tar.IVs["Atk"] "," tar.IVs["Def"] ","
        . tar.IVs["SpAtk"] "," tar.IVs["SpDef"] "," tar.IVs["Spe"] "," 
        . tar.date
    }
    FileAppend line "`n", "Saved Pokemon.csv"
}

;{ Debugging
DebugCtx(tarName, meName := "charizard", meLevel := 50, meGender := "male",
         batType := "single", encounter := "grass", weather := "clear", turn := 1,
         locName := "", locType := "route", locLit := true) {

    ctx := context(
        target(tarName),
        me(meName, meLevel, meGender),
        battle(batType, encounter, weather),
        location(locName, locType, locLit))
    ctx.bat.turn := turn

    msg := "=== TARGET ===`n"
         . "Name:      " ctx.tar.name       "`n"
         . "Level:     " ctx.tar.level      "`n"
         . "Gender:    " ctx.tar.gender     "`n"
         . "Nature:    " ctx.tar.nature     "`n"
         . "Status:    " ctx.tar.status     "`n"
         . "Ability:   " ctx.tar.ability    "`n"
         . "Species:   " ctx.tar.species    "`n"
         . "Type 1:    " ctx.tar.type_1     "`n"
         . "Type 2:    " ctx.tar.type_2     "`n"
         . "Weight:    " ctx.tar.weight     "`n"
         . "HPcur:     " ctx.tar.statsBattle["HP"] "`n"
         . "`n--- Stats ---`n"
         . "HP:    " ctx.tar.stats["HP"]    "`n"
         . "Atk:   " ctx.tar.stats["Atk"]   "`n"
         . "Def:   " ctx.tar.stats["Def"]   "`n"
         . "SpAtk: " ctx.tar.stats["SpAtk"] "`n"
         . "SpDef: " ctx.tar.stats["SpDef"] "`n"
         . "Spe:   " ctx.tar.stats["Spe"]   "`n"
         . "`n--- IVs ---`n"
         . "HP:    " ctx.tar.IVs["HP"]    "`n"
         . "Atk:   " ctx.tar.IVs["Atk"]   "`n"
         . "Def:   " ctx.tar.IVs["Def"]   "`n"
         . "SpAtk: " ctx.tar.IVs["SpAtk"] "`n"
         . "SpDef: " ctx.tar.IVs["SpDef"] "`n"
         . "Spe:   " ctx.tar.IVs["Spe"]   "`n"
         . "`n--- NatureMod ---`n"
         . "Atk:   " ctx.tar.natureMod["Atk"]   "`n"
         . "Def:   " ctx.tar.natureMod["Def"]   "`n"
         . "SpAtk: " ctx.tar.natureMod["SpAtk"] "`n"
         . "SpDef: " ctx.tar.natureMod["SpDef"] "`n"
         . "Spe:   " ctx.tar.natureMod["Spe"]   "`n"
         . "`n=== ME ===`n"
         . "Name:    " ctx.me.name    "`n"
         . "Level:   " ctx.me.level   "`n"
         . "Gender:  " ctx.me.gender  "`n"
         . "Species: " ctx.me.species "`n"
         . "`n=== BATTLE ===`n"
         . "Type:      " ctx.bat.type      "`n"
         . "Encounter: " ctx.bat.encounter "`n"
         . "Weather:   " ctx.bat.weather   "`n"
         . "Turn:      " ctx.bat.turn      "`n"
         . "`n=== LOCATION ===`n"
         . "Name: " ctx.loc.name "`n"
         . "Type: " ctx.loc.type "`n"
         . "Lit:  " ctx.loc.lit  "`n"
         . "`n=== PLAYER ===`n"
         . "Game:  " player.game  "`n"
         . "Gen:   " player.gen   "`n"
         . "Hours: " player.hours "`n"
         . "DexCaptured: " player.DexCaptured

    MsgBox msg, "Context Debug"
}
; F1::DebugCtx("sandslash")
;}