local pd <const> = playdate
local gfx <const> = playdate.graphics

local titleFont = gfx.font.new("data/fonts/m6x11-26")

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

    self.titleSprite = gfx.sprite.new()
    self.titleSprite:moveTo(200, 120)
    self.titleSprite:setZIndex(500)
    self.titleSprite:setIgnoresDrawOffset(true)
    self.titleSprite:add()
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

    local titleDelay = 200
    pd.timer.performAfterDelay(titleDelay, function()
        self:showLevelTitle()
    end)
end

function GameScene:startLevelTransition()
    local transitionTime = 700

    self.transitionSprite:add()
    local playerX, playerY = self.player:getScreenPosition()

    local startRadius, endRadius = 0, 500
    local transitionTimer = pd.timer.new(transitionTime, startRadius, endRadius, pd.easingFunctions.inCubic)
    transitionTimer.updateCallback = function(timer)
        local transitionImage = gfx.image.new(400, 240)
        gfx.pushContext(transitionImage)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(playerX, playerY, timer.value)
        gfx.popContext()
        self.transitionSprite:setImage(transitionImage)
    end

    transitionTimer.timerEndedCallback = function()
        self:clearLevel()
        self:setUpLevel()

        playerX, playerY = self.player:getScreenPosition()
        transitionTimer = pd.timer.new(transitionTime, startRadius, endRadius)
        transitionTimer.updateCallback = function(timer)
            local transitionImage = gfx.image.new(400, 240, gfx.kColorWhite)
            local transitionMask = gfx.image.new(400, 240, gfx.kColorWhite)
            gfx.pushContext(transitionMask)
                gfx.setColor(gfx.kColorBlack)
                gfx.fillCircleAtPoint(playerX, playerY, timer.value)
            gfx.popContext()
            transitionImage:setMaskImage(transitionMask)
            self.transitionSprite:setImage(transitionImage)
        end

        transitionTimer.timerEndedCallback = function()
            self.transitionSprite:setImage(nil)
            self.transitionSprite:remove()
        end
    end
end

function GameScene:showLevelTitle()
    self.titleSprite:add()
    local levelName = ldtk.get_custom_data("Level_" .. self.curLevelNum, "Name")

    local titleWidth, titleHeight = 400, 54
    local titleImage = gfx.image.new(titleWidth, titleHeight, gfx.kColorWhite)
    gfx.pushContext(titleImage)
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        titleFont:drawTextAligned(levelName --[[@as string]], titleWidth/2, 16, kTextAlignment.center)
    gfx.popContext()

    self.titleSprite:setImage(titleImage)
    self.titleSprite:setClipRect(0, 0, 0, titleHeight)

    local titleTime = 500
    local titleTimer = pd.timer.new(titleTime, 0, titleWidth, pd.easingFunctions.inOutCubic)
    titleTimer.updateCallback = function(timer)
        self.titleSprite:setClipRect(0, 0, timer.value, 240)
    end
    titleTimer.timerEndedCallback = function()
        self.titleSprite:clearClipRect()
        pd.timer.performAfterDelay(titleTime, function()
            titleTimer = pd.timer.new(titleTime, titleWidth, 0, pd.easingFunctions.inOutCubic)
            titleTimer.updateCallback = function(timer)
                self.titleSprite:setClipRect(titleWidth - timer.value, 0, timer.value, 240)
            end
            titleTimer.timerEndedCallback = function()
                self.player:enable()
                self.titleSprite:remove()
            end
        end)
    end
end