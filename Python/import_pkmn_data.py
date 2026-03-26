import json
import re
from pathlib import Path

BASE_PATH = Path("api-data-2024-05-07/data/api/v2")

# Ordem das propriedades no Map AHK: edite esta lista para mudar a ordem
AHK_ORDER = [
    "id",
    "name",
    "species_name",
    "species_id",
    "generation",
    "type_1",
    "type_2",
    "height",
    "weight",
    "gender_rate",
    "capture_rate",
    "games",               # <-- adicionada a propriedade games
    "ability_1",
    "ability_2",
    "ability_hidden",
    "HP",
    "Atk",
    "Def",
    "SpAtk",
    "SpDef",
    "Spe"
]

# Mapeamento de nomes Python -> nomes AHK (ex.: species_name -> species)
AHK_KEY_MAP = {
    "species_name": "species"
}

# Métodos que NÃO consideramos captura direta (ajuste conforme necessário)
NON_CAPTURE_METHODS = {
    "trade", "trade-evolution", "event", "scripted", "gift", "story", "tutorial"
}

ROMAN_MAP = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5,
    "VI": 6, "VII": 7, "VIII": 8, "IX": 9, "X": 10
}

def _id_from_url(url):
    return int(url.rstrip("/").split("/")[-1]) if url else None

def load_pokemon(pokemon_id):
    pid = str(pokemon_id)
    pokemon_path = BASE_PATH / "pokemon" / pid / "index.json"
    with open(pokemon_path, encoding="utf-8") as f:
        pokemon = json.load(f)

    # extrai species id a partir da URL dentro do JSON do pokemon
    species_url = pokemon.get("species", {}).get("url", "")
    if species_url:
        species_id = species_url.rstrip("/").split("/")[-1]
    else:
        species_id = pid

    species_path = BASE_PATH / "pokemon-species" / species_id / "index.json"
    with open(species_path, encoding="utf-8") as f:
        species = json.load(f)

    return pokemon, species

def get_all_ids():
    pokemon_path = BASE_PATH / "pokemon"
    ids = []
    for entry in pokemon_path.iterdir():
        if entry.is_dir() and entry.name.isdigit():
            ids.append(int(entry.name))
    return sorted(ids)

