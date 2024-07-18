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
local speedMultiplierConstant = 30 / 1000

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
    tableInsert(turretXSpeed, xSpeed * speedMultiplierConstant)
    tableInsert(turretYSpeed, ySpeed * speedMultiplierConstant)
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

        x += xSpeed * dt
        y += ySpeed * dt

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
