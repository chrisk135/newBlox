-- ==============================================================================
-- Roll Anime Card Farm - Advanced Automation Dashboard & Conveyor Pack Scanner
-- Version: 4.1 (Modal List Selectors, Robust Spawner, Rank 神, Trait Roller, Tower)
-- Self-contained, executable Lua script for loadstring or executor execution
-- ==============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ------------------------------------------------------------------------------
-- 1. SICHERE UMGEBUNG & EXECUTOR-KOMPATIBILITÄT
-- ------------------------------------------------------------------------------
local function getSafeGuiParent()
    if typeof(gethui) == "function" then
        return gethui()
    end
    local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if ok and coreGui and not RunService:IsStudio() then
        return coreGui
    end
    return player:WaitForChild("PlayerGui")
end

local function activatePrompt(prompt)
    if not prompt or not prompt.Parent then return false end
    local ok = false
    local oldLos = prompt.RequiresLineOfSight
    local oldDist = prompt.MaxActivationDistance
    local oldHold = prompt.HoldDuration

    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 999999
        prompt.HoldDuration = 0
    end)

    if typeof(fireproximityprompt) == "function" then
        ok = pcall(fireproximityprompt, prompt, 1) or pcall(fireproximityprompt, prompt)
    end
    if not ok then
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.05)
            prompt:InputHoldEnd()
            ok = true
        end)
    end

    pcall(function()
        prompt.HoldDuration = oldHold
        prompt.MaxActivationDistance = oldDist
        prompt.RequiresLineOfSight = oldLos
    end)

    return ok
end

local function activateClickDetector(cd)
    if not cd or not cd.Parent then return false end
    local ok = false
    local oldDist = cd.MaxActivationDistance
    pcall(function() cd.MaxActivationDistance = 999999 end)

    if typeof(fireclickdetector) == "function" then
        ok = pcall(fireclickdetector, cd, 1) or pcall(fireclickdetector, cd)
    end
    if not ok then
        pcall(function()
            if cd.MouseClick then
                cd.MouseClick:Fire(player)
                ok = true
            end
        end)
    end

    pcall(function() cd.MaxActivationDistance = oldDist end)
    return ok
end

local function touchPart(part)
    if not part or not part.Parent then return false end
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if typeof(firetouchinterest) == "function" then
        pcall(firetouchinterest, hrp, part, 0)
        task.wait(0.05)
        pcall(firetouchinterest, hrp, part, 1)
        return true
    else
        pcall(function()
            local oldPos = hrp.CFrame
            hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.1)
            hrp.CFrame = oldPos
        end)
        return true
    end
end

local function clickButton(btn)
    if not btn or not btn.Parent then return false end
    local ok = false
    if typeof(firesignal) == "function" then
        if btn:IsA("GuiButton") then
            pcall(firesignal, btn.MouseButton1Click)
            pcall(firesignal, btn.Activated)
            pcall(firesignal, btn.MouseButton1Down)
            pcall(firesignal, btn.MouseButton1Up)
            ok = true
        end
    end
    if typeof(getconnections) == "function" then
        pcall(function()
            if btn.MouseButton1Click then
                for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                    if conn.Fire then conn:Fire() elseif conn.fire then conn:fire() end
                    ok = true
                end
            end
            if btn.Activated then
                for _, conn in ipairs(getconnections(btn.Activated)) do
                    if conn.Fire then conn:Fire() elseif conn.fire then conn:fire() end
                    ok = true
                end
            end
        end)
    end
    return ok
end

local function findGameRemote(remoteNames)
    for _, name in ipairs(remoteNames) do
        local found = ReplicatedStorage:FindFirstChild(name, true)
        if found and (found:IsA("RemoteEvent") or found:IsA("RemoteFunction")) then
            return found
        end
    end
    return nil
end

local function getPlayerBase()
    local bases = workspace:FindFirstChild("Bases") or workspace:FindFirstChild("Plots") or workspace:FindFirstChild("Farms")
    if bases then
        local myBase = bases:FindFirstChild(player.Name) or bases:FindFirstChild(tostring(player.UserId))
        if myBase then return myBase end
        for _, b in ipairs(bases:GetChildren()) do
            local ownerVal = b:FindFirstChild("Owner") or b:FindFirstChild("OwnerName")
            if ownerVal and (ownerVal.Value == player or ownerVal.Value == player.Name) then
                return b
            end
        end
    end
    return nil
end

-- ------------------------------------------------------------------------------
-- 2. KONFIGURATION & ZUSTAND (SETTINGS & STATS)
-- ------------------------------------------------------------------------------
local SETTINGS = {
    Language = "DE", -- "DE", "EN"

    -- Conveyor & Pack Management (Sichere Defaults!)
    AutoSpawnEnabled = false,       -- Standardmäßig AUS (startet sicher, spawnt nicht ungefragt)
    ConveyorAutoBuyEnabled = false, -- Standardmäßig AUS (kauft NICHT sofort alles!)
    RequireMutationOnly = true,     -- Kauft NUR Packs MIT Mutation (normale Packs werden ignoriert!)
    SelectedPackFilter = "All",     -- "All" oder Pack-Name
    SelectedMutationFilter = "Nur mit Mutation (Any Mutation)", -- Nur Packs mit Mutation!
    SpawnInterval = 2.0,            -- Sekunden zwischen Spawns
    ConveyorScanInterval = 0.5,     -- Scan-Frequenz des Förderbands

    -- Rank Machine Settings (Screenshot 1 & 4)
    AutoRankRollEnabled = false,
    TargetRank = "神",              -- F, E, D, C, B, A, S, SS, SR, UR, LR, 神
    RankUseCash = true,
    RankUseGems = false,
    RankUseGemsFirst = false,

    -- Trait Roller Settings (Screenshot 2 & 3)
    AutoTraitRollEnabled = false,
    TargetTrait = "Almighty",       -- Any, Almighty, Sovereign, Godlike, Overlord, Berserk, Monarch, Solar, Cosmic

    -- Tower Replay Settings (Screenshot 5)
    AutoTowerEnabled = false,
    TowerStopOnDefeat = true,

    -- Base & Farm
    AutoCollectEnabled = true,

    -- Utility & Safety
    AntiAFKEnabled = true,
    FPSEnabled = true,
    SafeMode = true,
    GuiVisible = true,
    IsMinimised = false,

    -- Dynamisch erweiterbare Listen (aus Index-Buch & Förderband)
    AvailablePacks = {
        "All",
        "Dawn Pack",
        "Starter Pack",
        "Shadow Pack",
        "Demon Pack",
        "Pirate Pack",
        "Dragon Pack",
        "Titan Pack",
        "Slayer Pack",
        "Chakra Pack",
        "Sorcerer Pack",
        "Hero Pack",
        "Legendary Pack",
        "Mythic Pack",
        "Event Pack",
        "Halloween Pack",
        "Cosmic Pack",
        "Void Pack",
        "God Pack"
    },

    AvailableMutations = {
        "Nur mit Mutation (Any Mutation)",
        "Venomous",
        "Golden",
        "Diamond",
        "Rainbow",
        "Sakura",
        "Candy",
        "Blessed",
        "Radioactive",
        "Glitch",
        "Starfallen",
        "Admin",
        "Corrupt",
        "Void",
        "Shiny",
        "Electric",
        "Dark",
        "Frost",
        "Inferno",
        "Divine",
        "Normal (Keine)",
        "Any"
    }
}

local RANK_OPTIONS = {"F", "E", "D", "C", "B", "A", "S", "SS", "SR", "UR", "LR", "神"}
local TRAIT_OPTIONS = {"Any", "Almighty", "Sovereign", "Godlike", "Overlord", "Berserk", "Monarch", "Solar", "Cosmic", "Sniper", "Reaper", "Titan"}

local STATS = {
    PacksSpawned = 0,
    PacksBought = 0,
    LastBoughtPack = "Keines",
    LastBuyTime = "—",
    RankRolls = 0,
    TraitRolls = 0,
    TowerFloorsCleared = 0,
    IndexPacksFound = #SETTINGS.AvailablePacks,
    IndexMutationsFound = #SETTINGS.AvailableMutations,
    LastDetectedConveyorItem = "Warte auf Förderband...",
    StartTime = os.time()
}

