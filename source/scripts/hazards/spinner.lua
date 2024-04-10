local pd <const> = playdate
local gfx <const> = pd.graphics

local assets <const> = Assets

assets.preloadImagetable("images/hazards/spinner")

class('Spinner').extends(Hazard)

function Spinner:init(x, y, entity)
    Spinner.super.init(self, x, y)

    local fields = entity.fields
    local speed = fields.speed
    local spinnerImagetable = assets.getImagetable("images/hazards/spinner")
    self.animationLoop = gfx.animation.loop.new(speed, spinnerImagetable, true)
    self.curFrame = 1
    self:setCenter(0.5, 0.5)
    self:setCollideRect(0, 0, spinnerImagetable[1]:getSize())
    self:setImage(spinnerImagetable[1])
end

function Spinner:update()
    if self.stopped then
        return
    end

    if self.curFrame ~= self.animationLoop.frame then
        self.curFrame = self.animationLoop.frame
        self:setImage(self.animationLoop:image())
    end

    local _actualX, _actualY, collisions, length = self:moveWithCollisions(self.x, self.y)
    if length > 0 then
        local player = collisions[1].other
        if player:getTag() == TAGS.player and self:alphaCollision(player) then
            player:reset()
        end
    end
end