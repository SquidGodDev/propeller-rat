local pd <const> = playdate
local gfx <const> = pd.graphics

class('Pickup').extends(gfx.sprite)

function Pickup:init(x, y)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.pickup)
    self:setGroups(TAGS.pickup)
    self:setCollidesWithGroups({TAGS.player})
end

function Pickup:pickup(player)
    player:nextLevel()
end