-- ------------------------------------------------------------------------------
-- 3. MEHRSPRACHIGKEIT (LOCALIZATION: DE & EN)
-- ------------------------------------------------------------------------------
local LANGUAGES = {
    DE = {
        AppTitle = "Roll Anime Card Farm — Pro",
        Dashboard = "Dashboard",
        ConveyorTab = "Förderband & Packs",
        RankTab = "Rank-Maschine",
        TraitTab = "Trait-Roller",
        TowerTab = "Tower-Replay",
        BaseTab = "Basis & Farm",
        SettingsTab = "Optionen",

        DashboardStatus = "🚀 Automatisierungssystem aktiv",
        Session = "Sitzungszeit: ",
        Currency = "Yen: %s | Gems: %s",
        PacksSpawnedLabel = "Packs gespawnt: ",
        PacksBoughtLabel = "Packs gekauft: ",
        LastBoughtLabel = "Zuletzt gekauft: ",
        RankRollsLabel = "Rank-Rolls: ",
        TraitRollsLabel = "Trait-Rolls: ",
        TowerFloorsLabel = "Tower-Floors: ",
        ScanIndexBtn = "📖 Index-Buch scannen",
        StopAllBtn = "🛑 Alle Module stoppen",

        AutoSpawnToggleOn = "Auto Pack Spawnen: [ AN ]",
        AutoSpawnToggleOff = "Auto Pack Spawnen: [ AUS ]",
        ConveyorBuyToggleOn = "Förderband Auto-Kauf: [ AN ]",
        ConveyorBuyToggleOff = "Förderband Auto-Kauf: [ AUS ]",
        RequireMutationOn = "⭐ Nur Packs MIT Mutation kaufen: [ AN ]",
        RequireMutationOff = "⭐ Nur Packs MIT Mutation kaufen: [ AUS ]",
        PackFilterPrefix = "📦 Pack-Filter: ",
        MutationFilterPrefix = "✨ Mutations-Filter: ",
        ScanIndexManual = "🔄 Index & Förderband scannen",
        LiveConveyorHeader = "📡 Live Förderband-Erkennung:",
        PackSpawnerHint = "💡 Hinweis: Packs werden nicht geöffnet, sondern gekauft und in die Basis gelegt.",

        TargetRankPrefix = "🎯 Ziel-Rang: ",
        UseCashLabel = "Use Cash?",
        UseGemsLabel = "Use Gems?",
        UseGemsFirstLabel = "Use Gems First?",
        AutoRankToggleOn = "Auto-Rank Roll: [ AN ]",
        AutoRankToggleOff = "Auto-Rank Roll: [ AUS ]",

        TargetTraitPrefix = "🧬 Ziel-Trait: ",
        AutoTraitToggleOn = "Auto-Trait Roll: [ AN ]",
        AutoTraitToggleOff = "Auto-Trait Roll: [ AUS ]",
        TraitCostHint = "Kosten: 1 Gem pro Roll am Trait-Roller NPC",
        TraitPityHeader = "Pity-Garantien: 1.500 | 4.000 | 10.000 Rolls",

        AutoTowerToggleOn = "Auto-Tower Replay: [ AN ]",
        AutoTowerToggleOff = "Auto-Tower Replay: [ AUS ]",
        TowerDefeatStopOn = "Stopp nach Niederlage: [ AN ]",
        TowerDefeatStopOff = "Stopp nach Niederlage: [ AUS ]",
        TowerRewardHint = "Belohnung: +25 Trait Gems pro Floor",

        EquipBestBtn = "⭐ Beste Karten auf Farm setzen",
        AutoCollectOn = "Auto-Sammeln (Drops): [ AN ]",
        AutoCollectOff = "Auto-Sammeln (Drops): [ AUS ]",

        AntiAFKOn = "Anti-AFK Schutz: [ AN ]",
        AntiAFKOff = "Anti-AFK Schutz: [ AUS ]",
        FPSToggleOn = "FPS Booster: [ AN ]",
        FPSToggleOff = "FPS Booster: [ AUS ]",
        SafeModeOn = "Safe-Mode (Anti-Ban Drosselung): [ AN ]",
        SafeModeOff = "Safe-Mode (Anti-Ban Drosselung): [ AUS ]",
        KeybindHint = "💡 Drücke [Rechts-Strg] oder [Einfg] zum Ein-/Ausblenden",

        MiniPillFormat = "🃏 Anime Farm | 📦 %d gespawnt | 🛒 %d gekauft",
        ToastIndexScanned = "📖 Index gescannt: %d Packs & %d Mutationen geladen!",
        ToastPackBought = "🛒 Gekauft: %s!",
        ToastPackSpawned = "📦 Pack auf Förderband gespawnt!",
        ToastAllStopped = "🛑 Alle Automatisierungen gestoppt",

        OpenListHint = "  ▾ (Liste öffnen)",
        ModalTitlePack = "📦 Pack auswählen",
        ModalTitleMutation = "✨ Mutation auswählen",
        ModalTitleRank = "🎯 Ziel-Rang auswählen",
        ModalTitleTrait = "🧬 Ziel-Trait auswählen",
        SearchPlaceholder = "🔍 Suchen... (Tippen zum Filtern)",
        SelectedBadge = "Aktiv",
        ModalClose = "✕ Schließen"
    },
    EN = {
        AppTitle = "Roll Anime Card Farm — Pro",
        Dashboard = "Dashboard",
        ConveyorTab = "Conveyor & Packs",
        RankTab = "Rank Machine",
        TraitTab = "Trait Roller",
        TowerTab = "Tower Replay",
        BaseTab = "Base & Farm",
        SettingsTab = "Settings",

        DashboardStatus = "🚀 Automation System Active",
        Session = "Session: ",
        Currency = "Yen: %s | Gems: %s",
        PacksSpawnedLabel = "Packs Spawned: ",
        PacksBoughtLabel = "Packs Bought: ",
        LastBoughtLabel = "Last Bought: ",
        RankRollsLabel = "Rank Rolls: ",
        TraitRollsLabel = "Trait Rolls: ",
        TowerFloorsLabel = "Tower Floors: ",
        ScanIndexBtn = "📖 Scan Index Book",
        StopAllBtn = "🛑 Stop All Modules",

        AutoSpawnToggleOn = "Auto Spawn Pack: [ ON ]",
        AutoSpawnToggleOff = "Auto Spawn Pack: [ OFF ]",
        ConveyorBuyToggleOn = "Conveyor Auto-Buy: [ ON ]",
        ConveyorBuyToggleOff = "Conveyor Auto-Buy: [ OFF ]",
        RequireMutationOn = "⭐ Only Buy Mutated Packs: [ ON ]",
        RequireMutationOff = "⭐ Only Buy Mutated Packs: [ OFF ]",
        PackFilterPrefix = "📦 Pack Filter: ",
        MutationFilterPrefix = "✨ Mutation Filter: ",
        ScanIndexManual = "🔄 Scan Index & Conveyor",
        LiveConveyorHeader = "📡 Live Conveyor Feed:",
        PackSpawnerHint = "💡 Note: Packs are not opened; they are bought to your base for manual opening.",

        TargetRankPrefix = "🎯 Target Rank: ",
        UseCashLabel = "Use Cash?",
        UseGemsLabel = "Use Gems?",
        UseGemsFirstLabel = "Use Gems First?",
        AutoRankToggleOn = "Auto Rank Roll: [ ON ]",
        AutoRankToggleOff = "Auto Rank Roll: [ OFF ]",

        TargetTraitPrefix = "🧬 Target Trait: ",
        AutoTraitToggleOn = "Auto Trait Roll: [ ON ]",
        AutoTraitToggleOff = "Auto Trait Roll: [ OFF ]",
        TraitCostHint = "Cost: 1 Gem per roll at Trait Roller NPC",
        TraitPityHeader = "Pity Guarantees: 1,500 | 4,000 | 10,000 Rolls",

        AutoTowerToggleOn = "Auto Tower Replay: [ ON ]",
        AutoTowerToggleOff = "Auto Tower Replay: [ OFF ]",
        TowerDefeatStopOn = "Stop on Defeat: [ ON ]",
        TowerDefeatStopOff = "Stop on Defeat: [ OFF ]",
        TowerRewardHint = "Reward: +25 Trait Gems per cleared floor",

        EquipBestBtn = "⭐ Equip Best Cards to Farm",
        AutoCollectOn = "Auto-Collect Drops: [ ON ]",
        AutoCollectOff = "Auto-Collect Drops: [ OFF ]",

        AntiAFKOn = "Anti-AFK Protection: [ ON ]",
        AntiAFKOff = "Anti-AFK Protection: [ OFF ]",
        FPSToggleOn = "FPS Booster: [ ON ]",
        FPSToggleOff = "FPS Booster: [ OFF ]",
        SafeModeOn = "Safe-Mode (Anti-Ban Throttle): [ ON ]",
        SafeModeOff = "Safe-Mode (Anti-Ban Throttle): [ OFF ]",
        KeybindHint = "💡 Press [RightControl] or [Insert] to Toggle Menu",

        MiniPillFormat = "🃏 Anime Farm | 📦 %d spawned | 🛒 %d bought",
        ToastIndexScanned = "📖 Index scanned: %d packs & %d mutations loaded!",
        ToastPackBought = "🛒 Bought: %s!",
        ToastPackSpawned = "📦 Pack spawned on conveyor!",
        ToastAllStopped = "🛑 All automation modules stopped",

        OpenListHint = "  ▾ (Open List)",
        ModalTitlePack = "📦 Select Pack",
        ModalTitleMutation = "✨ Select Mutation",
        ModalTitleRank = "🎯 Select Target Rank",
        ModalTitleTrait = "🧬 Select Target Trait",
        SearchPlaceholder = "🔍 Search... (Type to filter)",
        SelectedBadge = "Active",
        ModalClose = "✕ Close"
    }
}

local translatableElements = {}

local function registerText(guiInstance, textKey, customFormatter)
    table.insert(translatableElements, {
        Instance = guiInstance,
        Key = textKey,
        Formatter = customFormatter
    })
    local langTable = LANGUAGES[SETTINGS.Language] or LANGUAGES.DE
    local rawText = langTable[textKey] or textKey
    if customFormatter then
        guiInstance.Text = customFormatter(rawText)
    else
        guiInstance.Text = rawText
    end
end

local function updateLanguage()
    local langTable = LANGUAGES[SETTINGS.Language] or LANGUAGES.DE
    for _, item in ipairs(translatableElements) do
        if item.Instance and item.Instance.Parent then
            local rawText = langTable[item.Key] or item.Key
            if item.Formatter then
                item.Instance.Text = item.Formatter(rawText)
            else
                item.Instance.Text = rawText
            end
        end
    end
end

-- ------------------------------------------------------------------------------
-- 4. DYNAMISCHE INDEX-BUCH & SPIELDATEN ERKENNUNG
-- ------------------------------------------------------------------------------
local packCyclerButtonRef = nil
local mutationCyclerButtonRef = nil

local FORBIDDEN_WORDS = {
    buy = true, open = true, spawn = true, claim = true, collect = true, equip = true,
    purchase = true, get = true, pack = true, item = true, card = true, all = true,
    any = true, none = true, press = true, hold = true, click = true, talk = true,
    roll = true, e = true, cost = true, price = true, free = true, level = true,
    locked = true, upgrade = true, ready = true, shop = true, index = true, profile = true
}

