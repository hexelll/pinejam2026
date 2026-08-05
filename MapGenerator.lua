
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
    return Color(color1):mix(Color(color2),1-val)
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
    -- center weighted noise
    local noisyP1 = NoiseMaker:newRandChoiceNoise(40,40, {
        func = function(u,v)
            return math.random()
        end
    })
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


    local waves = NoiseMaker:newPerlin(20,90)
    
    local worley = NoiseMaker:newWorleyNoise(5,5)



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

            local centerDist = (1-math.pow((math.sqrt((u-0.5)^2+(v-0.5)^2)), 1 )+0.25)

            local height = math.pow(centerDist,6) * clamp( (val1*0.6 + val2*0.3 + val3*0.1)*2.5) 

            local effect = clamp(1-val1)

            -- treesholds
            local oceanT = 0.1
            local coastT = (oceanT+0.01)
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
            elseif height < beachT then
                biome = "beach"
            elseif height < landT then
                biome = "land"
            else
                biome = "rock"
            end

            biomeMap:setPx(u,v,placable)

            -- color biomes
            if biome == "ocean" then
                local h = 1-height/oceanT
                local col = mapToGradient(h,"#001121","#095674")

                --col = col * (to01(waves:getValUV(u,v))*0.9 +0.4)
                return col
            elseif biome == "coast" then
                return Color("#508095")
            elseif biome == "beach" then
                --local h = (height - oceanT )*1
                local col = Color("#4f5457")

                col = col * (math.random()*0.1+0.45 )

                return col
            elseif biome == "land" then
                local color = mapToGradient(height,"#acb192","#232616")
                return color
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