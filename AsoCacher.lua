--[[

@title AsoCacher
@description Gathers from Material Caches
@author Asoziales <discord@Asoziales>
@date 01/10/2024
@version 2.1
@Changelog
2.1 <discord@dea.d>
    - Added UI to select hotspot when multiple matching exist
2.0 <discord@dea.d>
    - Auto select cache from area
    - Doesn't interact with depleted caches
    - Gathers from closest cache
    - Porters checkbox from UI has been moved to a boolean `usePorters`

1.2 <discord@Asoziales>
    - Added Third Age Iron

Message on Discord for any Errors or Bugs

Make sure you are wearing a Grace of the Elves and have any porters in inventory if using porters or memory shards

--]] local API = require("api")
local UTILS = require("utils")

-- variables
local startXp = API.GetSkillXP("ARCHAEOLOGY")
local MAX_IDLE_TIME_MINUTES = 5
local afk = os.time()

local skill = "ARCHAEOLOGY"
startXp = API.GetSkillXP(skill)
local version = "2.0"
local Material = ""
local targets = {}
local selectedCache
local matcount = 0
local startTime = os.time()
local usePorters = true
local runScript = false

API.logWarn("Started AsoCacher - (v" .. tostring(version) .. ") by Asoziales")
print("Started AsoCacher - (v" .. tostring(version) .. ") by Asoziales")
local aioSelectC = API.CreateIG_answer()
local CacheData = {{
    label = "Vulcanized rubber",
    CACHEID = 116387,
    MATERIALID = 49480
}, {
    label = "Ancient vis",
    CACHEID = 116432,
    MATERIALID = 49506
}, {
    label = "Blood of Orcus",
    CACHEID = 116435,
    MATERIALID = 49508
}, {
    label = "Hellfire metal",
    CACHEID = 116426,
    MATERIALID = 49504
}, {
    label = "Third Age Iron",
    CACHEID = 115426,
    MATERIALID = 49460
}, {
    label = "Cadmium red",
    CACHEID = 116420,
    MATERIALID = 49496
}, {
    label = "Armadylean yellow",
    CACHEID = 116379,
    MATERIALID = 49468
}, {
    label = "Cobalt blue",
    CACHEID = 116416,
    MATERIALID = 49486
}, {
    label = "Goldrune",
    CACHEID = 116402,
    MATERIALID = 49450
}, {
    label = "Samite silk",
    CACHEID = 116399,
    MATERIALID = 49456
}, {
    label = "Soapstone",
    CACHEID = 116410,
    MATERIALID = 49458
}, {
    label = "Tyrian purple",
    CACHEID = 116434,
    MATERIALID = 49512
}, {
    label = "Everlight silvthril",
    CACHEID = 116417,
    MATERIALID = 49488
}, {
    label = "Demonhide",
    CACHEID = 116423,
    MATERIALID = 49500
}, {
    label = "Keramos",
    CACHEID = 116413,
    MATERIALID = 49490
}, {
    label = "Chaotic brimstone",
    CACHEID = 116421,
    MATERIALID = 49498
}, {
    label = "Eye of Dagon",
    CACHEID = 116424,
    MATERIALID = 49502
}, {
    label = "Leather Scraps",
    CACHEID = 116405,
    MATERIALID = 49452
}, {
    label = "Zarosian insignia",
    CACHEID = 116429,
    MATERIALID = 49514
}}

ID = {
    CACHE = {
        CLAY_CACHE = 116391
    },
    AUTO_SCREENER = 50161,
    ELVEN_SHARD = 43358,
    PORTERS = {29281, 29283, 29285, 51490}
}