local function registerDiscoveredPack(packName)
    if not packName or type(packName) ~= "string" then return false end
    packName = packName:gsub("^%s+", ""):gsub("%s+$", "")
    if packName == "" or #packName > 50 then return false end

    local lower = packName:lower()
    if FORBIDDEN_WORDS[lower] or lower:find("spawn pack") or lower:find("open pack") or lower:find("buy pack") then
        return false
    end

    if not packName:find("Pack") then
        packName = packName .. " Pack"
    end
    for _, p in ipairs(SETTINGS.AvailablePacks) do
        if p:lower() == packName:lower() then return false end
    end
    table.insert(SETTINGS.AvailablePacks, packName)
    STATS.IndexPacksFound = #SETTINGS.AvailablePacks
    if packCyclerButtonRef and packCyclerButtonRef.UpdateText then
        packCyclerButtonRef.UpdateText()
    end
    return true
end

local function registerDiscoveredMutation(mutationName)
    if not mutationName or type(mutationName) ~= "string" then return false end
    mutationName = mutationName:gsub("^%s+", ""):gsub("%s+$", "")
    if mutationName == "" or #mutationName > 35 then return false end

    local lower = mutationName:lower()
    if FORBIDDEN_WORDS[lower] then return false end

    if lower:find("mutation") then
        mutationName = mutationName:gsub("%s*[Mm]utation%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
        lower = mutationName:lower()
        if lower == "" or FORBIDDEN_WORDS[lower] then return false end
    end

    for _, m in ipairs(SETTINGS.AvailableMutations) do
        if m:lower() == mutationName:lower() then return false end
    end
    table.insert(SETTINGS.AvailableMutations, mutationName)
    STATS.IndexMutationsFound = #SETTINGS.AvailableMutations
    if mutationCyclerButtonRef and mutationCyclerButtonRef.UpdateText then
        mutationCyclerButtonRef.UpdateText()
    end
    return true
end

local function scanIndexBook()
    local newPacks = 0
    local newMutations = 0

    -- 1. Scan PlayerGui Index Book / Dex / Collections
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetChildren()) do
            local gName = gui.Name:lower()
            if gName:find("index") or gName:find("book") or gName:find("card") or gName:find("dex") or gName:find("collection") then
                for _, desc in ipairs(gui:GetDescendants()) do
                    if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                        local text = desc.Text:gsub("^%s+", ""):gsub("%s+$", "")
                        if text ~= "" and #text < 45 then
                            if text:find("Pack") and not text:find("Spawn") and not text:find("Open") and not text:find("Buy") then
                                if registerDiscoveredPack(text) then newPacks += 1 end
                            end

                            local mutCandidate = text:match("^([%a%s]+)%s+Mutation")
                                or text:match("^Mutation:%s*([%a%s]+)")
                                or text:match("^([%a%s]+)%s*%([%d%.]+[KkMmBb%s/]*%)")
                            if mutCandidate then
                                if registerDiscoveredMutation(mutCandidate) then newMutations += 1 end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 2. Scan ReplicatedStorage Configuration / Modules / Folders
    local cardConfigs = ReplicatedStorage:FindFirstChild("Cards")
        or ReplicatedStorage:FindFirstChild("CardData")
        or ReplicatedStorage:FindFirstChild("Packs")
        or ReplicatedStorage:FindFirstChild("Index")
        or ReplicatedStorage:FindFirstChild("Mutations")

    if cardConfigs then
        for _, desc in ipairs(cardConfigs:GetDescendants()) do
            local n = desc.Name
            if n:find("Pack") and registerDiscoveredPack(n) then
                newPacks += 1
            elseif not FORBIDDEN_WORDS[n:lower()] and #n > 2 and registerDiscoveredMutation(n) then
                newMutations += 1
            end
        end
    end

    return newPacks, newMutations
end

-- ------------------------------------------------------------------------------
-- 5. FÖRDERBAND SCANNER & PARSER (CONVEYOR MONITOR)
-- ------------------------------------------------------------------------------
local KNOWN_MUTATION_KEYWORDS = {
    "venomous", "golden", "diamond", "rainbow", "sakura", "candy", "blessed",
    "radioactive", "glitch", "starfallen", "admin", "corrupt", "void", "shiny",
    "electric", "dark", "frost", "inferno", "divine", "mythic", "celestial"
}

local recentlyPurchasedPacks = {}

