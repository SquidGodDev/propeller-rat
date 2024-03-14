local pd <const> = playdate
local gfx <const> = pd.graphics

local projectileImage = gfx.image.new("images/hazards/turretProjectile")
local turretImagetable = gfx.imagetable.new("images/hazards/turret")
local turretFrameTime = 80 -- ms
local turretWidth = turretImagetable[1]:getSize()
local turretRadius = turretWidth / 2

local projectileBreakImageTable = gfx.imagetable.new("images/hazards/projectileBreak")

class('Turret').extends(Hazard)

function Turret:init(x, y, entity)
    Turret.super.init(self, x, y)

    local fields = entity.fields
    self.xSpeed, self.ySpeed = fields.xSpeed, fields.ySpeed
    local time = fields.time
    local startDelay = fields.startDelay

    self:setImage(turretImagetable[1])

    self.projectileX = x
    self.projectileY = y

    self.projectileFired = false

    pd.timer.performAfterDelay(startDelay, function()
        local fireFunction = function ()
            self.animationLoop = gfx.animation.loop.new(turretFrameTime, turretImagetable, false)
            self.projectileFired = false
        end

        fireFunction()
        local turretTimer = pd.timer.new(time, fireFunction)

        turretTimer.repeats = true
    end)
end

function Turret:update()
    if self.animationLoop then
        if self.animationLoop:isValid() then
            self:setImage(self.animationLoop:image())
        else
            Projectile(self.projectileX, self.projectileY, self.xSpeed, self.ySpeed)
            self:setImage(turretImagetable[1])
            self.animationLoop = nil
        end
    end
end

class('Projectile').extends(gfx.sprite)

function Projectile:init(x, y, xSpeed, ySpeed)
    self.xSpeed = xSpeed
    self.ySpeed = ySpeed

    self:setZIndex(Z_INDEXES.projectile)
    self:setImage(projectileImage)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.projectile)
    self:setGroups(TAGS.projectile)
    self:setCollidesWithGroups({TAGS.player, TAGS.hazard, TAGS.wall})
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

        if collisionTag == TAGS.hazard or collisionTag == TAGS.wall then
            Utilities.animatedSprite(self.x, self.y, projectileBreakImageTable, 20, false)
            self:remove()
        end
    end
end