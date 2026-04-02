import requests
import json
import os

# Cria a pasta /json se não existir
os.makedirs("json", exist_ok=True)

for i in range(1, 152):  # ids de 1 até 151
    url = f"https://pokeapi.co/api/v2/pokemon/{i}"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        # Salva cada Pokémon dentro da pasta /json
        with open(f"json/pokemon_{i}.json", "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"Pokemon {i} salvo em /json/pokemon_{i}.json")
    else:
        print(f"Erro ao acessar {url}: {response.status_code}")