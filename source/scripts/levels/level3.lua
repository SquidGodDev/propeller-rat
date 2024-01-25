local pd <const> = playdate
local gfx <const> = pd.graphics

local levelImage = gfx.image.new("images/levels/level3")

class('Level3').extends(Level)

function Level3:init()
    Level3.super.init(self, 32, 60, 296, 60, levelImage)

    Block(96, 16, 16, 16, 0, 1, levelImage)
    Block(96 + 48, 80, 16, 16, 0, -1, levelImage)
    Block(96 + 48 * 2, 16, 16, 16, 0, 1, levelImage)
    Block(96 + 48 * 3, 80, 16, 16, 0, -1, levelImage)
end
