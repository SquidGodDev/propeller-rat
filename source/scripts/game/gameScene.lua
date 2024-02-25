local pd <const> = playdate
local gfx <const> = playdate.graphics

local ldtk <const> = LDtk

local usePrecomputedLevels = not pd.isSimulator

ldtk.load("data/world.ldtk", usePrecomputedLevels)

if pd.isSimulator then
    ldtk.export_to_lua_files()
end

class('GameScene').extends()

function GameScene:init()
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    self.curLevelNum = CUR_LEVEL
    self:setUpLevel()

    self.transitionSprite = gfx.sprite.new()
    self.transitionSprite:moveTo(200, 120)
    self.transitionSprite:setZIndex(Z_INDEXES.transition)
    self.transitionSprite:setIgnoresDrawOffset(true)
    self.transitionSprite:add()
end

function GameScene:update()
    -- Nothing
end

function GameScene:nextLevel()
    local levelCount = ldtk.get_level_count()
    self.curLevelNum = math.ringInt(self.curLevelNum + 1, 1, levelCount)
    CUR_LEVEL = self.curLevelNum
    if self.curLevelNum <= levelCount then
        self:startLevelTransition()
    end
end

function GameScene:clearLevel()
    gfx.setDrawOffset(0, 0)
    local allTimers = pd.timer.allTimers()
    for _, timer in ipairs(allTimers) do
        timer:remove()
    end
    gfx.sprite.removeAll()
    self.transitionSprite:add()
end

function GameScene:setUpLevel()
    self.curLevel = Level(self.curLevelNum)
    local startX, startY = self.curLevel:getStartPos()
    self.player = Player(self, startX, startY, self.curLevel:getLevelImage())
end

function GameScene:startLevelTransition()
    self.transitionSprite:add()
    local playerX, playerY = self.player:getScreenPosition()
    local transitionTime = 700
    local startRadius, endRadius = 0, 500
    local transitionTimer = pd.timer.new(transitionTime, startRadius, endRadius, pd.easingFunctions.inCubic)
    transitionTimer.updateCallback = function()
        local transitionImage = gfx.image.new(400, 240)
        gfx.pushContext(transitionImage)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(playerX, playerY, transitionTimer.value)
        gfx.popContext()
        self.transitionSprite:setImage(transitionImage)
    end

    transitionTimer.timerEndedCallback = function()
        self:clearLevel()
        self:setUpLevel()

        playerX, playerY = self.player:getScreenPosition()
        transitionTimer = pd.timer.new(transitionTime, startRadius, endRadius)
        transitionTimer.updateCallback = function()
            local transitionImage = gfx.image.new(400, 240, gfx.kColorWhite)
            local transitionMask = gfx.image.new(400, 240, gfx.kColorWhite)
            gfx.pushContext(transitionMask)
                gfx.setColor(gfx.kColorBlack)
                gfx.fillCircleAtPoint(playerX, playerY, transitionTimer.value)
            gfx.popContext()
            transitionImage:setMaskImage(transitionMask)
            self.transitionSprite:setImage(transitionImage)
        end

        transitionTimer.timerEndedCallback = function()
            self.transitionSprite:remove()
        end
    end
end