local function setupOptions()
    btnStop = API.CreateIG_answer()
    btnStop.box_start = FFPOINT.new(120, 149, 0)
    btnStop.box_name = " STOP "
    btnStop.box_size = FFPOINT.new(90, 50, 0)
    btnStop.colour = ImColor.new(255, 0, 0)
    btnStop.string_value = "STOP"

    btnStart = API.CreateIG_answer()
    btnStart.box_start = FFPOINT.new(20, 149, 0)
    btnStart.box_name = " START "
    btnStart.box_size = FFPOINT.new(90, 50, 0)
    btnStart.colour = ImColor.new(0, 255, 0)
    btnStart.string_value = "START"

    IG_Text = API.CreateIG_answer()
    IG_Text.box_name = "TEXT"
    IG_Text.box_start = FFPOINT.new(16, 79, 0)
    IG_Text.colour = ImColor.new(196, 141, 59);
    IG_Text.string_value = "AsoCacher (v" .. version .. ") by Asoziales"

    IG_Back = API.CreateIG_answer()
    IG_Back.box_name = "back"
    IG_Back.box_start = FFPOINT.new(5, 64, 0)
    IG_Back.box_size = FFPOINT.new(226, 200, 0)
    IG_Back.colour = ImColor.new(15, 13, 18, 255)
    IG_Back.string_value = ""

    tickPorters = API.CreateIG_answer()
    tickPorters.box_ticked = usePorters
    tickPorters.box_name = "Porters"
    tickPorters.box_start = FFPOINT.new(69, 122, 0);
    tickPorters.colour = ImColor.new(0, 255, 0);
    tickPorters.tooltip_text = "Use Porters in inv."

    aioSelectC.box_name = "###Cache"
    aioSelectC.box_start = FFPOINT.new(32, 94, 0)
    aioSelectC.box_size = FFPOINT.new(240, 0, 0)
    aioSelectC.stringsArr = {}
    aioSelectC.tooltip_text = "Select a Cache to gather from."

    table.insert(aioSelectC.stringsArr, "Select a Cache")

    API.DrawSquareFilled(IG_Back)
    API.DrawTextAt(IG_Text)
    API.DrawBox(btnStart)
    API.DrawBox(btnStop)
    API.DrawCheckbox(tickPorters)
    API.DrawComboBox(aioSelectC, false)
end

local function formatNumber(num)
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

local function checkXpIncrease()
    local newXp = API.GetSkillXP("ARCHAEOLOGY")
    if newXp == startXp then
        API.logError("no xp increase")
        API.Write_LoopyLoop(false)
    else
        startXp = newXp
    end
end

local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
        -- comment this check xp if 200M
        checkXpIncrease()
        return true
    end
end

local function isMoving()
    return API.ReadPlayerMovin()
end

local function porterLogic()
    if not usePorters then
        return
    end
    local buffStatus = API.Buffbar_GetIDstatus(51490, false)
    local stacks = tonumber(buffStatus.text)

    local function findporters()
        local portersIds = {51490, 29285, 29283, 29281, 29279, 29277, 29275}
        local porters = API.CheckInvStuff3(portersIds)
        local foundIdx = -1
        for i, value in ipairs(porters) do
            if tostring(value) == '1' then
                foundIdx = i
                break
            end
        end
        if foundIdx ~= -1 then
            local foundId = portersIds[foundIdx]
            if foundId <= 51490 then
                return foundId
            else
                return nil
            end
        else
            return nil
        end
    end

    if Equipment:GetNeck(ESlot.NECK) == 44548 then
        if stacks and stacks <= 50 and findporters() then
            API.DoAction_Interface(0xffffffff, 0xae06, 6, 1464, 15, 2, API.OFF_ACT_GeneralInterface_route2)
            API.RandomSleep2(600, 600, 600)
            return
        elseif stacks and stacks <= 50 and findporters() == nil then
            API.DoAction_Inventory1(39488, 0, 1, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600, 300, 600)
            API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1371, 22, 13, API.OFF_ACT_GeneralInterface_route)
            API.RandomSleep2(600, 200, 600)
            API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, API.OFF_ACT_GeneralInterface_Choose_option)
            API.RandomSleep2(600, 300, 500)
            ::loop::
            if API.isProcessing() then
                API.RandomSleep2(200, 300, 200)
                goto loop
            end
            API.DoAction_Interface(0xffffffff, 0xae06, 6, 1464, 15, 2, API.OFF_ACT_GeneralInterface_route2)
            return
        end
    else
        if not buffStatus and findporters() then
            API.DoAction_Inventory1(findporters(), 0, 2, API.OFF_ACT_GeneralInterface_route)
        else
            if not buffStatus and findporters() == nil then
                API.DoAction_Inventory1(39488, 0, 1, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(600, 300, 600)
                API.DoAction_Interface(0xffffffff, 0xffffffff, 1, 1371, 22, 13, API.OFF_ACT_GeneralInterface_route)
                API.RandomSleep2(600, 200, 600)
                API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1,
                    API.OFF_ACT_GeneralInterface_Choose_option)
                API.RandomSleep2(600, 300, 500)
                ::loop::
                if API.isProcessing() then
                    API.RandomSleep2(200, 300, 200)
                    goto loop
                end
            end
        end
    end
end

local function excavate()
    local caches = API.ReadAllObjectsArray({0, 12}, {selectedCache.CACHEID}, {})
    local valid = {}
    for i = 1, #caches, 1 do
        local cache = caches[i]
        if cache.Bool1 == 0 then
            table.insert(valid, cache)
        end
    end
    if #valid > 0 then
        local target = API.Math_SortAODist(valid)
        if API.DoAction_Object_Direct(0x2, API.OFF_ACT_GeneralObject_route0, target) then
            UTILS.countTicks(2)
        end
    end
