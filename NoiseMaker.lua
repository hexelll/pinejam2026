local NoiseMaker = {}

--[[
    >>> UTILS
]]

-- random number with normal distribution
function NoiseMaker:normalDistrib()
    local u1,u2 = math.random(),math.random()

    local R = math.sqrt(-2*math.log(u1))
    local teta = 2*math.pi*u2

    return R*math.cos(teta)
end

-- Fonction lisse de l'intervalle [0.0, 1.0] vers lui-même
function NoiseMaker:smoothstep(w)
    if (w <= 0.0) then
        return 0.0
    end
    if (w >= 1.0) then
        return 1.0
    end
    return w*w*w*(w*(w*6-15)+10)
end

-- Fonction d'interpolation lisse entre a0 et a1
-- Le poids w doit être dans l'intervalle [0.0, 1.0]
function NoiseMaker:interpolate(a0,a1,w)
    return a0 + (a1 - a0) * self:smoothstep(w)
end

-- Fonction de calcul du produit scalaire entre le vecteur de distance et le vecteur de gradient.
function NoiseMaker:dotGridGradient(ix,iy,x,y,randomGrid)
    -- Vecteurs de gradient aux intersections de la grille (pré-calculés ou non)
    -- self.randomGrid

    -- Calcul du vecteur de distance
    local dx = x - ix
    local dy = y - iy

    -- Calcul du produit scalaire
    return (dx*randomGrid[ix+1][iy+1][1] + dy*randomGrid[ix+1][iy+1][2])
end



--[[
    >>> NOISE MAKERS
]]

-- Perlin noise
function NoiseMaker:newPerlin(sx,sy,params)
    params = params and params or {}
    
    -- func to build grid vector
    local func = params.func and params.func or function(u,v)
        local angle = math.random() * 2 * math.pi
        return {
            math.cos(angle),
            math.sin(angle)
        }
    end

    -- object
    local obj = {
        sx = sx,
        sy = sy,
        randomGrid = {},
        -- Calcul du bruit de Perlin au point de coordonnées (x, y)
        getValXY = function(self,x,y)
                -- Coordonnées de la case de la grille dans laquelle se trouve le point
                local x0 = math.floor(x)
                local x1 = x0 + 1
                local y0 = math.floor(y)
                local y1 = y0 + 1

                -- Poids pour l'interpolation
                -- (On pourrait utiliser des polynômes d'ordre supérieur ou d'autres fonctions lisses)
                local sx = x - x0
                local sy = y - y0

                -- Interpolation entre les coins de la case
                local n0, n1, ix0, ix1, value
                n0 = NoiseMaker:dotGridGradient(x0, y0, x, y, self.randomGrid)
                n1 = NoiseMaker:dotGridGradient(x1, y0, x, y, self.randomGrid)
                ix0 = NoiseMaker:interpolate(n0, n1, sx)
                n0 = NoiseMaker:dotGridGradient(x0, y1, x, y, self.randomGrid)
                n1 = NoiseMaker:dotGridGradient(x1, y1, x, y, self.randomGrid)
                ix1 = NoiseMaker:interpolate(n0, n1, sx)
                value = NoiseMaker:interpolate(ix0, ix1, sy)

                return value
            end,

        getValUV = function(self,u,v) 
                local x,y = self.sx*u,self.sy*v
                return self:getValXY(x,y)
            end
    }

    -- build Perlin random vector grid
    obj.randomGrid = {}
    for x=1,sx+2 do
        obj.randomGrid[x]={}
        for y=1,sy+2 do
            obj.randomGrid[x][y]=func(x/(sx+2),y/(sy+2))
        end
    end

    return obj
end

-- Random choice noise
function NoiseMaker:newRandChoiceNoise(sx,sy,params)
    params = params and params or {}
    
    -- func to build grid vector
    local func = params.func and params.func or function(u,v)
        return math.random()
    end

    -- object
    local o = {
        sx = sx,
        sy = sy,
        randomGrid = {},
       
        getValXY = function(self,x,y)
                
                local x0 = math.floor(x)
                local x1 = x0 + 1
                local y0 = math.floor(y)
                local y1 = y0 + 1

                local decimalX = x - math.floor(x)
                local decimalY = y - math.floor(y)

                local ix = math.random() > decimalX and x0 or x1
                local iy = math.random() > decimalY and y0 or y1

                return self.randomGrid[ix+1][iy+1]
            end,

        getValUV = function(self,u,v) 
                local x,y = self.sx*u,self.sy*v
                return self:getValXY(x,y)
            end
    }

    -- build random values grid
    o.randomGrid = {}
    for x=1,sx+2 do
        o.randomGrid[x]={}
        for y=1,sy+2 do
            o.randomGrid[x][y]=func(x/(sx+2),y/(sy+2))
        end
    end

    return o
end

-- Worley noise
function NoiseMaker:newWorleyNoise(sx,sy,params)
    params = params and params or {}
    
    -- func to build grid vector
    local func = params.func and params.func or function(u,v)
        return {math.random(),math.random()}
    end

    -- object
    local o = {
        sx = sx,
        sy = sy,
        randomGrid = {},
        getValXY = function(self,x,y)

                local x0 = math.floor(x)
                local y0 = math.floor(y)

                local decimalX = x - math.floor(x)
                local decimalY = y - math.floor(y)
                
                local minDist = math.huge
                local minDist2 = math.huge

                for dx=-1,1 do
                    for dy=-1,1 do
                        local point = self.randomGrid[x0+dx][y0+dy]
                        
                        local dist = math.sqrt( (x0+dx+point[1]-x)^2 + (y0+dy+point[2]-y)^2 )
                        
                        if dist < minDist then
                            minDist2 = minDist
                            minDist = dist
                        elseif dist < minDist2 then
                            minDist2 = dist
                        end
                    end
                end

                return minDist/minDist2
            end,

        getValUV = function(self,u,v) 
                local x,y = self.sx*u,self.sy*v
                return self:getValXY(x,y)
            end
    }

    -- build Worley random points grid
    o.randomGrid = {}
    for x=-1,sx+4 do
        o.randomGrid[x]={}
        for y=-1,sy+4 do
            o.randomGrid[x][y]=func((x+1)/(sx+4),(y+1)/(sy+4))
        end
    end

    return o
end


return NoiseMaker