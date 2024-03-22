local pd <const> = playdate
local gfx <const> = pd.graphics

local audioManager <const> = AudioManager

local querySpritesInRect = gfx.sprite.querySpritesInRect

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
    local xSpeed, ySpeed = fields.xSpeed, fields.ySpeed
    local time = fields.time
    local startDelay = fields.startDelay

    local turretImagetable = assets.getImagetable("images/hazards/turret")
    self:setImage(turretImagetable[1])

    self.projectileX = x
    self.projectileY = y

    self.projectileFired = false

    local projectileImage = assets.getImage("images/hazards/turretProjectile")
    local width, height = projectileImage:getSize()
    local halfWidth, halfHeight = width / 2, height / 2

    local projectileBreakImageTable = assets.getImagetable("images/hazards/projectileBreak")
    self.projectileUpdate = function(projectile)
        local projectileX, projectileY = projectile.x, projectile.y
        projectileX += xSpeed
        projectileY += ySpeed
        projectile.x = projectileX
        projectile.y = projectileY
        local sprites = querySpritesInRect(projectileX - halfWidth, projectileY - halfHeight, width, height)
        for i=1,#sprites do
            local sprite = sprites[i]
            local collisionTag = sprite:getTag()
            if collisionTag == TAGS.player then
                sprite:reset()
            end

            if collisionTag == TAGS.hazard or collisionTag == TAGS.wall then
                audioManager.play(audioManager.sfx.smash)
                Utilities.animatedSprite(projectileX, projectileY, projectileBreakImageTable, 20, false)
                return true -- Remove
            end
        end
        projectileImage:drawAnchored(projectileX, projectileY, 0.5, 0.5)
    end

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
            audioManager.play(audioManager.sfx.shoot)
            SceneManager.addToDrawQueue({
                x = self.projectileX,
                y = self.projectileY,
                update = self.projectileUpdate
            })
            local turretImagetable = assets.getImagetable("images/hazards/turret")
            self:setImage(turretImagetable[1])
            self.animationLoop = nil
        end
    end
end