# --- encounters helper: retorna versões onde o pokemon é capturável ---
def _load_encounters_for_pokemon(pid):
    """Tenta carregar o arquivo de encounters para pokemon/<pid> no dump local."""
    p1 = BASE_PATH / "pokemon" / str(pid) / "encounters" / "index.json"
    if p1.exists():
        try:
            with open(p1, encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    p2 = BASE_PATH / "pokemon" / str(pid) / "encounters.json"
    if p2.exists():
        try:
            with open(p2, encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    # fallback: alguns dumps colocam location_area_encounters dentro do index.json
    p3 = BASE_PATH / "pokemon" / str(pid) / "index.json"
    if p3.exists():
        try:
            with open(p3, encoding="utf-8") as f:
                obj = json.load(f)
            lae = obj.get("location_area_encounters") or obj.get("encounters") or obj.get("location_area_encounters_data")
            if isinstance(lae, list) and lae:
                return lae
        except Exception:
            pass
    return None

def get_capturable_games_for_pokemon(pokemon, species=None):
    """
    Retorna (games_set, details, source)
    - games_set: set de version names (ex: {'red','yellow','sun','moon'})
    - details: dict version -> list de encounter details (location_area, method, min_level, max_level)
    - source: 'encounters', 'varieties', 'none'
    """
    pid = pokemon.get("id") or _id_from_url(pokemon.get("url",""))
    enc = _load_encounters_for_pokemon(pid)
    games = set()
    details = {}

    if enc:
        for loc in enc:
            loc_name = ""
            la = loc.get("location_area")
            if isinstance(la, dict):
                loc_name = la.get("name", "")
            else:
                loc_name = la or ""
            for vd in loc.get("version_details", []) or []:
                version = vd.get("version", {}) or {}
                vname = version.get("name", "")
                for ed in vd.get("encounter_details", []) or []:
                    method = None
                    if isinstance(ed.get("method"), dict):
                        method = ed["method"].get("name")
                    elif ed.get("method"):
                        method = ed.get("method")
                    if not method and isinstance(ed.get("encounter_method"), dict):
                        method = ed["encounter_method"].get("name")
                    if method and method.lower() in NON_CAPTURE_METHODS:
                        continue
                    # considera capturável
                    games.add(vname)
                    min_level = ed.get("min_level", ed.get("minLevel", 0)) or 0
                    max_level = ed.get("max_level", ed.get("maxLevel", 0)) or 0
                    details.setdefault(vname, []).append({
                        "location_area": loc_name,
                        "method": method or "",
                        "min_level": min_level,
                        "max_level": max_level
                    })
        if games:
            return games, details, "encounters"

    # se não encontrou, tenta pelas varieties da species (às vezes outra variety tem encounters)
    if species is None:
        sp_url = pokemon.get("species", {}).get("url", "")
        if sp_url:
            spid = _id_from_url(sp_url)
            try:
                with open(BASE_PATH / "pokemon-species" / str(spid) / "index.json", encoding="utf-8") as f:
                    species = json.load(f)
            except FileNotFoundError:
                species = None

    if species:
        for v in species.get("varieties", []) or []:
            purl = v.get("pokemon", {}).get("url", "")
            if not purl:
                continue
            vid = _id_from_url(purl)
            pv_enc = _load_encounters_for_pokemon(vid)
            if not pv_enc:
                continue
            for loc in pv_enc:
                loc_name = ""
                la = loc.get("location_area")
                if isinstance(la, dict):
                    loc_name = la.get("name", "")
                else:
                    loc_name = la or ""
                for vd in loc.get("version_details", []) or []:
                    version = vd.get("version", {}) or {}
                    vname = version.get("name", "")
                    for ed in vd.get("encounter_details", []) or []:
                        method = None
                        if isinstance(ed.get("method"), dict):
                            method = ed["method"].get("name")
                        elif ed.get("method"):
                            method = ed.get("method")
                        if not method and isinstance(ed.get("encounter_method"), dict):
                            method = ed["encounter_method"].get("name")
                        if method and method.lower() in NON_CAPTURE_METHODS:
                            continue
                        games.add(vname)
                        min_level = ed.get("min_level", ed.get("minLevel", 0)) or 0
                        max_level = ed.get("max_level", ed.get("maxLevel", 0)) or 0
                        details.setdefault(vname, []).append({
                            "location_area": loc_name,
                            "method": method or "",
                            "min_level": min_level,
                            "max_level": max_level
                        })
        if games:
            return games, details, "varieties"

    return set(), {}, "none"

# --- utilitário para serializar games como Map("red", true, "yellow", true) ---
def ahk_map_from_games(games_list):
    """
    Recebe lista de version names (ex: ['red','fire-red']) e retorna
    uma string com o construtor AHK Map("red", true, "fire-red", true).
    Se a lista estiver vazia, retorna 'Map()'.
    """
    if not games_list:
        return "Map()"
    parts = []
    for g in games_list:
        key_js = json.dumps(g)   # garante escape correto
        parts.append(f"{key_js}, true")
    return "Map(" + ", ".join(parts) + ")"

def extract_basic(pokemon, species):
    pid = pokemon.get("id", 0)
    name = pokemon.get("name", "")
    species_name = species.get("name", "")
    species_id = species.get("id", 0)

    # types ordenados por slot
    types = sorted(pokemon.get("types", []), key=lambda t: t.get("slot", 0))
    type_1 = types[0]["type"]["name"] if len(types) > 0 else ""
    type_2 = types[1]["type"]["name"] if len(types) > 1 else ""

    # stats mapeados
    mapping = {
        "hp": "HP",
        "attack": "Atk",
        "defense": "Def",
        "special-attack": "SpAtk",
        "special-defense": "SpDef",
        "speed": "Spe"
    }
    stats = {}
    for s in pokemon.get("stats", []):
        stat_name = s["stat"]["name"]
        mapped = mapping.get(stat_name)
        if mapped:
            stats[mapped] = s.get("base_stat", 0)
    for v in mapping.values():
        stats.setdefault(v, 0)

    # abilities
    ability_1 = ""
    ability_2 = ""
    ability_hidden = ""
    for a in pokemon.get("abilities", []):
        ability_name = a["ability"]["name"].replace("-", " ").title()
        if a.get("is_hidden"):
            ability_hidden = ability_name
        elif ability_1 == "":
            ability_1 = ability_name
        else:
            ability_2 = ability_name

    height = pokemon.get("height", 0)
    weight = pokemon.get("weight", 0) / 10

    capture_rate = species.get("capture_rate", 0)
    gender_rate = species.get("gender_rate", -1)

    generation_obj = species.get("generation", {}) or {}
    gen_url = generation_obj.get("url", "")
    if gen_url:
        try:
            generation_id = int(gen_url.rstrip("/").split("/")[-1])
        except Exception:
            generation_id = 0
    else:
        gen_name = generation_obj.get("name", "") or ""
        generation_id = 0
        if gen_name.startswith("generation-"):
            roman = gen_name.split("-", 1)[1].upper()
            generation_id = ROMAN_MAP.get(roman, 0)

    # captura jogos onde o pokemon é capturável
    games_set, games_details, games_source = get_capturable_games_for_pokemon(pokemon, species)
    games_list = sorted(games_set)

    return {
        "id": pid,
        "name": name,
        "species_name": species_name,
        "species_id": species_id,
        "generation": generation_id,
        "type_1": type_1,
        "type_2": type_2,
        "height": height,
        "weight": weight,
        "gender_rate": gender_rate,
        "ability_1": ability_1,
        "ability_2": ability_2,
        "ability_hidden": ability_hidden,
        "stats": stats,
        "capture_rate": capture_rate,
        "games": games_list,               # lista de version names
        "games_details": games_details,    # opcional, pode ser grande
        "games_source": games_source
    }

def ahk_value(v):
    """
    Retorna a representação AHK para um valor:
    - strings -> JSON-escaped entre aspas
    - números -> sem aspas
    """
    if isinstance(v, str):
        return json.dumps(v)
    else:
        return str(v)

def generate_ahk_map(limit_ids=None):
    lines = []
    lines.append("pkmnDataAPI := Map()")
    lines.append("")

    ids = get_all_ids()
    if limit_ids is not None:
        ids = [i for i in ids if i in set(limit_ids)]

    for pid in ids:
        try:
            pokemon, species = load_pokemon(pid)
            data = extract_basic(pokemon, species)

            props = []
            for key in AHK_ORDER:
                ahk_key = AHK_KEY_MAP.get(key, key)
                # stats numéricos
                if key in ("HP", "Atk", "Def", "SpAtk", "SpDef", "Spe"):
                    props.append(f"{ahk_key}: {data['stats'][key]}")
                elif key == "games":
                    # data["games"] é lista de version names
                    games_list = data.get("games", []) or []
                    games_ahk = ahk_map_from_games(games_list)
                    props.append(f"{ahk_key}: {games_ahk}")
                else:
                    # captura capture_rate e gender_rate como números
                    if key in ("capture_rate", "gender_rate", "id", "species_id", "height", "generation"):
                        props.append(f"{ahk_key}: {ahk_value(data.get(key, 0))}")
                    else:
                        props.append(f"{ahk_key}: {ahk_value(data.get(key, ''))}")

            name_js = json.dumps(data["name"])
            line = f'pkmnDataAPI[{name_js}] := {{ ' + ", ".join(props) + " }"
            lines.append(line)

        except FileNotFoundError as e:
            # arquivo species ou pokemon faltando; registra e continua
            print(f"Arquivo não encontrado para Pokémon {pid}: {e}")
        except Exception as e:
            # outros erros: registra e continua
            print(f"Erro no Pokémon {pid}: {e}")

    return "\n".join(lines)

def save_output(text, filename="pkmnDataAPI 2.ahk"):
    output_path = Path(__file__).parent / filename
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(text)

if __name__ == "__main__":
    # Para gerar apenas os primeiros 151, descomente e ajuste:
    # ids_to_run = sorted(get_all_ids())[:151]
    # result = generate_ahk_map(limit_ids=ids_to_run)

    result = generate_ahk_map()
    save_output(result)
    print("Arquivo gerado com sucesso!")