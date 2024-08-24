local pd <const> = playdate
local gfx <const> = pd.graphics

Pickup = {}
class('Pickup').extends(gfx.sprite)

function Pickup:init(x, y)
    self:moveTo(x, y)
    self:add()

    self:setZIndex(Z_INDEXES.pickup)
    self:setTag(TAGS.pickup)
    self:setGroups(TAGS.pickup)
    self:setCollidesWithGroups({TAGS.player})
end

function Pickup:pickup(player)
    -- Override
end