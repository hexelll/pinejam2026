local import = (function() local function a(b)local c=b:find("https")local d=b:find("http")local e=c and c==1 and"https"or d and d==1 and"http"or""if#e==0 then return b end;local f=b:sub(#"https://"+1,#b):find("/")return{b:sub(1,f-1),b:sub(f,#b)}end;local function g(b)return b:sub(#b,#b)~='/'and fs.getDir(b)or b end;local function h(i,b,j)b=a(b)if type(b)=="table"then return b[1]..b[2],true,j and fs.combine(j,b[2])end;i=a(i)if type(i)=="table"then return i[1]..fs.combine(g(i[2]),b),true,j and fs.combine(j,b)end;return fs.combine(g(i),b),false end;local function k(b,l,m)if l then if m then local n=fs.open(m,"r")if n then local o=n.readAll()n.close()return o end end;local p=http.get(b)if not p then error("no such file at remote "..b)end;local o=p.readAll()p.close()if m then local n=fs.open(m,"w")n.write(o)n.close()end;return o end;local n=fs.open(b,"r")if not n then error("no such file at "..b)end;local o=n.readAll()n.close()return o end;local function q(i)i=i:sub(#i,#i)~='/'and i..'/'or i;i=i:sub(1,1)~='/'and'/'..i or i;return i end;local r={}function r:new(s)s=s or{}local t={}t.cache=s.cache or{}t.dir=s.dir or q('/'..fs.getDir(shell.getRunningProgram()))t.baseDir=t.dir;t.downloadDir=s.downloadDir and q(s.downloadDir)setmetatable(t,{__call=function(u,...)return t:import(...)end,__index=function(u,v)return self[v]end})return t end;function r:setDir(i)if i:find("http")~=nil then self.dir=i;return self end;self.dir=i:sub(1,1)=='/'and i or fs.combine(self.dir,i)self.dir=q(self.dir)return self end;function r:resetDir()self:setDir(self.baseDir)end;function r:setDownloadDir(i)self.downloadDir=i:sub(1,1)=='/'and i or fs.combine(self.dir,i)self.downloadDir=q(self.downloadDir)return self end;function r:resetCache(w)self.cache={}return self end;function r:import(b,i,w,j)w=w or self.cache;i=b:sub(1,1)=='/'and'/'or i and i or self.dir;j=j or self.downloadDir;local x,l,m=h(i,b,j)local y=w[x]if y then return y end;local o=k(x,l,m)local z=setmetatable({import=r:new{dir=x,downloadDir=m and g(m),cache=w}},{__index=_ENV})local A,B=load(o,"@/"..x,nil,z)if B then error(B)end;w[x]=A()return w[x]end;return r:new() end)() 

print('Game files load... ')
import
    :setDownloadDir('/vendor/game')
    :setDir('https://raw.githubusercontent.com/hexelll/pinejam2026/refs/heads/main/')

local gameHandler = import 'gameHandler.lua'
local mapExplorator = import 'mapExplorator.lua'
local NoiseMaker = import "NoiseMaker.lua"
local MapGenerator = import "MapGenerator.lua"
print('finished')

write('ComBox files load... ')
import
    :setDownloadDir("/vendor/combox")
    :setDir("https://raw.githubusercontent.com/hexelll/ComBox/refs/heads/pinejame2026/")

local Renderer = import 'Renderer.lua'
local ImageHandler = import 'ImageHandler.lua'
local Color = import 'Color.lua'
local MakeImage = import "pipelines/GenerateImage.lua"
local char = import('combinators/MathCharCombinator.lua'):new({
    usedChars = {0,1,2,4,5,6,8,11,12,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255}
})
local square = import('combinators/SquarePixelCombinator.lua'):new()
print('finished')

--[[
    INIT MAP
]]
write("Building the map... ")
local map = MapGenerator.makeMap()
print("map ready")


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
print("display ready")



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
        local x,y = shot.x,shot.y
        local du,dv = p[1]-x,p[2]-y
        local d = du*du+dv*dv
        if d <= shot.r*shot.r then
            state.ressources = math.max(0,state.ressources*0.9)
            removePoint(state,p[3])
        end
    end
end
-- shots explosions logic
gameHandler:addTask(function (state)
    local shots = {}
    -- explode when shot expires
    for k,shot in pairs(state.shots) do
        if ( shot.bombingTime <= os.clock() ) then
            kaboom(state,shot)
        else
            shots[k] = shot
        end
    end

    state.shots = shots

end)



local function randomFloat(min,max)
    return math.random()*(max-min)+min
end

-- create shots in bombs warning
local function launchAttack(state,w)
    
    local nbShots = state.dangerLevel*2--1--math.floor(state.dangerLevel+0.5)
    for i=1,nbShots do 
        local x,y = randomFloat(w.x-w.r+0.01,w.x+w.r-0.01),randomFloat(w.y-w.r+0.01,w.y+w.r-0.01)
        local d = math.min( w.r-math.abs(x-w.x), w.r-math.abs(y-w.y) )
        state.shots[state.shotsId] = {
            x= x,
            y= y,
            r= math.max( 0.01 , math.min( 0.4 , randomFloat(0.01,d) )),
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
            r= math.max( 0.05 , math.min( 0.25 , 0.05+math.random()*state.dangerLevel/10 )) ,
            bombingTime = os.clock()+10,
            startTime = os.clock()
        }
        state.warningId = state.warningId + 1

        state.bombWarningTime = os.clock()
    end

end)



-- days logic
gameHandler:addTask(function (state)
    if ( os.clock() - state.dayChangeTime > 5 )then -- time between days

        if (state.isAlive) then
            state.maxRessources = #state.cities+10
            state.ressources = math.min(state.maxRessources,state.ressources + #state.lines/2 + 1)
            --print("You have ".. state.ressources .." ressources")
        end

        state.dangerLevel = state.dangerLevel*1.05
        state.dayNb = state.dayNb + 1
        state.dayChangeTime = os.clock()
    end
end)


-- end logic
gameHandler:addTask(function (state)
    if state.cities and #state.cities <= 0 then
        state.isAlive = false
        print("\nGAME OVER !\n")
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
    maxRessources = 0,
    dayNb = 1,
    dayChangeTime = os.clock()-5,

    bombWarningTime = os.clock(),
    bombsWarnings = {},
    warningId = 1,

    shots = {},
    shotsId = 1,
}