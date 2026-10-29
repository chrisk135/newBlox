-- ==============================================================================
-- Roll Anime Card Farm - Advanced Automation Dashboard & Conveyor Pack Scanner
-- Version: 4.1 (Safe Start: Auto-Buy AUS, Nur Mutationen kaufen, Gezielter Filter)
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
    if typeof(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
        return true
    else
        local oldHold = prompt.HoldDuration
        prompt.HoldDuration = 0
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.05)
            prompt:InputHoldEnd()
        end)
        prompt.HoldDuration = oldHold
        return true
    end
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
    if typeof(getconnections) == "function" then
        pcall(function()
            if btn.MouseButton1Click then
                for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                    if conn.Fire then conn:Fire() elseif conn.fire then conn:fire() end
                end
            end
            if btn.Activated then
                for _, conn in ipairs(getconnections(btn.Activated)) do
                    if conn.Fire then conn:Fire() elseif conn.fire then conn:fire() end
                end
            end
        end)
    end
    return true
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
-- 2. KONFIGURATION & ZUSTAND (STANDARDMÄSSIG ALLES AUS!)
-- ------------------------------------------------------------------------------
local SETTINGS = {
    Language = "DE", -- "DE", "EN"

    -- Förderband & Pack-Kauf (Sicherer Start!)
    AutoSpawnEnabled = false,       -- Standardmäßig AUS (spawnt erst bei Klick auf AN)
    ConveyorAutoBuyEnabled = false, -- Standardmäßig AUS (kauft erst bei Klick auf AN)
    RequireMutationOnly = true,     -- Kauft NUR Packs MIT Mutation (normale Standard-Packs werden ignoriert!)
    SelectedPackFilter = "All",     -- "All" oder Wunsch-Pack
    SelectedMutationFilter = "Nur mit Mutation (Any Mutation)", -- Keine normalen Packs ohne Mutation!
    SpawnInterval = 2.0,            -- Sekunden zwischen Spawns
    ConveyorScanInterval = 0.5,     -- Scan-Frequenz des Förderbands

    -- Rank-Maschine (Screenshots 1 & 4)
    AutoRankRollEnabled = false,
    TargetRank = "神",              -- F, E, D, C, B, A, S, SS, SR, UR, LR, 神
    RankUseCash = true,
    RankUseGems = false,
    RankUseGemsFirst = false,

    -- Trait-Roller (Screenshots 2 & 3)
    AutoTraitRollEnabled = false,
    TargetTrait = "Almighty",       -- Any, Almighty, Sovereign, Godlike, Overlord, etc.

    -- Tower-Replay (Screenshot 5)
    AutoTowerEnabled = false,
    TowerStopOnDefeat = true,

    -- Basis & Farm
    AutoCollectEnabled = true,

    -- Utility & Sicherheit
    AntiAFKEnabled = true,
    FPSEnabled = true,
    SafeMode = true,
    GuiVisible = true,
    IsMinimised = false,

    AvailablePacks = {
        "All", "Dawn Pack", "Starter Pack", "Shadow Pack", "Demon Pack",
        "Pirate Pack", "Dragon Pack", "Titan Pack", "Slayer Pack", "Chakra Pack",
        "Sorcerer Pack", "Hero Pack", "Legendary Pack", "Mythic Pack", "Event Pack",
        "Halloween Pack", "Cosmic Pack", "Void Pack", "God Pack"
    },

    AvailableMutations = {
        "Nur mit Mutation (Any Mutation)",
        "Venomous", "Golden", "Diamond", "Rainbow", "Sakura", "Candy",
        "Blessed", "Radioactive", "Glitch", "Starfallen", "Admin",
        "Corrupt", "Void", "Shiny", "Electric", "Dark", "Frost",
        "Inferno", "Divine", "Normal (Keine)", "Any"
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
-- 3. MEHRSPRACHIGKEIT (LOCALIZATION)
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

        DashboardStatus = "🚀 System bereit (Kauf ist standardmäßig AUS)",
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

        MiniPillFormat = "🃏 Anime Farm | 📦 %d | 🛒 %d",
        ToastIndexScanned = "📖 Index gescannt: %d Packs & %d Mutationen geladen!",
        ToastPackBought = "🛒 Gekauft: %s!",
        ToastPackSpawned = "📦 Pack gespawnt!",
        ToastAllStopped = "🛑 Alle Automatisierungen gestoppt"
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

        DashboardStatus = "🚀 System Ready (Auto-Buy is OFF by default)",
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

        MiniPillFormat = "🃏 Anime Farm | 📦 %d | 🛒 %d",
        ToastIndexScanned = "📖 Index scanned: %d packs & %d mutations loaded!",
        ToastPackBought = "🛒 Bought: %s!",
        ToastPackSpawned = "📦 Pack spawned!",
        ToastAllStopped = "🛑 All automation modules stopped"
    }
}