local function parsePackInfo(packInstance)
    local detectedPack = "Unknown Pack"
    local detectedMutation = "Normal (Keine)"
    local detectedPrice = ""
    local combinedText = ""
    local titleTexts = {}
    local prompt = packInstance:FindFirstChildWhichIsA("ProximityPrompt", true)

    for _, desc in ipairs(packInstance:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextBox") then
            local txt = desc.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if txt ~= "" then
                combinedText = combinedText .. " " .. txt
                table.insert(titleTexts, txt)

                if txt:find("%$%s*[%d%.]+%s*[KkMmBbTt%a]*") or txt:find("[%d%.]+[KkMmBb%a]*%s*/%s*[%d%.]+[KkMmBb%a]*") then
                    detectedPrice = txt
                end
            end
        elseif desc:IsA("BillboardGui") or desc:IsA("SurfaceGui") then
            local bName = desc.Name
            if bName:find("Pack") then
                registerDiscoveredPack(bName)
                detectedPack = bName
            end
        end
    end

    -- 1. Match known packs from AvailablePacks
    for _, p in ipairs(SETTINGS.AvailablePacks) do
        if p ~= "All" then
            local pLower = p:lower()
            if combinedText:lower():find(pLower, 1, true) or packInstance.Name:lower():find(pLower, 1, true) then
                detectedPack = p
                break
            end
        end
    end

    -- 2. Match known mutations from AvailableMutations
    for _, m in ipairs(SETTINGS.AvailableMutations) do
        if m ~= "Any" and m ~= "Normal (Keine)" and m ~= "Nur mit Mutation (Any Mutation)" then
            local mLower = m:lower()
            if combinedText:lower():find(mLower, 1, true) or packInstance.Name:lower():find(mLower, 1, true) then
                detectedMutation = m
                break
            end
        end
    end

    -- 3. Heuristic extraction from title texts (e.g., "Venomous Dawn Pack")
    for _, line in ipairs(titleTexts) do
        local mCandidate, pCandidate = line:match("^([%a%s]+)%s+([%a%s]+Pack)")
        if mCandidate and pCandidate then
            local cleanM = mCandidate:gsub("^%s+", ""):gsub("%s+$", "")
            local cleanP = pCandidate:gsub("^%s+", ""):gsub("%s+$", "")
            if not FORBIDDEN_WORDS[cleanM:lower()] and cleanM ~= "" then
                registerDiscoveredMutation(cleanM)
                if detectedMutation == "Normal (Keine)" or detectedMutation == "None" then
                    detectedMutation = cleanM
                end
            end
            if not FORBIDDEN_WORDS[cleanP:lower()] and cleanP ~= "" then
                registerDiscoveredPack(cleanP)
                if detectedPack == "Unknown Pack" then
                    detectedPack = cleanP
                end
            end
        elseif line:find("Pack") then
            local pOnly = line:match("([%a%s]+Pack)")
            if pOnly then
                local cleanP = pOnly:gsub("^%s+", ""):gsub("%s+$", "")
                if not FORBIDDEN_WORDS[cleanP:lower()] and cleanP ~= "" then
                    registerDiscoveredPack(cleanP)
                    if detectedPack == "Unknown Pack" then
                        detectedPack = cleanP
                    end
                end
            end
        end
    end

    if detectedPack == "Unknown Pack" then
        if packInstance.Name:find("Pack") then
            detectedPack = packInstance.Name
        else
            detectedPack = "Dawn Pack"
        end
    end

    return {
        Instance = packInstance,
        Prompt = prompt,
        Name = detectedPack,
        Mutation = detectedMutation,
        Price = detectedPrice,
        CombinedText = combinedText
    }
end

local function matchesConveyorFilter(packInfo)
    if not SETTINGS.ConveyorAutoBuyEnabled then
        return false
    end

    local isNormalPack = (packInfo.Mutation == "Normal (Keine)" or packInfo.Mutation == "None" or packInfo.Mutation == "Normal")

    -- 1. Sicherheits-Filter: Wenn "Nur Mutationen kaufen" aktiv ist, normale Packs direkt verwerfen
    if SETTINGS.RequireMutationOnly and isNormalPack then
        return false
    end

    -- 2. Pack-Filter (Name)
    if SETTINGS.SelectedPackFilter ~= "All" then
        local filterLower = SETTINGS.SelectedPackFilter:lower():gsub(" pack", "")
        local packLower = packInfo.Name:lower():gsub(" pack", "")
        if not packLower:find(filterLower, 1, true) and not packInfo.CombinedText:lower():find(filterLower, 1, true) then
            return false
        end
    end

    -- 3. Mutations-Filter
    if SETTINGS.SelectedMutationFilter == "Nur mit Mutation (Any Mutation)" or SETTINGS.SelectedMutationFilter == "Any Mutation" then
        if isNormalPack then
            return false
        end
    elseif SETTINGS.SelectedMutationFilter ~= "Any" then
        local filterMut = SETTINGS.SelectedMutationFilter:lower()
        if filterMut:find("normal") or filterMut:find("keine") or filterMut == "none" then
            if not isNormalPack then
                return false
            end
        else
            local mutLower = packInfo.Mutation:lower()
            if not mutLower:find(filterMut, 1, true) and not packInfo.CombinedText:lower():find(filterMut, 1, true) then
                return false
            end
        end
    end

    return true
end

local function buyConveyorPack(packInfo)
    local targetInstance = packInfo.Instance
    local now = os.clock()
    if recentlyPurchasedPacks[targetInstance] and (now - recentlyPurchasedPacks[targetInstance] < 3.0) then
        return false
    end

    local bought = false

    if packInfo.Prompt and packInfo.Prompt.Parent then
        activatePrompt(packInfo.Prompt)
        bought = true
    else
        for _, desc in ipairs(packInfo.Instance:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                activatePrompt(desc)
                bought = true
                break
            end
        end
    end

    local buyRemote = findGameRemote({"BuyPack", "PurchasePack", "ConveyorBuy", "BuyConveyorPack", "BuyItem"})
    if buyRemote then
        pcall(function()
            if buyRemote:IsA("RemoteEvent") then
                buyRemote:FireServer(packInfo.Name, packInfo.Instance)
            else
                buyRemote:InvokeServer(packInfo.Name, packInfo.Instance)
            end
        end)
        bought = true
    end

    if bought then
        recentlyPurchasedPacks[targetInstance] = now
        STATS.PacksBought += 1
        STATS.LastBoughtPack = string.format("%s (%s)", packInfo.Name, packInfo.Mutation)
        STATS.LastBuyTime = os.date("%H:%M:%S")
    end

    return bought
end

local function scanConveyorPacks()
    local conveyorArea = workspace:FindFirstChild("Conveyor", true) 
        or workspace:FindFirstChild("Conveyors", true)
        or workspace:FindFirstChild("Belt", true)
        or workspace:FindFirstChild("Farm", true) 
        or getPlayerBase()
        or workspace

    local candidatePacks = {}
    local seenInstances = {}

    local function checkAndAddCandidate(modelOrPrompt)
        local targetModel = modelOrPrompt
        if modelOrPrompt:IsA("ProximityPrompt") then
            targetModel = modelOrPrompt.Parent
            if targetModel and not targetModel:IsA("Model") and targetModel.Parent and targetModel.Parent:IsA("Model") then
                targetModel = targetModel.Parent
            end
        end

        if not targetModel or seenInstances[targetModel] then return end

        local mName = targetModel.Name:lower()
        if mName:find("ground") or mName:find("base") or mName:find("floor") or mName:find("terrain") then
            return
        end

        local hasBuyPrompt = false
        local hasPackBillboard = false

        for _, d in ipairs(targetModel:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                local aText = (d.ActionText or ""):lower()
                local oText = (d.ObjectText or ""):lower()
                if aText:find("buy") or aText:find("pack") or oText:find("pack") or oText:find("buy") then
                    hasBuyPrompt = true
                    break
                end
            elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
                for _, lbl in ipairs(d:GetDescendants()) do
                    if (lbl:IsA("TextLabel") or lbl:IsA("TextBox")) and lbl.Text:find("Pack") then
                        hasPackBillboard = true
                        break
                    end
                end
            end
            if hasPackBillboard then break end
        end

        if hasBuyPrompt or hasPackBillboard or mName:find("pack") then
            seenInstances[targetModel] = true
            local info = parsePackInfo(targetModel)
            table.insert(candidatePacks, info)
        end
    end

    for _, desc in ipairs(conveyorArea:GetDescendants()) do
        if desc:IsA("Model") and desc.Name:lower():find("pack") then
            checkAndAddCandidate(desc)
        elseif desc:IsA("ProximityPrompt") and (desc.ActionText:lower():find("buy") or desc.ObjectText:lower():find("pack")) then
            checkAndAddCandidate(desc)
        end
    end

    return candidatePacks
end

-- ------------------------------------------------------------------------------
-- 6. AUTO PACK SPAWNER (GRÜNER SOCKEL IN DER BASIS / CONVEYOR PEDESTAL)
-- ------------------------------------------------------------------------------
local cachedSpawner = nil

local function isSpawnerObject(inst)
    if not inst then return false end
    local n = inst.Name:lower()

    if (n:find("spawn") and (n:find("pack") or n:find("card") or n:find("stand") or n:find("pedestal") or n:find("button") or n:find("pad") or n:find("conveyor")))
        or n == "spawnpack" or n == "packspawn" or n == "spawn_pack" or n == "pack_spawn"
        or n == "spawner" or n == "spawn" then
        return true
    end

    for _, desc in ipairs(inst:GetDescendants()) do
        if desc:IsA("SurfaceGui") or desc:IsA("BillboardGui") then
            for _, txt in ipairs(desc:GetDescendants()) do
                if (txt:IsA("TextLabel") or txt:IsA("TextButton")) and txt.Text then
                    local tLower = txt.Text:lower()
                    if tLower:find("spawn") and (tLower:find("pack") or tLower:find("card")) then
                        return true
                    end
                end
            end
        elseif desc:IsA("ProximityPrompt") then
            local aText = (desc.ActionText or ""):lower()
            local oText = (desc.ObjectText or ""):lower()
            if aText:find("spawn") or oText:find("spawn") then
                return true
            end
        end
    end
    return false
end

local function activateSpawnerTarget(target)
    if not target or not target.Parent then return false end
    local triggered = false

    -- 1. ClickDetector on target or descendants
    local cd = target:IsA("ClickDetector") and target or target:FindFirstChildWhichIsA("ClickDetector", true)
    if cd then
        if activateClickDetector(cd) then triggered = true end
    end

    -- 2. ProximityPrompt on target or descendants
    local prompt = target:IsA("ProximityPrompt") and target or target:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        if activatePrompt(prompt) then triggered = true end
    end

    -- 3. SurfaceGui / BillboardGui Buttons
    for _, desc in ipairs(target:GetDescendants()) do
        if desc:IsA("GuiButton") then
            if clickButton(desc) then triggered = true end
        end
    end

    -- 4. TouchPart (Physical step/collision)
    local part = target:IsA("BasePart") and target or target:FindFirstChildWhichIsA("BasePart", true)
    if part then
        if touchPart(part) then triggered = true end
    end

    return triggered
end

local function fireSpawnRemotes()
    local fired = false
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            local n = desc.Name:lower()
            if (n:find("spawn") and (n:find("pack") or n:find("card") or n:find("conveyor") or n:find("belt")))
                or n == "spawnpack" or n == "spawn_pack"
                or n == "rollpack" or n == "roll_pack"
                or n == "requestspawn" or n == "spawn" then
                pcall(function()
                    if desc:IsA("RemoteEvent") then
                        desc:FireServer()
                    else
                        desc:InvokeServer()
                    end
                    fired = true
                end)
            end
        end
    end
    return fired
end

local function triggerSpawnPackPedestal()
    local triggered = false

    -- 1. Try cached spawner if still valid
    if cachedSpawner and cachedSpawner.Parent then
        if activateSpawnerTarget(cachedSpawner) then
            triggered = true
        else
            cachedSpawner = nil
        end
    end

    -- 2. Search near player character (within 55 studs)
    if not triggered then
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local myPos = hrp.Position
            local nearbyCandidates = {}

            local function checkCandidate(item)
                if not item or not item.Parent then return end
                local pos = nil
                if item:IsA("BasePart") then
                    pos = item.Position
                elseif item:IsA("Model") then
                    pos = item.PrimaryPart and item.PrimaryPart.Position or (item:FindFirstChildWhichIsA("BasePart") and item:FindFirstChildWhichIsA("BasePart").Position)
                end
                if pos and (pos - myPos).Magnitude <= 55 then
                    table.insert(nearbyCandidates, item)
                end
            end

            local base = getPlayerBase()
            if base then
                for _, ch in ipairs(base:GetChildren()) do checkCandidate(ch) end
            end
            for _, ch in ipairs(workspace:GetChildren()) do checkCandidate(ch) end

            for _, cand in ipairs(nearbyCandidates) do
                if isSpawnerObject(cand) then
                    if activateSpawnerTarget(cand) then
                        cachedSpawner = cand
                        triggered = true
                        break
                    end
                end
            end
        end
    end

    -- 3. Search player base or workspace descendants
    if not triggered then
        local baseFolder = getPlayerBase() or workspace:FindFirstChild("Bases") or workspace
        for _, desc in ipairs(baseFolder:GetDescendants()) do
            if desc:IsA("Model") or desc:IsA("BasePart") or desc:IsA("SurfaceGui") or desc:IsA("BillboardGui") then
                if isSpawnerObject(desc) then
                    local target = (desc:IsA("SurfaceGui") or desc:IsA("BillboardGui")) and (desc.Adornee or desc.Parent) or desc
                    if activateSpawnerTarget(target) then
                        cachedSpawner = target
                        triggered = true
                        break
                    end
                end
            end
        end
    end

    -- 4. Remote events fallback
    if fireSpawnRemotes() then
        triggered = true
    end

    if triggered then
        STATS.PacksSpawned += 1
    end

    return triggered
end

-- ------------------------------------------------------------------------------
-- 7. AUTO RANK ROLL (RANK-MASCHINE TARGET F BIS 神)
-- ------------------------------------------------------------------------------
local function executeRankRoll()
    local rankGui = player:FindFirstChild("PlayerGui") and (
        player.PlayerGui:FindFirstChild("AutoRollSettings", true)
        or player.PlayerGui:FindFirstChild("RankMachine", true)
        or player.PlayerGui:FindFirstChild("GradeMachine", true)
        or player.PlayerGui:FindFirstChild("AutoRoll", true)
    )

    if rankGui then
        for _, desc in ipairs(rankGui:GetDescendants()) do
            if desc:IsA("GuiButton") then
                local bText = (desc:IsA("TextButton") and desc.Text or desc.Name):gsub("^%s+", ""):gsub("%s+$", "")
                if bText == SETTINGS.TargetRank or desc.Name == SETTINGS.TargetRank then
                    clickButton(desc)
                    break
                end
            end
        end

        local function syncCheckbox(keyword, desiredState)
            for _, desc in ipairs(rankGui:GetDescendants()) do
                if desc:IsA("GuiButton") or desc:IsA("Frame") then
                    local nameL = desc.Name:lower()
                    if nameL:find(keyword) then
                        local btn = desc:IsA("GuiButton") and desc or desc:FindFirstChildWhichIsA("GuiButton")
                        if btn then
                            local hasCheck = btn:FindFirstChild("Check") or btn:FindFirstChild("Tick") or (btn:IsA("TextButton") and btn.Text:find("✓"))
                            if (desiredState and not hasCheck) or (not desiredState and hasCheck) then
                                clickButton(btn)
                            end
                        end
                    end
                end
            end
        end

        syncCheckbox("cash", SETTINGS.RankUseCash)
        syncCheckbox("gemsfirst", SETTINGS.RankUseGemsFirst)
        syncCheckbox("gems", SETTINGS.RankUseGems)

        for _, desc in ipairs(rankGui:GetDescendants()) do
            if desc:IsA("GuiButton") and desc.Name:lower():find("start") or (desc:IsA("TextButton") and desc.Text:lower():find("start roll")) then
                clickButton(desc)
                STATS.RankRolls += 1
                break
            end
        end
    else
        local rankRemote = findGameRemote({"RollRank", "UpgradeRank", "GradeRoll", "AutoRollRank"})
        if rankRemote then
            pcall(function()
                if rankRemote:IsA("RemoteEvent") then
                    rankRemote:FireServer(SETTINGS.TargetRank, SETTINGS.RankUseCash, SETTINGS.RankUseGems, SETTINGS.RankUseGemsFirst)
                else
                    rankRemote:InvokeServer(SETTINGS.TargetRank, SETTINGS.RankUseCash, SETTINGS.RankUseGems, SETTINGS.RankUseGemsFirst)
                end
                STATS.RankRolls += 1
            end)
        end
    end
end

-- ------------------------------------------------------------------------------
-- 8. AUTO TRAIT ROLL (TRAIT ROLLER NPC, 1 GEM PER ROLL)
-- ------------------------------------------------------------------------------
local function executeTraitRoll()
    local traitGui = player:FindFirstChild("PlayerGui") and (
        player.PlayerGui:FindFirstChild("TraitsMachine", true)
        or player.PlayerGui:FindFirstChild("TraitRoller", true)
        or player.PlayerGui:FindFirstChild("TraitRoll", true)
    )

    if traitGui then
        for _, desc in ipairs(traitGui:GetDescendants()) do
            if desc:IsA("GuiButton") then
                local bText = (desc:IsA("TextButton") and desc.Text or desc.Name):lower()
                if bText:find("auto roll") or bText:find("roll") or desc.Name == "AutoRoll" then
                    clickButton(desc)
                    STATS.TraitRolls += 1
                    break
                end
            end
        end
    else
        local traitNpc = workspace:FindFirstChild("Trait Roller", true)
            or workspace:FindFirstChild("TraitRoller", true)
            or workspace:FindFirstChild("Gojyo", true)

        if traitNpc then
            local prompt = traitNpc:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                activatePrompt(prompt)
            end
        end

        local traitRemote = findGameRemote({"RollTrait", "RerollTrait", "TraitRoll", "BuyTraitRoll"})
        if traitRemote then
            pcall(function()
                if traitRemote:IsA("RemoteEvent") then
                    traitRemote:FireServer(SETTINGS.TargetTrait)
                else
                    traitRemote:InvokeServer(SETTINGS.TargetTrait)
                end
                STATS.TraitRolls += 1
            end)
        end
    end
end

-- ------------------------------------------------------------------------------
-- 9. AUTO TOWER REPLAY (INFINITY TOWER FLOOR REPLAY)
-- ------------------------------------------------------------------------------
local function checkTowerEntrance()
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local towerDoor = workspace:FindFirstChild("TowerEntrance", true)
        or workspace:FindFirstChild("InfinityTower", true)
        or workspace:FindFirstChild("CastleDoor", true)

    if not towerDoor then
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("TextLabel") and (desc.Text:match("^Floor%s*%d+") or desc.Text:find("InfinityTower")) then
                towerDoor = desc.Parent
                break
            end
        end
    end

    if towerDoor then
        local prompt = towerDoor:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            activatePrompt(prompt)
        end
    end

    local towerRemote = findGameRemote({"StartTower", "ReplayTower", "EnterFloor", "TowerReplay", "StartFloor"})
    if towerRemote then
        pcall(function()
            if towerRemote:IsA("RemoteEvent") then
                towerRemote:FireServer()
            else
                towerRemote:InvokeServer()
            end
            STATS.TowerFloorsCleared += 1
        end)
    end
end

-- ------------------------------------------------------------------------------
-- 10. OPTIMIERUNGEN & UTILITY (ANTI-AFK & FPS BOOSTER)
-- ------------------------------------------------------------------------------
local function setupAntiAFK()
    player.Idled:Connect(function()
        if SETTINGS.AntiAFKEnabled then
            local VirtualUser = game:GetService("VirtualUser")
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end
        end
    end)
end

local function applyFPSBoost()
    if not SETTINGS.FPSEnabled then return end
    pcall(function()
        settings().Rendering.QualityLevel = 1
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 0.5
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
    end)
end

local function setupKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert then
            SETTINGS.GuiVisible = not SETTINGS.GuiVisible
            local parentGui = getSafeGuiParent()
            local screenGui = parentGui:FindFirstChild("AnimeCardFarmProGUI")
            if screenGui then
                local mainFrame = screenGui:FindFirstChild("MainFrame")
                local miniPill = screenGui:FindFirstChild("MiniPill")
                if mainFrame then
                    mainFrame.Visible = SETTINGS.GuiVisible and not SETTINGS.IsMinimised
                end
                if miniPill then
                    miniPill.Visible = SETTINGS.GuiVisible and SETTINGS.IsMinimised
                end
            end
        end
    end)
end

-- ------------------------------------------------------------------------------
-- 11. UI STYLING & HELPERS
-- ------------------------------------------------------------------------------
local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = instance
    return corner
end

local function addStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(50, 55, 70)
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

local function createLabel(name, size, pos, text, parent, align, color, font, fontSize)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = pos
    label.Text = text or ""
    label.TextColor3 = color or Color3.fromRGB(220, 225, 235)
    label.Font = font or Enum.Font.Gotham
    label.TextSize = fontSize or 13
    label.TextXAlignment = align or Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = parent
    return label
end

local function createButton(name, size, pos, text, parent, bgColor)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = size
    btn.Position = pos
    btn.Text = text or ""
    btn.TextColor3 = Color3.fromRGB(240, 240, 245)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BackgroundColor3 = bgColor or Color3.fromRGB(36, 38, 50)
    btn.AutoButtonColor = true
    addCorner(btn, 6)
    btn.Parent = parent
    return btn
end

local function updateToggleButtonStyle(button, state)
    if state then
        button.BackgroundColor3 = Color3.fromRGB(36, 145, 78)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        button.BackgroundColor3 = Color3.fromRGB(45, 48, 62)
        button.TextColor3 = Color3.fromRGB(180, 185, 200)
    end
end

local function makeDraggable(dragHandle, targetFrame)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function getPlayerCurrencies()
    local yen = 0
    local gems = 0
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local y = leaderstats:FindFirstChild("Yen") or leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Coins")
        local g = leaderstats:FindFirstChild("Gems") or leaderstats:FindFirstChild("Diamonds")
        if y and typeof(y.Value) == "number" then yen = y.Value end
        if g and typeof(g.Value) == "number" then gems = g.Value end
    end
    local function fmt(n)
        if n >= 1e6 then return string.format("%.2fM", n / 1e6)
        elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
        else return tostring(n) end
    end
    return fmt(yen), fmt(gems)
end

-- ------------------------------------------------------------------------------
-- 12. UI MODAL SELECTION LIST & TABS ERSTELLUNG
-- ------------------------------------------------------------------------------
local activeScreenGui = nil
local activeToastLabel = nil

local function showToast(message)
    if activeToastLabel and activeToastLabel.Parent then
        activeToastLabel.Text = message
    end
end

local currentModal = nil

local function openSelectionModal(titleText, items, currentSelection, onSelect)
    if currentModal and currentModal.Parent then
        currentModal:Destroy()
        currentModal = nil
    end

    local parentGui = activeScreenGui or getSafeGuiParent():FindFirstChild("AnimeCardFarmProGUI")
    if not parentGui then return end

    -- Dim Backdrop
    local backdrop = Instance.new("TextButton")
    backdrop.Name = "SelectionModalBackdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.Position = UDim2.new(0, 0, 0, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.55
    backdrop.Text = ""
    backdrop.AutoButtonColor = false
    backdrop.ZIndex = 50
    backdrop.Parent = parentGui
    currentModal = backdrop

    -- Modal Container
    local modalFrame = Instance.new("Frame")
    modalFrame.Name = "ModalFrame"
    modalFrame.Size = UDim2.new(0, 480, 0, 400)
    modalFrame.Position = UDim2.new(0.5, -240, 0.5, -200)
    modalFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    modalFrame.ZIndex = 51
    addCorner(modalFrame, 10)
    addStroke(modalFrame, Color3.fromRGB(55, 105, 205), 1.8)
    modalFrame.Parent = backdrop

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = Color3.fromRGB(26, 29, 40)
    header.ZIndex = 52
    addCorner(header, 10)
    header.Parent = modalFrame

    local titleLbl = createLabel("Title", UDim2.new(1, -70, 1, 0), UDim2.new(0, 14, 0, 0), titleText .. string.format(" (%d)", #items), header, Enum.TextXAlignment.Left, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, 14)
    titleLbl.ZIndex = 53

    local closeBtn = createButton("CloseBtn", UDim2.new(0, 32, 0, 28), UDim2.new(1, -40, 0, 7), "✕", header, Color3.fromRGB(160, 40, 40))
    closeBtn.ZIndex = 53
    closeBtn.MouseButton1Click:Connect(function()
        if backdrop and backdrop.Parent then backdrop:Destroy() end
        currentModal = nil
    end)
    backdrop.MouseButton1Click:Connect(function()
        if backdrop and backdrop.Parent then backdrop:Destroy() end
        currentModal = nil
    end)

    -- Search Box
    local searchFrame = Instance.new("Frame")
    searchFrame.Name = "SearchFrame"
    searchFrame.Size = UDim2.new(1, -24, 0, 36)
    searchFrame.Position = UDim2.new(0, 12, 0, 50)
    searchFrame.BackgroundColor3 = Color3.fromRGB(28, 31, 42)
    searchFrame.ZIndex = 52
    addCorner(searchFrame, 6)
    addStroke(searchFrame, Color3.fromRGB(48, 55, 75), 1)
    searchFrame.Parent = modalFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -16, 1, 0)
    searchBox.Position = UDim2.new(0, 8, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = LANGUAGES[SETTINGS.Language].SearchPlaceholder or "🔍 Suchen... (z.B. Dawn, Shiny)"
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 155)
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(240, 240, 255)
    searchBox.TextSize = 13
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.ZIndex = 53
    searchBox.Parent = searchFrame

    -- Scrolling List Frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollList"
    scrollFrame.Size = UDim2.new(1, -24, 1, -100)
    scrollFrame.Position = UDim2.new(0, 12, 0, 92)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    scrollFrame.BackgroundTransparency = 0.5
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 100, 180)
    scrollFrame.ZIndex = 52
    addCorner(scrollFrame, 6)
    scrollFrame.Parent = modalFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 8)
    padding.Parent = scrollFrame

    local function populateList(filterQuery)
        for _, ch in ipairs(scrollFrame:GetChildren()) do
            if ch:IsA("GuiButton") or ch:IsA("Frame") then ch:Destroy() end
        end

        local qLower = filterQuery:lower():gsub("^%s+", ""):gsub("%s+$", "")
        local displayedCount = 0

        for idx, item in ipairs(items) do
            local matches = true
            if qLower ~= "" then
                matches = item:lower():find(qLower, 1, true) ~= nil
            end

            if matches then
                displayedCount += 1
                local isCurrent = (item == currentSelection)
                local rowBtn = Instance.new("TextButton")
                rowBtn.Name = "Item_" .. idx
                rowBtn.Size = UDim2.new(1, 0, 0, 34)
                rowBtn.ZIndex = 53
                addCorner(rowBtn, 6)

                if isCurrent then
                    rowBtn.BackgroundColor3 = Color3.fromRGB(38, 95, 175)
                    rowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    rowBtn.Font = Enum.Font.GothamBold
                    rowBtn.Text = "  ✓  " .. item .. "  [" .. (LANGUAGES[SETTINGS.Language].SelectedBadge or "Aktiv") .. "]"
                else
                    rowBtn.BackgroundColor3 = Color3.fromRGB(26, 29, 39)
                    rowBtn.TextColor3 = Color3.fromRGB(215, 220, 240)
                    rowBtn.Font = Enum.Font.GothamMedium
                    rowBtn.Text = "     " .. item
                end

                rowBtn.TextSize = 13
                rowBtn.TextXAlignment = Enum.TextXAlignment.Left
                rowBtn.Parent = scrollFrame

                rowBtn.MouseEnter:Connect(function()
                    if not isCurrent then
                        rowBtn.BackgroundColor3 = Color3.fromRGB(36, 42, 58)
                    end
                end)
                rowBtn.MouseLeave:Connect(function()
                    if not isCurrent then
                        rowBtn.BackgroundColor3 = Color3.fromRGB(26, 29, 39)
                    end
                end)

                rowBtn.MouseButton1Click:Connect(function()
                    if backdrop and backdrop.Parent then backdrop:Destroy() end
                    currentModal = nil
                    if onSelect then
                        onSelect(item)
                    end
                end)
            end
        end

        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, displayedCount * 38 + 10)
    end

    populateList("")

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        populateList(searchBox.Text)
    end)
