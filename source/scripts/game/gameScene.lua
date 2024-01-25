local pd <const> = playdate
local gfx <const> = playdate.graphics

local levels = {Level1, Level2, Level3, Level1, Level2, Level3}

class('GameScene').extends()

function GameScene:init()
    self.curLevelNum = 1
    self:setUpLevel()

    self.transitionSprite = gfx.sprite.new()
    self.transitionSprite:moveTo(200, 120)
    self.transitionSprite:setZIndex(Z_INDEXES.transition)
    self.transitionSprite:setIgnoresDrawOffset(true)
    self.transitionSprite:add()

    -- Todo:
    -- Transition from one level to next
    -- Test enter new level pickup
end

function GameScene:update()
    -- Nothing
end

function GameScene:nextLevel()
    self.curLevelNum += 1
    if self.curLevelNum <= #levels then
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
    local levelObject = levels[self.curLevelNum]

    self.curLevel = levelObject()
    local startX, startY = self.curLevel:getStartPos()
    self.player = Player(self, startX, startY, self.curLevel:getLevelImage())
end

function GameScene:startLevelTransition()
    local playerX, playerY = self.player:getScreenPosition()
    local transitionTime = 700
    local startRadius, endRadius = 0, 500
    local transitionTimer = pd.timer.new(transitionTime, startRadius, endRadius, pd.easingFunctions.inCubic)
    transitionTimer.updateCallback = function()
        local transitionImage = gfx.image.new(400, 240)
        gfx.pushContext(transitionImage)
            gfx.setColor(gfx.kColorBlack)
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
            local transitionImage = gfx.image.new(400, 240, gfx.kColorBlack)
            local transitionMask = gfx.image.new(400, 240, gfx.kColorWhite)
            gfx.pushContext(transitionMask)
                gfx.setColor(gfx.kColorBlack)
                gfx.fillCircleAtPoint(playerX, playerY, transitionTimer.value)
            gfx.popContext()
            transitionImage:setMaskImage(transitionMask)
            self.transitionSprite:setImage(transitionImage)
        end
    end
end