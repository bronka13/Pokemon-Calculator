/*
    Title: pCalc — Context
    Version: 1
    Created: Mar 27, 2026
*/

/**
 * SAV file related values.
 */
class player {
    static game := "emerald"
    static gen := gameGen[player.game]
    ;{ Pokedex
    static Pokedex := Map()
    static DexCount(value) {
        count := 0
        for k, v in player.Pokedex {
            if (v = value)
                count++
        }
        return count
    }
    static DexCaptured {
        get => player.DexCount(2)
    }
    static DexSeen {
        get => player.DexCount(1)
    }
    static DexRegistered {
        get {
            count := 0
            for k, v in player.Pokedex {
                if (v >= 1)
                    count++
            }
            return count
        }
    }
    ;}

    static hours := 12
    static minutes := 37
    static seconds := 18

    static location := "Route 10"

    ;{ Gen-Specific Properties
    ; Gen 5
    static ECPLevel := 0    ; 0, 1, 2, 3, "S", "MAX"
    static EntralinkCapturePower := Map(0, 100, 1, 110, 2, 120, 3, 130, "S", 130, "MAX", 130)
    ; Gen 6
    static OPLevel := 0     ; 0, 1, 2, 3, "S", "MAX"
    static OPower := Map(0, 1, 1, 1.5, 2, 2, 3, 2.5, "S", 2.5, "MAX", 2.5)
    ; Gen 7
    static RCBLevel := 0    ; 0, 1
    static RotoCatchBonus := Map(0, 1, 1, 2.5)
    ;}

    static gameFlags := Map(
        1, Map(
            "Red", Map(
                "StarterSelected", true,
                "HasPokedex", true,
                "HelpedBill", true,
                "HasBicycle", false
            )
        ),
        2, Map(),
        3, Map(),
        4, Map(),
        5, Map(),
        6, Map(),
        7, Map(
            "Sun", Map(
                "StarterSelected", true,
                "FestivalStarted", true
            )
        )
    )
}

/**
 * Encounter location information
 * @param name defines location name ("Route 1", "Mt. Moon", "Pallet Town")
 * @param type defines location type ("route", "cave", "forest", "town", "building")
 * @param lit is used for Dusk Ball bonus
 * @method isDark is a helper for such bonus
 */
class location {
    __New(name := "", type := "route", lit := true) {
        this.name := (name = "") ? player.location : name   ; "Route 1", "Mt. Moon", "Pallet Town"
        this.type := type   ; "route", "cave", "forest", "town", "building"
        this.lit := lit     ; false in dark caves, true in general
    }

    isDark() => (!this.lit)
}

/**
 * Battle information
 */
class battle {
    __New(type := "single", encounter := "grass", weather := "clear") {
        this.type := type           ; "single", "double", "raid"
        this.encounter := encounter ; "trainer", "grass", "tall grass", "surfing", "fishing", "underwater", "cave"
        this.weather := weather
        this.turn := 1
    }
    
    nextTurn() {
        this.turn++
    }

    isFishing() => (this.encounter = "fishing")
    isSurfing() => (this.encounter = "surfing")
    isUnderwater() => (this.encounter = "underwater")
}

/**
 * Wild Pokémon generator
 * Randomly generates IVs, Nature, Gender, Ability and Level
 */
class wildGenerator {
    static Generate(name, minLvl := 1, maxLvl := 1) {
        nature := wildGenerator.RandNature()
        return {
            IVs: Map(
                "HP", Random(0,31),
                "Atk", Random(0,31),
                "Def", Random(0,31),
                "SpAtk", Random(0,31),
                "SpDef", Random(0,31),
                "Spe", Random(0,31)),
            nature: nature,
            natureMod: wildGenerator.BuildNatureMod(nature),
            gender: wildGenerator.RandGender(name),
            ability: wildGenerator.RandAbility(name),
            level: wildGenerator.RandLevel(name, minLvl, maxLvl)
        }
    }

    static RandNature() {
        return naturesList[Random(1,24)]
    }
    static BuildNatureMod(nature) {
        mod := Map("Atk", 1, "Def", 1, "SpAtk", 1, "SpDef", 1, "Spe", 1)
        inc := naturesModList[nature][1]
        dec := naturesModList[nature][2]
        if (inc != dec) {
            mod[inc] := 1.1
            mod[dec] := 0.9
        }
        return mod
    }

