local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets

local titleFont = gfx.font.new("data/fonts/m6x11-12")

local ldtk <const> = LDtk

local usePrecomputedLevels = not pd.isSimulator

ldtk.load("data/world.ldtk", usePrecomputedLevels)

if not usePrecomputedLevels then
    ldtk.export_to_lua_files()
end

assets.preloadImage("images/decoration/stars")
assets.preloadImagetable("images/decoration/planet")

class('GameScene').extends()

function GameScene:init()
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    self.curLevelNum = CUR_LEVEL
    self:setUpLevel()

    self.titleSprite = gfx.sprite.new()
    self.titleSprite:moveTo(200, 120)
    self.titleSprite:setZIndex(500)
    self.titleSprite:setIgnoresDrawOffset(true)
    self.titleSprite:add()

    local systemMenu = pd.getSystemMenu()
    systemMenu:addMenuItem("Reset", function()
        if self.player then
            self.player:reset()
        end
    end)
    systemMenu:addMenuItem("Level Select", function()
        if self.player then
            if self.player:isDisabled() then
                return
            end
            self.player:disable()
        end
        SceneManager.switchScene(LevelSelectScene)
    end)
end

function GameScene:update()
    -- Nothing
end

function GameScene:nextLevel()
    local levelCount = ldtk.get_level_count()
    self.curLevelNum = math.ringInt(self.curLevelNum + 1, 1, levelCount)
    CUR_LEVEL = self.curLevelNum
    if self.curLevelNum <= levelCount then
        local playerX, playerY = self.player:getScreenPosition()
        SceneManager.switchScene(GameScene, playerX, playerY, true)
    end
end

function GameScene:clearLevel()
    gfx.setDrawOffset(0, 0)
    local allTimers = pd.timer.allTimers()
    for _, timer in ipairs(allTimers) do
        timer:remove()
    end
    gfx.sprite.removeAll()
end

function GameScene:setUpLevel()
    local starsImage = Assets.getImage("images/decoration/stars")
    local stars = gfx.sprite.new(starsImage)
    stars:setIgnoresDrawOffset(true)
    stars:moveTo(200, 120)
    stars:add()

    local planet = Utilities.animatedSprite(365, 45, "images/decoration/planet", 100, true)
    planet:setIgnoresDrawOffset(true)

    self.curLevel = Level(self.curLevelNum)
    local startX, startY = self.curLevel:getStartPos()
    self.player = Player(self, startX, startY)

    self:showLevelTitle()

    self.player:enable()
end

function GameScene:showLevelTitle()
    local levelName = ldtk.get_custom_data("Level_" .. self.curLevelNum, "Name") or ""

    local titleX, titleY = 5, 5
    local titleSprite = gfx.sprite.spriteWithText(levelName, 100, 20, gfx.kColorClear, nil, nil, nil, titleFont)
    local _, titleHeight = titleSprite:getSize()
    titleSprite:setIgnoresDrawOffset(true)
    titleSprite:setCenter(0, 0)
    titleSprite:moveTo(titleX, -titleHeight)
    titleSprite:setZIndex(Z_INDEXES.ui)
    titleSprite:add()


    local startDelay = 500
    local titleTransitionTime = 700
    local titleShowTime = 2000
    pd.timer.performAfterDelay(startDelay, function()
        local titleTimer = pd.timer.new(titleTransitionTime, -titleHeight, titleY, pd.easingFunctions.outCubic)
        titleTimer.updateCallback = function(timer)
            titleSprite:moveTo(titleX, timer.value)
        end
        titleTimer.timerEndedCallback = function()
            pd.timer.performAfterDelay(titleShowTime, function()
                titleTimer = pd.timer.new(titleTransitionTime, titleSprite.y, -titleHeight, pd.easingFunctions.inCubic)
                titleTimer.updateCallback = function(timer)
                    titleSprite:moveTo(titleX, timer.value)
                end
                titleTimer.timerEndedCallback= function()
                    titleSprite:remove()
                end
            end)
        end
    end)
end