local pd <const> = playdate
local gfx <const> = pd.graphics

class('Hazard').extends(gfx.sprite)

function Hazard:init(x, y)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.hazard)
    self:setGroups(TAGS.hazard)
    self:setCollidesWithGroups({TAGS.player})
end

function Hazard:setLevelImage(levelImage)
    self.levelImage = levelImage
end

function Hazard:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
end