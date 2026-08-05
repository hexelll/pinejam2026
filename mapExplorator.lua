import
    :setDownloadDir("/vendor/combox")
    :setDir("https://raw.githubusercontent.com/hexelll/ComBox/refs/heads/dev/")

local Color = import 'Color.lua'
local makeImage = import 'pipelines/GenerateImage.lua'
local pipeline = import 'pipelines/Display.lua'
local ImageHandler = import 'ImageHandler.lua'

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

    local arrowScale = 7

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
        :start{sx=21,sy=21,screen=screen}
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
        :start{sx=21,sy=21,screen=screen}
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
        :start{sx=21,sy=21,screen=screen}
        .image:resize(arrowScale+1,arrowScale+1)

    sleep()

    local p = {x=arrowScale*2,y=arrowScale*1.5}
    local pRight = {x=p.x+arrowScale,y=p.y}
    local pLeft = {x=p.x-arrowScale,y=p.y}
    local pTop = {x=p.x,y=p.y-arrowScale}
    local pBottom = {x=p.x,y=p.y+arrowScale}
    
    
    --local palette = image:duplicate():resize(sx,sy):findPalette('kmeans',nil,16)
    --palette[16] = Color("#FF0000")
    
    local palette = {Color("#acacbc"),
        Color("#4f5457"),Color("#252525"),Color("#505050"),Color("#717171"),Color("#e1e1f4"),
        Color("#094862"),Color("#002c42"),Color("#001729"),
        Color("#8a8e81"),Color("#5f634c"),Color("#444834")
    }
    
    sleep()
    local temp = ImageHandler:new(arrowScale+1,arrowScale+1)


    gameHandler.state.screen = screen
    gameHandler.state.x = 0
    gameHandler.state.y = 0
    gameHandler.state.level = 1

    pipeline
        :pipe(function(_,input)
            input.image:process(function(_,u,v)
                u,v = zoom(u,v,gameHandler.state.level,gameHandler.state.x,gameHandler.state.y)
                return (image:getPx(u,v) or Color())
            end)
            return input
        end)
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
                right={
                    image=temp,
                    from={pRight.x,pRight.y,'px'},
                    to={pRight.x+arrowScale,pRight.y+arrowScale,'px'},
                    color=function(self,u,v,U,V)
                        local px = arrow:getPx(u,v) or Color()
                        if px[4] > 0.1 then
                            screen.mask:setPx(U,V,square)
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
                            screen.mask:setPx(U,V,square)
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
                            screen.mask:setPx(U,V,square)
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
                            screen.mask:setPx(U,V,square)
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
                            screen.mask:setPx(U,V,square)
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

    return pipeline
end

-- gameHandler:run{
--     x=0,
--     y=0,
--     level=1,
--     screen=screen,
-- }