--[[

Aso's Elder Arrow Trifecta!!!

completes all the activities in order to make dinoarrows from collecting the shit, to shells and shafts.

Just start in the area of your desired activity and click from the dropdown menu....

Last updated: 21/9/24 -- fixed missed unknown offset
For bugs, errors or feature requests dm @Asoziales on discord


]]


local API = require("api")

startTime, afk = os.time(), os.time()
MAX_IDLE_TIME_MINUTES = 5
goodegg = 53099
badegg = 53100
tummisaurus = 56281
rootlesaurus = 53082
barnasaurus = 53081
berrisaurus = 53079
fertilizer = 53078

local options = {"Choose Selection", "Zygomite Hairstyling", "Eggsperimentation", "Dinosaur Shit"}

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

function idleCheck()
    local timeDiff = os.difftime(os.time(), afk)
    local randomTime = math.random((MAX_IDLE_TIME_MINUTES * 60) * 0.6, (MAX_IDLE_TIME_MINUTES * 60) * 0.9)

    if timeDiff > randomTime then
        API.PIdle2()
        afk = os.time()
    end
end

local function grabDinos()
    API.DoAction_Object1(0x2d, API.OFF_ACT_GeneralObject_route0, {123400}, 50)
end

local function feedRoots()
    API.DoAction_Object1(0x2f, API.OFF_ACT_GeneralObject_route0, {123409}, 50)
end

local function feedBeans()
    API.DoAction_Object1(0x2f, API.OFF_ACT_GeneralObject_route0, {123405}, 50)
end

local function feedBerries()
    API.DoAction_Object1(0x2f, API.OFF_ACT_GeneralObject_route0, {123403}, 50)
end

local function feedCereal()
    API.DoAction_Object1(0x2f, API.OFF_ACT_GeneralObject_route0, {123407}, 50)
end

local function burnPropellant()
    API.DoAction_Inventory2({fertilizer}, 40, 1, API.OFF_ACT_GeneralInterface_route)
    API.RandomSleep2(600, 200, 300)
end

local function grabDinoeggs()
    API.DoAction_Object1(0x2d,API.OFF_ACT_GeneralObject_route0,{ 123383 },50)
    API.RandomSleep2(600, 200, 300)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(600, 200, 300)
end

local function incubator()
    API.DoAction_Object1(0x2f, API.OFF_ACT_GeneralObject_route0, {123386}, 50)
    API.RandomSleep2(600, 200, 300)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(600, 200, 300)
end

local function compostbin()
    API.DoAction_Object1(0x2f, API.OFF_ACT_GeneralObject_route0, {123389}, 50)
    API.RandomSleep2(600, 200, 300)
    API.WaitUntilMovingEnds()
    API.RandomSleep2(600, 200, 300)
end

local function hairstyler()
    API.DoAction_NPC(0xcd,API.OFF_ACT_InteractNPC_route,{ 28978 },50)
    API.RandomSleep2(600, 200, 300)
end

local function drawGUI()
    API.DrawSquareFilled(imguiBackground)
end

while API.Read_LoopyLoop() do
    local selected = imguicombo.stringsArr[imguicombo.int_value + 1]
    API.SetDrawTrackedSkills(true)

    drawGUI()
    idleCheck()
    API.DoRandomEvents()

    if selected == "Choose Selection" then
        API.RandomSleep2(200, 300, 200)
    end

    if selected == "Zygomite Hairstyling" then
        if not API.CheckAnim(50) and not API.ReadPlayerMovin() then
            hairstyler()
            API.RandomSleep2(1200, 300, 200)
        end
        API.RandomSleep2(200, 300, 200)
    end

    if selected == "Eggsperimentation" then
        if API.InvItemFound1(goodegg) or API.InvItemFound1(badegg) then
            if API.InvItemFound1(goodegg) and not API.CheckAnim(50) and not API.ReadPlayerMovin() then
                print("good eggs:", API.InvItemcount_1(goodegg))
                incubator()
            elseif API.InvItemFound1(badegg) and not API.CheckAnim(50) and not API.ReadPlayerMovin() then
                print("bad eggs:", API.InvItemcount_1(badegg))
                compostbin()
            end
        else
            if not API.InvItemFound1(goodegg) and not API.InvItemFound1(badegg) then
                grabDinoeggs()
                API.RandomSleep2(600, 200, 300)
                API.WaitUntilMovingandAnimEnds()
                API.RandomSleep2(300, 200, 300)
            end
        end
        API.RandomSleep2(200, 300, 200)
    end

    if selected == "Dinosaur Shit" then
        if API.InvFull_() then
            if API.InvItemFound1(tummisaurus) and not API.CheckAnim(50) and not API.ReadPlayerMovin() then
                print("rootlesaurus:", API.InvItemcount_1(rootlesaurus))
                feedRoots()
            elseif API.InvItemFound1(rootlesaurus) and not API.CheckAnim(50) and not API.ReadPlayerMovin() then
                print("barnasaurus:", API.InvItemcount_1(barnasaurus))
                feedCereal()
            elseif API.InvItemFound1(barnasaurus) and not API.CheckAnim(50) and not API.ReadPlayerMovin() then
                print("berrisaurus:", API.InvItemcount_1(berrisaurus))
                feedBerries()
            elseif API.InvItemFound1(berrisaurus) and not API.CheckAnim(50) and not API.ReadPlayerMovin() then
                print("propellant:", API.InvItemcount_1(fertilizer))
                feedBeans()
            elseif API.InvItemFound1(fertilizer) and not API.CheckAnim(50) and not API.ReadPlayerMovin() then
                print("propellant:", API.InvItemcount_1(fertilizer))
                burnPropellant()
            end
        elseif not API.isProcessing() then
            grabDinos()
            API.RandomSleep2(600, 200, 300)
            API.WaitUntilMovingEnds()
        end
        API.RandomSleep2(200, 300, 200)
    end

    API.RandomSleep2(200, 300, 200)
end
API.SetDrawTrackedSkills(false)
