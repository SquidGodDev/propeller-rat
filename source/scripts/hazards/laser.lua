local pd <const> = playdate
local gfx <const> = pd.graphics

local laserNodeSize = 16
local laserNodeHalfSize = laserNodeSize / 2
local laserImage = gfx.image.new(laserNodeSize, laserNodeSize)
gfx.pushContext(laserImage)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleInRect(laserNodeHalfSize / 2, laserNodeHalfSize / 2, laserNodeHalfSize, laserNodeHalfSize)
gfx.popContext()

local laserTime = 1000 -- ms
local laserBeamWidth = 8
local laserFireTime = 500 -- ms

class('Laser').extends(gfx.sprite)

function Laser:init(x, y, entity)
    self:setImage(laserImage)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:add()

    if entity then
        local fields = entity.fields
        local tailX, tailY = fields.tail.cx * 16, fields.tail.cy * 16
        Laser(tailX, tailY)
        local laserTimer = pd.timer.new(laserTime, function()
            -- Play laser startup animation
            local laserHeadX, laserHeadY = x + laserNodeHalfSize, y + laserNodeHalfSize
            local laserTailX, laserTailY = tailX + laserNodeHalfSize, tailY + laserNodeHalfSize
            local fireTimer = pd.timer.new(laserFireTime, laserBeamWidth, 0, pd.easingFunctions.outExpo)
            fireTimer.updateCallback = function(timer)
                if timer.value >= 0.5 then
                    local drawLaser = function()
                        gfx.pushContext()
                            gfx.setColor(gfx.kColorWhite)
                            gfx.setLineWidth(timer.value)
                            gfx.drawLine(laserHeadX, laserHeadY, laserTailX, laserTailY)
                        gfx.popContext()
                    end
                    SceneManager.addToDrawQueue(drawLaser)
                end
            end
            local intersectedSprites = gfx.sprite.querySpritesAlongLine(laserHeadX, laserHeadY, laserTailX, laserTailY)
            for i=1, #intersectedSprites do
                local sprite = intersectedSprites[i]
                if sprite:getTag() == TAGS.player then
                    sprite:reset()
                end
            end
        end)
        laserTimer.repeats = true
    end
end

class('LaserBeam').extends(gfx.sprite)

function LaserBeam:init(headX, headY, tailX, tailY)
    self.width = math.abs(headX - tailX) + laserBeamWidth
    self.height = math.abs(headY - tailY) + laserBeamWidth
    local x = headX < tailX and headX or tailX - beamHalfWidth
    local y = headY < tailY and headY or tailY - beamHalfWidth
    self.headX = headX - x
    self.headY = headY - beamHalfWidth
    self:setCenter(0, 0)
    self:moveTo(x, y)
end

function LaserBeam:fire()
    self:add()
    local fireTimer = pd.timer.new(laserFireTime, laserBeamWidth, 0, pd.easingFunctions.outCubic)
    local beamImage = gfx.image.new(self.width, self.height)
    self:setImage(beamImage)
    fireTimer.updateCallback = function(timer)
        beamImage:clear(gfx.kColorClear)
        gfx.pushContext(beamImage)
            gfx.setColor(gfx.kColorWhite)
            gfx.setLineWidth(timer.value)
            gfx.drawLine(0, 0, self.width, self.height)
        gfx.popContext()
        self:setImage(beamImage)
    end
    fireTimer.timerEndedCallback = function()
        self:remove()
    end
end