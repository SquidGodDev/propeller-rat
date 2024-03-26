local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets

local titleFont = gfx.font.new("data/fonts/m6x11-26")

local ldtk <const> = LDtk

local usePrecomputedLevels = not pd.isSimulator

ldtk.load("data/world.ldtk", usePrecomputedLevels)

if not usePrecomputedLevels then
    ldtk.export_to_lua_files()
end

assets.preloadImage("images/decoration/stars")
assets.preloadImagetable("images/decoration/planet")

class('GameScene').extends()

function GameScene:init(showTitle)
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    self.curLevelNum = CUR_LEVEL
    self:setUpLevel(showTitle)

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

function GameScene:setUpLevel(showTitle)
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

    if showTitle then
        local titleDelay = 500
        pd.timer.performAfterDelay(titleDelay, function()
            self:showLevelTitle()
        end)
    else
        self.player:enable()
    end
end

function GameScene:showLevelTitle()
    local levelName = ldtk.get_custom_data("Level_" .. self.curLevelNum, "Name")

    local titleWidth, titleHeight = 400, 54
    local titleImage = gfx.image.new(titleWidth, titleHeight, gfx.kColorWhite)
    gfx.pushContext(titleImage)
        gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
        titleFont:drawTextAligned(levelName --[[@as string]], titleWidth/2, 16, kTextAlignment.center)
    gfx.popContext()

    local addToUiQueue = SceneManager.addToUiQueue
    local titleTime = 500
    local titleTimer = pd.timer.new(titleTime, 0, titleWidth, pd.easingFunctions.inOutCubic)
    addToUiQueue({
        timer = titleTimer,
        update = function(drawObject)
            gfx.setScreenClipRect(0, 0, drawObject.timer.value, 240)
            titleImage:drawIgnoringOffset(0, 120 - titleHeight / 2)
            gfx.clearClipRect()
            if drawObject.timer.timeLeft <= 0 then
                titleTimer = pd.timer.new(titleTime)
                addToUiQueue({
                    timer = titleTimer,
                    update = function(drawObject)
                        titleImage:drawIgnoringOffset(0, 120 - titleHeight / 2)
                        if drawObject.timer.timeLeft <= 0 then
                            return true
                        end
                    end
                })
                titleTimer.timerEndedCallback = function()
                    titleTimer = pd.timer.new(titleTime, titleWidth, 0, pd.easingFunctions.inOutCubic)
                    addToUiQueue({
                        timer = titleTimer,
                        update = function(drawObject)
                            if drawObject.timer.timeLeft <= 0 then
                                return true
                            end
                            local timer = drawObject.timer
                            gfx.setScreenClipRect(titleWidth - timer.value, 0, timer.value, 240)
                            titleImage:drawIgnoringOffset(0, 120 - titleHeight / 2)
                            gfx.clearClipRect()
                        end
                    })
                    titleTimer.timerEndedCallback = function()
                        self.player:enable()
                    end
                end
                return true
            end
        end
    })
end