end

local function createDashboardTab(onScanIndex, onStopAll)
    local frame = Instance.new("Frame")
    frame.Name = "DashboardTab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1

    local statusLbl = createLabel("StatusHeader", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 8), "", frame, Enum.TextXAlignment.Left, Color3.fromRGB(120, 210, 160), Enum.Font.GothamBold, 14)
    registerText(statusLbl, "DashboardStatus")

    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(1, -20, 0, 150)
    statsContainer.Position = UDim2.new(0, 10, 0, 38)
    statsContainer.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
    addCorner(statsContainer, 8)
    addStroke(statsContainer, Color3.fromRGB(48, 54, 72), 1)
    statsContainer.Parent = frame

    local currencyLabel = createLabel("Currencies", UDim2.new(0.5, -15, 0, 26), UDim2.new(0, 12, 0, 10), "Yen: 0 | Gems: 0", statsContainer, Enum.TextXAlignment.Left, Color3.fromRGB(255, 220, 100), Enum.Font.GothamBold, 13)
    local sessionLabel = createLabel("SessionTime", UDim2.new(0.5, -15, 0, 26), UDim2.new(0.5, 5, 0, 10), "Session: 00:00:00", statsContainer)

    local spawnedLabel = createLabel("PacksSpawned", UDim2.new(0.5, -15, 0, 24), UDim2.new(0, 12, 0, 42), "Packs gespawnt: 0", statsContainer)
    local boughtLabel = createLabel("PacksBought", UDim2.new(0.5, -15, 0, 24), UDim2.new(0.5, 5, 0, 42), "Packs gekauft: 0", statsContainer)

    local lastBoughtLabel = createLabel("LastBought", UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, 72), "Zuletzt gekauft: Keines", statsContainer, Enum.TextXAlignment.Left, Color3.fromRGB(180, 205, 240))
    local liveConveyorItem = createLabel("LiveConveyor", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 100), "Förderband: Warte auf Packs...", statsContainer, Enum.TextXAlignment.Left, Color3.fromRGB(200, 205, 220), Enum.Font.Gotham, 12)
    liveConveyorItem.TextWrapped = true

    local scanBtn = createButton("ScanIndexBtn", UDim2.new(0.48, 0, 0, 40), UDim2.new(0, 10, 0, 205), "", frame, Color3.fromRGB(40, 115, 215))
    registerText(scanBtn, "ScanIndexBtn")
    scanBtn.MouseButton1Click:Connect(function()
        if onScanIndex then onScanIndex() end
    end)

    local stopBtn = createButton("StopAllBtn", UDim2.new(0.48, 0, 0, 40), UDim2.new(0.52, 0, 0, 205), "", frame, Color3.fromRGB(180, 45, 45))
    registerText(stopBtn, "StopAllBtn")
    stopBtn.MouseButton1Click:Connect(function()
        if onStopAll then onStopAll() end
    end)

    return frame, sessionLabel, currencyLabel, spawnedLabel, boughtLabel, lastBoughtLabel, liveConveyorItem
