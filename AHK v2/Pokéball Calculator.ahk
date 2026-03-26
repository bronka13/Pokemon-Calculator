/*
    Pokéball Capture Calculator
*/

#SingleInstance Force
#Include Datasets.ahk

;{ General Functions
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

;{ Class Objects
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
class location {
    __New(name := "", type := "route", lit := true) {
        this.name := (name = "") ? player.location : name   ; "Route 1", "Mt. Moon", "Pallet Town"
        this.type := type   ; "route", "cave", "forest", "town", "building"
        this.lit := lit     ; false in dark caves, true in general
    }

    isDark() => (!this.lit)
}
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


class wildGenerator {
    static Generate(name) {
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
            level: wildGenerator.RandLevel(name)
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
        if data.ability_hidden != "" && (player.location = "Entree Forest" || player.location = "Hidden Grotto")
            return data.ability_hidden
        if data.ability_2 != "" && Random(0,1) = 1
            return data.ability_2
        return data.ability_1
    }

    static RandLevel(name) {
        ; this would use the game's lookup table for location encounter maps
        return Random(20,40)
    }
}
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

        /* overrides format (order not important)
        overrides := {
            IVs: Map("HP", 25, "Atk", 12, "Def", 16, "SpAtk", 0, "SpDef", 9, "Spe", 1),
            nature: "Timid",
            gender: "female",
            ability: "Overgrow",
            level: 45
        } */

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


class me {
    __New(name, level := 1, gender := "male") {
        this.name := name
        this.level := level
        this.gender := gender
        this.species := pkmnDataAPI[name].species
    }
}
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
;}

;{ Calculators
class gen1 {
    ;{ Ball Setup
    static balls := Map(
        "Poké Ball", 255, 
        "Great Ball", 200, 
        "Ultra Ball", 150, 
        "Safari Ball", 150, 
        "Master Ball", "")
    ;}

    ;{ Aux Functions
    static StatusValue(status) {
        if (status = 'Asleep' || status = 'Frozen')
            v1 := 25, v2 := 10
        else if (status = 'Poisoned' || status = 'Burned' || status = 'Paralyzed')
            v1 := 12, v2 := 5
        else
            v1 := 0, v2 := 0
        return { s1 : v1, s2 : v2}
    }
    ;}

    ;{ Main Functions
    static Capture(ballThrown, ctx) {
        if (ballThrown = "Master Ball")
            return "caught"

        maxN := gen1.balls[ballThrown]
        catchRate := GetCatchRate(ctx.tar.name)
        statusValue := gen1.StatusValue(ctx.tar.status)

        R1 := Random(0,maxN) - statusValue.s1

        if (R1 < 0)         
            return "caught"
        else if (catchRate < R1)
            return "break"

        ballValue := (ballThrown = "Great Ball") ? 8 : 12
        M := ctx.tar.stats["HP"]
        H := ctx.tar.statsBattle["HP"]
        Fmax := (M * 255)//ballValue
        Fcur := ((H // 4) = 0) ? 1 : (H // 4)
        F := ((Fmax // Fcur) > 255) ? 255 : (Fmax // Fcur)
        
        d := (catchRate * 100) // maxN
        x := ( d * F // 255 ) + statusValue.s2

        if (Random(0, 255) <= F)
            return "caught"
        else if (d >= 256)
            return  3
        else if (x < 10)
            return  "miss"
        else if (x < 30)
            return 1
        else if (x < 70)
            return 2
        else
            return 3
    }

    static Print(ballThrown, ctx) {
        res := gen1.Capture(ballThrown, ctx)
        if (res = "caught") {
            msg := ctx.tar.name " was caught!"
        } else if (res = "break") {
            msg := "Darn! " ctx.tar.name " broke free!"
        } else if (res = "miss") {
            msg :=  ballThrown " missed " ctx.tar.name "!"
        } else if (res = 1) {
            msg := "Darn! " ctx.tar.name " broke free!"
        } else if (res = 2) {
            msg := "Aww! It appeared to be caught!"
        } else if (res = 3) {
            msg := "Shoot! It was so close too!"
        }
        MsgBox msg
    }
    ;}
}

class gen2 {
    ;{ Ball Setup
    static FastBall(ctx) {
        c := GetCatchRate(ctx.tar.name)
        if (ctx.tar.name = "Grimer" || ctx.tar.name = "Tangela" || ctx.tar.name = "Magnemite")
            return c * 4
        return c
    }
    static HeavyBall(ctx) {
        weight := ctx.tar.weight
        c := GetCatchRate(ctx.tar.name)
        if weight >= 409.6
            return c + 40
        if weight >= 307.2
            return c + 30
        if weight >= 204.8
            return c + 20
        if weight >= 102.4
            return c
        return c - 20
    }
    static LevelBall(ctx) {
        c := GetCatchRate(ctx.tar.name)
        if (ctx.me.level * 4 > ctx.tar.level)
            return c * 8
        if (ctx.me.level * 2 > ctx.tar.level)
            return c * 4
        if (ctx.me.level > ctx.tar.level)
            return c * 2
        return c
    }
    static LoveBall(ctx) {
        c := GetCatchRate(ctx.tar.name)
        if (ctx.tar.species = ctx.me.species) && (ctx.tar.gender = ctx.me.gender)
            return c * 8
        return c
    }

    static balls := Map(
        "Poké Ball", (ctx) => GetCatchRate(ctx.tar.name),
        "Friend Ball", (ctx) => GetCatchRate(ctx.tar.name),
        "Great Ball", (ctx) => Floor(GetCatchRate(ctx.tar.name) * 1.5),
        "Park Ball", (ctx) => Floor(GetCatchRate(ctx.tar.name) * 1.5),
        "Ultra Ball", (ctx) => GetCatchRate(ctx.tar.name) * 2,
        "Fast Ball", (ctx) => gen2.FastBall(ctx),
        "Heavy Ball", (ctx) => gen2.HeavyBall(ctx),
        "Level Ball", (ctx) => gen2.LevelBall(ctx),
        "Love Ball", (ctx) => gen2.LoveBall(ctx),
        "Lure Ball", (ctx) => (ctx.bat.isFishing() ? GetCatchRate(ctx.tar.name) * 3 : GetCatchRate(ctx.tar.name)),
        "Moon Ball", (ctx) => GetCatchRate(ctx.tar.name),
        "Master Ball", (ctx) => "")
    ;}

    ;{ Aux Functions
    static statusValue(status) {
        if (status = "Asleep" || status = "Frozen")
            return 10
        else
            return 0
    }
    ;}

    ;{ Main Functions
    static Capture(ballThrown, ctx) {
        if (ballThrown = "Master Ball") {
            return "caught"
        }

        catchRate := gen2.balls[ballThrown](ctx)
        if (catchRate > 255)
            catchRate := 255
        else if (catchRate <= 0)
            catchRate := 1
        S := gen2.statusValue(ctx.tar.status)

        if (ballThrown = "Level Ball") {
            X := catchRate
        } else {
            M := ctx.tar.stats["HP"]
            H := ctx.tar.statsBattle["HP"]
            M3 := (3*M > 255) ? (3*M//4) : (3*M)
            H2 := (3*M > 255) ? (2*H//4) : (2*H)
            X := Max( ((M3 - H2) * catchRate) // M3, 1 ) + S

            if X > 255
                X := 255
        }

        if (Random(0, 255) <= X) {
            return "caught"
        }

        ; Shake checks
        if (Random(0,255) >= GSCshakeTable[X])
            return 0
        if (Random(0,255) >= GSCshakeTable[X])
            return 1
        if (Random(0,255) >= GSCshakeTable[X])
            return 2
        return 3
    }

    static Print(ballThrown, ctx) {
        res := gen2.Capture(ballThrown, ctx)
        if (res = "caught") {
            msg := ctx.tar.name " was caught!"
        } else if (res = 0) {
            msg := "Oh no! " ctx.tar.name " broke free!"
        } else if (res = 1) {
            msg := "Aww! It appeared to be caught!"
        } else if (res = 2) {
            msg := "Aargh! Almost had it!"
        } else if (res = 3) {
            msg := "Shoot! It was so close, too!"
        }
        MsgBox msg
    }
    ;}
}

class gen3 {
    ;{ Balls
    static DiveBall(ctx) {
        if (ctx.bat.isUnderwater() = true)
            return 3.5
        return 1
    }
    static NetBall(ctx) {
        if (ctx.tar.type_1 = "Water" || ctx.tar.type_1 = "Bug" || ctx.tar.type_2 = "Water" || ctx.tar.type_2 = "Bug")
            return 3
        return 1
    }
    static NestBall(ctx) {
        return Max( (Floor((40 - ctx.tar.level)/10)) , 1)
    }
    static RepeatBall(ctx) {
        if player.Pokedex.Has(ctx.tar.name) && player.Pokedex[ctx.tar.name] = 2
            return 3
        return 1
    }
    static TimerBall(ctx) {
        return Min( Floor( (ctx.bat.turn-1 + 10)/10), 4)
    }
    static balls := Map(
        "Poké Ball", 1,
        "Premier Ball", 1,
        "Luxury Ball", 1,
        "Heal Ball", 1,
        "Cherish Ball", 1,
        "Friend Ball", 1,
        "Fast Ball", 1,
        "Heavy Ball", 1,
        "Level Ball", 1,
        "Love Ball", 1,
        "Lure Ball", 1,
        "Moon Ball", 1, 
        "Great Ball", 1.5,
        "Safari Ball", 1.5,
        "Sport Ball", 1.5,
        "Ultra Ball", 2, 
        "Net Ball", (ctx) => gen3.NetBall(ctx),
        "Nest Ball", (ctx) => gen3.NestBall(ctx),
        "Dive Ball", (ctx) => gen3.DiveBall(ctx),
        "Repeat Ball", (ctx) => gen3.RepeatBall(ctx),
        "Timer Ball", (ctx) => gen3.TimerBall(ctx),
        "Master Ball", 1)
    ;}

    ;{ Aux Functions
    static status := Map("Asleep", 2, "Frozen", 2, "Poisoned", 1.5, "Paralyzed", 1.5, "Burned", 1.5)
    static StatusMod(status) {
        if gen3.status.Has(status)
            return gen3.status[status]
        return 1
    }
    ;}

    ;{ Main Functions
    static Capture(ballThrown, ctx) {
        if (ballThrown = "Master Ball" || ballThrown = "Park Ball")
            return "caught"

        M := ctx.tar.stats["HP"]
        H := ctx.tar.statsBattle["HP"]
        C := GetCatchRate(ctx.tar.name)
        B := gen3.balls[ballThrown]
        if (B is Func)
            B := B(ctx)
        S := gen3.StatusMod(ctx.tar.status)

        X := Floor( ( (3 * M - 2 * H) * Floor(C * B) // (3 * M) ) * S )
        if X < 1
            X := 1
        if X >= 255
            return "caught"

        Y := Floor(1048560 / Floor(Sqrt( Floor( Sqrt( Floor(16711680/X) ) ) ) ) )

        if (Random(0,65535) >= Y)
            return 0    ; broke
        if (Random(0,65535) >= Y)
            return 1    ; wobbled 1x then broke
        if (Random(0,65535) >= Y)
            return 2    ; wobbled 2x then broke
        if (Random(0,65535) >= Y)
            return 3    ; wobbled 3x then broke
        return "caught"
    }

    static Print(ballThrown, ctx) {
        res := gen3.Capture(ballThrown, ctx)
        if (res = "caught") {
            msg := ctx.tar.name " was caught!"
        } else if (res = 0) {
            msg := "Oh no! " ctx.tar.name " broke free!"
        } else if (res = 1) {
            msg := "Aww! It appeared to be caught!"
        } else if (res = 2) {
            msg := "Aargh! Almost had it!"
        } else if (res = 3) {
            msg := "Shoot! It was so close, too!"
        }
        MsgBox msg
    }
    ;}
}

class gen4 {
    ;{ Ball Setup
    static FastBall(ctx) {
        c := GetCatchRate(ctx.tar.name)
        if (pkmnDataAPI[ctx.tar.name].Spe >= 100)
            return c * 4
        return c
    }
    static HeavyBall(ctx) {
        weight := ctx.tar.weight
        c := GetCatchRate(ctx.tar.name)
        if (weight >= 409.6)
            return c + 40
        else if (weight >= 307.2)
            return c + 30
        else if (weight >= 204.8)
            return c + 20
        return c - 20
    }
    static LevelBall(ctx) {
        c := GetCatchRate(ctx.tar.name)
        if (ctx.me.level // 4 > ctx.tar.level)
            return c * 8
        else if (ctx.me.level // 2 > ctx.tar.level)
            return c * 4
        else if (ctx.me.level > ctx.tar.level)
            return c * 2
        return c
    }
    static LoveBall(ctx) {
        c := GetCatchRate(ctx.tar.name)
        if ((ctx.tar.species = ctx.me.species) && (ctx.tar.gender != ctx.me.gender))
            return c * 8
        return c
    }
    static LureBall(ctx) {
        c := GetCatchRate(ctx.tar.name)
        if (ctx.bat.isFishing() = true)
            return c * 3
        return c
    }
    static MoonStone := Map("Nidoran♂", 1, "Nidorino", 1, "Nidoking", 1, "Nidoran♀", 1, "Nidorina", 1, "Nidoqueen", 1,
                            "Clefairy", 1, "Clefable", 1, "Jigglypuff", 1, "Wigglytuff", 1, "Skitty", 1, "Delcatty", 1)
    static MoonBall(ctx) {
        c := GetCatchRate(ctx.tar.name)
        if (gen4.MoonStone.Has(ctx.tar.name))
            return c * 4
        return c
    }
    static ApricornBalls := Map("Fast Ball", 1, "Heavy Ball", 1, "Level Ball", 1, "Love Ball", 1, "Lure Ball", 1, "Moon Ball", 1)

    static DiveBall(ctx) {
        if (ctx.bat.isFishing() = true || ctx.bat.isSurfing() = true)
            return 3.5
        return 1
    }
    static QuickBall(ctx) {
        if (ctx.bat.turn = 1)
            return 4
        return 1
    }
    static DuskBall(ctx) {
        if (ctx.loc.type = "cave" || ctx.isNight())
            return 3.5
        return 1
    }

    static newBalls := Map(
        "Park Ball", 1,
        "Dive Ball", (ctx) => gen4.DiveBall(ctx),
        "Quick Ball", (ctx) => gen4.QuickBall(ctx),
        "Dusk Ball", (ctx) => gen4.DuskBall(ctx),
    )
    static balls := MergeMaps(gen3.balls, gen4.newBalls)
    ;}

    ;{ Aux Functions
    static CatchRate(ballThrown, ctx) {
        switch ballThrown {
            case "Fast Ball": return gen4.FastBall(ctx)
            case "Heavy Ball": return gen4.HeavyBall(ctx)
            case "Level Ball": return gen4.LevelBall(ctx)
            case "Love Ball": return gen4.LoveBall(ctx)
            case "Lure Ball": return gen4.LureBall(ctx)
            case "Moon Ball": return gen4.MoonBall(ctx)
        }
        return GetCatchRate(ctx.tar.name)
    }
    ;}

    ;{ Main Functions
    static Capture(ballThrown, ctx) {
        if (ballThrown = "Master Ball" || ballThrown = "Park Ball")
            return "caught"

        M := ctx.tar.stats["HP"]
        H := ctx.tar.statsBattle["HP"]
        C := gen4.CatchRate(ballThrown, ctx)
        B := gen4.balls[ballThrown]
        if (B is Func)
            B := B(ctx)
        S := gen3.StatusMod(ctx.tar.status)

        X := Floor( ( ( 3 * M - 2 * H) * Floor(C * B) // (3 * M) ) * S )
        if X < 1
            X := 1
        if X >= 255
            return "caught"

        Y := Floor(1048560 / Floor(Sqrt( Floor( Sqrt( Floor(16711680/X) ) ) ) ) )

        if (Random(0,65535) >= Y)
            return 0    ; broke
        if (Random(0,65535) >= Y)
            return 1    ; wobbled 1x then broke
        if (Random(0,65535) >= Y)
            return 2    ; wobbled 2x then broke
        if (Random(0,65535) >= Y)
            return 3    ; wobbled 3x then broke
        return "caught"
    }

    static Print(ballThrown, ctx) {
        res := gen4.Capture(ballThrown, ctx)
        if (res = "caught") {
            msg := ctx.tar.name " was caught!"
        } else if (res = 0) {
            msg := "Oh no! " ctx.tar.name " broke free!"
        } else if (res = 1) {
            msg := "Aww! It appeared to be caught!"
        } else if (res = 2) {
            msg := "Aargh! Almost had it!"
        } else if (res = 3) {
            msg := "Shoot! It was so close, too!"
        }
        MsgBox msg
    }
    ;}
}

class gen5 {
    ;{ Ball Setup
    static NestBall(ctx) {
        return Max( (Floor((41 - ctx.tar.level)/10)) , 1)
    }
    static DiveBall(ctx) {
        if (ctx.bat.isFishing() = true || ctx.bat.isSurfing() = true || ctx.bat.isUnderwater() = true)
            return 3.5
        return 1
    }
    static TimerBall(ctx) {
        return Min( 1 + ( ((ctx.bat.turn)-1) * (1229/4096) ) , 4 )
    }
    static QuickBall(ctx) {
        if (ctx.bat.turn = 1)
            return 5
        return 1
    }
    static DuskBall(ctx) {
        if (ctx.loc.type = "cave") || (ctx.loc.isDark() = true) || (ctx.isNight() && ctx.loc.type != "building")
            return 3.5
        return 1
    }
    static removedBalls := Map(
        "Friend Ball", 1, 
        "Fast Ball", 1, 
        "Heavy Ball", 1, 
        "Level Ball", 1, 
        "Love Ball", 1, 
        "Lure Ball", 1, 
        "Moon Ball", 1, 
        "Safari Ball", 1,
        "Sport Ball", 1, 
        "Park Ball", 1)
    static newBalls := Map(
        "Nest Ball", (ctx) => gen5.NestBall(ctx),
        "Dive Ball", (ctx) => gen5.DiveBall(ctx),
        "Timer Ball", (ctx) => gen5.TimerBall(ctx), 
        "Quick Ball", (ctx) => gen5.QuickBall(ctx),
        "Dusk Ball", (ctx) => gen5.DuskBall(ctx))
    static ballsRemoved := SubtractMaps(gen4.balls, gen5.removedBalls)
    static balls := MergeMaps(gen5.ballsRemoved,gen5.newBalls)
    ;}

    ;{ Aux Functions
    static status := Map("Asleep", 2.5, "Frozen", 2.5, "Poisoned", 1.5, "Paralyzed", 1.5, "Burned", 1.5)
    static StatusMod(status) {
        if gen5.status.Has(status)
            return gen5.status[status]
        return 1
    }

    static GrassMod(ctx) {
        if ctx.bat.encounter != "tall grass"
            return 1
        if player.DexCaptured > 600
            return 1
        if player.DexCaptured > 450
            return 3686/4096
        if player.DexCaptured > 300
            return 3277/4096
        if player.DexCaptured > 150
            return 2867/4096
        if player.DexCaptured > 30
            return 0.5
        else return 1229/4096
    }

    static PokedexMod() {
        if player.DexCaptured > 600
            return 2.5
        if player.DexCaptured > 450
            return 2
        if player.DexCaptured > 300
            return 1.5
        if player.DexCaptured > 150
            return 1
        if player.DexCaptured > 30
            return 0.5
        return 0
    }
    ;}

    ;{ Main Functions
    static Capture(ballThrown, ctx) {
        if (ballThrown = "Master Ball" || ctx.loc.name = "Entree Forest")
            return "caught"

        criticalCapture := false
        M := ctx.tar.stats["HP"]
        H := ctx.tar.statsBattle["HP"]
        C := GetCatchRate(ctx.tar.name)
        B := gen5.balls[ballThrown]
        if (B is Func)
            B := B(ctx)
        S := gen5.StatusMod(ctx.tar.status)
        G := gen5.GrassMod(ctx)
        E := player.EntralinkCapturePower[player.ECPLevel]

        X := FloorDS(RoundDS(FloorDS((RoundDS(RoundDS((3*M - 2*H) * G) * C * B) ) / (3*M)) * S) * (E/100))
        if (X = 255)
            return "caught"

        ; Critical Capture
        P := gen5.PokedexMod()

        CC := Floor((Min(255, X) * P)/6)
        if (CC > Random(0,255))
            criticalCapture := true

        Y := Floor(65536/Sqrt(Sqrt(255/X)))

        if (criticalCapture = true) {
            if (Random(0,65535) >= Y)
                return 1
            return "caught"
        }
        else if (Random(0,65535) >= Y)
            return 0
        else if (Random(0,65535) >= Y)
            return 1
        else if (Random(0,65535) >= Y)
            return 3
        return "caught"
    }

    static Print(ballThrown, ctx) {
        res := gen5.Capture(ballThrown, ctx)
        if (res = "caught") {
            msg := ctx.tar.name " was caught!"
        } else if (res = 0) {
            msg := "Oh no! " ctx.tar.name " broke free!"
        } else if (res = 1) {
            msg := "Aww! It appeared to be caught!"
        } else if (res = 3) {
            msg := "Aargh! Almost had it!"
        }
        MsgBox msg
    }
    ;}
}

class gen6 {
    ;{ Ball Setup
    static NestBall(ctx) {
        if (ctx.tar.level < 30)
            return Max( (Floor((41 - ctx.tar.level)/10)) , 1)
        return 1
    }
    static DuskBall(ctx) {
        if (ctx.loc.type = "cave" || ctx.isNight())
            return 3.5
        return 1
    }
    static removedBalls := Map(
        "Dream Ball", 1)
    static newBalls := Map(
        "Nest Ball", (ctx) => gen6.NestBall(ctx),
        "Dusk Ball", (ctx) => gen6.DuskBall(ctx))
    static ballsRemoved := SubtractMaps(gen5.balls, gen6.removedBalls)
    static balls := MergeMaps(gen6.ballsRemoved,gen6.newBalls)
    ;}

    ;{ Aux Functions
    static GrassMod(ctx) {
        if ctx.bat.encounter != "gen6_secret_thing"
            return 1
        if player.DexCaptured > 600
            return 1
        if player.DexCaptured > 450
            return 3686/4096
        if player.DexCaptured > 300
            return 3277/4096
        if player.DexCaptured > 150
            return 2867/4096
        if player.DexCaptured > 30
            return 0.5
        return 1229/4096
    }
    ;}

    ;{ Main Functions
    static Capture(ballThrown, ctx) {
        if (player.game = "X" || player.game = "Y") && player.location = "Route 2"
            return "caught"
        if (player.game = "OmegaRuby" || player.game = "AlphaSapphire") && player.location = "Route 101"
            return "caught"
        if (ballThrown = "Master Ball")
            return "caught"

        criticalCapture := false
        M := ctx.tar.stats["HP"]
        H := ctx.tar.statsBattle["HP"]
        G := gen6.GrassMod(ctx)
        C := GetCatchRate(ctx.tar.name)
        B := gen6.balls[ballThrown]
        if (B is Func)
            B := B(ctx)
        S := gen5.StatusMod(ctx.tar.status)
        O := player.OPower[player.OPLevel]

        X := (((3*M - 2*H) * G * C * B)/ (3*M)) * S * O

        if (X >= 255)
            return "caught"

        ; critical capture
        P := gen5.PokedexMod()

        CC := Floor((Min(255, X) * P)/6)
        if (CC > Random(0,255))
            criticalCapture := true

        Y := Floor(65536/(255/X)**(3/16))

        if (criticalCapture = true) {
            if (Random(0,65535) >= Y)
                return 1
            return "caught"
        }
        else if (Random(0,65535) >= Y)
            return 0
        else if (Random(0,65535) >= Y)
            return 1
        else if (Random(0,65535) >= Y)
            return 2
        else if (Random(0,65535) >= Y)
            return 3
        return "caught"
    }

    static Print(ballThrown, ctx) {
        res := gen6.Capture(ballThrown, ctx)
        if (res = "caught") {
            msg := ctx.tar.name " was caught!"
        } else if (res = 0) {
            msg := "Oh no! " ctx.tar.name " broke free!"
        } else if (res = 1) {
            msg := "Aww! It appeared to be caught!"
        } else if (res = 2) {
            msg := "Aargh! Almost had it!"
        } else if (res = 3) {
            msg := "Shoot! It was so close, too!"
        }
        MsgBox msg
    }
    ;}
}

class gen7 {
    ;{ Ball Setup
    static NetBall(ctx) {
        if (ctx.tar.type_1 = "Water" || ctx.tar.type_1 = "Bug" || ctx.tar.type_2 = "Water" || ctx.tar.type_2 = "Bug")
            return 3.5
        return 1
    }
    static RepeatBall(ctx) {
        if (player.Pokedex.Has(ctx.tar.name) && player.Pokedex[ctx.tar.name] = 2)
            return 3.5
        return 1
    }
    static DuskBall(ctx) {
        if (ctx.loc.type = "cave" || ctx.isNight())
            return 3
        return 1
    }
    static FastBall(ctx) {
        if (pkmnDataAPI[ctx.tar.name].Spe >= 100)
            return 4
        return 1
    }
    static LevelBall(ctx) {
        if (Floor(ctx.me.level/4) >= ctx.tar.level)
            return 8
        if (Floor(ctx.me.level/2) >= ctx.tar.level)
            return 4
        if (ctx.me.level > ctx.tar.level)
            return 2
        return 1
    }
    static LoveBall(ctx) {
        if (ctx.tar.species = ctx.me.species && ctx.tar.gender != ctx.me.gender)
            return 8
        return 1
    }
    static LureBall(ctx) {
        if (ctx.bat.isFishing() = true)
            return 5
        return 1
    }
    static MoonStone := Map("Nidorina", 1, "Nidorino", 1, "Clefairy", 1, "Jigglypuff", 1, "Skitty", 1, "Munna", 1)
    static MoonBall(ctx) {
        if gen7.MoonStone.Has(ctx.tar.name)
            return 4
        return 1
    }
    static UltraBeast := Map("Nihilego", 1, "Buzzwole", 1, "Pheromosa", 1, "Xurkitree", 1, "Celesteela", 1, "Kartana", 1, "Guzzlord", 1, "Poipole", 1, "Naganadel", 1, "Stakataka", 1, "Blacephalon", 1)
    static BeastBall(ctx) {
        if gen7.UltraBeast.Has(ctx.tar.name)
            return 5
        return 410/4096
    }
    static removedBalls := Map()
    static newBalls := Map(
        "Net Ball", (ctx) => gen7.NetBall(ctx),
        "Repeat Ball", (ctx) => gen7.RepeatBall(ctx),
        "Dusk Ball", (ctx) => gen7.DuskBall(ctx),
        "Fast Ball", (ctx) => gen7.FastBall(ctx),
        "Level Ball", (ctx) => gen7.LevelBall(ctx),
        "Love Ball", (ctx) => gen7.LoveBall(ctx),
        "Lure Ball", (ctx) => gen7.LureBall(ctx),
        "Moon Ball", (ctx) => gen7.MoonBall(ctx),
        "Beast Ball", (ctx) => gen7.BeastBall(ctx))
    static ballsRemoved := SubtractMaps(gen6.balls, gen7.removedBalls)
    static balls := MergeMaps(gen7.ballsRemoved,gen7.newBalls)
    ;}

    ;{ Aux Functions
    static CaptureRate(ballThrown, ctx){
        base := GetCatchRate(ctx.tar.name)
        if (ballThrown != "Heavy Ball")
            return base

        weight := pkmnDataAPI[ctx.tar.name].weight

        if (weight >= 300)
            c := base + 30
        else if (weight >= 200)
            c := base + 20
        else if (weight >= 100)
            c := base
        else
            c := base - 20

        if ((player.game = "Sun" || player.game = "Moon") && (c < 0))
            c := 0
        if ((player.game = "Ultra Sun" || player.game = "Ultra Moon") && (c < 0))
            c := 1
        
        return c
    }
    ;}

    ;{ Main Functions
    static Capture(ballThrown, ctx){
        if (HasFlag("FestivalStarted") && player.location = "Route 1")
            return "caught"
        if (ballThrown = "Master Ball")
            return "caught"

        criticalCapture := false
        M := ctx.tar.stats["HP"]
        H := ctx.tar.statsBattle["HP"]
        G := gen6.GrassMod(ctx)
        C := GetCatchRate(ctx.tar.name)
        B := gen7.balls[ballThrown]
        if (B is Func)
            B := B(ctx)
        S := gen5.StatusMod(ctx.tar.status)
        O := player.RotoCatchBonus[player.RCBLevel]

        X := (((3*M - 2*H) * G * C * B)/ (3*M)) * S * O

        if (X >= 255)
            return "caught"

        ; critical capture
        P := gen5.PokedexMod()

        CC := Floor((Min(255, X) * P)/6)
        if (CC > Random(0,255))
            criticalCapture := true

        Y := Floor(65536/(255/X)**(3/16))

        if (criticalCapture = true) {
            if (Random(0,65535) >= Y)
                return 1
            return "caught"
        }
        else if (Random(0,65535) >= Y)
            return 0
        else if (Random(0,65535) >= Y)
            return 1
        else if (Random(0,65535) >= Y)
            return 2
        else if (Random(0,65535) >= Y)
            return 3
        return "caught"
    }

    static Print(ballThrown, ctx) {
        res := gen7.Capture(ballThrown, ctx)
        if (res = "caught") {
            msg := ctx.tar.name " was caught!"
        } else if (res = 0) {
            msg := "Oh no! " ctx.tar.name " broke free!"
        } else if (res = 1) {
            msg := "Aww! It appeared to be caught!"
        } else if (res = 2) {
            msg := "Aargh! Almost had it!"
        } else if (res = 3) {
            msg := "Shoot! It was so close, too!"
        }
        MsgBox msg
    }
    ;}
}

class sim {
    static Sim(ballThrown, ctx, calcFunc) {
        success := 0
        Loop 10000 {
            if (calcFunc(ballThrown, ctx) = "caught")
                success++
        }
        return success/10000
    }

    static BallsNeeded(p,percent) {
        p := p + 0
        percent := percent + 0

        if (percent > 1)
            percent := percent / 100
        else if (percent <= 0)
            return 0
        else if (percent >= 1)
            return "infinity"
        else if (p <= 0)
            return "infinity"
        else if (p >= 1)
            return 1

        return Ceil(Log(1 - percent) / Log(1-p))
    }

    static Print(ballThrown, ctx, calcFunc) {
        p := sim.Sim(ballThrown, ctx, calcFunc)
        x := sim.BallsNeeded(p,0.5)
        y := sim.BallsNeeded(p,0.95)
        pStr := RTrim(RTrim(Format("{:.3f}", p*100), "0"), ".")
        MsgBox "You have a " pStr "% chance of capturing it per ball."
        .   "`nThus, you have at least a 50% chance of catching it within " x (x = 1 ? " ball," : " balls,")
        .   "`nand at least a 95% chance of catching it within " y (y = 1 ? " ball." : " balls.")
        , "Probability Simulation"
    }
}
;}

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