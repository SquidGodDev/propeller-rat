local pd <const> = playdate
local gfx <const> = pd.graphics

local setColor <const> = gfx.setColor
local kColorWhite <const> = gfx.kColorWhite
local setLineWidth <const> = gfx.setLineWidth
local drawLine <const> = gfx.drawLine
local setImage <const> = gfx.sprite.setImage
local querySpritesAlongLine <const> = gfx.sprite.querySpritesAlongLine
local setPattern <const> = gfx.setPattern
local ditherPattern <const> = {0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA}

local function easeOutExpo(x)
    return x == 1 and 1 or 1 - 2^(-10 * x)
end

local audioManager <const> = AudioManager
local playSfx <const> = audioManager.play
local laserSfx = audioManager.sfx.laser

local laserImagetable = gfx.imagetable.new("images/hazards/laser")
local laserImagetableLength = #laserImagetable

local laserFrameTime = 100 -- ms
local activateTime = 300.0
local beamWidth = 6.0
local fireTime = 1000.0 -- ms

local tableInsert = table.insert
local laserHeadSprites <const> = {}
local laserTailSprites <const> = {}
local laserHeadX <const> = {}
local laserHeadY <const> = {}
local laserTailX <const> = {}
local laserTailY <const> = {}
local laserDelay <const> = {}
local laserInterval <const> = {}
local laserCurrentInterval <const> = {}
local laserAnimationIndex <const> = {}
local laserAnimationFrameTime <const> = {}
local laserFired <const> = {}
local laserFireTime <const> = {}

LaserManager = {}
class('LaserManager').extends()

function LaserManager:init()
    self:clear()
    self.stopped = false
    self.flashCounter = 0
end

function LaserManager:stop()
    self.stopped = true
end

function LaserManager:clear()
    for i=#laserHeadX,1,-1 do
        laserHeadSprites[i] = nil
        laserTailSprites[i] = nil
        laserHeadX[i] = nil
        laserHeadY[i] = nil
        laserTailX[i] = nil
        laserTailY[i] = nil
        laserDelay[i] = nil
        laserInterval[i] = nil
        laserCurrentInterval[i] = nil
        laserAnimationIndex[i] = nil
        laserAnimationFrameTime[i] = nil
        laserFired[i] = nil
        laserFireTime[i] = nil
    end
end

function LaserManager:addLaser(headX, headY, tailX, tailY, delay, interval)
    local laserSpriteHead = gfx.sprite.new(laserImagetable[1])
    laserSpriteHead:setZIndex(Z_INDEXES.hazard)
    laserSpriteHead:moveTo(headX, headY)
    laserSpriteHead:add()
    local laserSpriteTail = gfx.sprite.new(laserImagetable[1])
    laserSpriteTail:setZIndex(Z_INDEXES.hazard)
    laserSpriteTail:moveTo(tailX, tailY)
    laserSpriteTail:add()
    tableInsert(laserHeadSprites, laserSpriteHead)
    tableInsert(laserTailSprites, laserSpriteTail)
    tableInsert(laserHeadX, headX)
    tableInsert(laserHeadY, headY)
    tableInsert(laserTailX, tailX)
    tableInsert(laserTailY, tailY)
    tableInsert(laserDelay, delay)
    tableInsert(laserInterval, interval)
    tableInsert(laserCurrentInterval, 0)
    tableInsert(laserAnimationIndex, 1)
    tableInsert(laserAnimationFrameTime, laserFrameTime)
    tableInsert(laserFired, false)
    tableInsert(laserFireTime, false)
end

function LaserManager:update(dt)
    setColor(kColorWhite)
    local stopped = self.stopped
    self.flashCounter += 1
    for i=#laserHeadX, 1, -1 do
        -- Check if laser has starting delay 
        local delay = laserDelay[i]
        if delay > 0 then
            delay -= dt
            laserDelay[i] = delay
        end

        if delay <= 0 and not stopped then
            local animationIndex = laserAnimationIndex[i]

            -- Update laser interval time
            local currentInterval = laserCurrentInterval[i]
            currentInterval -= dt
            if currentInterval > 0 then
                laserCurrentInterval[i] = currentInterval
            else
                currentInterval = laserInterval[i] + currentInterval
                laserCurrentInterval[i] = currentInterval
                laserFired[i] = false
                laserAnimationFrameTime[i] = laserFrameTime
                animationIndex = 2
            end

            if animationIndex > 1 then
                local headX, headY = laserHeadX[i], laserHeadY[i]
                local tailX, tailY = laserTailX[i], laserTailY[i]

                -- Update laser head/tail animation frame time
                local animationFrameTime = laserAnimationFrameTime[i]
                if animationFrameTime > 0 then
                    animationFrameTime -= dt
                end

                -- Update laser head/tail animation frame
                if animationFrameTime <= 0 then
                    animationIndex += 1
                    if animationIndex > laserImagetableLength then
                        -- Reset laser head/tail animation
                        animationIndex = 1
                    else
                        animationFrameTime = laserFrameTime
                    end
                end
                laserAnimationIndex[i] = animationIndex
                laserAnimationFrameTime[i] = animationFrameTime

                local activated = laserInterval[i] - currentInterval >= activateTime
                if not activated and animationIndex ~= 1 then
                    -- Draw preparation laser
                    setLineWidth(1)
                    setPattern(ditherPattern)
                    drawLine(headX, headY, tailX, tailY)
                    setColor(kColorWhite)
                elseif activated then
                    -- Fire laser
                    if not laserFired[i] then
                        playSfx(laserSfx)
                        laserFired[i] = true
                        laserFireTime[i] = fireTime
                        local intersectedSprites = querySpritesAlongLine(headX, headY, tailX, tailY)
                        for spriteIdx=1, #intersectedSprites do
                            local sprite = intersectedSprites[spriteIdx]
                            if sprite:getTag() == TAGS.player then
                                ---@diagnostic disable-next-line: undefined-field
                                sprite:collide()
                            end
                        end
                    end

                    -- Draw fired laser
                    local remainingFireTime = laserFireTime[i] - dt
                    laserFireTime[i] = remainingFireTime
                    if remainingFireTime > 0 then
                        local laserWidth = (1 - easeOutExpo(1 - remainingFireTime/fireTime)) * beamWidth
                        if laserWidth > 3 then
                            setLineWidth(laserWidth)
                            drawLine(headX, headY, tailX, tailY)
                        elseif laserWidth > 1 then
                            setPattern(ditherPattern)
                            setLineWidth(laserWidth)
                            drawLine(headX, headY, tailX, tailY)
                            setColor(kColorWhite)
                        end
                    end
                end

                -- Draw laser head/tail
                local laserImage = laserImagetable[animationIndex]
                setImage(laserHeadSprites[i], laserImage)
                setImage(laserTailSprites[i], laserImage)
            else
                local laserImage = laserImagetable[1]
                setImage(laserHeadSprites[i], laserImage)
                setImage(laserTailSprites[i], laserImage)
            end
        end
    end
end
