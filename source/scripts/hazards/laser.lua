local pd <const> = playdate
local gfx <const> = pd.graphics

local setColor = gfx.setColor
local kColorWhite = gfx.kColorWhite
local setLineWidth = gfx.setLineWidth
local drawLine = gfx.drawLine

local function easeOutExpo(x)
    return x == 1 and 1 or 1 - 2^(-10 * x)
end

local audioManager <const> = AudioManager

local laserImagetable = gfx.imagetable.new("images/hazards/laser")
local laserImagetableLength = #laserImagetable

local laserFrameTime = 100 -- ms
local activateTime = 300.0
local beamWidth = 8.0
local fireTime = 1000.0 -- ms

local tableInsert = table.insert
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

class('LaserManager').extends()

function LaserManager:init()
    self:clear()
    self.stopped = false
end

function LaserManager:stop()
    self.stopped = true
end

function LaserManager:clear()
    for i=#laserHeadX,1,-1 do
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
    laserSpriteHead:moveTo(headX, headY)
    laserSpriteHead:add()
    local laserSpriteTail = gfx.sprite.new(laserImagetable[1])
    laserSpriteTail:moveTo(tailX, tailY)
    laserSpriteTail:add()
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
    local reduceFlashing = pd.getReduceFlashing()
    for i=#laserHeadX, 1, -1 do
        local headX, headY = laserHeadX[i], laserHeadY[i]
        local tailX, tailY = laserTailX[i], laserTailY[i]
        local animationIndex = laserAnimationIndex[i]

        -- Check if laser has starting delay 
        local delay = laserDelay[i]
        if delay > 0 then
            delay -= dt
            laserDelay[i] = delay
        end

        if delay <= 0 and not self.stopped then
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
                -- Update laser head/tail animation frame time
                local animationFrameTime = laserAnimationFrameTime[i]
                if animationFrameTime > 0 then
                    animationFrameTime -= dt
                end

                local resetting = false
                -- Update laser head/tail animation frame
                if animationFrameTime <= 0 then
                    animationIndex += 1
                    if animationIndex > laserImagetableLength then
                        -- Reset laser head/tail animation
                        animationIndex = 1
                        resetting = true
                    else
                        animationFrameTime = laserFrameTime
                    end
                end
                laserAnimationIndex[i] = animationIndex
                laserAnimationFrameTime[i] = animationFrameTime

                local activated = laserInterval[i] - currentInterval >= activateTime
                if not activated and not resetting then
                    -- Draw preparation laser
                    if currentInterval % 2 == 0 or reduceFlashing then
                        setLineWidth(1)
                        drawLine(headX, headY, tailX, tailY)
                    end
                elseif activated then
                    -- Fire laser
                    if not laserFired[i] then
                        audioManager.play(audioManager.sfx.laser)
                        laserFired[i] = true
                        laserFireTime[i] = fireTime
                        local intersectedSprites = gfx.sprite.querySpritesAlongLine(headX, headY, tailX, tailY)
                        for spriteIdx=1, #intersectedSprites do
                            local sprite = intersectedSprites[spriteIdx]
                            if sprite:getTag() == TAGS.player then
                                sprite:reset()
                            end
                        end
                    end

                    -- Draw fired laser
                    local remainingFireTime = laserFireTime[i] - dt
                    laserFireTime[i] = remainingFireTime
                    if remainingFireTime > 0 then
                        local laserWidth = (1 - easeOutExpo(1 - remainingFireTime/fireTime)) * beamWidth
                        if laserWidth > 1 then
                            setLineWidth(laserWidth)
                            drawLine(headX, headY, tailX, tailY)
                        end
                    end
                end

                -- Draw laser head/tail
                local laserImage = laserImagetable[animationIndex]
                laserImage:drawAnchored(headX, headY, 0.5, 0.5)
                laserImage:drawAnchored(tailX, tailY, 0.5, 0.5)
            end
        end
    end
end
