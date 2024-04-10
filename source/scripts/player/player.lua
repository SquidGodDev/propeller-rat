local pd <const> = playdate
local gfx <const> = pd.graphics

local audioManager <const> = AudioManager
local squeaksSfx = {audioManager.sfx.squeak1, audioManager.sfx.squeak2, audioManager.sfx.squeak3, audioManager.sfx.squeak4}

local assets <const> = Assets

local rad <const> = math.rad
local cos <const> = math.cos
local sin <const> = math.sin
local floor <const> = math.floor
local random <const> = math.random

local getCrankPosition <const> = pd.getCrankPosition
local getDrawOffset <const> = gfx.getDrawOffset
local setDrawOffset <const> = gfx.setDrawOffset

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end

local setDisplayOffset = pd.display.setOffset

local smoothSpeed <const> = 0.06

assets.preloadImagetables({"images/player/rat", "images/player/propeller", "images/player/spinningRat", "images/player/aButtonPopup"})

local playerSpeed = 2.5
local playerAnimationFrameRate = 50 -- ms
local flyStartFrame, flyEndFrame = 1, 12

local spinningPlayerFrameRate = 20

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

    self.aButtonPopup = Utilities.animatedSprite(x, y - 32, assets.getImagetable("images/player/aButtonPopup"), 500, true)
    self.aButtonPopup:setZIndex(Z_INDEXES.ui)

    self.disabled = true
    self.frozen = true
    self.resetting = false

    local playerImageTable = assets.getImagetable("images/player/rat")
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

    local targetOffsetX, targetOffsetY = -(self.x - 200), -(self.y - 120)
    if self.resetting then
        targetOffsetX, targetOffsetY = -(self.startX - 200), -(self.startY - 120)
    end
    local drawOffsetX, drawOffsetY = getDrawOffset()
    local smoothedX = lerp(drawOffsetX, targetOffsetX, smoothSpeed)
    local smoothedY = lerp(drawOffsetY, targetOffsetY, smoothSpeed)
    setDrawOffset(smoothedX, smoothedY)

    if self.disabled then
        return
    end

    if self.frozen then
        if pd.buttonJustPressed(pd.kButtonA) then
            self.frozen = false
            self.aButtonPopup:remove()
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

function Player:levelEnd(x, y)
    if self.disabled then
        return
    end
    self:moveTo(x, y)
    self:disable()
    self:setVisible(false)
    local propellerImagetable = assets.getImagetable("images/player/propeller")
    local propellerSprite = Utilities.animatedSprite(0, 0, propellerImagetable, playerAnimationFrameRate, true)
    propellerSprite:setZIndex(Z_INDEXES.player)
    propellerSprite:moveTo(x, y)
    local propellerTimer = pd.timer.new(1500, y, y - 200, pd.easingFunctions.inCubic)
    propellerTimer.updateCallback = function(timer)
        propellerSprite:moveTo(x, timer.value)
    end

    pd.timer.performAfterDelay(1300, function()
        self.gameScene:levelEnd()
    end)
end

function Player:isDisabled()
    return self.disabled
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
    if self.disabled then
        return
    end

    self.aButtonPopup:remove()

    audioManager.playRandom(squeaksSfx)

    self.disabled = true
    self.frozen = true

    local shakeTimer = pd.timer.new(300, 6, 0)
    shakeTimer.timerEndedCallback = function()
        setDisplayOffset(0, 0)
    end
    shakeTimer.updateCallback = function(timer)
        local shakeAmount = timer.value
        local shakeAngle = random()*3.14*2;
        shakeX = floor(cos(shakeAngle)*shakeAmount);
        shakeY = floor(sin(shakeAngle)*shakeAmount);
        setDisplayOffset(shakeX, shakeY)
    end

    local deathX, deathY = self.x, self.y

    self:setCollisionsEnabled(false)
    self:setVisible(false)
    local spinningPlayerImagetable = assets.getImagetable("images/player/spinningRat")
    local spinningPlayerSprite = Utilities.animatedSprite(deathX, deathY, spinningPlayerImagetable, spinningPlayerFrameRate, true, nil, nil, self:getImageFlip())
    spinningPlayerSprite:setZIndex(Z_INDEXES.player)
    local moveTimer = pd.timer.new(1000, deathY, deathY + 200, pd.easingFunctions.inBack)
    moveTimer.updateCallback = function(timer)
        spinningPlayerSprite:moveTo(deathX, timer.value)
    end
    moveTimer.timerEndedCallback = function()
        spinningPlayerSprite:remove()
    end

    local propellerImagetable = assets.getImagetable("images/player/propeller")
    local propellerSprite = Utilities.animatedSprite(0, 0, propellerImagetable, playerAnimationFrameRate, true)
    propellerSprite:setZIndex(Z_INDEXES.player)
    propellerSprite:moveTo(deathX, deathY)
    local propellerTimer = pd.timer.new(1500, deathY, deathY - 200, pd.easingFunctions.inCubic)
    propellerTimer.updateCallback = function(timer)
        propellerSprite:moveTo(deathX, timer.value)
    end
    propellerTimer.timerEndedCallback = function()
        propellerSprite:remove()
    end

    pd.timer.performAfterDelay(1000, function()
        local playerX, playerY = self:getScreenPosition()
        SceneManager.switchScene(GameScene, playerX, playerY)
    end)
end