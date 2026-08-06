import
    :setDownloadDir("/vendor/combox")
    :setDir("https://raw.githubusercontent.com/hexelll/ComBox/refs/heads/dev/")

local Color = import 'Color.lua'
local makeImage = import 'pipelines/GenerateImage.lua'
local pipeline = import 'pipelines/Display.lua'
local ImageHandler = import 'ImageHandler.lua'

local drawLine = import 'pipes/drawLine.lua'

local function zoom(u,v,level,x,y)
    return (u-0.5) / level + 0.5 + x,(v-0.5) / level + 0.5 + y
end

local function invertZoom(u,v,level,x,y)
    return (u-x-0.5)*level+0.5,(v-y-0.5)*level+0.5
end

return function(gameHandler,screen,image)
    local char,square = screen.combinators[1],screen.combinators[2]
    local mon = peripheral.find('monitor')
    mon.setTextScale(0.5)
    sleep()
    local sx,sy = screen:getSize()

    local arrowScale = 8

    local arrow = makeImage:duplicate()
        :process{function(_,u,v)
            u,v = math.abs(u-0.5),math.abs(v-0.5)
            local k = (u*u*u+v*v*v)^(1/3)
            return k < 0.4 and Color(0.7,0.7,0.7) or Color(1,1,1,0)
        end}
        :drawTri{
            points={
                {0.3,0.2},
                {0.8,0.5},
                {0.3,0.8}
            },
            color=Color()
        }
        :start{sx=11,sy=11,screen=screen}
        .image:resize(arrowScale+1,arrowScale+1)
    sleep()
    local plus = makeImage:duplicate()
        :process{function(_,u,v)
            u,v = math.abs(u-0.5),math.abs(v-0.5)
            local k = (u*u*u+v*v*v)^(1/3)
            return k < 0.4 and Color(0.7,0.7,0.7) or Color(1,1,1,0)
        end}
        :image({
            from={0.5-0.1,0.3},
            to={0.5+0.1,0.7},
            color=Color()
        },'quad1')
        :image({
            from={0.3,0.5-0.1},
            to={0.7,0.5+0.1},
            color=Color()
        },'quad2')
        :start{sx=11,sy=11,screen=screen}
        .image:resize(arrowScale+1,arrowScale+1)
    sleep()
    local minus = makeImage:duplicate()
        :process{function(_,u,v)
            u,v = math.abs(u-0.5),math.abs(v-0.5)
            local k = (u*u*u+v*v*v)^(1/3)
            return k < 0.4 and Color(0.7,0.7,0.7) or Color(1,1,1,0)
        end}
        :image({
            from={0.3,0.5-0.1},
            to={0.7,0.5+0.1},
            color=Color()
        },'quad2')
        :start{sx=11,sy=11,screen=screen}
        .image:resize(arrowScale+1,arrowScale+1)

    sleep()

    local p = {x=sx-arrowScale*2,y=sy-arrowScale*3}
    local pRight = {x=p.x+arrowScale,y=p.y}
    local pLeft = {x=p.x-arrowScale,y=p.y}
    local pTop = {x=p.x,y=p.y-arrowScale}
    local pBottom = {x=p.x,y=p.y+arrowScale}
    local pBar = {x=pLeft.x+2-arrowScale,y=p.y+arrowScale*2}
    
    
    --local palette = image:duplicate():resize(sx,sy):findPalette('kmeans',nil,16)
    --palette[16] = Color("#FF0000")
    
    local palette = {Color("#acacbc"), Color("#4b3d27"),
        Color("#4f5457"),Color("#252525"),Color("#3C3C3C"),Color("#505050"),Color("#717171"),Color("#e1e1f4"),
        Color("#094862"),Color("#002c42"),Color("#001729"),
        Color("#8a8e81"),Color("#5f634c"),Color("#444834"),Color('#e74343'),Color('#ffb82b')
    }
    
    sleep()
    local temp = ImageHandler:new(arrowScale+1,arrowScale+1)

    local barLength = arrowScale*4-4
    local barHeight = 4

    local barTemp = ImageHandler:new(barLength,barHeight)

    gameHandler.state.screen = screen
    gameHandler.state.x = 0
    gameHandler.state.y = 0
    gameHandler.state.level = 1
    gameHandler.state.cities = {
        {0.4,0.4,-1}
    }
    gameHandler.state.cityId = 0
    gameHandler.state.lines = {}


    local iconSize = 3


    local function findPointById(state,id)
        for i,p in pairs(state.cities) do
            if p[3] == id then
                return i
            end
        end
        return nil
    end

    pipeline
        :pipe(function(_,input)
            input.image:process(function(_,u,v)
                u,v = zoom(u,v,gameHandler.state.level,gameHandler.state.x,gameHandler.state.y)
                return (image:getPx(u,v) or Color())
            end)
            return input
        end,'zoom')
        :pipe(function(self,input,alias)
            local state = gameHandler.state
            local shots = state.shots
            local dx,dy = 1/(sx-1),1/(sy-1)
            for _,w in pairs(shots) do
                local x,y = invertZoom(w.x,w.y,state.level,state.x,state.y)
                local dt = (w.bombingTime-os.clock())/(w.bombingTime-w.startTime)
                local r = w.r*state.level
                local sr = r*(1-dt)
                if x+r > 0 and x-r < 1 and y+r > 0 and y-r < 1 then
                    input.image:draw{
                        from={x-r,y-r},
                        to={x+r,y+r},
                        color=function(s,_,_,u,v)
                            local du,dv = u-x,v-y
                            local d = du*du+dv*dv
                            if d<=r*r and math.abs(math.sqrt(d)-r) < 1.5*dy then
                                screen.mask:setPx(u,v,square)
                                screen.mask:setPx(u,v+dy,square)
                                screen.mask:setPx(u,v-dy,square)
                                return Color(1)
                            end
                            return (s:getPx(u,v) or Color()):mix(Color(1),d<sr*sr and 0.4 or d<r*r and 0.2 or 0)
                        end
                    }
                end
            end
            local warnings = state.bombsWarnings
            for _,w in pairs(warnings) do
                local x,y = invertZoom(w.x,w.y,state.level,state.x,state.y)
                local r = w.r*state.level
                local X,Y,RX,RY = math.floor(x*sx+0.4999),math.floor(0.4999+y*sy),math.floor(r*sx+0.4999),math.floor(r*sy+0.4999)
                if x+r > 0 and x-r < 1 and y+r > 0 and y-r < 1 then
                    input.image:draw{
                        from={X-RX,Y-RY,'px'},
                        to={X+RX,Y+RY,'px'},
                        color=function(s,U,V,u,v)
                            if math.abs(U) < 1.8*dx  or math.abs(V) < 1.8*dy or math.abs(V-1-dy) < 1.8*dy or math.abs(U-1-dx) < 1.8*dx  then
                                screen.mask:setPx(u,v,square)
                                screen.mask:setPx(u,v+dy,square)
                                screen.mask:setPx(u,v-dy,square)
                                local n = ((math.floor(0.4999+u*sx)+math.floor(0.4999+v*sy))%3)
                                if n == 0 then
                                    return Color(1)
                                end
                            end
                            return (s:getPx(u,v) or Color()):mix(Color(1),0.05)
                        end
                    }
                end
            end
            local lines = state.lines
            for i,l in pairs(state.lines) do
                local p1 = state.cities[findPointById(state,l[1])]
                local p2 = state.cities[findPointById(state,l[2])]
                self:runPipe({
                    drawLine,
                    'line_'..i,
                    {
                        from={invertZoom(p1[1],p1[2],state.level,state.x,state.y)},
                        to={invertZoom(p2[1],p2[2],state.level,state.x,state.y)},
                        color=function(_,_,U,V)
                            screen.mask:setPx(U,V,square)
                            screen.mask:setPx(U,V+dy,square)
                            screen.mask:setPx(U,V-dy,square)
                            return Color()
                        end
                    }
                },input)
            end
            local points = state.cities
            for i,p in pairs(points) do
                local x,y = invertZoom(p[1],p[2],state.level,state.x,state.y)
                local sx,sy = screen:getSize()
                x,y = math.floor(x*(sx-1)+0.4999),math.floor(y*(sy-1)+0.4999)
                local n = math.floor(0.4999+iconSize/2)
                input.image:draw{
                    from={x-n,y-n,'px'},
                    to={x+n,y+n,'px'},
                    image=temp,
                    color=function(self,u,v,U,V)
                        u,v = u-0.5,v-0.5
                        screen.mask:setPx(U,V,square)
                        screen.mask:setPx(U,V+dy,square)
                        screen.mask:setPx(U,V-dy,square)
                        return (p[3] == state.selected and Color(1,1,1) or Color(0.8,0.8)) * (1-math.sqrt(u*u+v*v))
                    end
                }
            end
            return input
        end)
        :image('bar')
        :image('right')
        :image('left')
        :image('top')
        :image('bottom')
        :image('plus')
        :image('minus')

    
    gameHandler
        :addTask(function(state)
            local sx,sy = state.screen:getSize()
            pipeline:start{
                palette=palette,
                screen=screen,
                zoom={
                    level=state.level,
                    x=state.x,--0.5*math.sin(os.clock()),
                    y=state.y--0.5*math.cos(os.clock())
                },
                bar={
                    image=barTemp,
                    from={pBar.x,pBar.y,'px'},
                    to={pBar.x+barLength,pBar.y+barHeight,'px'},
                    color=function(self,u,v,U,V)
                        local dx,dy = 1/(sx-1),1/(sy-1)
                        screen.mask:setPx(U,V,square)
                        screen.mask:setPx(U+dx,V,square)
                        screen.mask:setPx(U-dx,V,square)
                        local k = state.ressources/state.maxRessources
                        if u <= k then
                            return Color(1)
                        else
                            return Color(1,1,1)
                        end
                    end
                },
                right={
                    image=temp,
                    from={pRight.x,pRight.y,'px'},
                    to={pRight.x+arrowScale,pRight.y+arrowScale,'px'},
                    color=function(self,u,v,U,V)
                        local px = arrow:getPx(u,v) or Color()
                        if px[4] > 0.1 then
                            local dx,dy = 1/(sx-1),1/(sy-1)
                            screen.mask:setPx(U,V,square)
                            screen.mask:setPx(U,V+dy,square)
                            screen.mask:setPx(U,V-dy,square)
                        end
                        return px:mix(self:getPx(U,V) or Color(),1-px[4]) or self:getPx(U,V)
                    end
                },
                left={
                    image=temp,
                    from={pLeft.x+1,pLeft.y,'px'},
                    to={pLeft.x+1+arrowScale,pLeft.y+arrowScale,'px'},
                    color=function(self,u,v,U,V)
                        local px = arrow:getPx(1-u,v)
                        if px[4] > 0.1 then
                            local dx,dy = 1/(sx-1),1/(sy-1)
                            screen.mask:setPx(U,V,square)
                            screen.mask:setPx(U,V+dy,square)
                            screen.mask:setPx(U,V-dy,square)
                        end
                        return px and px:mix(self:getPx(U,V) or Color(),1-px[4]) or self:getPx(U,V)
                    end
                },
                top={
                    image=temp,
                    from={pTop.x,pTop.y,'px'},
                    to={pTop.x+arrowScale,pTop.y+arrowScale,'px'},
                    color=function(self,u,v,U,V)
                        local px = arrow:getPx(1-v,1-u)
                        if px[4] > 0.1 then
                            local dx,dy = 1/(sx-1),1/(sy-1)
                            screen.mask:setPx(U,V,square)
                            screen.mask:setPx(U,V+dy,square)
                            screen.mask:setPx(U,V-dy,square)
                        end
                        return px and px:mix(self:getPx(U,V) or Color(),1-px[4]) or self:getPx(U,V)
                    end
                },
                bottom={
                    image=temp,
                    from={pBottom.x,pBottom.y-1,'px'},
                    to={pBottom.x+arrowScale,pBottom.y+arrowScale-1,'px'},
                    color=function(self,u,v,U,V)
                        local px = arrow:getPx(v,1-u)
                        if px[4] > 0.1 then
                            local dx,dy = 1/(sx-1),1/(sy-1)
                            screen.mask:setPx(U,V,square)
                            screen.mask:setPx(U,V+dy,square)
                            screen.mask:setPx(U,V-dy,square)
                        end
                        return px and px:mix(self:getPx(U,V) or Color(),1-px[4]) or self:getPx(U,V)
                    end
                },
                plus={
                    image=temp,
                    from={pLeft.x+1-arrowScale,pTop.y+2,'px'},
                    to={pLeft.x+1,pTop.y+arrowScale+2,'px'},
                    color=function(self,u,v,U,V)
                        local px = plus:getPx(u,v) or Color()
                        if px[4] > 0.1 then
                            local dx,dy = 1/(sx-1),1/(sy-1)
                            screen.mask:setPx(U,V,square)
                            screen.mask:setPx(U,V+dy,square)
                            screen.mask:setPx(U,V-dy,square)
                        end
                        return px:mix(self:getPx(U,V) or Color(),1-px[4]) or self:getPx(U,V)
                    end
                },
                minus={
                    image=temp,
                    from={pLeft.x+1-arrowScale,pTop.y+2*arrowScale-2,'px'},
                    to={pLeft.x+1,pTop.y+3*arrowScale-2,'px'},
                    color=function(self,u,v,U,V)
                        local px = minus:getPx(u,v) or Color()
                        if px[4] > 0.1 then
                            screen.mask:setPx(U,V,square)
                        end
                        return px:mix(self:getPx(U,V) or Color(),1-px[4]) or self:getPx(U,V)
                    end
                },
            }
        end)
        :addButton{
            from={pRight.x,pRight.y,'px'},
            to={pRight.x+arrowScale,pRight.y+arrowScale,'px'},
            onClick=function(state)
                state.x=state.x+0.1/state.level
                return true
            end
        }
        :addButton{
            from={pLeft.x+1,pLeft.y,'px'},
            to={pLeft.x+1+arrowScale,pLeft.y+arrowScale,'px'},
            onClick=function(state)
                state.x=state.x-0.1/state.level
                return true
            end
        }
        :addButton{
            from={pTop.x,pTop.y,'px'},
            to={pTop.x+arrowScale,pTop.y+arrowScale,'px'},
            onClick=function(state)
                state.y=state.y-0.1/state.level
                return true
            end
        }
        :addButton{
            from={pBottom.x,pBottom.y-1,'px'},
            to={pBottom.x+arrowScale,pBottom.y+arrowScale-1,'px'},
            onClick=function(state)
                state.y=state.y+0.1/state.level
                return true
            end
        }
        :addButton{
            from={pLeft.x+1-arrowScale,pTop.y+2,'px'},
            to={pLeft.x+1,pTop.y+arrowScale+2,'px'},
            onClick=function(state)
                state.level=state.level*1.1
                return true
            end
        }
        :addButton{
            from={pLeft.x+1-arrowScale,pTop.y+2*arrowScale-2,'px'},
            to={pLeft.x+1,pTop.y+3*arrowScale-2,'px'},
            onClick=function(state)
                state.level=state.level*0.9
                return true
            end
        }

    local function findPoint(state,x,y)
        for i,p in pairs(state.cities) do
            local u,v = x-p[1],y-p[2]
            local d = u*u+v*v
            if math.sqrt(d) <= iconSize/sx then
                return i
            end
        end
        return nil
    end

    local function findLine(state,i,j)
        for k,l in pairs(state.lines) do
            if l[1] == i and l[2] == j or l[1] == j and l[2] == i then
                return k
            end
        end
        return nil
    end

    local cityPrice = 4

    gameHandler:on('click',function(state,x,y)
        local u,v = zoom(x/(screen.sx-1),y/(screen.sy-1),state.level,state.x,state.y)
        local i = findPoint(state,u,v)
        local si = findPointById(state,state.selected)
        if not i and si then
            if state.biomeMap:getPx(u,v) then
                local ps = state.cities[si]
                local dx,dy = ps[1]-u,ps[2]-v
                local cost = (dx*dx+dy*dy)/10+cityPrice
                if state.ressources - cost >= 0 then
                    state.cities[#state.cities+1] = {u,v,state.cityId}
                    state.lines[#state.lines+1] = {state.selected,state.cityId}
                    state.ressources = state.ressources - cost
                    state.selected = state.cityId
                    state.cityId = state.cityId+1
                end
            end
        elseif i then
            local p = state.cities[i]
            if state.selected == p[3] then
                state.selected = nil
            else
                if si then
                    local l = findLine(state,state.selected,p[3])
                    if not l then
                        local ps = state.cities[si]
                        local dx,dy = ps[1]-u,ps[2]-v
                        local cost = (dx*dx+dy*dy)/10+cityPrice
                        if state.ressources - cost >= 0 then
                            state.lines[#state.lines+1] = {state.selected,state.cities[i][3]}
                            state.ressources = state.ressources - cost
                        end
                    end
                end
                state.selected = p[3]
            end
        end
    end)

    return pipeline
end

-- gameHandler:run{
--     x=0,
--     y=0,
--     level=1,
--     screen=screen,
-- }