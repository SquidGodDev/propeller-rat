local pd <const> = playdate
local gfx <const> = pd.graphics

local levelEndImagetable = gfx.imagetable.new("images/levels/teleporter")
local idleStartFrame = 1
local idleEndFrame = 4
local teleportStartFrame = 5
local teleportEndFrame = #levelEndImagetable

class('LevelEnd').extends(Pickup)

function LevelEnd:init(x, y)
    LevelEnd.super.init(self, x, y)
    self:setImage(levelEndImagetable[1])
    self:setCollideRect(16, 13, 16, 22)
    self.animationLoop = gfx.animation.loop.new(100, levelEndImagetable, true)
    self.animationLoop.startFrame = idleStartFrame
    self.animationLoop.endFrame = idleEndFrame
end

function LevelEnd:update()
    self:setImage(self.animationLoop:image())
    if not self.animationLoop:isValid() then
        self.animationLoop = gfx.animation.loop.new(100, levelEndImagetable, true)
        self.animationLoop.startFrame = idleStartFrame
        self.animationLoop.endFrame = idleEndFrame
    end
end

function LevelEnd:pickup(player)
    player:nextLevel(self.x, self.y)
    self.animationLoop = gfx.animation.loop.new(100, levelEndImagetable, false)
    self.animationLoop.startFrame = teleportStartFrame
    self.animationLoop.endFrame = teleportEndFrame
end