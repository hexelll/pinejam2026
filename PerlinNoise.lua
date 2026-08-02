local PerlinNoise = {}

function PerlinNoise:buildGrid(sx,sy)
    self.sx = sx
    self.sy = sy
    
    self.randomGrid = {}
    for x=0,sx do
        self.randomGrid[x]={}
        for y=0,sy do
            self.randomGrid[x][y]=math.random()
        end
    end
end

function PerlinNoise:getValueXY(x,y)
    local x1,x2 = math.floor(x), math.ceil(x)
    local y1,y2 = math.floor(y), math.ceil(y)

    local r = PerlinNoise.randomGrid

    local a,b,c,d = r[x1][y1],r[x2][y1],r[x1][y2],r[x2][y2]

    return (a+b+c+d)/4
end


function PerlinNoise:getValueUV(u,v)
    local x,y = self.sx*u, self.sy*v
    return PerlinNoise:getValueXY(x,y)
end


return PerlinNoise