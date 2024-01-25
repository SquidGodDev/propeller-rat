local pd <const> = playdate
local gfx <const> = pd.graphics

local levelImage = gfx.image.new("images/levels/level2")

class('Level2').extends(Level)

function Level2:init()
    Level2.super.init(self, 42, 32, 168, 136, levelImage)
end
