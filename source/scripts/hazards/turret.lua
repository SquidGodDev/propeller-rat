local pd <const> = playdate
local gfx <const> = pd.graphics

local audioManager <const> = AudioManager

local assets <const> = Assets

local animatedSprite = Utilities.animatedSprite

local shootSfx = audioManager.sfx.shoot
local playerTag <const> = TAGS.player
local hazardTag <const> = TAGS.hazard
local wallTag <const> = TAGS.wall

local turretProjectileImage = gfx.image.new("images/hazards/turretProjectile")
local turretImagetable = gfx.imagetable.new("images/hazards/turret")
local turretImagetableSize = #turretImagetable
local projectileBreakImagetable = gfx.imagetable.new("images/hazards/projectileBreak")

local turretFrameTime = 80 -- ms
local projectileWidth = 10
local projectileBorder = 2
local projectileHitboxSize = projectileWidth - projectileBorder * 2
local projectileHitboxHalfSize = projectileHitboxSize / 2

local querySpritesInRect = gfx.sprite.querySpritesInRect

local tableInsert = table.insert
local tableRemove = table.remove

local turretX <const> = {}
local turretY <const> = {}
local turretXSpeed <const> = {}
local turretYSpeed <const> = {}
local turretTime <const> = {}
local turretCurTime <const> = {}
local turretStartDelay <const> = {}
local turretCurFrame <const> = {}
local turretCurFrameTime <const> = {}

local projectileX <const> = {}
local projectileY <const> = {}
local projectileTurretIndex <const> = {}

class('TurretManager').extends()

function TurretManager:init()
    for i=#turretX, 1, -1 do
        turretX[i] = nil
        turretY[i] = nil
        turretXSpeed[i] = nil
        turretYSpeed[i] = nil
        turretTime[i] = nil
        turretCurTime[i] = nil
        turretStartDelay[i] = nil
        turretCurFrame[i] = nil
        turretCurFrameTime[i] = nil
    end

    for i=#projectileX, 1, -1 do
        projectileX[i] = nil
        projectileY[i] = nil
        projectileTurretIndex[i] = nil
    end
end

function TurretManager:addTurret(x, y, xSpeed, ySpeed, time, startDelay)
    local turretSprite = gfx.sprite.new(turretImagetable[1])
    turretSprite:setZIndex(Z_INDEXES.hazard)
    turretSprite:moveTo(x, y)
    turretSprite:add()
    tableInsert(turretX, x)
    tableInsert(turretY, y)
    tableInsert(turretXSpeed, xSpeed)
    tableInsert(turretYSpeed, ySpeed)
    tableInsert(turretTime, time)
    tableInsert(turretCurTime, 0)
    tableInsert(turretStartDelay, startDelay)
    tableInsert(turretCurFrame, 1)
    tableInsert(turretCurFrameTime, turretFrameTime)
end

function TurretManager:stop()
    self.stopped = true
end

function TurretManager:update(dt)
    local stopped = self.stopped
    for i=#turretX, 1, -1 do
        local startDelay = turretStartDelay[i]
        if startDelay > 0 then
            startDelay -= dt
            turretStartDelay[i] = startDelay
        end

        if startDelay <= 0 and not stopped then
            local animationIndex = turretCurFrame[i]

            local currentTime = turretCurTime[i]
            currentTime -= dt
            if currentTime > 0 then
                turretCurTime[i] = currentTime
            else
                currentTime = turretTime[i] + currentTime
                turretCurTime[i] = currentTime
                turretCurFrameTime[i] = turretFrameTime
                animationIndex = 2
            end

            if animationIndex > 1 then
                local frameTime = turretCurFrameTime[i]
                frameTime -= dt

                if frameTime <= 0 then
                    animationIndex += 1
                    if animationIndex > turretImagetableSize then
                        -- Reset animation
                        animationIndex = 1
                    else
                        frameTime = turretFrameTime
                    end
                end
                turretCurFrame[i] = animationIndex
                turretCurFrameTime[i] = frameTime

                local x, y = turretX[i], turretY[i]
                -- If animation is being reset, that means it's time to fire the projectile
                if animationIndex == 1 then
                    audioManager.play(shootSfx)
                    tableInsert(projectileX, x)
                    tableInsert(projectileY, y)
                    tableInsert(projectileTurretIndex, i)
                else
                    local turretImage = turretImagetable[animationIndex]
                    turretImage:drawAnchored(x, y, 0.5, 0.5)
                end
            end
        end
    end

    if stopped then
        return
    end

    for i=#projectileX, 1, -1 do
        local x, y = projectileX[i], projectileY[i]
        local turretIndex = projectileTurretIndex[i]
        local xSpeed, ySpeed = turretXSpeed[turretIndex], turretYSpeed[turretIndex]

        x += xSpeed
        y += ySpeed

        local destroy = false
        local collidedSprites = querySpritesInRect(x - projectileHitboxHalfSize, y - projectileHitboxHalfSize, projectileHitboxSize, projectileHitboxSize)
        for spriteIdx=1, #collidedSprites do
            local sprite = collidedSprites[spriteIdx]
            local collisionTag = sprite:getTag()
            if collisionTag == playerTag then
                sprite:reset()
            end

            if collisionTag == wallTag or collisionTag == hazardTag then
                destroy = true
            end
        end

        if destroy then
            animatedSprite(x, y, projectileBreakImagetable, 20, false)
            tableRemove(projectileX, i)
            tableRemove(projectileY, i)
            tableRemove(projectileTurretIndex, i)
        else
            projectileX[i] = x
            projectileY[i] = y
            turretProjectileImage:drawAnchored(x, y, 0.5, 0.5)
        end
    end
