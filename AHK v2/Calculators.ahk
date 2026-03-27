/*
    Title: pCalc — Calculators
    Version: 1
    Created: Mar 20, 2026
*/

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

    ;{ Aux Methods
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

    ;{ Main Methods
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

    ;{ Aux Methods
    static statusValue(status) {
        if (status = "Asleep" || status = "Frozen")
            return 10
        else
            return 0
    }
    ;}

    ;{ Main Methods
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

    ;{ Aux Methods
    static status := Map("Asleep", 2, "Frozen", 2, "Poisoned", 1.5, "Paralyzed", 1.5, "Burned", 1.5)
    static StatusMod(status) {
        if gen3.status.Has(status)
            return gen3.status[status]
        return 1
    }
    ;}

    ;{ Main Methods
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

    ;{ Aux Methods
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

    ;{ Main Methods
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

    ;{ Aux Methods
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

    ;{ Main Methods
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

    ;{ Aux Methods
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

    ;{ Main Methods
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

    ;{ Aux Methods
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

    ;{ Main Methods
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
;}

;{ Statistics
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