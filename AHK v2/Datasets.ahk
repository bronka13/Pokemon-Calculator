;;;;;;;;;;;;;

#Include pkmnDataAPI.ahk
CatchRatesAPI := Map()
for name, data in pkmnDataAPI
    CatchRatesAPI[name] := data.capture_rate

;{ Functions
ToNum(val) => (val = "" ? 0 : val + 0)
;}

;{ Fixed Datasets
gameGen := Map(
    "red", 1, "blue", 1, "yellow", 1,
    "gold", 2, "silver", 2, "crystal", 2,
    "ruby", 3, "sapphire", 3, "emerald", 3, "firered", 3, "leafgreen", 3, "colosseum", 3, "xd", 3,
    "diamond", 4, "pearl", 4, "platinum", 4, "heartgold", 4, "soulsilver", 4,
    "black", 5, "white", 5, "black-2", 5, "white-2", 5,
    "x", 6, "y", 6, "omega-ruby", 6, "alpha-sapphire", 6,
    "sun", 7, "moon", 7, "ultra-sun", 7, "ultra-moon", 7,
    "sword", 8, "shield", 8, "brilliant-diamond", 8, "shining-pearl", 8, "legends-arceus", 8,
    "scarlet", 9, "violet", 9, "legends-z-a", 9,
    "winds", 10, "waves", 10
    )
GSCshakeTable := Map(0,63,1,63,2,75,3,84,4,90,5,95,6,103,7,103,8,113,9,113,10,113,11,126,12,126,13,126,14,126,15,126,16,134,17,134,18,134,19,134,20,134,21,149,22,149,23,149,24,149,25,149,26,149,27,149,28,149,29,149,30,149,31,160,32,160,33,160,34,160,35,160,36,160,37,160,38,160,39,160,40,160,41,169,42,169,43,169,44,169,45,169,46,169,47,169,48,169,49,169,50,169,51,177,52,177,53,177,54,177,55,177,56,177,57,177,58,177,59,177,60,177,61,191,62,191,63,191,64,191,65,191,66,191,67,191,68,191,69,191,70,191,71,191,72,191,73,191,74,191,75,191,76,191,77,191,78,191,79,191,80,191,81,201,82,201,83,201,84,201,85,201,86,201,87,201,88,201,89,201,90,201,91,201,92,201,93,201,94,201,95,201,96,201,97,201,98,201,99,201,100,201,101,211,102,211,103,211,104,211,105,211,106,211,107,211,108,211,109,211,110,211,111,211,112,211,113,211,114,211,115,211,116,211,117,211,118,211,119,211,120,211,121,220,122,220,123,220,124,220,125,220,126,220,127,220,128,220,129,220,130,220,131,220,132,220,133,220,134,220,135,220,136,220,137,220,138,220,139,220,140,220,141,227,142,227,143,227,144,227,145,227,146,227,147,227,148,227,149,227,150,227,151,227,152,227,153,227,154,227,155,227,156,227,157,227,158,227,159,227,160,227,161,234,162,234,163,234,164,234,165,234,166,234,167,234,168,234,169,234,170,234,171,234,172,234,173,234,174,234,175,234,176,234,177,234,178,234,179,234,180,234,181,240,182,240,183,240,184,240,185,240,186,240,187,240,188,240,189,240,190,240,191,240,192,240,193,240,194,240,195,240,196,240,197,240,198,240,199,240,200,240,201,246,202,246,203,246,204,246,205,246,206,246,207,246,208,246,209,246,210,246,211,246,212,246,213,246,214,246,215,246,216,246,217,246,218,246,219,246,220,246,221,251,222,251,223,251,224,251,225,251,226,251,227,251,228,251,229,251,230,251,231,251,232,251,233,251,234,251,235,251,236,251,237,251,238,251,239,251,240,251,241,253,242,253,243,253,244,253,245,253,246,253,247,253,248,253,249,253,250,253,251,253,252,253,253,253,254,253,255,255)
naturesList := [
	"Hardy", "Lonely", "Brave", "Adamant", "Naughty", "Bold", "Docile", "Relaxed", "Impish",
	"Lax", "Timid", "Hasty", "Serious", "Jolly", "Naive", "Modest", "Mild", "Quiet", "Bashful", "Rash",
	"Calm", "Gentle", "Sassy", "Careful", "Quirky"
    ]
naturesModList := Map(
	"Hardy", ["Atk", "Atk"], "Lonely", ["Atk", "Def"], "Brave", ["Atk", "Spe"], "Adamant", ["Atk", "SpAtk"], "Naughty", ["Atk", "SpDef"],
	"Bold", ["Def", "Atk"], "Docile", ["Def", "Def"], "Relaxed", ["Def", "Spe"], "Impish", ["Def", "SpAtk"], "Lax", ["Def", "SpDef"],
	"Timid", ["Spe", "Atk"], "Hasty", ["Spe", "Def"], "Serious", ["Spe", "Spe"], "Jolly", ["Spe", "SpAtk"], "Naive", ["Spe", "SpDef"],
	"Modest", ["SpAtk", "Atk"], "Mild", ["SpAtk", "Def"], "Quiet", ["SpAtk", "Spe"], "Bashful", ["SpAtk", "SpAtk"], "Rash", ["SpAtk", "SpDef"],
	"Calm", ["SpDef", "Atk"], "Gentle", ["SpDef", "Def"], "Sassy", ["SpDef", "Spe"], "Careful", ["SpDef", "SpAtk"], "Quirky", ["SpDef", "SpDef"]
    )
;}

