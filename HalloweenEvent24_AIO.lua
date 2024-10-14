--[[

@title HalloweenEvent24_AIO
@description does the 3 basic Halloween event skilling locations
@author Asoziales <discord@Asoziales> Credit Deadcodes for easy Arch 
@date 14/10/24 ( 13 minutes post update ;) )
@version 1.0

Message on Discord for any Errors or Bugs

Start in area and select from the dropdown

--]]

local API = require("api")
local UTILS = require("utils")
local LODE = require("lodestones")

startTime, afk = os.time(), os.time()
MAX_IDLE_TIME_MINUTES = 5

IDS = { OBJ = { CANDLES = {131362,131364}, 
                SUMMONCIRCLE = {131360},
                LOOTABLE = {131353,131351},
                ARCH = {131355},
    },
        NPC = { EEP = {31287}, 
    }
    }

    local options = {"Choose Selection", "Thieving", "Archeology", "Summoning"}

local imguicombo = API.CreateIG_answer()
imguicombo.box_name = " Options     "
imguicombo.box_start = FFPOINT.new(100, 20, 0)
imguicombo.stringsArr = options
imguicombo.tooltip_text = "What are you wanting to do?"
    
local imguiBackground = API.CreateIG_answer();
imguiBackground.box_name = "imguiBackground";
imguiBackground.box_start = FFPOINT.new(105, 25, 0);
imguiBackground.box_size = FFPOINT.new(380, 50, 0)

API.DrawComboBox(imguicombo, false)

imguiBackground.colour = ImColor.new(10, 13, 29)

local function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

--#region Archeology

local function FindHl(objects, maxdistance, highlight)
    local objObjs = API.GetAllObjArray1(objects, maxdistance, {12})
    local hlObjs = API.GetAllObjArray1(highlight, maxdistance, {4})
    local shiny = {}
    for i = 0, 1.5, 0.1 do
        for _, obj in ipairs(objObjs) do
            for _, hl in ipairs(hlObjs) do
                if math.abs(obj.Tile_XYZ.x - hl.Tile_XYZ.x) < i and math.abs(obj.Tile_XYZ.y - hl.Tile_XYZ.y) < i then
                    shiny = obj
                end
            end
        end
    end
    return shiny
end

local function followTimeSprite(objects)
    local foundObjects = API.GetAllObjArray1(IDS.OBJ.ARCH, 60, {12})
    local targetIds = {}
    for i = 1, #foundObjects do
        local rock = foundObjects[i]
    end
    local sprite = FindHl(IDS.OBJ.ARCH, 60, { 7307 })
    if not API.ReadPlayerMovin2() then
        if sprite.Id ~= nil then
            local spritePos = WPOINT.new(sprite.TileX / 512, sprite.TileY / 512, sprite.TileZ / 512)
            local distanceF = API.Math_DistanceF(API.PlayerCoordfloat(), sprite.Tile_XYZ)
            if distanceF > 1.6 then
                UTILS.randomSleep(400)
                if not API.CheckAnim(20) and #foundObjects > 0 then
                    API.logInfo("Excavating " .. 'Mystery remains')
                else
                    API.logInfo("Sprite has moved, chasing it")
                end
                API.DoAction_Object2(0x2, API.OFF_ACT_GeneralObject_route0, { sprite.Id }, 60, spritePos)
                UTILS.randomSleep(1000)
                API.WaitUntilMovingEnds()
                return
            end
        end
        if not API.CheckAnim(40) and not API.InvFull_() and #foundObjects > 0 then
            API.logInfo("Excavating " .. 'Mystery remains')
            API.DoAction_Object1(0x2, API.OFF_ACT_GeneralObject_route0, IDS.OBJ.ARCH, 60)
            UTILS.randomSleep(800)
        end
    end
end

local destroyInterface = {
    InterfaceComp5.new(1183, 11, -1, -1, 0),
}

local function destroyInterfaceFound()
    local result = API.ScanForInterfaceTest2Get(true, destroyInterface)
    if #result > 0 then
        return true
    else
        return false
    end
end

local function destroyTome()
    local inventory = API.ReadInvArrays33()

    local items = UTILS.getDistinctByProperty(inventory, "textitem")
    for i = 1, #items, 1 do
        local item = items[i]
        if string.find(tostring(item.textitem), "Complete tome") then
            API.logWarn("Destroying " .. item.textitem)
            API.DoAction_Interface(0x24, item.itemid1, 8, item.id1, item.id2, item.id3,
                API.OFF_ACT_GeneralInterface_route2)
            UTILS.SleepUntil(destroyInterfaceFound, 5, "Destroying " .. item.textitem)
            API.DoAction_Interface(0xffffffff, 0xffffffff, 0, 1183, 5, -1, API.OFF_ACT_GeneralInterface_Choose_option)
            UTILS.randomSleep(800)
        end
    end
end

local function handInCollection()
    if API.InvFull_() then
        API.DoAction_NPC(0x29,API.OFF_ACT_InteractNPC_route2,IDS.NPC.EEP,50)
        API.WaitUntilMovingEnds(10,3)
        API.DoAction_Interface(0x24,0xffffffff,1,656,25,0,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600,200,200)
        API.DoAction_Interface(0x24,0xffffffff,1,656,25,0,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600,200,200)
        API.DoAction_Interface(0x24,0xffffffff,1,656,25,0,API.OFF_ACT_GeneralInterface_route)
        API.RandomSleep2(600,200,200)
        API.DoAction_Interface(0x24,0xffffffff,1,656,25,0,API.OFF_ACT_GeneralInterface_route)   
        API.RandomSleep2(600,1200,600)
        if API.InvFull_() then
            API.Write_LoopyLoop(false)
        end
    end
end

--#endregion

local function drawGUI()
    API.DrawSquareFilled(imguiBackground)
end


API.SetDrawLogs(true)
API.SetDrawTrackedSkills(true)
API.Write_LoopyLoop(true)
while (API.Read_LoopyLoop()) do
    local selected = imguicombo.stringsArr[imguicombo.int_value + 1]

    if selected == "Choose Selection" then
        API.RandomSleep2(200, 300, 200)
    end

    if selected == "Archeology" then
        followTimeSprite()
        destroyTome()
        handInCollection()
    end

    if selected == "Summoning" then
        if API.DoAction_Object1(0x41, API.OFF_ACT_GeneralObject_route0, IDS.OBJ.CANDLES, 50) then
            API.RandomSleep2(1200, 900, 200)
        end

        if not API.CheckAnim(20) and not API.ReadPlayerMovin2() then
            API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, IDS.OBJ.SUMMONCIRCLE, 50)
            API.RandomSleep2(300, 300, 200)
        end
    end

    if selected == "Thieving" then
        if not API.CheckAnim(50) and not API.ReadPlayerMovin2() then
            API.DoAction_Object1(0x29, API.OFF_ACT_GeneralObject_route0, IDS.OBJ.LOOTABLE, 50)
            API.RandomSleep2(1200, 500, 200)
        end
    end

    idleCheck()
    API.DoRandomEvents()
    API.RandomSleep2(300, 200, 300)
end

