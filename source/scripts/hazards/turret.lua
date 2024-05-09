local pd <const> = playdate
local gfx <const> = pd.graphics

local audioManager <const> = AudioManager

local assets <const> = Assets

assets.preloadImage("images/hazards/turretProjectile")
assets.preloadImagetables({
    "images/hazards/turret",
    "images/hazards/projectileBreak"
})

local turretFrameTime = 80 -- ms

class('Turret').extends(Hazard)

function Turret:init(x, y, entity)
    Turret.super.init(self, x, y)

    local fields = entity.fields
    self.xSpeed, self.ySpeed = fields.xSpeed, fields.ySpeed
    local time = fields.time
    local startDelay = fields.startDelay

    local turretImagetable = assets.getImagetable("images/hazards/turret")
    self:setImage(turretImagetable[1])
    self.curFrame = 1

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
    if self.stopped then
        return
    end

    local animationLoop = self.animationLoop
    if animationLoop then
        if animationLoop:isValid() and self.curFrame ~= animationLoop.frame then
            self.curFrame = animationLoop.frame
            self:setImage(animationLoop:image())
        else
            audioManager.play(audioManager.sfx.shoot)
            Projectile(self.projectileX, self.projectileY, self.xSpeed, self.ySpeed)
            local turretImagetable = assets.getImagetable("images/hazards/turret")
            self:setImage(turretImagetable[1])
            self.animationLoop = nil
        end
    end
end

class('Projectile').extends(gfx.sprite)

function Projectile:init(x, y, xSpeed, ySpeed)
    self.xSpeed = xSpeed
    self.ySpeed = ySpeed

    local projectileImage = assets.getImage("images/hazards/turretProjectile")
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
            local projectileBreakImageTable = assets.getImagetable("images/hazards/projectileBreak")
            Utilities.animatedSprite(self.x, self.y, projectileBreakImageTable, 20, false)
            self:remove()
        end
    end
end
