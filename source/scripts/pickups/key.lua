local pd <const> = playdate
local gfx <const> = pd.graphics

local assets <const> = Assets
local audioManager <const> = AudioManager

assets.preloadImage("images/levels/key")
assets.preloadImagetable("images/levels/pickupParticles")

class('Key').extends(Pickup)

function Key:init(x, y)
    Key.super.init(self, x, y)

    local keyImage = assets.getImage("images/levels/key")
    self:setImage(keyImage)
    self:setCollideRect(0, 0, self:getSize())

    local bobTimer = pd.timer.new(1000, -4, 4)
    bobTimer.repeats = true
    bobTimer.reverses = true
    bobTimer.updateCallback = function(timer)
        self:moveTo(x, y - timer.value)
    end
end

function Key:setLevelEnd(levelEnd)
    self.levelEnd = levelEnd
end

function Key:pickup(_player)
    audioManager.play(audioManager.sfx.chipPickUp)
    local pickupParticlesImagetable = assets.getImagetable("images/levels/pickupParticles")
    local pickupParticles = Utilities.animatedSprite(self.x, self.y, pickupParticlesImagetable, 16, false)
    pickupParticles:setZIndex(Z_INDEXES.level)
    self.levelEnd:keyPickup()
    self:remove()
end