;{ Modified Catch Rates
gen1_CatchRates := Map("raticate", 90)
Y_CatchRates := Map("dragonair", 27, "dragonite", 9)
gen2_CatchRates := Map("raticate", 90)
gen3_CatchRates := Map("kyogre", 5, "groudon", 5)
Col_CatchRates := Map("bayleef", 180, "quilava", 180, "croconaw", 180, "togetic", 45, "skarmory", 15, "raikou", 15, "entei", 15, "suicune", 15, "tyranitar", 10, "metagross", 15)
XDGoD_CatchRates := Map("butterfree", 45, "beedrill", 45, "venomoth", 120, "dugtrio", 100, "primeape", 80, "poliwrath", 90, "magneton", 110, "farfetch'd", 80, "dodrio", 90, "hypno", 80, "exegguctor", 80, "marowak", 110, "hitmonlee", 90, "hitmonchan", 90, "chansey", 70, "tangela", 90, "kangaskhan", 90, "starmie", 110, "mr. mime", 90, "scyther", 90, "electabuzz", 90, "pinsir", 90, "tauros", 80, "lapras", 80, "snorlax", 70, "articuno", 25, "zapdos", 25, "moltres", 25, "magcargo", 120, "houndour", 225, "swellow", 90, "delcatty", 120, "sableye", 90, "mawile", 120, "manectric", 80, "altaria", 80, "lunatone", 100, "solrock", 90, "banette", 90, "tropius", 45, "salamence", 80)
gen4_CatchRates := Map("kyogre", 5, "groudon", 5, "dialga", 30, "palkia", 30)
gen5_CatchRates := Map("kyogre", 5, "groudon", 5, "dialga", 30, "palkia", 30, "reshiram", 45, "zekrom", 45)
XY_CatchRates := Map("kyogre", 5, "groudon", 5, "dialga", 30, "palkia", 30, "reshiram", 45, "zekrom", 45)
ORAS_CatchRates := Map("rayquaza", 45)
gen7_CatchRates := Map("cosmog", 45, "cosmoem", 45, "solgaleo", 45, "lunala", 45, "poipole", 3, "naganadel", 3, "stakataka", 3, "blacephalon", 3)
SM_CatchRates := Map("buzzwole", 25, "pheromosa", 255, "xurkitree", 30, "celesteela", 25, "kartana", 255, "guzzlord", 15)
USUM_CatchRates := Map("rayquaza", 45, "necrozma", 255)
gen8_CatchRates := Map("rayquaza", 45)
SwSh_CatchRates := Map("necrozma", 255)
LZA_CatchRates := Map("mewtwo", 20, "beldum", 20, "metang", 20, "metagross", 20, "latias", 45, "latios", 45, "kyogre", 45, "groudon", 45, "rayquaza", 45, "heatran", 45, "darkrai", 45, "cobalion", 45, "terrakion", 45, "virizion", 45, "keldeo", 45, "meloetta", 45, "genesect", 45, "zygarde", 255, "diancie", 20, "hoopa", 45, "volcanion", 45, "magearna", 45, "marshadow", 45, "zeraora", 45, "meltan", 45, "melmetal", 45, "kleavor", 20)
;}

CatchRates := Map(
    1, Map(
        "base", CatchRatesAPI,
        "gen", gen1_CatchRates,
        "games", Map(
            "Yellow", Y_CatchRates)
    ),
    2, Map(
        "base", CatchRatesAPI,
        "gen", gen2_CatchRates
    ),
    3, Map(
        "base", CatchRatesAPI,
        "gen", gen3_CatchRates,
        "games", Map(
            "Colosseum", Col_CatchRates,
            "XD: Gale of Darkness", XDGoD_CatchRates)
    ),
    4, Map(
        "base", CatchRatesAPI,
        "gen", gen4_CatchRates
    ),
    5, Map(
        "base", CatchRatesAPI,
        "gen", gen5_CatchRates
    ),
    6, Map(
        "base", CatchRatesAPI,
        "games", Map(
            "X", XY_CatchRates,
			"Y", XY_CatchRates,
            "OmegaRuby", ORAS_CatchRates,
			"AlphaSapphire", ORAS_CatchRates)
    ),
    7, Map(
        "base", CatchRatesAPI,
        "gen", gen7_CatchRates,
        "games", Map(
            "Sun", SM_CatchRates,
            "Moon", SM_CatchRates,
            "Ultra Sun", USUM_CatchRates,
            "Ultra Moon", USUM_CatchRates)
    ),
    8, Map(
        "base", CatchRatesAPI,
        "gen", gen8_CatchRates,
        "games", Map(
            "Sword", SwSh_CatchRates,
            "Shield", SwSh_CatchRates)
    ),
    9, Map(
        "base", CatchRatesAPI,
        "games", Map(
            "Legends Z-A", LZA_CatchRates)
    )
)