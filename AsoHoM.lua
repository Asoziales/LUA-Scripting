--[[

@title Aso Hall of Memorys
@description does HoM for big XP gains
@author Asoziales <discord@Asoziales>
@date 
@version 1.2

Message on Discord for any Errors or Bugs

--]]

local API = require("api")
local UTILS = require("utils")
local LODE = require("lodestones")

LOCATIONS = {
    hallOfMemories  =  {x = 2209, y = 9116, radius = 55, z = 0}
}

IDS = {
    OBJECTS = {
        jarDepot  =  { 111374 },
        unstableRift  =  { 111375 },
        plinth = { 111376 },
    },
    NPCS = {
        fadedMemories  =  { 25540 },
        lustrousMemories  =  { 25542, 25541 }, -- 70
        brilliantMemories  =  { 25543, 25544 }, -- 80
        radiantMemories  =  { 25545, 25546 }, -- 85
        luminousMemories  =  { 25548, 25547 }, -- 90
        incandescentMemories  =  { 25550, 25549 }, -- 95
        recollectionButterfly  =  { 225565 },
        coreMemoryFragment  =  { 25563 },
        knowledgeFragment  =  { 25564 },
        aagi  =  { 25551 },
        seren  =  { 25552 },
        juna  =  { 25553 },
        swordOfEdicts  =  { 25554 },
        cres  =  { 25555 },
    },
    ITEMS = {
        emptyJar  =  42898,
        partialJar  =  42899,
        fullJar  =  42900,
        coreMemoryFragment  =  42901,
    }
}

local version = "1.0"
local scriptPaused = true
local twoTick
local dumpCore


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
    IG_Text.string_value = "AsoHoM (v" .. version .. ") by Asoziales"

    IG_Back = API.CreateIG_answer()
    IG_Back.box_name = "back"
    IG_Back.box_start = FFPOINT.new(5, 64, 0)
    IG_Back.box_size = FFPOINT.new(226, 200, 0)
    IG_Back.colour = ImColor.new(15, 13, 18, 255)
    IG_Back.string_value = ""

    tickPorters = API.CreateIG_answer()
    tickPorters.box_ticked = true
    tickPorters.box_name = "2 Ticking?"
    tickPorters.box_start = FFPOINT.new(69, 122, 0);
    tickPorters.colour = ImColor.new(0, 255, 0);
    tickPorters.tooltip_text = "should i be 2 ticking?"

    tickcore = API.CreateIG_answer()
    tickcore.box_ticked = false
    tickcore.box_name = "use cores?"
    tickcore.box_start = FFPOINT.new(69, 100, 0);
    tickcore.colour = ImColor.new(0, 255, 0);
    tickcore.tooltip_text = "use cores on plinth?"

    API.DrawSquareFilled(IG_Back)
    API.DrawTextAt(IG_Text)
    API.DrawBox(btnStart)
    API.DrawBox(btnStop)
    API.DrawCheckbox(tickPorters)
    API.DrawCheckbox(tickcore)
end

fullinv = { 42898 }

--config--
local useCoreFragments = false
local collectKnowledgeFrags = true
local collectMemoryFrags = true

--data--
local startXp = API.GetSkillXP("DIVINATION")
local corefragsgathered = 0

startTime, afk = os.time(), os.time()
MAX_IDLE_TIME_MINUTES = 5

function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

function foundNPC(npcid)
    return #API.ReadAllObjectsArray({1}, npcid, {}) > 0
end

local function returnCurrentLevelMemory()
    local level = API.GetSkillByName("DIVINATION").level

    --if Playback found do those instead
    if foundNPC(IDS.NPCS.aagi) then
        return IDS.NPCS.aagi end
    if foundNPC(IDS.NPCS.seren) then
        return IDS.NPCS.seren end
    if foundNPC(IDS.NPCS.juna) then
        return IDS.NPCS.juna end
    if foundNPC(IDS.NPCS.swordOfEdicts) then
        return IDS.NPCS.swordOfEdicts end
    if foundNPC(IDS.NPCS.cres) then
        return IDS.NPCS.cres end

    -- Memories returned at level brackets
    if level >= 70 and level < 80 then
        return IDS.NPCS.lustrousMemories end
    if level >= 80 and level < 85 then
        return IDS.NPCS.brilliantMemories end
    if level >= 85 and level < 90 then
        return IDS.NPCS.radiantMemories end
    if level >= 90 and level < 95 then
        return IDS.NPCS.luminousMemories end
    if level >= 95 then
        return IDS.NPCS.incandescentMemories end
end