end

local function createConveyorTab(onManualScan)
    local frame = Instance.new("Frame")
    frame.Name = "ConveyorTab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1

    local hintLbl = createLabel("Hint", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 6), "", frame, Enum.TextXAlignment.Left, Color3.fromRGB(160, 190, 235), Enum.Font.GothamMedium, 12)
    hintLbl.TextWrapped = true
    registerText(hintLbl, "PackSpawnerHint")

    local spawnToggle = createButton("SpawnToggle", UDim2.new(0.48, 0, 0, 42), UDim2.new(0, 10, 0, 45), "", frame)
    local function updateSpawnBtn()
        updateToggleButtonStyle(spawnToggle, SETTINGS.AutoSpawnEnabled)
        spawnToggle.Text = SETTINGS.AutoSpawnEnabled and (LANGUAGES[SETTINGS.Language].AutoSpawnToggleOn) or (LANGUAGES[SETTINGS.Language].AutoSpawnToggleOff)
    end
    registerText(spawnToggle, "AutoSpawnToggleOn", function()
        return SETTINGS.AutoSpawnEnabled and LANGUAGES[SETTINGS.Language].AutoSpawnToggleOn or LANGUAGES[SETTINGS.Language].AutoSpawnToggleOff
    end)
    updateSpawnBtn()
    spawnToggle.MouseButton1Click:Connect(function()
        SETTINGS.AutoSpawnEnabled = not SETTINGS.AutoSpawnEnabled
        updateSpawnBtn()
        if SETTINGS.AutoSpawnEnabled then
            showToast("▶ Auto-Pack Spawner: GESTARTET")
        else
            showToast("⏸ Auto-Pack Spawner: PAUSIERT")
        end
    end)

    local buyToggle = createButton("BuyToggle", UDim2.new(0.48, 0, 0, 42), UDim2.new(0.52, 0, 0, 45), "", frame)
    local function updateBuyBtn()
        updateToggleButtonStyle(buyToggle, SETTINGS.ConveyorAutoBuyEnabled)
        buyToggle.Text = SETTINGS.ConveyorAutoBuyEnabled and (LANGUAGES[SETTINGS.Language].ConveyorBuyToggleOn) or (LANGUAGES[SETTINGS.Language].ConveyorBuyToggleOff)
    end
    registerText(buyToggle, "ConveyorBuyToggleOn", function()
        return SETTINGS.ConveyorAutoBuyEnabled and LANGUAGES[SETTINGS.Language].ConveyorBuyToggleOn or LANGUAGES[SETTINGS.Language].ConveyorBuyToggleOff
    end)
    updateBuyBtn()
    buyToggle.MouseButton1Click:Connect(function()
        SETTINGS.ConveyorAutoBuyEnabled = not SETTINGS.ConveyorAutoBuyEnabled
        updateBuyBtn()
        if SETTINGS.ConveyorAutoBuyEnabled then
            showToast("▶ Förderband Auto-Kauf: GESTARTET")
        else
            showToast("⏸ Förderband Auto-Kauf: PAUSIERT")
        end
    end)

    local mutOnlyToggle = createButton("MutOnlyToggle", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 95), "", frame)
    local function updateMutOnlyBtn()
        updateToggleButtonStyle(mutOnlyToggle, SETTINGS.RequireMutationOnly)
        mutOnlyToggle.Text = SETTINGS.RequireMutationOnly and (LANGUAGES[SETTINGS.Language].RequireMutationOn) or (LANGUAGES[SETTINGS.Language].RequireMutationOff)
    end
    registerText(mutOnlyToggle, "RequireMutationOn", function()
        return SETTINGS.RequireMutationOnly and LANGUAGES[SETTINGS.Language].RequireMutationOn or LANGUAGES[SETTINGS.Language].RequireMutationOff
    end)
    updateMutOnlyBtn()
    mutOnlyToggle.MouseButton1Click:Connect(function()
        SETTINGS.RequireMutationOnly = not SETTINGS.RequireMutationOnly
        updateMutOnlyBtn()
    end)

    local packSelectBtn = createButton("PackSelectBtn", UDim2.new(1, -20, 0, 38), UDim2.new(0, 10, 0, 138), "", frame, Color3.fromRGB(34, 42, 60))
    local function updatePackText()
        local prefix = LANGUAGES[SETTINGS.Language].PackFilterPrefix or "📦 Pack: "
        local hint = LANGUAGES[SETTINGS.Language].OpenListHint or "  ▾ (Liste öffnen)"
        packSelectBtn.Text = prefix .. SETTINGS.SelectedPackFilter .. hint
    end
    packCyclerButtonRef = {
        Button = packSelectBtn,
        UpdateText = updatePackText
    }
    registerText(packSelectBtn, "PackFilterPrefix", function(pfx)
        local hint = LANGUAGES[SETTINGS.Language].OpenListHint or "  ▾ (Liste öffnen)"
        return pfx .. SETTINGS.SelectedPackFilter .. hint
    end)
    updatePackText()
    packSelectBtn.MouseButton1Click:Connect(function()
        local title = LANGUAGES[SETTINGS.Language].ModalTitlePack or "📦 Pack auswählen"
        openSelectionModal(title, SETTINGS.AvailablePacks, SETTINGS.SelectedPackFilter, function(chosen)
            SETTINGS.SelectedPackFilter = chosen
            updatePackText()
            showToast("📦 Filter: " .. chosen)
        end)
    end)

    local mutSelectBtn = createButton("MutationSelectBtn", UDim2.new(1, -20, 0, 38), UDim2.new(0, 10, 0, 182), "", frame, Color3.fromRGB(42, 36, 62))
    local function updateMutText()
        local prefix = LANGUAGES[SETTINGS.Language].MutationFilterPrefix or "✨ Mutation: "
        local hint = LANGUAGES[SETTINGS.Language].OpenListHint or "  ▾ (Liste öffnen)"
        mutSelectBtn.Text = prefix .. SETTINGS.SelectedMutationFilter .. hint
    end
    mutationCyclerButtonRef = {
        Button = mutSelectBtn,
        UpdateText = updateMutText
    }
    registerText(mutSelectBtn, "MutationFilterPrefix", function(pfx)
        local hint = LANGUAGES[SETTINGS.Language].OpenListHint or "  ▾ (Liste öffnen)"
        return pfx .. SETTINGS.SelectedMutationFilter .. hint
    end)
    updateMutText()
    mutSelectBtn.MouseButton1Click:Connect(function()
        local title = LANGUAGES[SETTINGS.Language].ModalTitleMutation or "✨ Mutation auswählen"
        openSelectionModal(title, SETTINGS.AvailableMutations, SETTINGS.SelectedMutationFilter, function(chosen)
            SETTINGS.SelectedMutationFilter = chosen
            updateMutText()
            showToast("✨ Filter: " .. chosen)
        end)
    end)

    local scanIndexBtn = createButton("ManualScanBtn", UDim2.new(1, -20, 0, 36), UDim2.new(0, 10, 0, 228), "", frame, Color3.fromRGB(38, 90, 175))
    registerText(scanIndexBtn, "ScanIndexManual")
    scanIndexBtn.MouseButton1Click:Connect(function()
        if onManualScan then onManualScan() end
    end)

    return frame
