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

local crankIndicator = pd.ui.crankIndicator

local baseLevels = {}
local levelCount = ldtk.get_level_count()
for levelIndex=1,levelCount do
    local levelName = "Level_" .. levelIndex
    local levelDepth = ldtk.get_depth(levelName)
    local baseLevel = baseLevels[levelDepth+1]
    if not baseLevel then
        baseLevels[levelDepth+1] = levelIndex
    end
end

local levelEndPopupImage = gfx.image.new("images/levels/ui/levelEndPopup")
local popupWidth, popupHeight = levelEndPopupImage:getSize()
local popupX, popupY = 200 - popupWidth / 2, 120 - popupHeight / 2
local selectorBaseX, selectorBaseY = popupX + 57, popupY + 68
local selectorGap = 41

local planetImagetables = PLANET_IMAGETABLES

assets.preloadImages({"images/decoration/stars"})
assets.preloadImagetables({"images/levels/ui/selector"})

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
    if self.popupActive then
        if pd.buttonJustPressed(pd.kButtonLeft) then
            self.levelEndOption = math.clamp(self.levelEndOption - 1, 1, 3)
            self.selectorSprite:moveTo(selectorBaseX + (self.levelEndOption - 1) * selectorGap, selectorBaseY)
        elseif pd.buttonJustPressed(pd.kButtonRight) then
            self.levelEndOption = math.clamp(self.levelEndOption + 1, 1, 3)
            self.selectorSprite:moveTo(selectorBaseX + (self.levelEndOption - 1) * selectorGap, selectorBaseY)
        elseif pd.buttonJustPressed(pd.kButtonA) then
            self.popupActive = false
            if self.levelEndOption == 1 then
                SceneManager.switchScene(LevelSelectScene)
            elseif self.levelEndOption == 2 then
                SceneManager.switchScene(GameScene)
            elseif self.levelEndOption then
                self:nextLevel()
            end
        end
    end

    if pd.isCrankDocked() then
        crankIndicator:draw()
    end
end

function GameScene:levelEnd()
    self.curLevel:stopLevelHazards()

    self.popupActive = false
    self.levelEndOption = 3

    local popupSprite = gfx.sprite.new(levelEndPopupImage)
    popupSprite:setIgnoresDrawOffset(true)
    popupSprite:setZIndex(Z_INDEXES.ui)
    popupSprite:setCenter(0, 0)
    popupSprite:moveTo(popupX, popupY + 240)
    popupSprite:add()
    local popupTimer = pd.timer.new(900, popupSprite.y, popupY, pd.easingFunctions.outBack)
    popupTimer.updateCallback = function(timer)
        popupSprite:moveTo(popupX, timer.value)
    end

    local selectorImagetable = assets.getImagetable("images/levels/ui/selector")
    local selectorSprite = Utilities.animatedSprite(selectorBaseX + selectorGap * 2, selectorBaseY + 240, selectorImagetable, 50, true)
    selectorSprite:setIgnoresDrawOffset(true)
    selectorSprite:setZIndex(Z_INDEXES.ui)
    selectorSprite:setCenter(0, 0)
    self.selectorSprite = selectorSprite
    pd.timer.performAfterDelay(200, function()
        self.popupActive = true
        local selectorTimer = pd.timer.new(900, selectorSprite.y, selectorBaseY, pd.easingFunctions.outBack)
        selectorTimer.updateCallback = function(timer)
            selectorSprite:moveTo(selectorSprite.x, timer.value)
        end
    end)
end

function GameScene:nextLevel()
    self.curLevelNum = self.curLevelNum + 1
    if self.curLevelNum <= levelCount then
        if SELECTED_WORLD < #baseLevels then
            local nextWorldStartLevel = baseLevels[SELECTED_WORLD + 1]
            if self.curLevelNum >= nextWorldStartLevel then
                SELECTED_WORLD += 1
                SceneManager.switchScene(WorldSelectScene, playerX, playerY)
                return
            end
        end
        CUR_LEVEL = self.curLevelNum
        local playerX, playerY = self.player:getScreenPosition()
        SceneManager.switchScene(GameScene, playerX, playerY)
    else
        SceneManager.switchScene(WorldSelectScene, playerX, playerY)
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

    local planetImagetable = planetImagetables[SELECTED_WORLD]
    local planet = Utilities.animatedSprite(365, 45, planetImagetable, 100, true)
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
    local titleSprite = gfx.sprite.spriteWithText(levelName, 400, 20, gfx.kColorClear, nil, nil, nil, titleFont)
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