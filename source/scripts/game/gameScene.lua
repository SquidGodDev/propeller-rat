local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities
local audioManager <const> = AudioManager

local formatTime = utilities.formatTime
local getElapsedTime = pd.getElapsedTime
local pushContext = gfx.pushContext
local popContext = gfx.popContext
local newImage = gfx.image.new

local font = FONT

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
local selectorBaseX, selectorBaseY = popupX + 56, popupY + 92
local selectorGap = 41
local popupTimeX, popupTimeY = 90, 68

local planetImagetables = PLANET_IMAGETABLES

local timeTextWidth, timeTextHeight = 64, 13

local previousTime = nil

assets.preloadImages({"images/decoration/stars"})
assets.preloadImagetables({"images/levels/ui/selector"})

class('GameScene').extends()

function GameScene:init()
    self.timerActive = false

    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    self.curLevelNum = CUR_LEVEL
    self:setUpLevel()

    self.titleSprite = gfx.sprite.new()
    self.titleSprite:setZIndex(Z_INDEXES.ui)
    self.titleSprite:setIgnoresDrawOffset(true)
    self.titleSprite:add()

    self.timeSprite = gfx.sprite.new()
    self.timeSprite:setCenter(0, 0)
    self.timeSprite:moveTo(400 - timeTextWidth - 2, 2)
    self.timeSprite:setZIndex(Z_INDEXES.ui)
    self.timeSprite:setIgnoresDrawOffset(true)
    self.timeSprite:add()

    self:updateTimeSprite(0.0)

    local systemMenu = pd.getSystemMenu()
    self.resetLevelMenuItem = systemMenu:addMenuItem("Reset Level", function()
        if self.player then
            self.player:reset()
        end
    end)
    self.levelSelectMenuItem = systemMenu:addMenuItem("Level Select", function()
        if self.player then
            if self.player:isDisabled() then
                return
            end
            self.player:disable()
        end
        SceneManager.switchScene(LevelSelectScene)
    end)

    previousTime = nil
end

function GameScene:update()
    if self.timerActive then
        self:updateTimeSprite(getElapsedTime())
    end

    local dt = 0
    local currentTime <const> = playdate.getCurrentTimeMilliseconds()
	if previousTime ~= nil then
		dt = currentTime - previousTime
	end
	previousTime = currentTime
    if self.laserManager then
        self.laserManager:update(dt)
    end
    if self.projectileManager then
        self.projectileManager:update(dt)
    end
    if self.player then
        self.player:updatePlayer(dt)
    end

    if self.popupActive then
        if pd.buttonJustPressed(pd.kButtonLeft) then
            if self.levelEndOption > 1 then
                audioManager.play(audioManager.sfx.navigate)
                self.levelEndOption -= 1
                self.selectorSprite:moveTo(selectorBaseX + (self.levelEndOption - 1) * selectorGap, selectorBaseY)
            end
        elseif pd.buttonJustPressed(pd.kButtonRight) then
            if self.levelEndOption < 3 then
                audioManager.play(audioManager.sfx.navigate)
                self.levelEndOption += 1
                self.selectorSprite:moveTo(selectorBaseX + (self.levelEndOption - 1) * selectorGap, selectorBaseY)
            end
        elseif pd.buttonJustPressed(pd.kButtonA) then
            audioManager.play(audioManager.sfx.select)
            self.popupActive = false
            if self.levelEndOption == 1 then
                SceneManager.switchScene(LevelSelectScene)
            elseif self.levelEndOption == 2 then
                SceneManager.switchScene(GameScene)
            elseif self.levelEndOption == 3 then
                self:nextLevel()
            end
        end
    end

    if pd.isCrankDocked() then
        crankIndicator:draw()
    end
end

function GameScene:updateTimeSprite(time)
    local levelTimeText = formatTime(time)
    local textImage = newImage(timeTextWidth, timeTextHeight)
    pushContext(textImage)
        font:drawText(levelTimeText, 0, 0)
    popContext()
    self.timeSprite:setImage(textImage)
end

function GameScene:startLevelTime()
    self.timerActive = true
    pd.resetElapsedTime()
end

function GameScene:recordLevelTime()
    self.timerActive = false
    local levelTime = getElapsedTime()

    self:updateTimeSprite(levelTime)

    local levelIID = LEVEL_INDEX_TO_IID[self.curLevelNum]
    local oldLevelTime = LEVEL_TIMES[levelIID]

    local newBestTime = false
    if not oldLevelTime or (levelTime < oldLevelTime) then
        newBestTime = true
        LEVEL_TIMES[levelIID] = levelTime
    end
    local levelTimeText = formatTime(levelTime)
    if newBestTime then
        levelTimeText = levelTimeText .. " *NEW*"
    end

    self.levelTimeText = levelTimeText
end

function GameScene:levelEnd()
    local systemMenu = pd.getSystemMenu()
    systemMenu:removeMenuItem(self.resetLevelMenuItem)
    systemMenu:removeMenuItem(self.levelSelectMenuItem)

    self.curLevel:stopLevelHazards()

    self.popupActive = false
    self.levelEndOption = 3

    local popupImage = levelEndPopupImage:copy()
    pushContext(popupImage)
        font:drawText(self.levelTimeText, popupTimeX, popupTimeY)
    popContext()
    local popupSprite = gfx.sprite.new(popupImage)
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

    self.laserManager = LaserManager()
    self.projectileManager = nil
    self.curLevel = Level(self.curLevelNum, self.laserManager, self.projectileManager)
    local startX, startY = self.curLevel:getStartPos()
    self.player = Player(self, startX, startY)

    self:showLevelTitle()

    self.player:enable()
end

function GameScene:showLevelTitle()
    local levelName = ldtk.get_custom_data("Level_" .. self.curLevelNum, "Name") or ""

    local titleX, titleY = 5, 5
    local titleSprite = gfx.sprite.spriteWithText(levelName, 400, 20, gfx.kColorClear, nil, nil, nil, font)
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