end

local function createRankMachineTab()
    local frame = Instance.new("Frame")
    frame.Name = "RankMachineTab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1

    local rankBtn = createButton("TargetRankSelectBtn", UDim2.new(1, -20, 0, 42), UDim2.new(0, 10, 0, 10), "", frame, Color3.fromRGB(90, 40, 140))
    local function updateRankBtnText()
        local prefix = LANGUAGES[SETTINGS.Language].TargetRankPrefix or "🎯 Ziel-Rang: "
        local hint = LANGUAGES[SETTINGS.Language].OpenListHint or "  ▾ (Liste öffnen)"
        rankBtn.Text = prefix .. SETTINGS.TargetRank .. hint
    end
    registerText(rankBtn, "TargetRankPrefix", function(pfx)
        local hint = LANGUAGES[SETTINGS.Language].OpenListHint or "  ▾ (Liste öffnen)"
        return pfx .. SETTINGS.TargetRank .. hint
    end)
    updateRankBtnText()
    rankBtn.MouseButton1Click:Connect(function()
        local title = LANGUAGES[SETTINGS.Language].ModalTitleRank or "🎯 Ziel-Rang auswählen"
        openSelectionModal(title, RANK_OPTIONS, SETTINGS.TargetRank, function(chosen)
            SETTINGS.TargetRank = chosen
            updateRankBtnText()
            showToast("🎯 Ziel-Rang: " .. chosen)
        end)
    end)

    local function createCheckbox(name, pos, textKey, defaultVal, onToggle)
        local cbBtn = createButton(name, UDim2.new(0.31, 0, 0, 36), pos, "", frame)
        local isChecked = defaultVal
        local function updateCb()
            local baseText = LANGUAGES[SETTINGS.Language][textKey] or textKey
            cbBtn.Text = (isChecked and "☑ " or "☐ ") .. baseText
            if isChecked then
                cbBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 70)
            else
                cbBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
            end
        end
        registerText(cbBtn, textKey, function(txt) return (isChecked and "☑ " or "☐ ") .. txt end)
        updateCb()
        cbBtn.MouseButton1Click:Connect(function()
            isChecked = not isChecked
            onToggle(isChecked)
            updateCb()
        end)
        return cbBtn
    end

    createCheckbox("UseCashCb", UDim2.new(0, 10, 0, 65), "UseCashLabel", SETTINGS.RankUseCash, function(v) SETTINGS.RankUseCash = v end)
    createCheckbox("UseGemsCb", UDim2.new(0.35, 0, 0, 65), "UseGemsLabel", SETTINGS.RankUseGems, function(v) SETTINGS.RankUseGems = v end)
    createCheckbox("UseGemsFirstCb", UDim2.new(0.68, 0, 0, 65), "UseGemsFirstLabel", SETTINGS.RankUseGemsFirst, function(v) SETTINGS.RankUseGemsFirst = v end)

    local autoRankToggle = createButton("AutoRankToggle", UDim2.new(1, -20, 0, 44), UDim2.new(0, 10, 0, 120), "", frame)
    local function updateAutoRankBtn()
        updateToggleButtonStyle(autoRankToggle, SETTINGS.AutoRankRollEnabled)
        autoRankToggle.Text = SETTINGS.AutoRankRollEnabled and LANGUAGES[SETTINGS.Language].AutoRankToggleOn or LANGUAGES[SETTINGS.Language].AutoRankToggleOff
    end
    registerText(autoRankToggle, "AutoRankToggleOn", function()
        return SETTINGS.AutoRankRollEnabled and LANGUAGES[SETTINGS.Language].AutoRankToggleOn or LANGUAGES[SETTINGS.Language].AutoRankToggleOff
    end)
    updateAutoRankBtn()
    autoRankToggle.MouseButton1Click:Connect(function()
        SETTINGS.AutoRankRollEnabled = not SETTINGS.AutoRankRollEnabled
        updateAutoRankBtn()
    end)

    return frame
end

local function createTraitRollerTab()
    local frame = Instance.new("Frame")
    frame.Name = "TraitRollerTab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1

    local pityLbl = createLabel("PityHeader", UDim2.new(1, -20, 0, 24), UDim2.new(0, 10, 0, 10), "", frame, Enum.TextXAlignment.Left, Color3.fromRGB(240, 180, 70), Enum.Font.GothamBold, 13)
    registerText(pityLbl, "TraitPityHeader")

    local costLbl = createLabel("CostHint", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 36), "", frame, Enum.TextXAlignment.Left, Color3.fromRGB(180, 185, 205), Enum.Font.Gotham, 12)
    registerText(costLbl, "TraitCostHint")

    local traitBtn = createButton("TargetTraitSelectBtn", UDim2.new(1, -20, 0, 42), UDim2.new(0, 10, 0, 70), "", frame, Color3.fromRGB(50, 75, 135))
    local function updateTraitBtnText()
        local prefix = LANGUAGES[SETTINGS.Language].TargetTraitPrefix or "🧬 Ziel-Trait: "
        local hint = LANGUAGES[SETTINGS.Language].OpenListHint or "  ▾ (Liste öffnen)"
        traitBtn.Text = prefix .. SETTINGS.TargetTrait .. hint
    end
    registerText(traitBtn, "TargetTraitPrefix", function(pfx)
        local hint = LANGUAGES[SETTINGS.Language].OpenListHint or "  ▾ (Liste öffnen)"
        return pfx .. SETTINGS.TargetTrait .. hint
    end)
    updateTraitBtnText()
    traitBtn.MouseButton1Click:Connect(function()
        local title = LANGUAGES[SETTINGS.Language].ModalTitleTrait or "🧬 Ziel-Trait auswählen"
        openSelectionModal(title, TRAIT_OPTIONS, SETTINGS.TargetTrait, function(chosen)
            SETTINGS.TargetTrait = chosen
            updateTraitBtnText()
            showToast("🧬 Ziel-Trait: " .. chosen)
        end)
    end)

    local autoTraitToggle = createButton("AutoTraitToggle", UDim2.new(1, -20, 0, 44), UDim2.new(0, 10, 0, 125), "", frame)
    local function updateAutoTraitBtn()
        updateToggleButtonStyle(autoTraitToggle, SETTINGS.AutoTraitRollEnabled)
        autoTraitToggle.Text = SETTINGS.AutoTraitRollEnabled and LANGUAGES[SETTINGS.Language].AutoTraitToggleOn or LANGUAGES[SETTINGS.Language].AutoTraitToggleOff
    end
    registerText(autoTraitToggle, "AutoTraitToggleOn", function()
        return SETTINGS.AutoTraitRollEnabled and LANGUAGES[SETTINGS.Language].AutoTraitToggleOn or LANGUAGES[SETTINGS.Language].AutoTraitToggleOff
    end)
    updateAutoTraitBtn()
    autoTraitToggle.MouseButton1Click:Connect(function()
        SETTINGS.AutoTraitRollEnabled = not SETTINGS.AutoTraitRollEnabled
        updateAutoTraitBtn()
    end)

    return frame
