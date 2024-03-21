local pd <const> = playdate
local gfx <const> = pd.graphics

local assets <const> = Assets
local audioManager <const> = AudioManager

Assets.preloadImagetable("images/hazards/laser")

local laserFrameTime = 100 -- ms
local fireFrame = 5

local laserBeamWidth = 8
local laserFireTime = 1000 -- ms

class('Laser').extends(gfx.sprite)

function Laser:init(x, y, entity)
    local laserImagetable = assets.getImagetable("images/hazards/laser")
    self:setImage(laserImagetable[1])
    self:moveTo(x, y)
    self:add()

    if entity then
        local fields = entity.fields
        local delay = fields.delay
        local interval = fields.interval
        local tailX, tailY = fields.tail.cx * 16 + 8, fields.tail.cy * 16 + 8
        local tailLaser = Laser(tailX, tailY)
        self.tailX, self.tailY = tailX, tailY
        self.fired = false
        pd.timer.performAfterDelay(delay, function()
            local laserTimer = pd.timer.new(interval, function()
                self:startupAnimation()
                tailLaser:startupAnimation()
            end)
            laserTimer.repeats = true
        end)
    end
end

function Laser:update()
    if self.animationLoop then
        if self.animationLoop:isValid() then
            self:setImage(self.animationLoop:image())
            if self.tailX and self.tailY and not self.fired and self.animationLoop.frame == fireFrame then
                audioManager.play(audioManager.sfx.laser)
                self:fire()
                self.fired = true
            end
        else
            local laserImagetable = assets.getImagetable("images/hazards/laser")
            self:setImage(laserImagetable[1])
            self.animationLoop = nil
        end
    end
end

function Laser:startupAnimation()
    local laserImagetable = assets.getImagetable("images/hazards/laser")
    self.animationLoop = gfx.animation.loop.new(laserFrameTime, laserImagetable, false)
    self.fired = false
end

function Laser:fire()
    local laserHeadX, laserHeadY = self.x, self.y
    local laserTailX, laserTailY = self.tailX, self.tailY
    local fireTimer = pd.timer.new(laserFireTime, laserBeamWidth, 0, pd.easingFunctions.outExpo)
    fireTimer.updateCallback = function(timer)
        if timer.value >= 0.3 then
            local drawLaser = function()
                gfx.pushContext()
                    gfx.setColor(gfx.kColorWhite)
                    gfx.setLineWidth(timer.value)
                    gfx.drawLine(laserHeadX, laserHeadY, laserTailX, laserTailY)
                gfx.popContext()
                return true
            end
            SceneManager.addToDrawQueue({update = drawLaser})
        end
    end
    local intersectedSprites = gfx.sprite.querySpritesAlongLine(laserHeadX, laserHeadY, laserTailX, laserTailY)
    for i=1, #intersectedSprites do
        local sprite = intersectedSprites[i]
        if sprite:getTag() == TAGS.player then
            sprite:reset()
        end
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