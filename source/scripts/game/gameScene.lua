local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities
local audioManager <const> = AudioManager

local formatTime <const> = utilities.formatTime
local getElapsedTime <const> = pd.getElapsedTime
local pushContext <const> = gfx.pushContext
local popContext <const> = gfx.popContext
local newImage <const> = gfx.image.new
local getDrawOffset <const> = gfx.getDrawOffset

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

local levelEndPopupImage = newImage("images/levels/ui/levelEndPopup")
local popupWidth, popupHeight = levelEndPopupImage:getSize()
local popupX, popupY = 200 - popupWidth / 2, 120 - popupHeight / 2
local selectorBaseX, selectorBaseY = popupX + 56, popupY + 92
local selectorGap = 41
local popupTimeX, popupTimeY = 75, 67

local planetImagetables = PLANET_IMAGETABLES

local timeTextWidth = 74
local timeX <const>, timeY <const> = 400 - timeTextWidth - 2, 2
local timerTime = 0.0

local previousTime = nil

assets.preloadImages({"images/decoration/stars"})
assets.preloadImagetables({"images/levels/ui/selector"})

GameScene = {}
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

    timerTime = 0.0

    local systemMenu = pd.getSystemMenu()
    self.levelSelectMenuItem = systemMenu:addMenuItem("Level Select", function()
        if SceneManager.switchSceneOverride(LevelSelectScene) then
            if self.player then
                if self.player:isDisabled() then
                    return
                end
                self.player:disable()
            end
        end
    end)
    self.resetLevelMenuItem = systemMenu:addMenuItem("Reset Level", function()
        if self.player then
            self.player:reset()
        end
    end)

    previousTime = nil

    self.crankTracker = nil
end

function GameScene:update()
    local dt = 0
    local currentTime <const> = playdate.getCurrentTimeMilliseconds()
	if previousTime ~= nil then
		dt = currentTime - previousTime
	end
	previousTime = currentTime
    if self.laserManager then
        self.laserManager:update(dt)
    end
    if self.turretManager then
        self.turretManager:update(dt)
    end
    if self.hazardManager then
        self.hazardManager:update(dt)
    end
    if self.player then
        self.player:updatePlayer(dt)
    end

    local popupSprite = self.popupSprite
    if popupSprite then
        popupSprite:getImage():drawIgnoringOffset(popupSprite.x, popupSprite.y)
    end
    local selectorSprite = self.selectorSprite
    if selectorSprite then
        selectorSprite:update()
        selectorSprite:getImage():drawIgnoringOffset(selectorSprite.x, selectorSprite.y)
    end

    if self.timerActive then
        timerTime = getElapsedTime()
    end
    local drawOffsetX, drawOffsetY = getDrawOffset()
    font:drawText(formatTime(timerTime), timeX - drawOffsetX, timeY - drawOffsetY)

    if self.popupActive then
        local crankTick = self.crankTracker:getCrankTicksRelative()
        if pd.buttonJustPressed(pd.kButtonLeft) or crankTick == -1 then
            if self.levelEndOption > 1 then
                audioManager.play(audioManager.sfx.navigate)
                self.levelEndOption -= 1
                self.selectorSprite:moveTo(selectorBaseX + (self.levelEndOption - 1) * selectorGap, selectorBaseY)
            end
        elseif pd.buttonJustPressed(pd.kButtonRight) or crankTick == 1 then
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

function GameScene:startLevelTime()
    self.timerActive = true
    pd.resetElapsedTime()
end

