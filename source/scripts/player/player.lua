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

local pickupTag <const> = TAGS.pickup
local wallTag <const> = TAGS.wall

local getCrankPosition <const> = pd.getCrankPosition
local getDrawOffset <const> = gfx.getDrawOffset
local setDrawOffset <const> = gfx.setDrawOffset
local spriteSetImage <const> = gfx.sprite.setImage
local moveWithCollisions <const> = gfx.sprite.moveWithCollisions
local setCollideRect <const> = gfx.sprite.setCollideRect
local animationLoopImage <const> = gfx.animation.loop.image
local kImageUnflipped <const> = gfx.kImageUnflipped
local kImageFlippedX <const> = gfx.kImageFlippedX

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end

local setDisplayOffset = pd.display.setOffset

local smoothSpeed <const> = 0.06

assets.preloadImagetables({
    "images/player/rat",
    "images/player/propeller",
    "images/player/spinningRat",
    "images/player/directionArrow",
    "images/levels/entranceTeleporter",
    "images/levels/fadingEntranceTeleporter"})

local playerSpeed = 2.5 * (30 / 1000)
local playerAnimationFrameRate = 50 -- ms
local flyStartFrame, flyEndFrame = 1, 12

local spinningPlayerFrameRate = 20

local levelPassKey = LEVEL_PASS_KEY

Player = {}
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
    self.unflippedCollisionRect = pd.geometry.rect.new(5, 6, 11, 17)
    self.flippedCollisionRect = pd.geometry.rect.new(7, 6, 11, 17)
    self:setCollideRect(self.unflippedCollisionRect)
    self.imageFlip = kImageUnflipped

    self.frozenPlayerSprite = Utilities.animatedSprite(x, y, assets.getImagetable("images/levels/entranceTeleporter"), 100, true)
    self.frozenPlayerSprite:setZIndex(Z_INDEXES.ui)
    self:setVisible(false)

    self.disabled = true
    self.frozen = true
    self.resetting = false

    local playerImageTable = assets.getImagetable("images/player/rat")
    self.animationLoop = gfx.animation.loop.new(playerAnimationFrameRate, playerImageTable, true)
    ---@diagnostic disable-next-line: inject-field
    self.animationLoop.startFrame = flyStartFrame
    ---@diagnostic disable-next-line: inject-field
    self.animationLoop.endFrame = flyEndFrame
    self:setImage(self.animationLoop:image())

    self.directionArrows = assets.getImagetable("images/player/directionArrow")
    self.directionArrowSprite = gfx.sprite.new()
    self.directionArrowSprite:moveTo(x, y)
    self.directionArrowSprite:setZIndex(Z_INDEXES.ui)
    self.directionArrowSprite:add()
end

function Player:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
end

function Player:updatePlayer(dt)
    local x, y = self.x, self.y
    spriteSetImage(self, animationLoopImage(self.animationLoop), self.imageFlip)

    local targetOffsetX, targetOffsetY = -(x - 200), -(y - 120)
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
        if pd.buttonIsPressed(pd.kButtonA)
        or pd.buttonIsPressed(pd.kButtonB)
        or pd.buttonIsPressed(pd.kButtonUp)
        or pd.buttonIsPressed(pd.kButtonDown)
        or pd.buttonIsPressed(pd.kButtonLeft)
        or pd.buttonIsPressed(pd.kButtonRight) then
            audioManager.play(audioManager.sfx.release)
            self.frozen = false
            self.frozenPlayerSprite:setVisible(false)
            self.frozenPlayerSprite:remove()
            local fadingEntranceTeleporter = Utilities.animatedSprite(self.x, self.y, assets.getImagetable("images/levels/fadingEntranceTeleporter"), 100, false)
            fadingEntranceTeleporter:setZIndex(Z_INDEXES.ui)
            self:setVisible(true)
            self.gameScene:startLevelTime()
            self.directionArrowSprite:remove()
        else
            local crankPosition = math.floor(getCrankPosition()) + 1
            self.directionArrowSprite:setImage(self.directionArrows[crankPosition])
            return
        end
    end

    if levelPassKey then
        if pd.buttonJustPressed(pd.kButtonUp) then
            self:levelEnd(self.x, self.y)
        end
    end

    local crankPosition = rad(getCrankPosition() - 90)
    local crankCos, crankSin = cos(crankPosition), sin(crankPosition)
    local adjustedPlayerSpeed = playerSpeed * dt
    local _, _, collisions, length = moveWithCollisions(self, x + adjustedPlayerSpeed * crankCos, y + adjustedPlayerSpeed * crankSin)
    if crankCos < 0 and self.imageFlip ~= kImageFlippedX then
        self.imageFlip = kImageFlippedX
        setCollideRect(self, self.flippedCollisionRect)
    elseif crankCos > 0 and self.imageFlip ~= kImageUnflipped then
        self.imageFlip = kImageUnflipped
        setCollideRect(self, self.unflippedCollisionRect)
    end

    for i=1, length do
        local collision = collisions[i]
        local collisionSprite = collision.other
        local collisionTag = collisionSprite:getTag()
        if collisionTag == pickupTag then
            ---@diagnostic disable-next-line: undefined-field
            collisionSprite:pickup(self)
        elseif collisionTag == wallTag then
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
    propellerTimer.updateCallback = function()
        propellerSprite:moveTo(x, propellerTimer.value)
    end

    self.gameScene:recordLevelTime()
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

