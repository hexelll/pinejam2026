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
    INIT MAP
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
local function findPointById(state,id)
        for i,p in pairs(state.cities) do
            if p[3] == id then
                return i
            end
        end
        return nil
    end
local function removePoint(state,id)
    table.remove(state.cities,findPointById(state,id))
    local newLines = {}
    for i,l in pairs(state.lines) do
        if not(l[1] == id or l[2] == id) then
            newLines[#newLines+1] = l
        end
    end
    state.lines = newLines
end
local function invertZoom(u,v,level,x,y)
    return (u-x-0.5)*level+0.5,(v-y-0.5)*level+0.5
end
-- explode one shot
local function kaboom(state,shot)
    -- destroy cities/lines

    for _,p in pairs(state.cities) do
        local x,y = invertZoom(shot.x,shot.y,state.level,state.x,state.y)
        local du,dv = p[1]-x,p[2]-y
        local d = du*du+dv*dv
        if d < shot.r*shot.r then
            print("KABOOM")
            removePoint(state,p[3])
        end
    end
end
-- shots explosions logic
gameHandler:addTask(function (state)

    -- explode when shot expires
    for k,shot in pairs(state.shots) do
        if ( shot.bombingTime <= os.clock() ) then
            kaboom(state,shot)
            state.shots[k] = nil
        end
    end

end)



local function randomFloat(min,max)
    return math.random()*(max-min)+min
end

-- create shots in bombs warning
local function launchAttack(state,w)
    
    local nbShots = 1--math.floor(state.dangerLevel+0.5)
    for i=1,nbShots do 

        local x,y = randomFloat(w.x-w.r+0.01,w.x+w.r-0.01),randomFloat(w.y-w.r+0.01,w.y+w.r-0.01)

        local d = math.min( w.r-math.abs(x-w.x), w.r-math.abs(y-w.y) )

        state.shots[state.shotsId] = {
            x= x,
            y= y,
            r= math.max( 0.01 , math.min( 0.3 , randomFloat(0.01,d) )),
            bombingTime = os.clock()+1,
            startTime = os.clock()
        }
        state.shotsId = state.shotsId + 1

    end

end
-- bombs warnings logic
gameHandler:addTask(function (state)

    -- launch bombs when bombwarning expires
    for k,warning in pairs(state.bombsWarnings) do
        if ( warning.bombingTime <= os.clock() ) then
            launchAttack(state,warning)
            state.bombsWarnings[k] = nil
        end
    end
    
    -- add warnings 
    local delayBombs = math.max( 3, (1/state.dangerLevel)*5)
    if ( os.clock() - state.bombWarningTime > delayBombs )then
   
        state.bombsWarnings[state.warningId] = {
            x=math.random(),
            y=math.random(),
            r= math.max( 0.05 , math.min( 0.7 , 0.05+math.random()*state.dangerLevel/10 )) ,
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
    isAlive = true,
    dangerLevel = 1,

    ressources = 4,
    maxRessources=100,

    dayNb = 1,
    dayChangeTime = os.clock(),

    bombWarningTime = os.clock(),
    bombsWarnings = {},
    warningId = 1,

    shots = {},
    shotsId = 1,
}