local pd <const> = playdate
local gfx <const> = pd.graphics

local levelImage = gfx.image.new("images/levels/level1")

class('Level1').extends(Level)

function Level1:init()
    Level1.super.init(self, 32, 60, 296, 60, levelImage)
end
