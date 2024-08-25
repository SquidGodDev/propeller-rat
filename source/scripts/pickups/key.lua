local pd <const> = playdate
local gfx <const> = pd.graphics

local assets <const> = Assets
local audioManager <const> = AudioManager

assets.preloadImage("images/levels/key")
assets.preloadImagetable("images/levels/pickupParticles")

Key = {}
class('Key').extends(Pickup)

function Key:init(x, y)
    Key.super.init(self, x, y)

    local keyImage = assets.getImage("images/levels/key")
    self:setImage(keyImage)
    local hitboxBuffer = 4
    local keyWidth, keyHeight = self:getSize()
    self:setCollideRect(-hitboxBuffer, -hitboxBuffer, keyWidth + hitboxBuffer*2, keyHeight + hitboxBuffer*2)
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