local translatableElements = {}
local function registerText(instance, textKey, formatter)
    table.insert(translatableElements, {
        Instance = instance,
        Key = textKey,
        Formatter = formatter
    })
    local langTable = LANGUAGES[SETTINGS.Language] or LANGUAGES.DE
    local rawText = langTable[textKey] or textKey
    if formatter then
        instance.Text = formatter(rawText)
    else
        instance.Text = rawText
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
                            else
                                local parentName = (desc.Parent and desc.Parent.Name:lower()) or ""
                                local grandParentName = (desc.Parent and desc.Parent.Parent and desc.Parent.Parent.Name:lower()) or ""
                                if parentName:find("mutation") or grandParentName:find("mutation") then
                                    if not text:find("%d") and not FORBIDDEN_WORDS[text:lower()] and #text >= 3 then
                                        if registerDiscoveredMutation(text) then newMutations += 1 end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
        local iName = item.Name:lower()
        local parentName = (item.Parent and item.Parent.Name:lower()) or ""

        if parentName:find("mutation") then
            if registerDiscoveredMutation(item.Name) then newMutations += 1 end
            if item:IsA("StringValue") and item.Value ~= "" then
                if registerDiscoveredMutation(item.Value) then newMutations += 1 end
            end
        elseif parentName:find("pack") then
            if registerDiscoveredPack(item.Name) then newPacks += 1 end
            if item:IsA("StringValue") and item.Value ~= "" then
                if registerDiscoveredPack(item.Value) then newPacks += 1 end
            end
        end

        if iName:find("pack") and not parentName:find("pack") and not item:IsA("Folder") then
            if registerDiscoveredPack(item.Name) then newPacks += 1 end
        elseif iName:find("mutation") and not parentName:find("mutation") and not item:IsA("Folder") then
            if registerDiscoveredMutation(item.Name) then newMutations += 1 end
        end
    end

    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("BillboardGui") then
            for _, label in ipairs(desc:GetDescendants()) do
                if label:IsA("TextLabel") and label.Text:find("Pack") then
                    local m, p = label.Text:match("^([%a%s]+)%s+([%a%s]+Pack)")
                    if m and p then
                        local cleanM = m:gsub("^%s+", ""):gsub("%s+$", "")
                        local cleanP = p:gsub("^%s+", ""):gsub("%s+$", "")
                        if not FORBIDDEN_WORDS[cleanM:lower()] then
                            if registerDiscoveredMutation(cleanM) then newMutations += 1 end
                        end
                        if not FORBIDDEN_WORDS[cleanP:lower()] then
                            if registerDiscoveredPack(cleanP) then newPacks += 1 end
                        end
                    end
                end
            end
        end
    end

    return newPacks, newMutations
end

-- ------------------------------------------------------------------------------
-- 5. FÖRDERBAND-SCANNER & SICHERER FILTER-ABGLEICH
-- ------------------------------------------------------------------------------
local recentlyPurchasedPacks = {}

local function isPlayerCharacter(inst)
    if not inst then return false end
    if Players:GetPlayerFromCharacter(inst) then return true end
    if inst:FindFirstChildOfClass("Humanoid") then return true end
    return false
end

