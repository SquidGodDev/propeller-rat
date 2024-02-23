local pd <const> = playdate
local gfx <const> = pd.graphics

class('Turret').extends(Hazard)

function Turret:init(x, y, entity)
    Turret.super.init(self, x, y)

    local fields = entity.fields
    local xSpeed, ySpeed = fields.xSpeed, fields.ySpeed
    local diameter = fields.projectileDiameter
    local time = fields.time
    local startDelay = fields.startDelay

    local turretDiameter = 8
    local turretImage = gfx.image.new(turretDiameter, turretDiameter)
    gfx.pushContext(turretImage)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawCircleInRect(0, 0, turretDiameter, turretDiameter)
    gfx.popContext()
    self:setImage(turretImage)

    local projectileImage = gfx.image.new(diameter, diameter)
    gfx.pushContext(projectileImage)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleInRect(0, 0, diameter, diameter)
    gfx.popContext()

    local turretRadius = turretDiameter / 2
    local projectileX = x + turretRadius + turretRadius * math.zeroSign(xSpeed)
    local projectileY = y + turretRadius + turretRadius * math.zeroSign(ySpeed)

    pd.timer.new(startDelay, function()
        local turretTimer = pd.timer.new(time, function()
            Projectile(projectileX, projectileY, xSpeed, ySpeed, projectileImage, self.levelImage)
        end)

        turretTimer.repeats = true
    end)

end

class('Projectile').extends(gfx.sprite)

function Projectile:init(x, y, xSpeed, ySpeed, projectileImage, levelImage)
    self.xSpeed = xSpeed
    self.ySpeed = ySpeed
    self.levelImage = levelImage

    self:setCenter(0.5, 0.5)
    self:setImage(projectileImage)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.projectile)
    self:setGroups(TAGS.projectile)
    self:setCollidesWithGroups({TAGS.player, TAGS.hazard})
    self:setCollideRect(0, 0, projectileImage:getSize())
end

function Projectile:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
end

function Projectile:update()
    local _actualX, _actualY, collisions, length = self:moveWithCollisions(self.x + self.xSpeed, self.y + self.ySpeed)

    for i=1,length do
        local collisionSprite = collisions[i].other
        local collisionTag = collisionSprite:getTag()
        if collisionTag == TAGS.player then
            collisionSprite:reset()
        end

        if collisionTag == TAGS.hazard then
            self:remove()
        end
    end

    if self.levelImage:sample(self.x, self.y) ~= gfx.kColorClear then
        self:remove()
    end
end