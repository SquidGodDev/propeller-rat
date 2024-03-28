local pd <const> = playdate
local gfx <const> = pd.graphics

local assets <const> = Assets
local audioManager <const> = AudioManager

assets.preloadImage("images/levels/teleporterDisabled")
assets.preloadImagetable("images/levels/teleporter")

local idleStartFrame = 1
local idleEndFrame = 4
local teleportStartFrame = 5
local teleportEndFrame = 20

class('LevelEnd').extends(Pickup)

function LevelEnd:init(x, y)
    LevelEnd.super.init(self, x, y)
    local levelEndDisabled = assets.getImage("images/levels/teleporterDisabled")
    self:setImage(levelEndDisabled)
    self:setCollideRect(16, 13, 16, 22)

    self.keyCount = 0
end

function LevelEnd:update()
    if self.animationLoop then
        self:setImage(self.animationLoop:image())
        if not self.animationLoop:isValid() then
            self:enable()
        end
    end
end

function LevelEnd:enable()
    local levelEndImagetable = assets.getImagetable("images/levels/teleporter")
    self:setImage(levelEndImagetable[1])
    self.animationLoop = gfx.animation.loop.new(100, levelEndImagetable, true)
    self.animationLoop.startFrame = idleStartFrame
    self.animationLoop.endFrame = idleEndFrame
end

function LevelEnd:setKeyCount(count)
    self.keyCount = count
    if count <= 0 then
        self:enable()
    end
end

function LevelEnd:keyPickup()
    self.keyCount -= 1
    if self.keyCount <= 0 then
        audioManager.play(audioManager.sfx.teleporterPowerUp)
        self:enable()
    end
end

function LevelEnd:pickup(player)
    if self.keyCount > 0 then
        return
    end
    audioManager.play(audioManager.sfx.teleport)
    player:nextLevel(self.x, self.y)
    local levelEndImagetable = assets.getImagetable("images/levels/teleporter")
    self.animationLoop = gfx.animation.loop.new(100, levelEndImagetable, false)
    self.animationLoop.startFrame = teleportStartFrame
    self.animationLoop.endFrame = teleportEndFrame
end