local function parsePackInfo(packInstance)
    local titleTexts = {}
    local prompt = nil
    local detectedPrice = ""

    for _, desc in ipairs(packInstance:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            local txt = desc.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if txt ~= "" then
                table.insert(titleTexts, txt)
                local priceMatch = txt:match("(%$[0-9%.]+%a*)") or txt:match("([0-9%.]+%s*[KMBTPESxd]+/[0-9%.]+%s*[KMBTPESxd]+)")
                if priceMatch and detectedPrice == "" then
                    detectedPrice = priceMatch
                end
            end
        elseif desc:IsA("ProximityPrompt") then
            prompt = desc
        end
    end
    table.insert(titleTexts, packInstance.Name)

    local combinedText = table.concat(titleTexts, " ")
    local detectedMutation = "Normal (Keine)"
    local detectedPack = "Unknown Pack"

    for _, mut in ipairs(SETTINGS.AvailableMutations) do
        if mut ~= "Any" and mut ~= "Normal (Keine)" and mut ~= "None" and mut ~= "Nur mit Mutation (Any Mutation)" then
            if string.find(combinedText:lower(), mut:lower(), 1, true) then
                detectedMutation = mut
                break
            end
        end
    end

    for _, p in ipairs(SETTINGS.AvailablePacks) do
        if p ~= "All" then
            if string.find(combinedText:lower(), p:lower(), 1, true) then
                detectedPack = p
                break
            end
        end
    end

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
    -- Schutz: Wenn der Auto-Kauf deaktiviert ist, NIEMALS kaufen!
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
                buyRemote:FireServer(packInfo.Instance, packInfo.Name)
            else
                buyRemote:InvokeServer(packInfo.Instance, packInfo.Name)
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
        if isPlayerCharacter(targetModel) then return end

        local mName = targetModel.Name:lower()
        if mName:find("spawn") or mName:find("pedestal") or mName:find("roller") or mName:find("machine") or mName:find("tower") or mName:find("plot") or mName:find("base") then
            return
        end

        local prompt = targetModel:FindFirstChildWhichIsA("ProximityPrompt", true)
        local hasPackBillboard = false
        local hasBuyPrompt = false

        if prompt then
            local act = (prompt.ActionText or ""):lower()
            local obj = (prompt.ObjectText or ""):lower()
            if act:find("buy") or act:find("purchase") or obj:find("buy") or obj:find("pack") then
                hasBuyPrompt = true
            end
        end

        for _, bg in ipairs(targetModel:GetDescendants()) do
            if bg:IsA("BillboardGui") then
                for _, lbl in ipairs(bg:GetDescendants()) do
                    if lbl:IsA("TextLabel") or lbl:IsA("TextButton") then
                        local txt = lbl.Text:lower()
                        if txt:find("pack") or txt:find("%$") then
                            hasPackBillboard = true
                            break
                        end
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
-- 6. AUTO PACK SPAWNER (GRÜNER SOCKEL)
-- ------------------------------------------------------------------------------
local function triggerSpawnPackPedestal()
    local triggered = false
    local baseFolder = getPlayerBase() or workspace

    for _, desc in ipairs(baseFolder:GetDescendants()) do
        local nameLower = desc.Name:lower()
        local isSpawner = nameLower:find("spawnpack") or nameLower:find("packspawn")
            or (nameLower:find("spawn") and nameLower:find("stand"))
            or (nameLower:find("spawn") and nameLower:find("pedestal"))

        if not isSpawner and desc:IsA("BillboardGui") then
            for _, label in ipairs(desc:GetDescendants()) do
                if label:IsA("TextLabel") and label.Text:lower():find("spawn pack") then
                    isSpawner = true
                    break
                end
            end
        end

        if isSpawner then
            local physicalTarget = (desc:IsA("BillboardGui") and (desc.Adornee or desc.Parent)) or desc
            if physicalTarget then
                local prompt = physicalTarget:FindFirstChildWhichIsA("ProximityPrompt", true)
                    or desc:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    activatePrompt(prompt)
                    triggered = true
                    break
                end

                local part = physicalTarget:IsA("BasePart") and physicalTarget or physicalTarget:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    touchPart(part)
                    triggered = true
                    break
                end
            end
        end
    end

    local spawnRemote = findGameRemote({"SpawnPack", "RequestSpawnPack", "BaseSpawnPack", "SpawnCardPack"})
    if spawnRemote then
        pcall(function()
            if spawnRemote:IsA("RemoteEvent") then
                spawnRemote:FireServer()
            else
                spawnRemote:InvokeServer()
            end
        end)
        triggered = true
    end

    if triggered then
        STATS.PacksSpawned += 1
    end

    return triggered
end

-- ------------------------------------------------------------------------------
-- 7. AUTO RANK ROLL (RANK-MASCHINE)
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
                local nameLower = desc.Name:lower()
                local textLower = desc:IsA("TextLabel") and desc.Text:lower() or (desc:IsA("GuiButton") and desc.Text:lower() or "")
                if nameLower:find(keyword) or textLower:find(keyword) then
                    local btn = desc:IsA("GuiButton") and desc or desc:FindFirstChildWhichIsA("GuiButton", true) or (desc.Parent and desc.Parent:FindFirstChildWhichIsA("GuiButton"))
                    if btn then
                        local isChecked = (btn.Text:find("☑") or btn.Text:find("true") or btn.Name:find("On") or btn.BackgroundColor3 == Color3.fromRGB(40, 120, 70)) ~= nil
                        if isChecked ~= desiredState then
                            clickButton(btn)
                        end
                    end
                end
            end
        end

        syncCheckbox("gems first", SETTINGS.RankUseGemsFirst)
        syncCheckbox("cash", SETTINGS.RankUseCash)
        syncCheckbox("gems", SETTINGS.RankUseGems)

        local startBtn = nil
        for _, desc in ipairs(rankGui:GetDescendants()) do
            if desc:IsA("GuiButton") then
                local txt = (desc:IsA("TextButton") and desc.Text or desc.Name):lower()
                if txt:find("start") or txt:find("roll") then
                    startBtn = desc
                    break
                end
            end
        end
        if startBtn then
            clickButton(startBtn)
        end
    end

    local rankMachine = workspace:FindFirstChild("Rank Machine", true)
        or workspace:FindFirstChild("RankMachine", true)
        or workspace:FindFirstChild("Grade Machine", true)
    if rankMachine then
        local prompt = rankMachine:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then activatePrompt(prompt) end
    end

    local rankRemote = findGameRemote({"RollRank", "UpgradeRank", "RankMachineRoll", "AutoRollRank", "RollGrade"})
    if rankRemote then
        pcall(function()
            local payload = {
                TargetRank = SETTINGS.TargetRank,
                UseCash = SETTINGS.RankUseCash,
                UseGems = SETTINGS.RankUseGems,
                UseGemsFirst = SETTINGS.RankUseGemsFirst
            }
            if rankRemote:IsA("RemoteEvent") then
                rankRemote:FireServer(payload)
                rankRemote:FireServer(SETTINGS.TargetRank, SETTINGS.RankUseCash, SETTINGS.RankUseGems, SETTINGS.RankUseGemsFirst)
            else
                rankRemote:InvokeServer(payload)
            end
        end)
    end

    STATS.RankRolls += 1
end

-- ------------------------------------------------------------------------------
-- 8. AUTO TRAIT ROLL
-- ------------------------------------------------------------------------------
local function executeTraitRoll()
    local npc = workspace:FindFirstChild("Trait Roller", true) or workspace:FindFirstChild("TraitRoller", true)
    if npc then
        local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then activatePrompt(prompt) end
    end

    local traitGui = player:FindFirstChild("PlayerGui") and (
        player.PlayerGui:FindFirstChild("TraitsMachine", true)
        or player.PlayerGui:FindFirstChild("TraitMachine", true)
        or player.PlayerGui:FindFirstChild("TraitRoller", true)
    )
    if traitGui then
        local autoBtn = nil
        for _, desc in ipairs(traitGui:GetDescendants()) do
            if desc:IsA("GuiButton") then
                local txt = (desc:IsA("TextButton") and desc.Text or desc.Name):lower()
                if txt:find("auto") or txt:find("roll") then
                    autoBtn = desc
                    break
                end
            end
        end
        if autoBtn then
            clickButton(autoBtn)
        end
    end

    local traitRemote = findGameRemote({"RollTrait", "RerollTrait", "TraitRoll", "TraitMachineRoll", "AutoRollTrait"})
    if traitRemote then
        pcall(function()
            if traitRemote:IsA("RemoteEvent") then
                traitRemote:FireServer(SETTINGS.TargetTrait)
            else
                traitRemote:InvokeServer(SETTINGS.TargetTrait)
            end
        end)
    end

    STATS.TraitRolls += 1
end

-- ------------------------------------------------------------------------------
-- 9. AUTO TOWER REPLAY
-- ------------------------------------------------------------------------------
local function executeTowerReplay()
    local tower = workspace:FindFirstChild("InfinityTower", true)
        or workspace:FindFirstChild("Tower", true)

    if not tower then
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("BillboardGui") then
                for _, lbl in ipairs(desc:GetDescendants()) do
                    if lbl:IsA("TextLabel") and lbl.Text:match("Floor%s*%d+") then
                        tower = desc.Adornee or desc.Parent
                        break
                    end
                end
            end
            if tower then break end
        end
    end

    if tower then
        local prompt = tower:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then activatePrompt(prompt) end
        local part = tower:IsA("BasePart") and tower or tower:FindFirstChildWhichIsA("BasePart", true)
        if part then touchPart(part) end
    end

    local towerRemote = findGameRemote({"EnterTower", "StartTower", "ReplayTower", "NextFloor", "TowerAction"})
    if towerRemote then
        pcall(function()
            if towerRemote:IsA("RemoteEvent") then
                towerRemote:FireServer("Replay")
            else
                towerRemote:InvokeServer("Replay")
            end
        end)
    end

    STATS.TowerFloorsCleared += 1
end

-- ------------------------------------------------------------------------------
-- 10. UI FACTORY
-- ------------------------------------------------------------------------------
local function addCorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = inst
    return c
end

local function addStroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(55, 60, 75)
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function createLabel(name, size, pos, text, parent, align, color, font, textSize)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.Size = size
    lbl.Position = pos
    lbl.Text = text or ""
    lbl.TextColor3 = color or Color3.fromRGB(235, 235, 245)
    lbl.TextSize = textSize or 13
    lbl.Font = font or Enum.Font.GothamMedium
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = align or Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function createButton(name, size, pos, text, parent, bgCol)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = size
    btn.Position = pos
    btn.Text = text or ""
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = bgCol or Color3.fromRGB(42, 45, 58)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    addCorner(btn, 6)
    addStroke(btn, Color3.fromRGB(65, 70, 85), 1)
    btn.Parent = parent
    return btn
end

local function updateToggleButtonStyle(button, isEnabled)
    if isEnabled then
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
-- 11. UI TABS ERSTELLUNG
-- ------------------------------------------------------------------------------
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

    -- 1. Reihe: Auto-Spawn und Auto-Kauf (Standardmäßig AUS!)
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
    end)

    -- 2. Reihe: Schutz-Schalter "Nur Packs MIT Mutation kaufen"
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

    -- 3. Reihe: Pack-Filter
    local packIndex = 1
    local packCycler = createButton("PackCycler", UDim2.new(1, -20, 0, 38), UDim2.new(0, 10, 0, 138), "", frame)
    local function updatePackText()
        local prefix = LANGUAGES[SETTINGS.Language].PackFilterPrefix or "📦 Pack: "
        packCycler.Text = prefix .. SETTINGS.SelectedPackFilter
    end
    packCyclerButtonRef = {
        Button = packCycler,
        UpdateText = updatePackText
    }
    registerText(packCycler, "PackFilterPrefix", function(pfx) return pfx .. SETTINGS.SelectedPackFilter end)
    updatePackText()
    packCycler.MouseButton1Click:Connect(function()
        packIndex = (packIndex % #SETTINGS.AvailablePacks) + 1
        SETTINGS.SelectedPackFilter = SETTINGS.AvailablePacks[packIndex]
        updatePackText()
    end)
    packCycler.MouseButton2Click:Connect(function()
        packIndex = (packIndex - 2 + #SETTINGS.AvailablePacks) % #SETTINGS.AvailablePacks + 1
        SETTINGS.SelectedPackFilter = SETTINGS.AvailablePacks[packIndex]
        updatePackText()
    end)

    -- 4. Reihe: Mutations-Filter
    local mutationIndex = 1
    local mutCycler = createButton("MutationCycler", UDim2.new(1, -20, 0, 38), UDim2.new(0, 10, 0, 182), "", frame)
    local function updateMutText()
        local prefix = LANGUAGES[SETTINGS.Language].MutationFilterPrefix or "✨ Mutation: "
        mutCycler.Text = prefix .. SETTINGS.SelectedMutationFilter
    end
    mutationCyclerButtonRef = {
        Button = mutCycler,
        UpdateText = updateMutText
    }
    registerText(mutCycler, "MutationFilterPrefix", function(pfx) return pfx .. SETTINGS.SelectedMutationFilter end)
    updateMutText()
    mutCycler.MouseButton1Click:Connect(function()
        mutationIndex = (mutationIndex % #SETTINGS.AvailableMutations) + 1
        SETTINGS.SelectedMutationFilter = SETTINGS.AvailableMutations[mutationIndex]
        updateMutText()
    end)
    mutCycler.MouseButton2Click:Connect(function()
        mutationIndex = (mutationIndex - 2 + #SETTINGS.AvailableMutations) % #SETTINGS.AvailableMutations + 1
        SETTINGS.SelectedMutationFilter = SETTINGS.AvailableMutations[mutationIndex]
        updateMutText()
    end)

    -- 5. Reihe: Index-Scan Button
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

    local rankIdx = 12
    local rankBtn = createButton("TargetRankCycler", UDim2.new(1, -20, 0, 42), UDim2.new(0, 10, 0, 10), "", frame, Color3.fromRGB(90, 40, 140))
    local function updateRankBtnText()
        local prefix = LANGUAGES[SETTINGS.Language].TargetRankPrefix or "🎯 Ziel-Rang: "
        rankBtn.Text = prefix .. SETTINGS.TargetRank
    end
    registerText(rankBtn, "TargetRankPrefix", function(pfx) return pfx .. SETTINGS.TargetRank end)
    updateRankBtnText()
    rankBtn.MouseButton1Click:Connect(function()
        rankIdx = (rankIdx % #RANK_OPTIONS) + 1
        SETTINGS.TargetRank = RANK_OPTIONS[rankIdx]
        updateRankBtnText()
    end)
    rankBtn.MouseButton2Click:Connect(function()
        rankIdx = (rankIdx - 2 + #RANK_OPTIONS) % #RANK_OPTIONS + 1
        SETTINGS.TargetRank = RANK_OPTIONS[rankIdx]
        updateRankBtnText()
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

    local traitIdx = 2
    local traitBtn = createButton("TraitCycler", UDim2.new(1, -20, 0, 42), UDim2.new(0, 10, 0, 70), "", frame, Color3.fromRGB(50, 75, 135))
    local function updateTraitBtnText()
        local prefix = LANGUAGES[SETTINGS.Language].TargetTraitPrefix or "🧬 Ziel-Trait: "
        traitBtn.Text = prefix .. SETTINGS.TargetTrait
    end
    registerText(traitBtn, "TargetTraitPrefix", function(pfx) return pfx .. SETTINGS.TargetTrait end)
    updateTraitBtnText()
    traitBtn.MouseButton1Click:Connect(function()
        traitIdx = (traitIdx % #TRAIT_OPTIONS) + 1
        SETTINGS.TargetTrait = TRAIT_OPTIONS[traitIdx]
        updateTraitBtnText()
    end)
    traitBtn.MouseButton2Click:Connect(function()
        traitIdx = (traitIdx - 2 + #TRAIT_OPTIONS) % #TRAIT_OPTIONS + 1
        SETTINGS.TargetTrait = TRAIT_OPTIONS[traitIdx]
        updateTraitBtnText()
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
-- 12. HAUPTFENSTER, MINI-PILL & TOASTS
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

    local miniBtn = createButton("MiniBtn", UDim2.new(0, 32, 0, 28), UDim2.new(1, -80, 0, 7), "—", topBar, Color3.fromRGB(38, 42, 56))
    local closeBtn = createButton("CloseBtn", UDim2.new(0, 32, 0, 28), UDim2.new(1, -42, 0, 7), "✕", topBar, Color3.fromRGB(160, 40, 40))

    local miniPill = Instance.new("Frame")
    miniPill.Name = "MiniPill"
    miniPill.Size = UDim2.new(0, 360, 0, 42)
    miniPill.Position = UDim2.new(0.5, -180, 0, 20)
    miniPill.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    miniPill.Visible = false
    addCorner(miniPill, 8)
    addStroke(miniPill, Color3.fromRGB(60, 105, 195), 1.5)
    miniPill.Parent = screenGui
    makeDraggable(miniPill, miniPill)

    local miniLabel = createLabel("MiniLabel", UDim2.new(1, -60, 1, 0), UDim2.new(0, 12, 0, 0), "🃏 Anime Farm | 📦 0 | 🛒 0", miniPill, Enum.TextXAlignment.Left, Color3.fromRGB(240, 240, 255), Enum.Font.GothamBold, 12)
    local restoreBtn = createButton("RestoreBtn", UDim2.new(0, 42, 0, 28), UDim2.new(1, -48, 0, 7), "⤢", miniPill, Color3.fromRGB(45, 90, 180))

    local function setMinimised(minimised)
        SETTINGS.IsMinimised = minimised
        mainFrame.Visible = not minimised
        miniPill.Visible = minimised
    end

    miniBtn.MouseButton1Click:Connect(function() setMinimised(true) end)
    restoreBtn.MouseButton1Click:Connect(function() setMinimised(false) end)
    closeBtn.MouseButton1Click:Connect(function()
        SETTINGS.GuiVisible = false
        mainFrame.Visible = false
        miniPill.Visible = false
    end)

    local tabNav = Instance.new("Frame")
    tabNav.Size = UDim2.new(1, -20, 0, 34)
    tabNav.Position = UDim2.new(0, 10, 0, 48)
    tabNav.BackgroundTransparency = 1
    tabNav.Parent = mainFrame

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -20, 1, -125)
    contentFrame.Position = UDim2.new(0, 10, 0, 88)
    contentFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
    addCorner(contentFrame, 8)
    addStroke(contentFrame, Color3.fromRGB(42, 45, 58), 1)
    contentFrame.Parent = mainFrame

    local toastFrame = Instance.new("Frame")
    toastFrame.Size = UDim2.new(1, -20, 0, 24)
    toastFrame.Position = UDim2.new(0, 10, 1, -30)
    toastFrame.BackgroundTransparency = 1
    toastFrame.Parent = mainFrame

    local toastLabel = createLabel("ToastLabel", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "Status: Bereit", toastFrame, Enum.TextXAlignment.Center, Color3.fromRGB(120, 215, 150), Enum.Font.GothamMedium, 12)

    local dashTab, sessionLbl, currLbl, spawnedLbl, boughtLbl, lastBoughtLbl, liveConveyorLbl = createDashboardTab(onScanIndex, onStopAll)
    local convTab = createConveyorTab(onScanIndex)
    local rankTab = createRankMachineTab()
    local traitTab = createTraitRollerTab()
    local towerTab = createTowerTab()
    local baseTab = createBaseTab()
    local setTab = createSettingsTab()

    local tabs = {
        {Key = "Dashboard", Frame = dashTab},
        {Key = "ConveyorTab", Frame = convTab},
        {Key = "RankTab", Frame = rankTab},
        {Key = "TraitTab", Frame = traitTab},
        {Key = "TowerTab", Frame = towerTab},
        {Key = "BaseTab", Frame = baseTab},
        {Key = "SettingsTab", Frame = setTab}
    }

    local tabButtons = {}
    local numTabs = #tabs
    for i, t in ipairs(tabs) do
        t.Frame.Visible = (i == 1)
        t.Frame.Parent = contentFrame

        local btnW = 1 / numTabs
        local btn = createButton(t.Key .. "Btn", UDim2.new(btnW, -3, 1, 0), UDim2.new((i - 1) * btnW, 1, 0, 0), "", tabNav, i == 1 and Color3.fromRGB(50, 100, 195) or Color3.fromRGB(32, 34, 44))
        registerText(btn, t.Key)
        table.insert(tabButtons, {Btn = btn, Key = t.Key, Frame = t.Frame})

        btn.MouseButton1Click:Connect(function()
            for _, tb in ipairs(tabButtons) do
                tb.Frame.Visible = false
                tb.Btn.BackgroundColor3 = Color3.fromRGB(32, 34, 44)
            end
            t.Frame.Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(50, 100, 195)
        end)
    end

    return {
        ScreenGui = screenGui,
        MainFrame = mainFrame,
        MiniPill = miniPill,
        SessionLabel = sessionLbl,
        CurrencyLabel = currLbl,
        SpawnedLabel = spawnedLbl,
        BoughtLabel = boughtLbl,
        LastBoughtLabel = lastBoughtLbl,
        LiveConveyorLabel = liveConveyorLbl,
        ToastLabel = toastLabel,
        MiniLabel = miniLabel,
        SetMinimised = setMinimised
    }
end

-- ------------------------------------------------------------------------------
-- 13. HINTERGRUND-ROUTINEN & AUTOMATISIERUNGS-LOOPS
-- ------------------------------------------------------------------------------
local guiElements = nil

local function showToast(message)
    if guiElements and guiElements.ToastLabel and guiElements.ToastLabel.Parent then
        guiElements.ToastLabel.Text = message
    end
end

local lastSpawnTime = 0

task.spawn(function()
    while true do
        task.wait(SETTINGS.ConveyorScanInterval or 0.5)

        local now = os.clock()
        for inst, t in pairs(recentlyPurchasedPacks) do
            if (now - t) > 10.0 or not inst.Parent then
                recentlyPurchasedPacks[inst] = nil
            end
        end

        if SETTINGS.AutoSpawnEnabled then
            if lastSpawnTime == 0 or (now - lastSpawnTime) >= (SETTINGS.SpawnInterval or 2.0) then
                if triggerSpawnPackPedestal() then
                    lastSpawnTime = now
                end
            end
        end

        local packs = scanConveyorPacks()
        if #packs > 0 then
            local latest = packs[1]
            STATS.LastDetectedConveyorItem = string.format("%s %s [%s]", latest.Mutation, latest.Name, latest.Price ~= "" and latest.Price or "Conveyor")

            -- Kauft NUR, wenn der Nutzer ConveyorAutoBuyEnabled aktiv eingeschaltet hat
            if SETTINGS.ConveyorAutoBuyEnabled then
                for _, pack in ipairs(packs) do
                    if matchesConveyorFilter(pack) then
                        local bought = buyConveyorPack(pack)
                        if bought then
                            showToast(string.format("🛒 Gekauft: %s (%s)", pack.Name, pack.Mutation))
                            if SETTINGS.SafeMode then
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end

        if SETTINGS.SafeMode then
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1.2)
        if SETTINGS.AutoRankRollEnabled then
            executeRankRoll()
            if SETTINGS.SafeMode then task.wait(0.6) end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1.5)
        if SETTINGS.AutoTraitRollEnabled then
            executeTraitRoll()
            if SETTINGS.SafeMode then task.wait(0.8) end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(3.0)
        if SETTINGS.AutoTowerEnabled then
            executeTowerReplay()
            if SETTINGS.SafeMode then task.wait(1.5) end
        end
    end
end)

local function setupAntiAFK()
    local VirtualUser = nil
    pcall(function() VirtualUser = game:GetService("VirtualUser") end)

    player.Idled:Connect(function()
        if SETTINGS.AntiAFKEnabled then
            if VirtualUser then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            else
                local character = player.Character
                local hum = character and character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
end

local function applyFPSBoost()
    if not SETTINGS.FPSEnabled then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
    end
end

local function setupKeybinds()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightControl or input.KeyCode == Enum.KeyCode.Insert then
            SETTINGS.GuiVisible = not SETTINGS.GuiVisible
            if guiElements and guiElements.MainFrame then
                if SETTINGS.IsMinimised then
                    guiElements.MiniPill.Visible = SETTINGS.GuiVisible
                else
                    guiElements.MainFrame.Visible = SETTINGS.GuiVisible
                end
            end
        end
    end)
end

-- ------------------------------------------------------------------------------
-- 14. INITIALISIERUNG
-- ------------------------------------------------------------------------------
guiElements = createGUI(
    function()
        local pFound, mFound = scanIndexBook()
        local lang = LANGUAGES[SETTINGS.Language] or LANGUAGES.DE
        showToast(string.format(lang.ToastIndexScanned, #SETTINGS.AvailablePacks, #SETTINGS.AvailableMutations))
    end,
    function()
        SETTINGS.AutoSpawnEnabled = false
        SETTINGS.ConveyorAutoBuyEnabled = false
        SETTINGS.AutoRankRollEnabled = false
        SETTINGS.AutoTraitRollEnabled = false
        SETTINGS.AutoTowerEnabled = false
        showToast("🛑 Alle Automatisierungen gestoppt")
    end
)

setupAntiAFK()
applyFPSBoost()
setupKeybinds()

task.spawn(function()
    task.wait(1.0)
    scanIndexBook()
end)

task.spawn(function()
    while true do
        task.wait(1)
        if guiElements then
            local lang = LANGUAGES[SETTINGS.Language] or LANGUAGES.DE
            local elapsed = os.time() - STATS.StartTime
            local hrs = math.floor(elapsed / 3600)
            local mins = math.floor((elapsed % 3600) / 60)
            local secs = elapsed % 60

            if guiElements.SessionLabel and guiElements.SessionLabel.Parent then
                local pfx = lang.Session or "Session: "
                guiElements.SessionLabel.Text = string.format("%s%02d:%02d:%02d", pfx, hrs, mins, secs)
            end

            if guiElements.CurrencyLabel and guiElements.CurrencyLabel.Parent then
                local y, g = getPlayerCurrencies()
                guiElements.CurrencyLabel.Text = string.format("Yen: %s | Gems: %s", y, g)
            end

            if guiElements.SpawnedLabel and guiElements.SpawnedLabel.Parent then
                local pfx = lang.PacksSpawnedLabel or "Packs gespawnt: "
                guiElements.SpawnedLabel.Text = string.format("%s%d", pfx, STATS.PacksSpawned)
            end

            if guiElements.BoughtLabel and guiElements.BoughtLabel.Parent then
                local pfx = lang.PacksBoughtLabel or "Packs gekauft: "
                guiElements.BoughtLabel.Text = string.format("%s%d", pfx, STATS.PacksBought)
            end

            if guiElements.LastBoughtLabel and guiElements.LastBoughtLabel.Parent then
                local pfx = lang.LastBoughtLabel or "Zuletzt gekauft: "
                guiElements.LastBoughtLabel.Text = string.format("%s%s (%s)", pfx, STATS.LastBoughtPack, STATS.LastBuyTime)
            end

            if guiElements.LiveConveyorLabel and guiElements.LiveConveyorLabel.Parent then
                local pfx = lang.LiveConveyorHeader or "📡 Live Förderband-Erkennung: "
                guiElements.LiveConveyorLabel.Text = string.format("%s\n%s", pfx, STATS.LastDetectedConveyorItem)
            end

            if guiElements.MiniLabel and guiElements.MiniLabel.Parent then
                local fmt = lang.MiniPillFormat or "🃏 Anime Farm | 📦 %d | 🛒 %d"
                guiElements.MiniLabel.Text = string.format(fmt, STATS.PacksSpawned, STATS.PacksBought)
            end
        end
    end
end)

print("==============================================================================")
print("  Roll Anime Card Farm — Pro v4.1 erfolgreich geladen!")
print("  • Auto-Kauf & Auto-Spawn: STANDARDMÄSSIG AUS (Sicherer Start)")
print("  • Schutz: Kauft NUR Packs mit Mutation (normale Packs werden ignoriert)")
print("  • Stelle deine Wunsch-Packs im Menü ein und aktiviere den Kauf bei Bedarf!")
print("==============================================================================")
