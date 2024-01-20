
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local pd <const> = playdate
local gfx <const> = playdate.graphics

pd.display.setRefreshRate(50)

local getCurTimeMil = pd.getCurrentTimeMilliseconds
local previous_time = nil

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end

local smoothSpeed <const> = 0.06

local levelImage = gfx.image.new("images/testLevel")
local levelSprite = gfx.sprite.new(levelImage)
levelSprite:add()
levelSprite:setCenter(0, 0)
levelSprite:moveTo(0, 0)

local playerSpeed = 60
local playerDiameter = 8
local playerImage = gfx.image.new(playerDiameter, playerDiameter)
gfx.pushContext(playerImage)
    gfx.fillCircleInRect(0, 0, playerDiameter, playerDiameter)
gfx.popContext()
local playerSprite = gfx.sprite.new(playerImage)
local playerTailSprites = {}
local maxTailLength = 40
local tailImage = gfx.image.new(playerDiameter, playerDiameter)
gfx.pushContext(tailImage)
    gfx.drawCircleInRect(0, 0, playerDiameter, playerDiameter)
gfx.popContext()
for i=1, maxTailLength do
    playerTailSprites[i] = gfx.sprite.new(playerImage)
    playerTailSprites[i]:add()
end

local function resetTail(x, y)
    for i=1,maxTailLength do
        playerTailSprites[i]:moveTo(x, y)
    end
end

local startX, startY = 33, 37
gfx.setDrawOffset(startX, startY)
playerSprite:moveTo(startX, startY)
playerSprite:add()
resetTail(startX, startY)

function pd.update()
    local dt = 1 / pd.display.getRefreshRate()
    local current_time <const> = getCurTimeMil()
    if previous_time ~= nil then
        dt = (current_time - previous_time) / 1000.0
    end
    previous_time = current_time

    local tailSprite = table.remove(playerTailSprites, 1)
    tailSprite:moveTo(playerSprite.x, playerSprite.y)
    table.insert(playerTailSprites, tailSprite)

    local crankPosition = math.rad(pd.getCrankPosition() - 90)
    playerSprite:moveBy(playerSpeed * math.cos(crankPosition) * dt, playerSpeed * math.sin(crankPosition) * dt)

    if levelImage:sample(playerSprite.x, playerSprite.y) == gfx.kColorBlack then
        playerSprite:moveTo(startX, startY)
        resetTail(startX, startY)
    end

    local drawOffsetX, drawOffsetY = gfx.getDrawOffset()
    local targetOffsetX, targetOffsetY = -(playerSprite.x - 200), -(playerSprite.y - 120)
    local smoothedX = lerp(drawOffsetX, targetOffsetX, smoothSpeed)
    local smoothedY = lerp(drawOffsetY, targetOffsetY, smoothSpeed)
    gfx.setDrawOffset(smoothedX, smoothedY)

    gfx.sprite.update()
    pd.timer.updateTimers()
end
