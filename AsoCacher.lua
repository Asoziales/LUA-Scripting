--[[

@title AsoCacher
@description Gathers from Material Caches
@author Asoziales <discord@Asoziales>
@date 01/10/2024
@version 2.0
@Changelog
2.0 <discord@dea.d>
    - Auto select cache from area
    - Doesn't interact with depleted caches
    - Gathers from closest cache
    - Porters checkbox from UI has been moved to a boolean `usePorters`

1.2 <discord@Asoziales>
    - Added Third Age Iron

Message on Discord for any Errors or Bugs

Make sure you are wearing a Grace of the Elves and have any porters in inventory if using porters or memory shards

--]]

local API = require("api")
local UTILS = require("utils")

-- variables
local startXp = API.GetSkillXP("ARCHAEOLOGY")
local MAX_IDLE_TIME_MINUTES = 5
local afk = os.time()

local skill = "ARCHAEOLOGY"
startXp = API.GetSkillXP(skill)
local version = "2.0"
local Material = ""
local selectedCache = nil
local matcount = 0
local startTime = os.time()
local usePorters = true

API.logWarn("Started AsoCacher - (v" .. tostring(version) .. ") by Asoziales")
print("Started AsoCacher - (v" .. tostring(version) .. ") by Asoziales")

local CacheData = { {
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
} }

ID = {
    CACHE = {
        CLAY_CACHE = 116391
    },
    AUTO_SCREENER = 50161,
    ELVEN_SHARD = 43358,
    PORTERS = { 29281, 29283, 29285, 51490 }
}

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

local function keepGOTEcharged()
    if not usePorters then return end
    local buffStatus = API.Buffbar_GetIDstatus(51490, false)
    local stacks = tonumber(buffStatus.text)

    local function findporters()
        local portersIds = { 51490, 29285, 29283, 29281, 29279, 29277, 29275 }
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

local function excavate()
    local caches = API.ReadAllObjectsArray({ 0, 12 }, { selectedCache }, {})
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
            if k > 2 then
                break
            end
            if string.find(v.text, "the following item to your") or string.find(v.text, "perk transports your items") then
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
    if not (API.InvItemcount_1(ID.ELVEN_SHARD) > 0) then return end
    local prayer = API.GetPrayPrecent()
    local elvenCD = API.DeBuffbar_GetIDstatus(ID.ELVEN_SHARD, false)
    if prayer < 50 and not elvenCD.found then
        API.logDebug("Using Elven Shard")
        API.DoAction_Inventory1(ID.ELVEN_SHARD, 0, 1, API.OFF_ACT_GeneralInterface_route)
        UTILS.randomSleep(600)
    end
end

local function onStart()
    for key, cache in pairs(CacheData) do
        if (#API.ReadAllObjectsArray({ 0, 12 }, { cache.CACHEID }, {}) > 0) then
            selectedCache = cache.CACHEID
            Material = cache.label
            API.logWarn('Found Cache:' .. Material)
            print('Found Cache:' .. Material)
            break
        end
    end
end

onStart()
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)

while (API.Read_LoopyLoop()) do
    MaterialCounter()
    local metrics = {
        { "Script", "AsoCacher - (v" .. version .. ") by Asoziales"},
        { "Selected:", Material },
        { "Runtime:", formatElapsedTime(startTime)},
        { "Mats:", formatNumber(matcount)}
    }

    API.DrawTable(metrics)
    gameStateChecks()
    API.DoRandomEvents()
    idleCheck()
    if hasElvenRitualShard() then useElvenRitualShard() end
    if selectedCache == nil then
        API.Write_LoopyLoop(false)
        print("Couldn't find a valid cache")
        API.logError("Couldn't find a valid cache")
        break
    else
        if not isMoving() and not API.CheckAnim(40) then
            if keepGOTEcharged() then
                API.RandomSleep2(600, 200, 300)
            else
                excavate()
            end
        end
    end
    UTILS.rangeSleep(200, 0, 0)
end
