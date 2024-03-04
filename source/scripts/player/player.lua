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
local unfreezeSensitivity = 0.1
local resetTime = 500 -- ms

local playerSpeed = 1.4
local playerAnimationFrameRate = 50 -- ms
local playerImageTable = gfx.imagetable.new("images/player/rat")
local flyStartFrame, flyEndFrame = 1, 12

local propellerImagetable = gfx.imagetable.new("images/player/propeller")
local propellerSprite = Utilities.animatedSprite(0, 0, propellerImagetable, playerAnimationFrameRate, true)
propellerSprite:setZIndex(Z_INDEXES.player)
propellerSprite:remove()

local beamImage = gfx.image.new(24, 300, gfx.kColorWhite)
local beamSprite = gfx.sprite.new(beamImage)
beamSprite:setZIndex(Z_INDEXES.player)

class('Player').extends(gfx.sprite)

function Player:init(gameScene, x, y)
    self.gameScene = gameScene

    self.startX = x
    self.startY = y
    setDrawOffset(-x + 200, -y + 120)
    self:setZIndex(Z_INDEXES.player)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.player)
    self:setGroups(TAGS.player)
    self:setCollidesWithGroups({TAGS.hazard, TAGS.projectile, TAGS.pickup, TAGS.wall})
    self:setCollideRect(4, 3, 15, 21)

    self.disabled = true
    self.frozen = true
    self.resetTimer = nil

    self.animationLoop = gfx.animation.loop.new(playerAnimationFrameRate, playerImageTable, true)
    self.animationLoop.startFrame = flyStartFrame
    self.animationLoop.endFrame = flyEndFrame
    self:setImage(self.animationLoop:image())
end

function Player:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
end

function Player:update()
    self:setImage(self.animationLoop:image())

    local drawOffsetX, drawOffsetY = getDrawOffset()
    local targetOffsetX, targetOffsetY = -(self.x - 200), -(self.y - 120)
    local smoothedX = lerp(drawOffsetX, targetOffsetX, smoothSpeed)
    local smoothedY = lerp(drawOffsetY, targetOffsetY, smoothSpeed)
    setDrawOffset(smoothedX, smoothedY)

    if self.disabled then
        return
    end

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

    local x, y = self.x, self.y
    local crankPosition = rad(getCrankPosition() - 90)
    local crankCos, crankSin = cos(crankPosition), sin(crankPosition)
    local _, _, collisions, length = self:moveWithCollisions(x + playerSpeed * crankCos, y + playerSpeed * crankSin)
    if crankCos < 0 then
        self:setImageFlip(gfx.kImageFlippedX)
    elseif crankCos > 0 then
        self:setImageFlip(gfx.kImageUnflipped)
    end

    for i=1, length do
        local collision = collisions[i]
        local collisionSprite = collision.other
        local collisionTag = collisionSprite:getTag()
        if collisionTag == TAGS.pickup then
            collisionSprite:pickup(self)
        elseif collisionTag == TAGS.wall then
            self:reset()
        end
    end
end

function Player:getScreenPosition()
    local drawOffsetX, drawOffsetY = getDrawOffset()
    return self.x + drawOffsetX, self.y + drawOffsetY
end

function Player:nextLevel(x, y)
    if self.disabled then
        return
    end
    self:moveTo(x, y)
    self:disable()
    self:setVisible(false)
    propellerSprite:moveTo(x, y)
    propellerSprite:add()
    local propellerTimer = pd.timer.new(1500, y, y - 200, pd.easingFunctions.inCubic)
    propellerTimer.updateCallback = function(timer)
        propellerSprite:moveTo(x, timer.value)
    end

    pd.timer.performAfterDelay(1700, function()
        self.gameScene:nextLevel()
    end)
end

function Player:disable()
    self.disabled = true
    self:setCollisionsEnabled(false)
end

function Player:enable()
    self.disabled = false
    self:setCollisionsEnabled(true)
end

function Player:reset()
    if self.disabled or self.resetTimer or self.frozen then
        return
    end

    self:setCollisionsEnabled(false)

    self:moveTo(self.startX, self.startY)
    self.resetTimer = pd.timer.new(resetTime, function()
        self.resetTimer = nil
        self:setCollisionsEnabled(true)
    end)
    self.frozen = true
end