    static RandGender(name) {
        return (Random(1,8) <= pkmnDataAPI[name].gender_rate) ? "female" : "male"
    }

    static RandAbility(name) {
        data := pkmnDataAPI[name]
        if (data.ability_hidden != "") && (player.location = "Entree Forest" || player.location = "Hidden Grotto")
            return data.ability_hidden
        if data.ability_2 != "" && Random(0,1) = 1
            return data.ability_2
        return data.ability_1
    }

    static RandLevel(name, minLvl, maxLvl) {
        ; this would use the game's lookup table for location encounter maps
        ; minLvl := encounter.min_level
        ; maxLvl := encounter.max_level
        ; return Random(minLvl,maxLvl)
        return Random(20,40)
    }
}

/**
 * Target Pokémon generator
 * May use wildGenerator for randomly generated values, accepts overrides.
 * @param name defines target Pokémon species
 * @param status defines target's status condition
 * @param overrides defines if any randomly generated parameters are to be overridden
 *                  overrides := {
 *                      IVs: Map("HP", 0, "Atk", 0, "Def", 0, "SpAtk", 0, "SpDef", 0, "Spe", 0),
 *                      nature: "Timid",
 *                      gender: "female",
 *                      ability: "Overgrow",
 *                      level: 45
 *                  }
 */
class target {
    __New(name, status := "", overrides := "") {
        this.name := name
        this.type_1 := pkmnDataAPI[name].type_1
        this.type_2 := pkmnDataAPI[name].type_2

        wild := wildGenerator.Generate(name)
        this.IVs := overrides.HasProp("IVs") ? overrides.IVs : wild.IVs
        this.nature := overrides.HasProp("nature") ? overrides.nature : wild.nature
        this.natureMod := overrides.HasProp("nature") ? wildGenerator.BuildNatureMod(this.nature) : wild.natureMod
        this.gender := overrides.HasProp("gender") ? overrides.gender : wild.gender
        this.ability := overrides.HasProp("ability") ? overrides.ability : wild.ability
        this.level := overrides.HasProp("level") ? overrides.level : wild.level

        this.EVs := Map("HP", 0, "Atk", 0, "Def", 0, "SpAtk", 0, "SpDef", 0, "Spe", 0)
        this.stats := Map(
            "HP", this.calcHP(),
            "Atk", this.calcStat("Atk"), 
            "Def", this.calcStat("Def"), 
            "SpAtk", this.calcStat("SpAtk"), 
            "SpDef", this.calcStat("SpDef"), 
            "Spe", this.calcStat("Spe"))
        this.statsBattle := MergeMaps(this.stats, Map())

        this.species := pkmnDataAPI[name].species
        this.weight := pkmnDataAPI[name].weight
        this.heldItem := ""
        this.status := status
    }

    calcHP() {
        return Floor(((2*pkmnDataAPI[this.name].HP + this.IVs["HP"] + this.EVs["HP"]//4) * this.level) // 100) + this.level + 10
    }
    calcStat(stat) {
        return Floor((Floor((2*pkmnDataAPI[this.name].%stat% + this.IVs[stat] + this.EVs[stat]//4) * this.level // 100) + 5) * this.natureMod[stat])
    }
}

/**
 * My Pokémon generator
 * Generates Pokémon on your side of the battle based on standard or user-input values
 * @param name defines my Pokémon species
 * @param level defines my Pokémon's level
 * @param gender defines my Pokémon's gender
 */
class me {
    __New(name, level := 1, gender := "male") {
        this.name := name
        this.level := level
        this.gender := gender
        this.species := pkmnDataAPI[name].species
    }
}

/***
 * Context generator
 * Gathers information fed to @name target, @name me, @name battle,
 * @name location and @name player to generate a @name context object
 * and be accessed by the various calculator classes
 */
class context {
    __New(tar, me, bat, loc) {
        this.tar := tar
        this.me := me
        this.bat := bat
        this.loc := loc
        this.player := player
    }

    isNight() { ; simplified
        if (player.hours >= 20 || player.hours < 4)
            return true
        return false
    }
}

/*
ctx := context(
    target("sandslash", ""), 
    me("charizard", 52, "male"), 
    battle("single", "grass"), 
    location("Route 10", "route", true)
*/