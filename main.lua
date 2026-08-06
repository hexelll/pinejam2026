local import = require 'import'

local gameHandler = import 'gameHandler.lua'
local mapExplorator = import 'mapExplorator.lua'
local NoiseMaker = import "NoiseMaker.lua"
local MapGenerator = import "MapGenerator.lua"

import
    :setDownloadDir("/vendor/combox")
    :setDir("https://raw.githubusercontent.com/hexelll/ComBox/refs/heads/dev/")

local Renderer = import 'Renderer.lua'
local ImageHandler = import 'ImageHandler.lua'
local Color = import 'Color.lua'
local MakeImage = import "pipelines/GenerateImage.lua"
local char,square = import('combinators/MathCharCombinator.lua'):new(),import('combinators/SquarePixelCombinator.lua'):new()


--[[
    INIT GAME
]]
write("Building the map... ")
local map = MapGenerator.makeMap()
print("Map ready")


--[[
    SETUP DISPLAY
]]
write("Initializing display... ")
local mon = peripheral.find('monitor')
mon.setTextScale(0.5)

local screen = Renderer:new{
    term=mon,
    combinators={char,square}
}

gameHandler.state = {
    biomeMap = map.biomeMap,
}
local pipeline = mapExplorator(gameHandler,screen, map.prettyMap)
print("Display ready")


--[[
    GAME LOGIC 
]]

local function kaboom()
    print("KABOOM")
end

local function launchAttack(warning)
    
end

-- bombs logic
gameHandler:addTask(function (state)

    -- launch bombs when bombwarning expires
    for k,warning in pairs(state.bombsWarnings) do
        if ( warning.bombingTime <= os.clock() ) then
            launchAttack(warning)
            state.bombsWarnings[k] = nil
        end
    end
    
    -- add warnings 
    local delayBombs = (1/state.dangerLevel)*5
    if ( os.clock() - state.bombWarningTime > delayBombs )then
   
        state.bombsWarnings[state.warningId] = {
            warningId = state.warningId,
            x=math.random(),
            y=math.random(),
            r=0.05+math.random()*state.dangerLevel/10,
            bombingTime = os.clock()+10,
            startTime = os.clock()
        }
        state.warningId = state.warningId + 1

        print("BOMBS COMMING")

        state.bombWarningTime = os.clock()
    end

end)

-- days logic
gameHandler:addTask(function (state)
    if ( os.clock() - state.dayChangeTime > 5 )then -- time between days

        if (state.isAlive) then
            state.ressources = state.ressources + state.dayNb
            
            print("You have ".. state.ressources .." ressources")
        end

        state.dangerLevel = state.dangerLevel*1.1
        state.dayNb = state.dayNb + 1
        state.dayChangeTime = os.clock()
    end
end)

-- end logic
gameHandler:addTask(function (state)
    if state.cities and #state.cities <= 0 then
        state.isAlive = false
        print("GAME OVER !")
    end
end)


--[[
    START 
]]
print("Game started !")
gameHandler:run{
    warningId = 1,
    isAlive = true,
    dangerLevel = 1,
    ressources = 4,
    maxRessources=100,
    dayNb = 1,
    dayChangeTime = os.clock(),
    bombWarningTime = os.clock(),
    bombsWarnings = {},
    shots = {}
}