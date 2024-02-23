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

function Block:collisionResponse()
    return gfx.sprite.kCollisionTypeBounce
end

function Block:update()
    local _actualX, _actualY, collisions, length = self:moveWithCollisions(self.x + self.xSpeed, self.y + self.ySpeed)

    local bounceCollision = false
    for i=1,length do
        local collisionSprite = collisions[i].other
        local collisionTag = collisionSprite:getTag()
        if collisionTag == TAGS.player then
            collisionSprite:reset()
        end

        if collisionTag == TAGS.hazard then
            bounceCollision = true
            collisionSprite:bounce()
        end
    end

    if self.xSpeed ~= 0 then
        if bounceCollision or self.levelImage:sample(self.x + (self.xSpeed > 0 and self.width or 0), self.y) ~= gfx.kColorClear then
            self.xSpeed = -self.xSpeed
        end
    end
    if self.ySpeed ~= 0 then
        if bounceCollision or self.levelImage:sample(self.x, self.y + (self.ySpeed > 0 and self.height or 0)) ~= gfx.kColorClear then
            self.ySpeed = -self.ySpeed
        end
    end
end

function Block:bounce()
    self.ySpeed = -self.ySpeed
    self.xSpeed = -self.xSpeed
end