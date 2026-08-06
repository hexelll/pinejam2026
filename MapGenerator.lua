
local import = require "import"

local NoiseMaker = import "NoiseMaker.lua"

import
    :setDownloadDir("/vendor/combox")
    :setDir("https://raw.githubusercontent.com/hexelll/ComBox/refs/heads/dev/")
local Color = import "Color.lua"
local ImageHandler = import "ImageHandler.lua"

local MakeImage = import "pipelines/GenerateImage.lua"


--[[
    UTILS
]]
local function clamp(val)
    return math.min(math.max(0,val),1)
end

local function mapToGradient(val,color1,color2)
    if (type(color1) == "string")then
        color1 = Color(color1)
    end
    if (type(color2) == "string")then
        color2 = Color(color2)
    end
    return color1:mix(color2,1-val)
end


--[[
    FUNC 
]]
local function to01(val)
    return clamp((val+0.2)/2*1.414  )
end


--[[
    MAIN
]]
return {
    makeMap = function()

    --[[
        SETUP
    ]]
    -- continent noises
    local p1 = NoiseMaker:newPerlin(10,10,{
        func = function(u,v)
            local v1 = NoiseMaker:normalDistrib()
            local v2 = NoiseMaker:normalDistrib()
            local norm = math.sqrt(v1^2+v2^2)
            return {
                v1/norm,
                v2/norm
            }
        end
    })
    local p2 = NoiseMaker:newPerlin(18,18)
    local p3 = NoiseMaker:newPerlin(30,30)
    local p4 = NoiseMaker:newPerlin(70,70)

    local pdetail1 = NoiseMaker:newPerlin(10,10)
    local pdetail2 = NoiseMaker:newPerlin(40,40)

    -- center weighted noise
    local noisyP3 = NoiseMaker:newRandChoiceNoise(80,80, {
        func = function(u,v)
            return p3:getValUV(u,v)
        end
    })

    local worley1 = NoiseMaker:newWorleyNoise(10,10)
    local worley2 = NoiseMaker:newWorleyNoise(40,40)


    local du,dv = math.random()*0.2-0.1,math.random()*0.2-0.1

    --[[
        PROCESS
    ]]
    local prettyMap = ImageHandler:new(400,400)
    local biomeMap = ImageHandler:new(400,400)

    MakeImage
        :process{function (self,u,v)
            
            -- make noise map
            local val1 = to01(p1:getValUV(u,v))
            local val2 = to01(p2:getValUV(u,v))
            local val3 = to01(p3:getValUV(u,v))
            local val4 = to01(p4:getValUV(u,v))

            local centerDist = (1- math.sqrt( ((u+du-0.5)^2) + ((v+dv-0.5)^2) ) +0.25)

            local height = math.pow(centerDist,6) * math.max( centerDist*0.05, clamp( (val1*0.6 + val2*0.25 + val3*0.08 + val4*0.03)*2.5) )

            local detail1 = to01(pdetail1:getValUV(u,v))
            local detail2 = to01(pdetail2:getValUV(u,v))

            -- treesholds
            local oceanT = 0.1
            local coastT = (oceanT+ 0.03*math.max(0,(val2*3)) )
            local beachT = (oceanT+0.1)*centerDist*1.1
            local landT = 0.9
            
            -- build biomes
            local biome = "rock"
            local placable = true
            if height < oceanT then
                biome = "ocean"
                placable = false
            elseif ((height < coastT) and (centerDist < 0.9)) then
                biome = "coast"
                placable = false
            elseif height > beachT and height < landT then
                biome = "land"
            elseif height < beachT then
                biome = "beach"
            else
                biome = "rock"
            end

            biomeMap:setPx(u,v,placable)

            -- color biomes
            if biome == "ocean" then
                local h = 0.7*(1-height/oceanT) + 0.3*(1-(worley2:getValUV(u,v)^4))
                local col = mapToGradient(h,"#001121","#095674")
                
                --local noise = 
                --if noise > 0.6 then
                --    return col:mix(Color("#095674"), (noise-0.6)*1.8 )
                --end
                
                return col
            elseif biome == "coast" then
                local col 
                if math.random() < 0.3 then
                    col = Color("#508095")
                    col = col * ( ( math.random() )*0.07 +1 )
                    
                else
                    local h = 0.7*(1-height/oceanT) + 0.3*(1-(worley2:getValUV(u,v)^4))
                    col = mapToGradient(h,"#001121","#095674")
                end
                return col
            elseif biome == "beach" then
                --local h = (height - oceanT )*1
                local col = Color("#2C2C2C")

                col = col * ( (noisyP3:getValUV(u,v)*0.8 + math.random()*0.2  )*0.4 +0.85 )

                return col
            elseif biome == "land" then
                local h = 0.7*(height/landT) + 0.3*noisyP3:getValUV(u,v)
                local col = mapToGradient(1-h,"#232616","#acb192")
                
                col = mapToGradient( 1-math.max(0,val2-0.4) , col, "#FFFFFF" )
                col = mapToGradient( 1-math.max(0,detail1-0.2) , col, "#4b3d27" )

                --col = col * ( (noisyP3:getValUV(u,v)*0.8 + math.random()*0.2  )*0.1 +0.95 )
                return col
            else
                return Color(height*0.5,height*0.5,height*0.5)
            end
            
            return Color(height*0.5,height*0.5,height*0.5)
        end}


    -- generate image
    local result = MakeImage:start{
                        image = prettyMap,
                        term=term
                    }

    return {prettyMap=result.image,biomeMap=biomeMap}
end}