local pd <const> = playdate
local gfx <const> = pd.graphics

local levelEndSize = 16
local levelEndImage = gfx.image.new(levelEndSize, levelEndSize)
gfx.pushContext(levelEndImage)
    gfx.setColor(gfx.kColorWhite)
    gfx.drawCircleInRect(0, 0, levelEndSize, levelEndSize)
gfx.popContext()

class('LevelEnd').extends(Pickup)

function LevelEnd:init(x, y)
    LevelEnd.super.init(self, x, y)
    self:setImage(levelEndImage)
    self:setCollideRect(0, 0, levelEndImage:getSize())
end

function LevelEnd:pickup(player)
    player:nextLevel()
end