end

local function createTowerTab()
    local frame = Instance.new("Frame")
    frame.Name = "TowerTab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1

    local rewardLbl = createLabel("RewardHint", UDim2.new(1, -20, 0, 26), UDim2.new(0, 10, 0, 10), "", frame, Enum.TextXAlignment.Left, Color3.fromRGB(120, 220, 160), Enum.Font.GothamBold, 13)
    registerText(rewardLbl, "TowerRewardHint")

    local autoTowerToggle = createButton("AutoTowerToggle", UDim2.new(1, -20, 0, 44), UDim2.new(0, 10, 0, 45), "", frame)
    local function updateTowerBtn()
        updateToggleButtonStyle(autoTowerToggle, SETTINGS.AutoTowerEnabled)
        autoTowerToggle.Text = SETTINGS.AutoTowerEnabled and LANGUAGES[SETTINGS.Language].AutoTowerToggleOn or LANGUAGES[SETTINGS.Language].AutoTowerToggleOff
    end
    registerText(autoTowerToggle, "AutoTowerToggleOn", function()
        return SETTINGS.AutoTowerEnabled and LANGUAGES[SETTINGS.Language].AutoTowerToggleOn or LANGUAGES[SETTINGS.Language].AutoTowerToggleOff
    end)
    updateTowerBtn()
    autoTowerToggle.MouseButton1Click:Connect(function()
        SETTINGS.AutoTowerEnabled = not SETTINGS.AutoTowerEnabled
        updateTowerBtn()
    end)

    local defeatToggle = createButton("DefeatToggle", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, 0, 100), "", frame)
    local function updateDefeatBtn()
        updateToggleButtonStyle(defeatToggle, SETTINGS.TowerStopOnDefeat)
        defeatToggle.Text = SETTINGS.TowerStopOnDefeat and LANGUAGES[SETTINGS.Language].TowerDefeatStopOn or LANGUAGES[SETTINGS.Language].TowerDefeatStopOff
    end
    registerText(defeatToggle, "TowerDefeatStopOn", function()
        return SETTINGS.TowerStopOnDefeat and LANGUAGES[SETTINGS.Language].TowerDefeatStopOn or LANGUAGES[SETTINGS.Language].TowerDefeatStopOff
    end)
    updateDefeatBtn()
    defeatToggle.MouseButton1Click:Connect(function()
        SETTINGS.TowerStopOnDefeat = not SETTINGS.TowerStopOnDefeat
        updateDefeatBtn()
    end)

    return frame
end

local function createBaseTab()
    local frame = Instance.new("Frame")
    frame.Name = "BaseTab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1

    local equipBtn = createButton("EquipBestBtn", UDim2.new(1, -20, 0, 42), UDim2.new(0, 10, 0, 10), "", frame, Color3.fromRGB(55, 95, 160))
    registerText(equipBtn, "EquipBestBtn")
    equipBtn.MouseButton1Click:Connect(function()
        local baseRemote = findGameRemote({"EquipBestCards", "AutoEquip", "EquipCards"})
        if baseRemote then
            pcall(function()
                if baseRemote:IsA("RemoteEvent") then baseRemote:FireServer() else baseRemote:InvokeServer() end
            end)
        end
    end)

    local collectToggle = createButton("CollectToggle", UDim2.new(1, -20, 0, 42), UDim2.new(0, 10, 0, 65), "", frame)
    local function updateCollectBtn()
        updateToggleButtonStyle(collectToggle, SETTINGS.AutoCollectEnabled)
        collectToggle.Text = SETTINGS.AutoCollectEnabled and LANGUAGES[SETTINGS.Language].AutoCollectOn or LANGUAGES[SETTINGS.Language].AutoCollectOff
    end
    registerText(collectToggle, "AutoCollectOn", function()
        return SETTINGS.AutoCollectEnabled and LANGUAGES[SETTINGS.Language].AutoCollectOn or LANGUAGES[SETTINGS.Language].AutoCollectOff
    end)
    updateCollectBtn()
    collectToggle.MouseButton1Click:Connect(function()
        SETTINGS.AutoCollectEnabled = not SETTINGS.AutoCollectEnabled
        updateCollectBtn()
    end)

    return frame
end

local function createSettingsTab()
    local frame = Instance.new("Frame")
    frame.Name = "SettingsTab"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1

    local antiAfkBtn = createButton("AntiAfkBtn", UDim2.new(1, -20, 0, 38), UDim2.new(0, 10, 0, 10), "", frame)
    local function updateAntiAfk()
        updateToggleButtonStyle(antiAfkBtn, SETTINGS.AntiAFKEnabled)
        antiAfkBtn.Text = SETTINGS.AntiAFKEnabled and LANGUAGES[SETTINGS.Language].AntiAFKOn or LANGUAGES[SETTINGS.Language].AntiAFKOff
    end
    registerText(antiAfkBtn, "AntiAFKOn", function() return SETTINGS.AntiAFKEnabled and LANGUAGES[SETTINGS.Language].AntiAFKOn or LANGUAGES[SETTINGS.Language].AntiAFKOff end)
    updateAntiAfk()
    antiAfkBtn.MouseButton1Click:Connect(function()
        SETTINGS.AntiAFKEnabled = not SETTINGS.AntiAFKEnabled
        updateAntiAfk()
    end)

    local fpsBtn = createButton("FpsBtn", UDim2.new(1, -20, 0, 38), UDim2.new(0, 10, 0, 56), "", frame)
    local function updateFps()
        updateToggleButtonStyle(fpsBtn, SETTINGS.FPSEnabled)
        fpsBtn.Text = SETTINGS.FPSEnabled and LANGUAGES[SETTINGS.Language].FPSToggleOn or LANGUAGES[SETTINGS.Language].FPSToggleOff
    end
    registerText(fpsBtn, "FPSToggleOn", function() return SETTINGS.FPSEnabled and LANGUAGES[SETTINGS.Language].FPSToggleOn or LANGUAGES[SETTINGS.Language].FPSToggleOff end)
    updateFps()
    fpsBtn.MouseButton1Click:Connect(function()
        SETTINGS.FPSEnabled = not SETTINGS.FPSEnabled
        updateFps()
    end)

    local safeBtn = createButton("SafeModeBtn", UDim2.new(1, -20, 0, 38), UDim2.new(0, 10, 0, 102), "", frame)
    local function updateSafeMode()
        updateToggleButtonStyle(safeBtn, SETTINGS.SafeMode)
        safeBtn.Text = SETTINGS.SafeMode and LANGUAGES[SETTINGS.Language].SafeModeOn or LANGUAGES[SETTINGS.Language].SafeModeOff
    end
    registerText(safeBtn, "SafeModeOn", function() return SETTINGS.SafeMode and LANGUAGES[SETTINGS.Language].SafeModeOn or LANGUAGES[SETTINGS.Language].SafeModeOff end)
    updateSafeMode()
    safeBtn.MouseButton1Click:Connect(function()
        SETTINGS.SafeMode = not SETTINGS.SafeMode
        updateSafeMode()
    end)

    local hintLabel = createLabel("KeybindHint", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 150), "", frame, Enum.TextXAlignment.Left, Color3.fromRGB(150, 185, 235))
    registerText(hintLabel, "KeybindHint")

    return frame
end

-- ------------------------------------------------------------------------------
-- 13. HAUPTFENSTER, FLOATING MINI-PILL & TOASTS
-- ------------------------------------------------------------------------------
local function createGUI(onScanIndex, onStopAll)
    local parentGui = getSafeGuiParent()
    local old = parentGui:FindFirstChild("AnimeCardFarmProGUI")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnimeCardFarmProGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = parentGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 680, 0, 460)
    mainFrame.Position = UDim2.new(0.5, -340, 0.5, -230)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    addCorner(mainFrame, 10)
    addStroke(mainFrame, Color3.fromRGB(48, 55, 75), 1.5)
    mainFrame.Parent = screenGui

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 42)
    topBar.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
    addCorner(topBar, 10)
    topBar.Parent = mainFrame
    makeDraggable(topBar, mainFrame)

    local titleLbl = createLabel("Title", UDim2.new(0, 280, 1, 0), UDim2.new(0, 14, 0, 0), "Roll Anime Card Farm — Pro", topBar, Enum.TextXAlignment.Left, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, 15)
    registerText(titleLbl, "AppTitle")

    local langBtn = createButton("LangBtn", UDim2.new(0, 68, 0, 28), UDim2.new(1, -155, 0, 7), "🌐 " .. SETTINGS.Language, topBar, Color3.fromRGB(38, 42, 56))
    langBtn.MouseButton1Click:Connect(function()
        SETTINGS.Language = (SETTINGS.Language == "DE") and "EN" or "DE"
        langBtn.Text = "🌐 " .. SETTINGS.Language
        updateLanguage()
    end)

    local miniBtn = createButton("MiniBtn", UDim2.new(0, 32, 0,