end

local function MaterialCounter()
    local chatEvents = API.GatherEvents_chat_check()
    if chatEvents then
        for k, v in pairs(chatEvents) do
            if string.find(v.text, "the following item to your") or string.find(v.text, "perk transports your items") then
                matcount = matcount + 1
            end
            if string.find(v.text, "sash brush perfectly") then
                matcount = matcount + 1
            end
        end
    end
end

local function formatElapsedTime(startTime)
    local currentTime = os.time()
    local elapsedTime = currentTime - startTime
    local hours = math.floor(elapsedTime / 3600)
    local minutes = math.floor((elapsedTime % 3600) / 60)
    local seconds = elapsedTime % 60
    return string.format("[%02d:%02d:%02d]", hours, minutes, seconds)
end

local function gameStateChecks()
    local gameState = API.GetGameState2()
    if (gameState ~= 3) then
        API.logError('Not ingame with state:' .. tostring(gameState))
        API.Write_LoopyLoop(false)
        return
    end
    if not API.PlayerLoggedIn() then
        API.logError('Not Logged In')
        API.Write_LoopyLoop(false)
        return;
    end
end

local function hasElvenRitualShard()
    return API.InvItemcount_1(ID.ELVEN_SHARD) > 0
end

local function useElvenRitualShard()
    if not (API.InvItemcount_1(ID.ELVEN_SHARD) > 0) then
        return
    end
    local prayer = API.GetPrayPrecent()
    local elvenCD = API.DeBuffbar_GetIDstatus(ID.ELVEN_SHARD, false)
    if prayer < 50 and not elvenCD.found then
        API.logDebug("Using Elven Shard")
        API.DoAction_Inventory1(ID.ELVEN_SHARD, 0, 1, API.OFF_ACT_GeneralInterface_route)
        UTILS.randomSleep(600)
    end
end

local function populateDropdown()
    for key, cache in pairs(CacheData) do
        if (#API.ReadAllObjectsArray({0, 12}, {cache.CACHEID}, {}) > 0) then
            table.insert(targets, cache)
        end
    end
    if #targets > 0 then
        local valueStrings = {}
        for i = 1, #targets, 1 do
            local item = targets[i]
            table.insert(valueStrings, item.label)
        end
        aioSelectC.stringsArr = valueStrings
        aioSelectC.int_value = 0
    end
end

local function onStart()
    setupOptions()
    API.SetDrawLogs(true)
    API.SetDrawTrackedSkills(true)
    populateDropdown()
    startTime = os.time()
    MAX_IDLE_TIME_MINUTES = 15
    selectedCache = targets[aioSelectC.int_value + 1]
    Material = selectedCache.label
end

local function guiLoop()
    if aioSelectC.return_click then
        local currentHotspot = Material
        local selected = aioSelectC.stringsArr[aioSelectC.int_value + 1]
        if selected == nil then
            return
        end
        selectedCache = targets[aioSelectC.int_value + 1]
        print(selectedCache.label)
        if currentHotspot ~= selected then
            Material = selected
            excavate()
        end
        aioSelectC.return_click = false
    end

    usePorters = tickPorters.box_ticked
    if btnStart.return_click then
        btnStart.return_click = false
        usePorters = tickPorters.box_ticked
        if btnStart.box_name == " PAUSE " then
            runScript = false
            btnStart.box_name = " START "
        else
            runScript = true
            btnStart.box_name = " PAUSE "
        end
    end
    if btnStop.return_click then
        API.Write_LoopyLoop(false)
        API.SetDrawLogs(false)
        btnStop.return_click = false
    end
end

onStart()
while (API.Read_LoopyLoop()) do
    MaterialCounter()
    local metrics = {{"Script", "AsoCacher - (v" .. version .. ") by Asoziales"}, {"Selected:", Material},
                     {"Runtime:", formatElapsedTime(startTime)}, {"Mats:", formatNumber(matcount)}}

    API.DrawTable(metrics)
    gameStateChecks()
    API.DoRandomEvents()
    idleCheck()
    guiLoop()
    if hasElvenRitualShard() then
        useElvenRitualShard()
    end
    if selectedCache ~= nil then
        if runScript then
            porterLogic()
            if not isMoving() and not API.CheckAnim(40) then
                excavate()
            end
        end
    end
    UTILS.rangeSleep(200, 0, 0)
end
