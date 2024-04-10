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
    self.xSpeed = fields.xSpeed
    self.ySpeed = fields.ySpeed

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

function Block:update()
    if self.stopped then
       return
    end

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
        elseif collisionTag == TAGS.wall then
            bounceCollision = true
        end
    end

    if bounceCollision then
        audioManager.play(audioManager.sfx.bounce)
        self.xSpeed = -self.xSpeed
        self.ySpeed = -self.ySpeed
    end
end

function Block:bounce()
    self.ySpeed = -self.ySpeed
    self.xSpeed = -self.xSpeed
end