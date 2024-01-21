local pd <const> = playdate
local gfx <const> = pd.graphics

class('Block').extends(gfx.sprite)

function Block:init(x, y, width, height, xSpeed, ySpeed, levelImage)
    self.levelImage = levelImage
    self.width = width
    self.height = height
    self.xSpeed = xSpeed
    self.ySpeed = ySpeed

    local cornerRadius = 2
    local blockImage = gfx.image.new(width, height)
    gfx.pushContext(blockImage)
        gfx.fillRoundRect(0, 0, width, height, cornerRadius)
    gfx.popContext()
    self:setImage(blockImage)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.hazard)
    self:setGroups(TAGS.hazard)
    self:setCollidesWithGroups({TAGS.player})
    self:setCollideRect(0, 0, blockImage:getSize())
end

function Block:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
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
        if self.levelImage:sample(self.x + speedSign * self.width / 2, self.y) == gfx.kColorBlack then
            self.xSpeed = -self.xSpeed
        end
    end
    if self.ySpeed ~= 0 then
        local speedSign = math.sign(self.ySpeed)
        if self.levelImage:sample(self.x, self.y + speedSign * self.height / 2) == gfx.kColorBlack then
            self.ySpeed = -self.ySpeed
        end
    end
end