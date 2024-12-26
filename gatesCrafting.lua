--[[

@title Gates of Elidinis Moonstone abuser
@description Abuse early Abuse often
@author Asoziales <discord@Asoziales>
@date 24/9/24
@version 1.0

Message on Discord for any Errors or Bugs

start in wars or near the sanctum

--]]

local API = require("api")
local UTILS = require("utils")
local LODE = require("lodestones")

startTime, afk = os.time(), os.time()
MAX_IDLE_TIME_MINUTES = 5

wars = {x = 3294, y = 10127, r = 40, z = 0}

local fail = 0

function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

function detectThing(type,npcid)
    return #API.ReadAllObjectsArray({type}, npcid, {}) > 0
end

local function instanceStarted()
    if API.VB_FindPSettinOrder(6931, 0).state == 0 then
        return false
    else return true
    end
end


local function startInstance()
    API.DoAction_Object1(0x39,API.OFF_ACT_GeneralObject_route0,{ 130974 },50)
    API.WaitUntilMovingEnds()
    API.DoAction_Interface(0x24,0xffffffff,1,1591,60,-1,API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600,600,600)
end

local function startEncounter()
    local icthlarin = API.ReadAllObjectsArray({1}, {17693}, {})
    local ichyX = math.floor(icthlarin[1].TileX / 512)
    local ichyY = math.floor(icthlarin[1].TileY / 512)
    API.DoAction_Tile(WPOINT.new(ichyX + 8, ichyY, 0))
    API.WaitUntilMovingEnds()
    API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,{ 17693 },50)
    fail = fail + 1
end

local function chiselMoonstone()
    API.DoAction_Object1(0x3e,API.OFF_ACT_GeneralObject_route0,{ 130991 },50)
    API.WaitUntilMovingEnds()
    fail = 0
end

API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.Write_LoopyLoop(true)
while (API.Read_LoopyLoop()) do
::continue::

    if fail == 5 then 
        API.DoAction_Ability("War's Retreat Teleport", 1, API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(3600,1200,200)
        fail = 0
    end

    if API.CheckAnim(30) or API.ReadPlayerMovin2() then
        API.RandomSleep2(300,200,100)
        goto continue
    end

    if API.PInArea(wars.x, wars.r, wars.y, wars.r, wars.z) then
        API.DoAction_Object1(0x39,API.OFF_ACT_GeneralObject_route0,{ 114764 },50)
        API.WaitUntilMovingEnds()
    end
 
    if detectThing(1,{31110}) then
        startInstance()
    end

    if detectThing(1,{17693}) and API.VB_FindPSettinOrder(4680).state == 0 then 
        startEncounter()
    end

    if API.VB_FindPSettinOrder(4680).state == 53 then
        chiselMoonstone()
    end

    idleCheck()
    API.DoRandomEvents()
    API.RandomSleep2(300, 200, 300)
end
