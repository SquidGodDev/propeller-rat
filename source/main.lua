-- Core
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- Globals
import "scripts/globals"

-- Libraries
import "scripts/libraries/Utilities"

import "scripts/player/player"
import "scripts/hazards/spinner"
import "scripts/hazards/block"

local pd <const> = playdate
local gfx <const> = pd.graphics

pd.display.setRefreshRate(50)

local levelImage = gfx.image.new("images/testLevel")
local levelSprite = gfx.sprite.new(levelImage)
levelSprite:add()
levelSprite:setCenter(0, 0)
levelSprite:moveTo(0, 0)

local startX, startY = 33, 37
Player(startX, startY, levelImage)

Block(151, 39, 8, 8, 0, -1, levelImage)
Block(151, 20, 8, 8, 0, 1, levelImage)

Block(87, 100, 16, 16, -2, 0, levelImage)
Block(87, 132, 16, 16, 2, 0, levelImage)
Block(87, 164, 16, 16, -2, 0, levelImage)
Block(87, 196, 16, 16, 2, 0, levelImage)
Block(87, 196+32, 16, 16, -2, 0, levelImage)
Block(87, 196+64, 16, 16, 2, 0, levelImage)
-- Spinner(122, 85)
-- Spinner(122+96, 85)
-- Spinner(122+96*2, 85)
-- Spinner(122+96*3, 85)

-- Spinner(122, 85+96)
-- Spinner(122+96, 85+96)
-- Spinner(122+96*2, 85+96)
-- Spinner(122+96*3, 85+96)

-- Spinner(122, 85+96*2)
-- Spinner(122+96, 85+96*2)
-- Spinner(122+96*2, 85+96*2)
-- Spinner(122+96*3, 85+96*2)

function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()

    pd.drawFPS(0, 228)
end
