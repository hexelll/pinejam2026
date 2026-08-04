local gameHandler = {
    tasks = {},
    state = {},
    events = {}
}

function gameHandler:addTask(fn)
    self.tasks[#self.tasks+1] = function()
        while true do
            fn(self.state)
            sleep()
        end
    end
    return self
end

function gameHandler:on(event,fn)
    if event == 'click' then
        self.events.mouse_click = self.events.mouse_click or {}
        local mc = self.events.mouse_click
        mc[#mc+1] = function(state,_,x,y)
            return fn(state,x,y)
        end
        self.events.monitor_touch = self.events.monitor_touch or {}
        local mt = self.events.monitor_touch
        mt[#mt+1] = function(state,_,x,y)
            return fn(state,x,y)
        end
    else
        self.events[event] = self.events[event] or {}
        local events = self.events[event]
        events[#events+1] = fn
    end
    return self
end

function gameHandler:addButton(args)
    args = args or {}
    local screen = self.state.screen
    local onClick = args.onClick or error 'missing onClick function'
    local function eval(x,...)
        return type(x) == 'function' and x(...) or x
    end
    local function evalVec(u,...)
        local v = {}
        v[1] = u[1] and eval(u[1],...) or 0
        v[2] = u[2] and eval(u[2],...) or 0
        if u[3] == 'px' then
            v[1] = (v[1]-1)/(screen.sx-1)
            v[2] = (v[2]-1)/(screen.sy-1)
        end
        return v
    end
    local from = evalVec(args.from and eval(args.from,screen) or {0,0})
    local to = evalVec(args.to and eval(args.to,screen,from) or {1,1})
    local sx = (to[1]-from[1])*(screen.sx)
    local sy = (to[2]-from[2])*(screen.sy)
    local x = from[1]*screen.sx
    local y = from[2]*screen.sy
    self:on('click',function(state,mx,my)
        local screenx,screeny = screen:getSize()
        mx = (mx-1)*(screenx-1)/(screen.sx-1) + 1
        my = (my-1)*(screeny-1)/(screen.sy-1) + 1
        if mx >= x and mx <= x + sx and my >= y and my <= y + sy then
            return onClick(state,mx,my,x,y)
        end
    end)
    return self
end

function gameHandler:run(state)
    self.tasks[#self.tasks+1] = function()
        while true do
            local eventData = {os.pullEvent()}
            local event = eventData[1]
            table.remove(eventData,1)
            if self.events[event] then 
                for _,fn in pairs(self.events[event]) do
                    if fn(self.state,table.unpack(eventData)) then
                        break
                    end
                end
            end
        end
    end
    for k,v in pairs(state) do
        self.state[k] = v
    end
    parallel.waitForAny(table.unpack(self.tasks))
    return self
end

return gameHandler