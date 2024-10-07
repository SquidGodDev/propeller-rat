local pd <const> = playdate
local gfx <const> = pd.graphics

local audioManager <const> = AudioManager

local shootSfx <const> = audioManager.sfx.shoot
local smashSfx <const> = audioManager.sfx.smash
local playSfx <const> = audioManager.play
local playerTag <const> = TAGS.player
local hazardTag <const> = TAGS.hazard
local wallTag <const> = TAGS.wall
local getTag <const> = gfx.sprite.getTag

local turretProjectileImage <const> = gfx.image.new("images/hazards/turretProjectile")
local turretProjectileWidth <const> = turretProjectileImage:getSize()
local turretProjectileHalfWidth <const> = turretProjectileWidth / 2
local turretImagetable <const> = gfx.imagetable.new("images/hazards/turret")
local turretImagetableSize <const> = #turretImagetable
local projectileBreakImagetable <const> = gfx.imagetable.new("images/hazards/projectileBreak")

local turretFrameTime <const> = 80 -- ms
local projectileWidth <const> = 10
local projectileBorder <const> = 2
local projectileHitboxSize <const> = projectileWidth - projectileBorder * 2
local speedMultiplierConstant <const> = 30 / 1000

local querySpritesInRect <const> = gfx.sprite.querySpritesInRect
local draw <const> = gfx.image.draw
local setImage <const> = gfx.sprite.setImage

local tableInsert <const> = table.insert
local tableRemove <const> = table.remove

local turretSprites <const> = {}
local turretX <const> = {}
local turretY <const> = {}
local turretXSpeed <const> = {}
local turretYSpeed <const> = {}
local turretTime <const> = {}
local turretCurTime <const> = {}
local turretStartDelay <const> = {}
local turretCurFrame <const> = {}
local turretCurFrameTime <const> = {}

local collisionCheckRate <const> = 2
local collisionCheckCount = 0

local maxProjectileCount <const> = 50
local projectileX <const> = table.create(maxProjectileCount, 0)
local projectileY <const> = table.create(maxProjectileCount, 0)
local projectileTurretIndex <const> = table.create(maxProjectileCount, 0)

local projectileBreakSpriteCount = 50
local projectileBreakSprites <const> = table.create(projectileBreakSpriteCount, 0)

local spriteNew <const> = gfx.sprite.new
local spriteSetImage <const> = gfx.sprite.setImage
local spriteMoveTo <const> = gfx.sprite.moveTo
local spriteAdd <const> = gfx.sprite.add
local spriteRemove <const> = gfx.sprite.remove

local animationLoopNew <const> = gfx.animation.loop.new
local animationLoopImage <const> = gfx.animation.loop.image
local animationLoopIsValid <const> = gfx.animation.loop.isValid
local function createProjectileBreakSprite()
    local sprite = spriteNew(projectileBreakImagetable[1])
    local animationLoop = animationLoopNew(20, projectileBreakImagetable, false)
    ---@diagnostic disable-next-line: inject-field
    sprite.animationLoop = animationLoop
    local curFrame = animationLoop.startFrame
    sprite.update = function()
        local frame = animationLoop.frame
        if frame ~= curFrame then
            curFrame = frame
            spriteSetImage(sprite, animationLoopImage(animationLoop))
        end
        if not animationLoopIsValid(animationLoop) then
            curFrame = 1
            animationLoop.frame = 1
            spriteRemove(sprite)
            tableInsert(projectileBreakSprites, sprite)
        end
    end
    return sprite
end

for i=1,projectileBreakSpriteCount do
    projectileBreakSprites[i] = createProjectileBreakSprite()
end

TurretManager = {}
class('TurretManager').extends()

function TurretManager:init()
    for i=#turretX, 1, -1 do
        turretSprites[i] = nil
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

    for i=1, maxProjectileCount do
        projectileX[i] = -1
        projectileY[i] = -1
        projectileTurretIndex[i] = -1
    end
end

function TurretManager:addTurret(x, y, xSpeed, ySpeed, time, startDelay)
    local turretSprite = gfx.sprite.new(turretImagetable[1])
    turretSprite:setZIndex(Z_INDEXES.hazard)
    turretSprite:moveTo(x, y)
    turretSprite:add()
    tableInsert(turretSprites, turretSprite)
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
    collisionCheckCount = (collisionCheckCount + 1) % collisionCheckRate
    for i=#turretX, 1, -1 do
        local startDelay = turretStartDelay[i]
        if startDelay > 0 then
            startDelay -= dt
            turretStartDelay[i] = startDelay
        end

        if startDelay <= 0 then
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
                    if not stopped then
                        playSfx(shootSfx)
                    end
                    for idx=1, maxProjectileCount do
                        if projectileTurretIndex[idx] == -1 then
                            projectileX[idx] = x - turretProjectileHalfWidth
                            projectileY[idx] = y - turretProjectileHalfWidth
                            projectileTurretIndex[idx] = i
                            break
                        end
                    end
                    setImage(turretSprites[i], turretImagetable[1])
                else
                    setImage(turretSprites[i], turretImagetable[animationIndex])
                end
            end
        end
    end

    for i=1, maxProjectileCount do
        local turretIndex = projectileTurretIndex[i]
        if turretIndex ~= -1 then
            local x, y = projectileX[i], projectileY[i]
            local destroy = false
            local xSpeed, ySpeed = turretXSpeed[turretIndex], turretYSpeed[turretIndex]

            x += xSpeed * dt
            y += ySpeed * dt

            if collisionCheckCount == 0 then
                local collidedSprites = querySpritesInRect(x + projectileBorder, y + projectileBorder, projectileHitboxSize, projectileHitboxSize)
                for spriteIdx=1, #collidedSprites do
                    local sprite = collidedSprites[spriteIdx]
                    local collisionTag = getTag(sprite)
                    if collisionTag == playerTag then
                        ---@diagnostic disable-next-line: undefined-field
                        sprite:collide()
                    elseif collisionTag == wallTag or collisionTag == hazardTag then
                        destroy = true
                    end
                end
            end

            if destroy then
                if not stopped then
                    playSfx(smashSfx)
                end
                local projectileBreakSprite = tableRemove(projectileBreakSprites)
                if projectileBreakSprite then
                    projectileBreakSprite.animationLoop.frame = 1
                    spriteMoveTo(projectileBreakSprite, x + 2, y + 2)
                    spriteAdd(projectileBreakSprite)
                end
                projectileTurretIndex[i] = -1
            else
                projectileX[i] = x
                projectileY[i] = y
                draw(turretProjectileImage, x, y)
            end
        end
    end
end

function TurretManager:debugDraw()
    for i=#projectileX, 1, -1 do
        local x, y = projectileX[i], projectileY[i]
        gfx.drawRect(x + projectileBorder, y + projectileBorder, projectileHitboxSize, projectileHitboxSize)
    end
end