local function twoTicking()
    local newXp = API.GetSkillXP("DIVINATION")
    if newXp == startXp then
        return
    else
        startXp = newXp
        API.DoAction_NPC(0xc8, API.OFF_ACT_InteractNPC_route, returnCurrentLevelMemory(), 50)
    end
end

local function collectCoreMemoryFrag()
    if collectMemoryFrags then
        if foundNPC(IDS.NPCS.coreMemoryFragment) and API.InvFull_() and not API.InvItemFound1(IDS.ITEMS.coreMemoryFragment) then
            API.DoAction_Inventory1(42898,0,8,API.OFF_ACT_GeneralInterface_route2)
            API.RandomSleep2(1000, 300, 200)
            API.KeyboardPress2(0x59, 40, 60)
            API.RandomSleep2(600, 300, 200)
        end
        if foundNPC(IDS.NPCS.coreMemoryFragment) then
            API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,IDS.NPCS.coreMemoryFragment,50)
            API.WaitUntilMovingandAnimEnds(20,2)
        end
    end
end

local function collectKnowledgeFrag()
    ::loop::
    if collectKnowledgeFrag then
        if foundNPC(IDS.NPCS.knowledgeFragment) then
            API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route,IDS.NPCS.knowledgeFragment,50)
            API.WaitUntilMovingEnds(10,2)
            goto loop
        end
    end
end

local function collectEmptyJars()
    if not API.InvItemFound1(IDS.ITEMS.partialJar) and not API.InvItemFound1(IDS.ITEMS.fullJar) and API.Invfreecount_() >= 5 then
        API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,IDS.OBJECTS.jarDepot,50)
        API.WaitUntilMovingandAnimEnds()
    end
end

local function fillJars()
    if API.CheckAnim(25) then return end
    if API.ReadPlayerMovin2() then return end
    if twoTick then
        if API.InvItemFound1(IDS.ITEMS.emptyJar) or API.InvItemFound1(IDS.ITEMS.partialJar) then
            API.DoAction_NPC(0xc8, API.OFF_ACT_InteractNPC_route, returnCurrentLevelMemory(), 50)
            API.WaitUntilMovingEnds(5,2)
        end
    else
        if API.InvItemFound1(IDS.ITEMS.emptyJar) or API.InvItemFound1(IDS.ITEMS.partialJar) then
            API.DoAction_NPC(0xc8, API.OFF_ACT_InteractNPC_route, returnCurrentLevelMemory(), 50)
            API.WaitUntilMovingandAnimEnds()
        end
    end
end

local function depositJars()
    if API.InvItemFound1(IDS.ITEMS.fullJar) and not API.InvItemFound1(IDS.ITEMS.emptyJar) and not API.InvItemFound1(IDS.ITEMS.partialJar) then
        API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,IDS.OBJECTS.unstableRift,50)
        API.WaitUntilMovingEnds()
    end
end

local function centerActive()
    if foundNPC(IDS.NPCS.aagi) or foundNPC(IDS.NPCS.seren) or foundNPC(IDS.NPCS.juna) or foundNPC(IDS.NPCS.swordOfEdicts) or foundNPC(IDS.NPCS.cres) then
        return true
    else return false end
end

setupOptions()
API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.Write_LoopyLoop(true)
while (API.Read_LoopyLoop()) do
::home::
    if btnStop.return_click then
        API.Write_LoopyLoop(false)
        API.SetDrawLogs(false)
    end
    if scriptPaused == false then
        if btnStart.return_click then
            btnStart.return_click = false
            btnStart.box_name = " START "
            scriptPaused = true
            goto home
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
            tickcore.remove = true
            twoTick = tickPorters.box_ticked
            dumpCore = tickcore.box_ticked
            MAX_IDLE_TIME_MINUTES = 15
            scriptPaused = false
            print("Script started!")
            API.logDebug("Info: Script started!")
            if firstRun then
                startTime = os.time()
            end
        end
        
    end
    
    
    collectKnowledgeFrag()
    collectCoreMemoryFrag()

    ::core::
    if dumpCore and not centerActive() and API.InvStackSize(IDS.ITEMS.coreMemoryFragment) > 0 then
        API.DoAction_Object_valid1(0x29,API.OFF_ACT_GeneralObject_route0,IDS.OBJECTS.plinth,50,true) 
        API.RandomSleep2(2400,1800,1800)
        API.WaitUntilMovingEnds(20,2)
        goto core
    end

    if twoTick and API.ReadPlayerAnim() == 31889 then
        twoTicking()
    end

    collectEmptyJars()
    fillJars()
    depositJars()

    idleCheck()

    API.DoRandomEvents()
end