end

function TurretManager:debugDraw()
    for i=#projectileX, 1, -1 do
        local x, y = projectileX[i], projectileY[i]
        gfx.drawRect(x - projectileHitboxHalfSize, y - projectileHitboxHalfSize, projectileHitboxSize, projectileHitboxSize)
    end
end

class('Turret').extends(Hazard)

function Turret:init(x, y, entity)
    Turret.super.init(self, x, y)

    local fields = entity.fields
    self.xSpeed, self.ySpeed = fields.xSpeed, fields.ySpeed
    local time = fields.time
    local startDelay = fields.startDelay

    self:setImage(turretImagetable[1])
    self.curFrame = 1

    self.projectileX = x
    self.projectileY = y

    self.projectileFired = false

    pd.timer.performAfterDelay(startDelay, function()
        local fireFunction = function ()
            self.animationLoop = gfx.animation.loop.new(turretFrameTime, turretImagetable, false)
            self.projectileFired = false
        end

        fireFunction()
        local turretTimer = pd.timer.new(time, fireFunction)

        turretTimer.repeats = true
    end)
end

function Turret:update()
    if self.stopped then
        return
    end

    local animationLoop = self.animationLoop
    if animationLoop then
        if animationLoop:isValid() and self.curFrame ~= animationLoop.frame then
            self.curFrame = animationLoop.frame
            self:setImage(animationLoop:image())
        else
            audioManager.play(audioManager.sfx.shoot)
            Projectile(self.projectileX, self.projectileY, self.xSpeed, self.ySpeed)
            self:setImage(turretImagetable[1])
            self.animationLoop = nil
        end
    end
end

class('Projectile').extends(gfx.sprite)

function Projectile:init(x, y, xSpeed, ySpeed)
    self.xSpeed = xSpeed
    self.ySpeed = ySpeed

    self:setZIndex(Z_INDEXES.projectile)
    self:setImage(turretProjectileImage)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.projectile)
    self:setGroups(TAGS.projectile)
    self:setCollidesWithGroups({TAGS.player, TAGS.hazard, TAGS.wall})
    self:setCollideRect(projectileBorder, projectileBorder, projectileWidth - projectileBorder * 2, projectileWidth - projectileBorder * 2)
end

function Projectile:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
end

function Projectile:update()
    local _actualX, _actualY, collisions, length = self:moveWithCollisions(self.x + self.xSpeed, self.y + self.ySpeed)

    for i=1,length do
        local collisionSprite = collisions[i].other
        local collisionTag = collisionSprite:getTag()
        if collisionTag == TAGS.player then
            collisionSprite:reset()
        end

        if collisionTag == TAGS.hazard or collisionTag == TAGS.wall then
            local projectileBreakImageTable = assets.getImagetable("images/hazards/projectileBreak")
            Utilities.animatedSprite(self.x, self.y, projectileBreakImageTable, 20, false)
            self:remove()
        end
    end
end
