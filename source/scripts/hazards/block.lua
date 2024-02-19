local pd <const> = playdate
local gfx <const> = pd.graphics

class('Block').extends(Hazard)

function Block:init(x, y, entity)
    Block.super.init(self, x, y)

    self.width = entity.size.width
    self.height = entity.size.height
    local fields = entity.fields
    self.xSpeed = fields.xSpeed
    self.ySpeed = fields.ySpeed

    local cornerRadius = 2
    local blockImage = gfx.image.new(self.width, self.height)
    gfx.pushContext(blockImage)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(0, 0, self.width, self.height, cornerRadius)
    gfx.popContext()
    self:setImage(blockImage)

    self:setCollideRect(0, 0, blockImage:getSize())
end

function Block:update()
    local _actualX, _actualY, collisions, length = self:moveWithCollisions(self.x + self.xSpeed, self.y + self.ySpeed)

    for i=1,length do
        local collisionSprite = collisions[i].other
        local collisionTag = collisionSprite:getTag()
        if collisionTag == TAGS.player then
            collisionSprite:reset()
        end
    end

    if self.xSpeed ~= 0 then
        local speedSign = math.sign(self.xSpeed)
        if self.levelImage:sample(self.x + speedSign * self.width / 2, self.y) ~= gfx.kColorClear then
            self.xSpeed = -self.xSpeed
        end
    end
    if self.ySpeed ~= 0 then
        local speedSign = math.sign(self.ySpeed)
        if self.levelImage:sample(self.x, self.y + speedSign * self.height / 2) ~= gfx.kColorClear then
            self.ySpeed = -self.ySpeed
        end
    end
end