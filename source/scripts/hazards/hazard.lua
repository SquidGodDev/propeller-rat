local pd <const> = playdate
local gfx <const> = pd.graphics

HazardManager = {}
class('HazardManager').extends()

function HazardManager:init()
    self.hazards = {}
end

function HazardManager:addHazard(hazard)
    table.insert(self.hazards, hazard)
end

function HazardManager:update(dt)
    for i=1, #self.hazards do
        local hazard = self.hazards[i]
        hazard:updateHazard(dt)
    end
end

function HazardManager:stop()
    for i=1, #self.hazards do
        local hazard = self.hazards[i]
        hazard:stop()
    end
end

Hazard = {}
class('Hazard').extends(gfx.sprite)

function Hazard:init(x, y)
    self:setZIndex(Z_INDEXES.hazard)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.hazard)
    self:setGroups(TAGS.hazard)
    self:setCollidesWithGroups({TAGS.player, TAGS.hazard})

    self.stopped = false
end

function Hazard:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
end

function Hazard:stop()
    self.stopped = true
end
