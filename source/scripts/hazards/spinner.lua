local pd <const> = playdate
local gfx <const> = pd.graphics

local spinnerImagetable = gfx.imagetable.new("images/hazards/spinner")

class('Spinner').extends(Hazard)

function Spinner:init(x, y)
    Spinner.super.init(self, x, y)

    self.angle = 1
    self.maxAngle = 90

    self:setCenter(0.5, 0.5)
    self:setCollideRect(0, 0, spinnerImagetable[1]:getSize())
end

function Spinner:update()
    self:setImage(spinnerImagetable[self.angle])
    self.angle = math.ringInt(self.angle + 1, 1, self.maxAngle)

    local _actualX, _actualY, collisions, length = self:moveWithCollisions(self.x, self.y)
    if length > 0 then
        local player = collisions[1].other
        if player:getTag() == TAGS.player and self:alphaCollision(player) then
            player:reset()
        end
    end
end