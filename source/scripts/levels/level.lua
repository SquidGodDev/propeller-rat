local pd <const> = playdate
local gfx <const> = pd.graphics

class('Level').extends(gfx.sprite)

function Level:init(startX, startY, endX, endY, image)
    self.startX = startX
    self.startY = startY
    self:setImage(image)
    self:setCenter(0, 0)
    self:moveTo(0, 0)
    self:add()

    LevelEnd(endX, endY)
end

function Level:getStartPos()
    return self.startX, self.startY
end

function Level:getLevelImage()
    return self:getImage()
end


local levelEndSize = 16
local levelEndImage = gfx.image.new(levelEndSize, levelEndSize)
gfx.pushContext(levelEndImage)
    gfx.drawCircleInRect(0, 0, levelEndSize, levelEndSize)
gfx.popContext()

class('LevelEnd').extends(gfx.sprite)

function LevelEnd:init(x, y)
    self:setImage(levelEndImage)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.levelEnd)
    self:setGroups(TAGS.levelEnd)
    self:setCollidesWithGroups({TAGS.player})
    self:setCollideRect(0, 0, levelEndImage:getSize())
end

function LevelEnd:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
end