local pd <const> = playdate
local gfx <const> = pd.graphics

local audioManager <const> = AudioManager

local boxImage = gfx.image.new("images/levels/box")
local medBoxImage = gfx.image.new("images/levels/mediumBox")

local boxImages = {
    [1] = {
        [1] = boxImage
    },
    [2] = {
        [2] = medBoxImage
    }
}

local function getBoxImage(width, height)
    local tileSize = 16
    local tileWidth, tileHeight = width / tileSize, height / tileSize
    local heightDict = boxImages[tileWidth]
    if heightDict then
        local image = heightDict[tileHeight]
        if image then
            return image
        end
    else
        heightDict = {}
        boxImages[tileWidth] = heightDict
    end
    local image = gfx.image.new(width, height)
    gfx.pushContext(image)
        for x=0,width-tileSize,tileSize do
            for y=0,height-tileSize,tileSize do
                boxImage:draw(x, y)
            end
        end
    gfx.popContext()
    heightDict[tileHeight] = image
    return image
end

class('Block').extends(Hazard)

function Block:init(x, y, entity)
    Block.super.init(self, x, y)

    self.width = entity.size.width
    self.height = entity.size.height
    local fields = entity.fields
    self.xSpeed = fields.xSpeed * (30 / 1000)
    self.ySpeed = fields.ySpeed * (30 / 1000)

    local blockImage = getBoxImage(self.width, self.height)
    self:setImage(blockImage)

    self:setCollideRect(0, 0, blockImage:getSize())
    self:setCollidesWithGroups({TAGS.player, TAGS.hazard, TAGS.wall})
end

function Block:collisionResponse(other)
    if other:getTag() == TAGS.player then
        return gfx.sprite.kCollisionTypeOverlap
    end
    return gfx.sprite.kCollisionTypeBounce
end

function Block:updateHazard(dt)
    if self.stopped then
       return
    end

    local _actualX, _actualY, collisions, length = self:moveWithCollisions(self.x + self.xSpeed * dt, self.y + self.ySpeed * dt)

    local bounceNormal
    local bounceCollision = false
    for i=1,length do
        local collision = collisions[i]
        local collisionSprite = collision.other
        local collisionTag = collisionSprite:getTag()
        bounceNormal = collision.normal
        if collisionTag == TAGS.player then
            collisionSprite:reset()
        end

        if collisionTag == TAGS.hazard then
            bounceCollision = true
            collisionSprite:bounce()
        elseif collisionTag == TAGS.wall then
            bounceCollision = true
        end
    end

    if bounceCollision then
        audioManager.play(audioManager.sfx.bounce)
        if bounceNormal.x ~= 0 then
            self.xSpeed = -self.xSpeed
        end
        if bounceNormal.y ~= 0 then
            self.ySpeed = -self.ySpeed
        end
    end
end

function Block:bounce()
    self.ySpeed = -self.ySpeed
    self.xSpeed = -self.xSpeed
end