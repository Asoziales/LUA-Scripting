--[[

@title AsoAIOFramer
@description Creates frames and Wall segments
@author Asoziales <discord@Asoziales>
@date 23/12/24
@version 1.0

Message on Discord for any Errors or Bugs

Load Last preset as logs,planks,refinedplanks or bricks to make whatever 

--]]

local API = require("api")
MAX_IDLE_TIME_MINUTES = 8
startTime, afk = os.time(), os.time()
local startXp = API.GetSkillXP("CONSTRUCTION")
local timeout = 0

---------------------------
local logs = {1511, -- tree
1521, -- oak
1519, -- willow
1517, -- maple
6333, -- teak
40285, -- acadia
5332, -- mahogany
1515, -- yew
1513, -- magic
29556} -- elder
local planks = {960, -- tree
8778, -- oak
54860, -- willow
54862, -- maple
8780, -- teak
54864, -- acadia
8782, -- mahogany
54866, -- yew
54868, -- magic
54870} -- elder 
local refinedPlanks = {54444, -- tree
54446, -- oak
54840, -- acadia
54448, -- teak
54450, -- mahogany
54837, -- willow
54838, -- maple
54842, -- yew
54844, -- magic
54846} -- elder
local frames = {54452, -- tree
54454, -- oak
54456, -- teak
54458, -- mahogany
54848, -- willow
54850, -- maple
54852, -- acadia
54854, -- yew
54856, -- magic
54858} -- elder
local bricks = {3420} -- limestone brick
local wallSegment = {54460} -- Wall segment
---------------------------

function banking()
    API.DoAction_Object1(0x33, API.OFF_ACT_GeneralObject_route3, {125115}, 50)
    API.WaitUntilMovingEnds(5, 2)
    timeout = timeout + 1
end

function cutstone()
    Interact:Object('Stonecutter', 'Cut stone')
    API.WaitUntilMovingEnds(5, 2)
    API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, API.OFF_ACT_GeneralInterface_Choose_option)
    API.RandomSleep2(2400, 600, 600)
    timeout = 0
end

function cutplanks()
    Interact:Object('Sawmill', 'Process planks')
    API.WaitUntilMovingEnds(5, 2)
    API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, API.OFF_ACT_GeneralInterface_Choose_option)
    API.RandomSleep2(2400, 600, 600)
    timeout = 0
end

function cutFrames()
    Interact:Object('Woodworking bench', 'Construct frames')
    API.WaitUntilMovingEnds(5, 2)
    API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1370, 30, -1, API.OFF_ACT_GeneralInterface_Choose_option)
    API.RandomSleep2(2400, 600, 600)
    timeout = 0
end

local function checkXpIncrease()
    local newXp = API.GetSkillXP("CONSTRUCTION")
    if newXp == startXp then
        API.logError("no xp increase")
        API.Write_LoopyLoop(false)
    else
        startXp = newXp
    end
end

function idleCheck()
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
-- Exported function list is in API
-- main loop
API.Write_LoopyLoop(true)
while (API.Read_LoopyLoop()) do

    ::start::
    if API.isProcessing() then
        API.RandomSleep2(200, 300, 200)
        goto start
    end

    if timeout == 5 then
        API.Write_LoopyLoop(false)
    end

    if Inventory:ContainsAny(bricks) and not API.isProcessing() then
        cutstone()
    end

    if Inventory:ContainsAny(logs) or Inventory:ContainsAny(planks) and not API.isProcessing() then
        cutplanks()
    end

    if Inventory:ContainsAny(refinedPlanks) and not Inventory:ContainsAny(frames) and not API.isProcessing() then
        cutFrames()
    end

    if Inventory:ContainsAny(frames) and not API.isProcessing() or Inventory:ContainsAny(wallSegment) and
        not API.isProcessing() then
        Interact:Object('Bank chest', 'Load Last Preset from')
        API.WaitUntilMovingEnds(5, 2)
    end

    idleCheck()
    API.DoRandomEvents()

    API.RandomSleep2(200, 300, 200)
end ----------------------------------------------------------------------------------
