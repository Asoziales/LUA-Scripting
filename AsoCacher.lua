--[[

@title AsoCacher
@description Gathers from Material Caches 
@author Asoziales <discord@Asoziales>
@date 10/07/2024
@version 1.2 ~ Added Third Age Iron

Message on Discord for any Errors or Bugs

Make sure you are wearing a Grace of the Elves and have any porters in inventory if using porters or memory shards

--]]

local API = require("api")
local UTILS = require("utils")

-- variables
local startXp = API.GetSkillXP("ARCHAEOLOGY")
local MAX_IDLE_TIME_MINUTES = 5
local afk = os.time()
local depositAttempt = 0

local skill = "ARCHAEOLOGY"
startXp = API.GetSkillXP(skill)
local version = "1.0"
local Material = ""
local selectedCache = nil
local selectedMaterial = nil
local scriptPaused = true
local matcount = 0
-- local hazele = 0
-- local blurb = 0
local banking = 0
local startTime = os.time()
local errors = {}
local usePorters
local firstRun = true

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
}}

ID = {
    CACHE = {
        CLAY_CACHE = 116391
    },
    AUTO_SCREENER = 50161,
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
    tickPorters.box_ticked = true
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
    for i, v in ipairs(CacheData) do
        table.insert(aioSelectC.stringsArr, v.label)
    end

    API.DrawSquareFilled(IG_Back)
    API.DrawTextAt(IG_Text)
    API.DrawBox(btnStart)
    API.DrawBox(btnStop)
    API.DrawCheckbox(tickPorters)
    API.DrawComboBox(aioSelectC, false)
end

local function round(val, decimal)
    if decimal then
        return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return math.floor(val + 0.5)
    end
end

function formatNumber(num)
    if num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

-- helper functions
local function invContains(items)
    local loot = API.InvItemcount_2(items)
    for _, v in ipairs(loot) do
        if v > 0 then
            return true
        end
    end
    return false
end

local function CachetoGather()
    if (aioSelectC.string_value == "Vulcanized rubber") then
        Material = "Vulcanized rubber"
    elseif (aioSelectC.string_value == "Ancient vis") then
        Material = "Ancient vis"
    elseif (aioSelectC.string_value == "Blood of Orcus") then
        Material = "Blood of Orcus"
    elseif (aioSelectC.string_value == "Hellfire metal") then
        Material = "Hellfire metal"
    elseif (aioSelectC.string_value == "Third Age Iron") then
        Material = "Third Age Iron"
    end
end

local function Logout()
    API.logDebug("Info: Logging out!")
    API.logInfo("Logging out!")
    API.DoAction_Logout_mini()
    API.RandomSleep2(1000, 150, 150)
    API.DoAction_Interface(0x24,0xffffffff,1,1433,71,-1,API.OFF_ACT_GeneralInterface_route)
    API.Write_LoopyLoop(false)
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

local function gameStateChecks()
    local gameState = API.GetGameState2()
    if (gameState ~= 3) then
        API.logDebug('Not ingame with state:', gameState)
        API.Write_LoopyLoop(false)
        return
    end
    if not API.PlayerLoggedIn() then
        API.logDebug('Not Logged In')
        API.Write_LoopyLoop(false)
        return;
    end
end

local function isMoving()
    return API.ReadPlayerMovin()
end

local function openBank()
    API.DoAction_Object1(0x2e, API.OFF_ACT_GeneralObject_route1, {115427}, 50)
end

local function keepGOTEcharged()

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

    if stacks and stacks <= 50 and findporters() then
        print("Recharging GOTE")
        API.DoAction_Interface(0xffffffff, 0xae06, 6, 1464, 15, 2, API.OFF_ACT_GeneralInterface_route2)
        API.RandomSleep2(600, 600, 600)
        return
    end
    if stacks and stacks <= 50 and findporters() == nil then
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
end

local function Bank()

    API.logWarn("Not implemented ggez")
    -- if not API.BankOpen2() then
    --     openBank()
    -- end
    -- depositAttempt = depositAttempt + 1;
    -- if depositAttempt > 3 then 
    --     API.Write_LoopyLoop(false)
    -- end 

    -- print("pressing 3")
    -- API.KeyboardPress("3",50,100)
    -- if not API.InvFull_() then
    --     depositAttempt = 0
    -- end
end

local function depositCart()
    API.logDebug('Inventory is full after using soilbox, trying to deposit: ' .. depositAttempt)
    depositAttempt = depositAttempt + 1;
    if depositAttempt > 3 then
        API.Write_LoopyLoop(false)
    end
    local cart = API.GetAllObjArrayInteract_str({"Material storage container"}, 60, {0})
    if #cart > 0 then
        API.DoAction_Object_string1(0x29, API.OFF_ACT_GeneralObject_route0, {"Material storage container"}, 60, true);
        UTILS.randomSleep(800)
        API.WaitUntilMovingEnds()
        if not API.InvFull_() then
            depositAttempt = 0
        end
    else
        API.logWarn('Didn\'t find: Material storage container within 60 tiles')
    end
end

local function porterCheck()
    if invContains(ID.PORTERS) then
        return true
    else
        return false
    end
end

local function excavate()
    if not API.DoAction_Object_valid1(0x2, API.OFF_ACT_GeneralObject_route0, {selectedCache}, 50, true) then
        API.logDebug("NO Cache found")
        API.DoAction_Object_valid1(0x2, API.OFF_ACT_GeneralObject_route0, {ID.CACHE.CLAY_CACHE}, 50, true)
    end
    API.RandomSleep2(5000, 1000, 2000)
end

local function HasAutoScreener()
    return API.InvItemcount_1(ID.AUTO_SCREENER) > 0
end

local function MaterialCounter()
    local chatEvents = API.GatherEvents_chat_check()
    if chatEvents then
        for k, v in pairs(chatEvents) do
            if k > 2 then
                break
            end
            if string.find(v.text, "the following item to your") then
                matcount = matcount + 1
                -- else if string.find(v.text, "The Seren spirit gifts you: 1X") then
                --     blurb = blurb + 1
                -- else if string.find(v.text, "You transport the following item to your bank") then
                --     hazele = hazele + 1
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
        API.logError('Not ingame with state:', gameState)
        API.Write_LoopyLoop(false)
        return
    end
    if not API.PlayerLoggedIn() then
        API.logError('Not Logged In')
        API.Write_LoopyLoop(false)
        return;
    end
end

local IDS = {ELVEN_SHARD = 43358}

local function hasElvenRitualShard()
    return API.InvItemcount_1(IDS.ELVEN_SHARD) > 0
end

local function useElvenRitualShard()
    if not (API.InvItemcount_1(IDS.ELVEN_SHARD) > 0) then return end
    local prayer = API.GetPrayPrecent()
    local elvenCD = API.DeBuffbar_GetIDstatus(IDS.ELVEN_SHARD, false)
    if prayer < 50 and not elvenCD.found then
        API.logDebug("Using Elven Shard")
        API.DoAction_Inventory1(IDS.ELVEN_SHARD, 0, 1, API.OFF_ACT_GeneralInterface_route)
        UTILS.randomSleep(600)
    end
end

setupOptions()
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
while (API.Read_LoopyLoop()) do
    MaterialCounter()
    CachetoGather()
    local elapsedMinutes = (os.time() - startTime)
    local metrics = {{"Script", "AsoCacher - (v" .. version .. ") by Asoziales"}, {"Selected:", Material},
                     {"Runtime:", formatElapsedTime(startTime)}, {"Mats:", formatNumber(matcount)} -- {"Blurbs:", tostring(blurb)},
    --  {"Hazelmere's:", tostring(hazele)}
    }
    API.DrawTable(metrics)
    gameStateChecks()
    MaterialCounter()
    API.DoRandomEvents()
    idleCheck()
    if hasElvenRitualShard() then useElvenRitualShard() end
    ---------------- UI
    if btnStop.return_click then
        API.Write_LoopyLoop(false)
        API.SetDrawLogs(false)
    end
    if scriptPaused == false then
        if btnStart.return_click then
            btnStart.return_click = false
            btnStart.box_name = " START "
            scriptPaused = true
        end
    end
    if scriptPaused == true then
        if btnStart.return_click then
            btnStart.return_click = false
            btnStart.box_name = " PAUSE "
            IG_Back.remove = true
            btnStart.remove = true
            IG_Text.remove = true
            btnStop.remove = true
            tickPorters.remove = true
            aioSelectC.remove = true
            usePorters = tickPorters.box_ticked
            MAX_IDLE_TIME_MINUTES = 15
            scriptPaused = false
            print("Script started!")
            API.logDebug("Info: Script started!")
            if firstRun then
                startTime = os.time()
            end

            if (aioSelectC.return_click) then
                aioSelectC.return_click = false
                for i, v in ipairs(CacheData) do
                    if (aioSelectC.string_value == v.label) then
                        selectedCache = v.CACHEID
                        selectedMaterial = v.MATERIALID
                    end
                end
            end

            if selectedCache == nil then
                API.Write_LoopyLoop(false)
                print("Please select a Cache type from the dropdown menu!")
                API.logError("Please select a Cache type from the dropdown menu!")
            end
        end
        goto continue
    end

    if not isMoving() and not API.CheckAnim(40) then
        if keepGOTEcharged() then
            API.RandomSleep2(600, 200, 300)
        else
            excavate()
            API.RandomSleep2(600, 200, 300)
        end
    end

    ::continue::
    API.RandomSleep2(500, 650, 500)
end

