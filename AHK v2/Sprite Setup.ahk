; Sprite Setup

baseURL := "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/"
genURL := Map(
    1, "versions/generation-i/", 2, "versions/generation-ii/", 3, "versions/generation-iii/", 4, "versions/generation-iv/",
    5, "versions/generation-v/", 6, "", 7, "", 8, "",
    9, "" )
gameURL := Map(
    "red", "red-blue/", "blue", "red-blue/", "yellow", "yellow/",
    "gold", "gold/", "silver", "silver/", "crystal", "crystal/",
    "ruby", "ruby-sapphire/", "sapphire", "ruby-sapphire/", "emerald", "emerald/",
    "firered", "firered-leafgreen/", "leafgreen", "firered-leafgreen/",
    "diamond", "diamond-pearl/", "pearl", "diamond-pearl/", "platinum", "platinum/",
    "heartgold", "heartgold-soulsilver/", "soulsilver", "heartgold-soulsilver/", 
    "black", "black-white/", "white", "black-white/", "black-2", "black-white/", "white-2", "black-white/",
    "x", "", "y", "", "omega-ruby", "", "alpha-sapphire", "",
    "sun", "", "moon", "", "ultra-sun", "", "ultra-moon", "" )
typeURL := Map(
    "front_default", "",
    "front_female", "female/",
    "back_default", "back/",
    "back_female", "female/",
    "front_shiny", "shiny/",
    "front_shiny_female", "shiny/female/",
    "back_shiny", "back/shiny/",
    "back_shiny_female", "back/shiny/female/" )
spriteFilename := pkmnDataAPI[ctx.tar.name].id ".png"
; spriteURL := baseURL genURL[player.gen] gameURL[player.game] typeURL["front_default"] spriteFilename

