/*
    Title: script
    Version: 0.1
    Created: Apr 1, 2026
*/

// #region CSS import
const root = document.documentElement;
const hpHigh = getComputedStyle(root).getPropertyValue("--hpHigh").trim();
const hpMid = getComputedStyle(root).getPropertyValue("--hpMid").trim();
const hpLow =  getComputedStyle(root).getPropertyValue("--hpLow").trim();
// #endregion



// #region JS-AHK communication
function updateGame(gameName) {
    window.chrome.webview.postMessage({ action: "UpdateGameContext", game: gameName });
}

function targetChanged(pkmnName) {
    window.chrome.webview.postMessage({ action: "UpdateSprite", name: pkmnName });
}

function RunThrow() {
    const dataForAHK = {
        action: "RunThrow",
        // tar
        tarName: document.getElementById("guiTarget").value,
        tarStatus: document.getElementById("guiTargetStatus")?.value || "",
        tarLvl: document.getElementById("guiTargetLvl")?.value || 1,
        tarGender: document.getElementById("guiTargetGender")?.value || "male",
        HPper: document.getElementById("hpSlider").value,
        // me
        myName: document.getElementById("guiMe")?.value || "bulbasaur",
        myLvl: document.getElementById("guiMyLvl")?.value || 1,
        myGender: document.getElementById("guiMyGender")?.value || "male",
        // battle & location
        encounter: document.getElementById("guiEncounter")?.value || "grass",
        locName: document.getElementById("guiLocationName")?.value || "", 
        locType: document.getElementById("guiLocationType")?.value || "route",
        isLit: document.getElementById("guiLocationLit")?.checked || false,
        // ball
        ball: document.getElementById("guiBall")?.value || "Poké Ball"
    };

    window.chrome.webview.postMessage(dataForAHK);
}
// #endregion


// #region functions called by AHK
let firstPokemon = "";
function updateTargetSelect(listRaw) {
    const list = listRaw.split(",");
    firstPokemon = list[0]; // saves the first one (e.g. bulbasaur or abra)

    const targetInput = document.getElementById("guiTarget");
    const datalist = document.getElementById("targetOptions");
    datalist.innerHTML = list.map(p => `<option value="${p}">`).join('');

    //if (!targetInput.value) {
        targetInput.value = firstPokemon;
    //}
}
function updateBallSelect(listRaw) {
    console.log("Bolas recebidas do AHK:", listRaw);
    const ballSelect = document.getElementById("guiBall");

    if (!ballSelect) {
        console.error("ERRO: Não encontrei o elemento com id 'guiBall' no HTML!");
        return;
    }

    const list = listRaw.split(",");

    ballSelect.options.length = 0;

    list.forEach(ballName => {
        let option = new Option(ballName, ballName);
        ballSelect.add(option);
    });

    if (list.includes("Poké Ball")) {
        ballSelect.value = "Poké Ball";
    }
}

function updateMeSelect(listRaw) {
    const list = listRaw.split(",");
    document.getElementById("meOptions").innerHTML = list.map(p => `<option value="${p}">`).join('');
}

function updateTarSprite(url) {
    document.getElementById("tarSprite").src = url
}

function updateMeSprite(url) {
    document.getElementById("meSprite").src = url
}
// #endregion


// #region GUI Behavior
const targetInput = document.getElementById("guiTarget");
// clears field on click
targetInput.addEventListener("focus", function() {
    this.value = '';
});
// selecting item or typing in
targetInput.addEventListener("input", function() {
    const list = document.getElementById("targetOptions").options;
    for (let i = 0; i < list.length; i++) {
        if (list[i].value === this.value) {
            targetChanged(this.value);
            this.blur();
            break;
        }
    }
})
// on leaving field
targetInput.addEventListener("blur", function() {
    if (this.value.trim() === "") {
        this.value = firstPokemon;
        targetChanged(this.value);
    }
});

function targetChanged(pkmnName) {
    if (!pkmnName || pkmnName.trim() === "") return;

    window.chrome.webview.postMessage({
        action: "UpdateSprite", 
        name: pkmnName
    });
}

function updateHPVisual(percent) {
    const fill = document.getElementById("hpFillTar");
    const text = document.getElementById("hpTextTar");

    fill.style.width = percent + "%";

    text.innerText = percent + "%";

    if (percent >= 50) {
        fill.style.backgroundColor = hpHigh;
    } else if (percent >= 20) {
        fill.style.backgroundColor = hpMid;
    } else {
        fill.style.backgroundColor = hpLow;
    }
}
// #endregion