function Player:collide()
    if self.frozen then
        return
    end
    self:reset()
end

function Player:reset()
    if self.disabled then
        return
    end

    self.gameScene:removeMenuItems()

    if not self.frozen then
        DEATH_COUNT += 1
    end

    audioManager.playRandom(squeaksSfx)

    self.disabled = true
    self.frozen = true

    self.directionArrowSprite:remove()

    if self.frozenPlayerSprite:isVisible() then
        self.frozenPlayerSprite:remove()
        local fadingEntranceTeleporter = Utilities.animatedSprite(self.x, self.y, assets.getImagetable("images/levels/fadingEntranceTeleporter"), 100, false)
        fadingEntranceTeleporter:setZIndex(Z_INDEXES.ui)
    end

    local shakeTimer = pd.timer.new(300, 6, 0)
    shakeTimer.timerEndedCallback = function()
        setDisplayOffset(0, 0)
    end
    shakeTimer.updateCallback = function()
        local shakeAmount = shakeTimer.value
        local shakeAngle = random()*3.14*2;
        local shakeX = floor(cos(shakeAngle)*shakeAmount);
        local shakeY = floor(sin(shakeAngle)*shakeAmount);
        setDisplayOffset(shakeX, shakeY)
    end

    local deathX, deathY = self.x, self.y

    self:setCollisionsEnabled(false)
    self:setVisible(false)
    local spinningPlayerImagetable = assets.getImagetable("images/player/spinningRat")
    local spinningPlayerSprite = Utilities.animatedSprite(deathX, deathY, spinningPlayerImagetable, spinningPlayerFrameRate, true, nil, nil, self:getImageFlip())
    spinningPlayerSprite:setZIndex(Z_INDEXES.player)
    local moveTimer = pd.timer.new(1000, deathY, deathY + 200, pd.easingFunctions.inBack)
    moveTimer.updateCallback = function()
        spinningPlayerSprite:moveTo(deathX, moveTimer.value)
    end
    moveTimer.timerEndedCallback = function()
        spinningPlayerSprite:remove()
    end

    local propellerImagetable = assets.getImagetable("images/player/propeller")
    local propellerSprite = Utilities.animatedSprite(0, 0, propellerImagetable, playerAnimationFrameRate, true)
    propellerSprite:setZIndex(Z_INDEXES.player)
    propellerSprite:moveTo(deathX, deathY)
    local propellerTimer = pd.timer.new(1500, deathY, deathY - 200, pd.easingFunctions.inCubic)
    propellerTimer.updateCallback = function()
        propellerSprite:moveTo(deathX, propellerTimer.value)
    end
    propellerTimer.timerEndedCallback = function()
        propellerSprite:remove()
    end

    pd.timer.performAfterDelay(1000, function()
        local playerX, playerY = self:getScreenPosition()
        SceneManager.switchScene(GameScene, playerX, playerY)
    end)
end