local pd <const> = playdate
local gfx <const> = pd.graphics

local rad <const> = math.rad
local cos <const> = math.cos
local sin <const> = math.sin

local getCrankPosition <const> = pd.getCrankPosition
local getDrawOffset <const> = gfx.getDrawOffset
local setDrawOffset <const> = gfx.setDrawOffset

local sample = gfx.image.sample
local kColorClear <const> = gfx.kColorClear

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end

local smoothSpeed <const> = 0.06
local unfreezeSensitivity = 0.1
local resetTime = 500 -- ms

local playerSpeed = 1.4
local playerDiameter = 12
local playerRadius = playerDiameter / 2
local playerImage = gfx.image.new(playerDiameter, playerDiameter)
gfx.pushContext(playerImage)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleInRect(0, 0, playerDiameter, playerDiameter)
gfx.popContext()

class('Player').extends(gfx.sprite)

function Player:init(gameScene, x, y, levelImage)
    self.gameScene = gameScene

    self.startX = x
    self.startY = y
    self.levelImage = levelImage
    setDrawOffset(x, y)
    self:setImage(playerImage)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.player)
    self:setGroups(TAGS.player)
    self:setCollidesWithGroups({TAGS.hazard, TAGS.pickup})
    self:setCollideRect(0, 0, playerImage:getSize())

    self.disabled = false
    self.frozen = true
    self.resetTimer = nil
end

function Player:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
end

function Player:update()
    if self.disabled then
        return
    end

    local drawOffsetX, drawOffsetY = getDrawOffset()
    local targetOffsetX, targetOffsetY = -(self.x - 200), -(self.y - 120)
    local smoothedX = lerp(drawOffsetX, targetOffsetX, smoothSpeed)
    local smoothedY = lerp(drawOffsetY, targetOffsetY, smoothSpeed)
    setDrawOffset(smoothedX, smoothedY)

    if self.resetTimer then
        return
    end

    if self.frozen then
        local _, acceleratedChange = pd.getCrankChange()
        if math.abs(acceleratedChange) >= unfreezeSensitivity then
            self.frozen = false
        else
            return
        end
    end

    local levelImage = self.levelImage
    local x, y = self.x, self.y
    if sample(levelImage, x + playerRadius, y + playerRadius) ~= kColorClear
    or sample(levelImage, x + playerRadius, y - playerRadius) ~= kColorClear
    or sample(levelImage, x - playerRadius, y + playerRadius) ~= kColorClear
    or sample(levelImage, x - playerRadius, y - playerRadius) ~= kColorClear then
        self:reset()
        return
    end

    local crankPosition = rad(getCrankPosition() - 90)
    local crankCos, crankSin = cos(crankPosition), sin(crankPosition)
    local _, _, collisions, length = self:moveWithCollisions(x + playerSpeed * crankCos, y + playerSpeed * crankSin)

    for i=1, length do
        local collision = collisions[i]
        local collisionSprite = collision.other
        local collisionTag = collisionSprite:getTag()
        if collisionTag == TAGS.pickup then
            collisionSprite:pickup(self)
        end
    end
end

function Player:getScreenPosition()
    local drawOffsetX, drawOffsetY = getDrawOffset()
    return self.x + drawOffsetX, self.y + drawOffsetY
end

function Player:nextLevel()
    self:disable()
    self.gameScene:nextLevel()
end

function Player:disable()
    self.disabled = true
end

function Player:reset()
    if self.disabled or self.resetTimer or self.frozen then
        return
    end

    self:moveTo(self.startX, self.startY)
    self.resetTimer = pd.timer.new(resetTime, function()
        self.resetTimer = nil
    end)
end