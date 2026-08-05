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

local mon = peripheral.find('monitor')
mon.setTextScale(0.5)

local screen = Renderer:new{
    term=mon,
    combinators={char,square}
}

print("making map")
local map = MapGenerator.makeMap()

print("making pipeline")
sleep()
local pipeline = mapExplorator(gameHandler,screen, map.prettyMap)
    --:after("zoom","maskEdge")

print("yay")

gameHandler:run{}