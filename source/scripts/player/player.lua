local pd <const> = playdate
local gfx <const> = pd.graphics

local rad <const> = math.rad
local cos <const> = math.cos
local sin <const> = math.sin

local getCrankPosition <const> = pd.getCrankPosition
local getDrawOffset <const> = gfx.getDrawOffset
local setDrawOffset <const> = gfx.setDrawOffset

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end

local smoothSpeed <const> = 0.06

local playerSpeed = 1.2
local playerDiameter = 8
local playerImage = gfx.image.new(playerDiameter, playerDiameter)
gfx.pushContext(playerImage)
    gfx.fillCircleInRect(0, 0, playerDiameter, playerDiameter)
gfx.popContext()

class('Player').extends(gfx.sprite)

function Player:init(x, y, levelImage)
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
end

function Player:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
end

function Player:update()
    local crankPosition = rad(getCrankPosition() - 90)
    self:moveBy(playerSpeed * cos(crankPosition), playerSpeed * sin(crankPosition))

    if self.levelImage:sample(self.x, self.y) == gfx.kColorBlack then
        self:reset()
    end

    local drawOffsetX, drawOffsetY = getDrawOffset()
    local targetOffsetX, targetOffsetY = -(self.x - 200), -(self.y - 120)
    local smoothedX = lerp(drawOffsetX, targetOffsetX, smoothSpeed)
    local smoothedY = lerp(drawOffsetY, targetOffsetY, smoothSpeed)
    setDrawOffset(smoothedX, smoothedY)
end

function Player:reset()
    self:moveTo(self.startX, self.startY)
end