function GameScene:recordLevelTime()
    self.timerActive = false
    local levelTime = getElapsedTime()

    timerTime = levelTime

    local levelIID = LEVEL_INDEX_TO_IID[self.curLevelNum]
    local oldLevelTime = LEVEL_TIMES[levelIID]

    if not oldLevelTime then
        JUST_COMPLETED_LEVEL = self.curLevelNum
    end

    local newBestTime = false
    if not oldLevelTime or (levelTime < oldLevelTime) then
        newBestTime = true
        LEVEL_TIMES[levelIID] = levelTime
    end
    local levelTimeText = formatTime(levelTime)
    if newBestTime then
        levelTimeText = levelTimeText .. " *NEW*"
    end

    -- Submit to leaderboards
    local levelTimes = LEVEL_TIMES
    local timeTotal = 0.0
    local worldLevelIIDs = LEVEL_IID_BY_WORLD[SELECTED_WORLD]
    local worldCompleted = true
    for _, iid in ipairs(worldLevelIIDs) do
        local curLevelTime = levelTimes[iid]
        if not curLevelTime then
            worldCompleted = false
            break
        else
            timeTotal += curLevelTime
        end
    end

    if worldCompleted then
        local scoreboardTime = math.floor(timeTotal * 1000)
        local scoreboardID = "world" .. SELECTED_WORLD
        pd.scoreboards.addScore(scoreboardID, scoreboardTime, function(status, result)
            printTable(status)
            printTable(result)
        end)
    end

    self.levelTimeText = levelTimeText
end

function GameScene:levelEnd()
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
    local popupTimer = pd.timer.new(900, popupSprite.y, popupY, pd.easingFunctions.outBack)
    popupTimer.updateCallback = function()
        popupSprite:moveTo(popupX, popupTimer.value)
    end
    self.popupSprite = popupSprite

    local selectorImagetable = assets.getImagetable("images/levels/ui/selector")
    local selectorSprite = utilities.animatedSprite(selectorBaseX + selectorGap * 2, selectorBaseY + 240, selectorImagetable, 50, true)
    selectorSprite:remove()
    selectorSprite:setIgnoresDrawOffset(true)
    selectorSprite:setZIndex(Z_INDEXES.ui)
    selectorSprite:setCenter(0, 0)
    self.selectorSprite = selectorSprite
    pd.timer.performAfterDelay(200, function()
        self.popupActive = true
        self.crankTracker = CrankTracker(120)
        local selectorTimer = pd.timer.new(900, selectorSprite.y, selectorBaseY, pd.easingFunctions.outBack)
        selectorTimer.updateCallback = function()
            selectorSprite:moveTo(selectorSprite.x, selectorTimer.value)
        end
    end)
end

function GameScene:nextLevel()
    local nextLevel = self.curLevelNum + 1
    SceneManager.switchScene(LevelSelectScene, nil, nil, nextLevel)
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
    local starsImage = assets.getImage("images/decoration/stars")
    local stars = gfx.sprite.new(starsImage)
    stars:setIgnoresDrawOffset(true)
    stars:moveTo(200, 120)
    stars:add()

    local planetImagetable = planetImagetables[SELECTED_WORLD]
    local planet = utilities.animatedSprite(365, 45, planetImagetable, 100, true)
    planet:setIgnoresDrawOffset(true)

    self.laserManager = LaserManager()
    self.turretManager = TurretManager()
    self.hazardManager = HazardManager()
    self.curLevel = Level(self.curLevelNum, self.laserManager, self.turretManager, self.hazardManager)
    local startX, startY = self.curLevel:getStartPos()
    self.player = Player(self, startX, startY)

    self:showLevelTitle()

    self.player:enable()

    -- pd.debugDraw = function()
    --     self.turretManager:debugDraw()
    -- end
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
        titleTimer.updateCallback = function()
            titleSprite:moveTo(titleX, titleTimer.value)
        end
        titleTimer.timerEndedCallback = function()
            pd.timer.performAfterDelay(titleShowTime, function()
                titleTimer = pd.timer.new(titleTransitionTime, titleSprite.y, -titleHeight, pd.easingFunctions.inCubic)
                titleTimer.updateCallback = function()
                    titleSprite:moveTo(titleX, titleTimer.value)
                end
                titleTimer.timerEndedCallback= function()
                    titleSprite:remove()
                end
            end)
        end
    end)
end