local import = require 'import'

local gameHandler = import 'gameHandler.lua'
local mapExplorator = import 'mapExplorator.lua'

import
    :setDownloadDir("/vendor/combox")
    :setDir("https://raw.githubusercontent.com/hexelll/ComBox/refs/heads/dev/")

local Renderer = import 'Renderer.lua'
local ImageHandler = import 'ImageHandler.lua'
local Color = import 'Color.lua'
local char,square = import('combinators/FastCharCombinator.lua'):new(),import('combinators/SquarePixelCombinator.lua'):new()

local mon = peripheral.find('monitor')
mon.setTextScale(0.5)

local screen = Renderer:new{
    term=mon,
    combinators={char,square}
}

local pipeline = mapExplorator(gameHandler,screen,ImageHandler:new(screen:getSize()):process(function(_,u,v)
    return Color(u,v)
end))

local function zoom(u,v,level,x,y)
    return (u-0.5) / level + 0.5 + x,(v-0.5) / level + 0.5 + y
end

local function invertZoom(u,v,level,x,y)
    return (u-x-0.5)*level+0.5,(v-y-0.5)*level+0.5
end

local state = gameHandler.state

pipeline:after('zoom',function(self,input,alias)
    local args = input[alias]
    local last
    local drawLine = import 'pipes/drawLine.lua'
    for i,p in pairs(state.points) do
        local u,v = invertZoom(p[1],p[2],state.level,state.x,state.y)
        if last then
            self:runPipe(
                {
                    drawLine,
                    'points'..i,
                    {
                        from=last,
                        to={u,v},
                        color=function(_,_,u,v)
                            screen.mask:setPx(u,v,square)
                            screen.mask:setPx(u,v+1/(screen.mask.sy-1),square)
                            screen.mask:setPx(u,v-1/(screen.mask.sy-1),square)
                            return Color(1)
                        end
                    }
                },
                input
            )
        end
        last = {u,v}
    end
end)

gameHandler
    :on('click',function(state,x,y)
        local u,v = (x-1)/(state.screen.sx-1),(y-1)/(state.screen.sy-1)
        state.points[#state.points+1] = {zoom(u,v,state.level,state.x,state.y)}
    end)

gameHandler:run{
    points={}
}