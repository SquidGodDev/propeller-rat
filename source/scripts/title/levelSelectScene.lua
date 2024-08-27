local pd <const> = playdate
local gfx <const> = playdate.graphics

local utilities <const> = Utilities
local ldtk <const> = LDtk
local sceneManager <const> = SceneManager
local audioManager <const> = AudioManager

local assets <const> = Assets
assets.preloadImages({
    "images/levelSelect/previewBorder",
    "images/levelSelect/progressBar",
    "images/levelSelect/flagIcon",
    "images/decoration/stars"
})

assets.preloadImagetable("images/levelSelect/burst")

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end
local smoothSpeed <const> = 0.3

local planetImagetables = PLANET_IMAGETABLES

local font = FONT
local titleFont = TITLE_FONT

local previewWidth, previewHeight = 176, 116
local tileSize = 4
local tileScale = 4
local wallIcon = gfx.image.new("images/levelSelect/icons/wall")
local startIcon = gfx.image.new("images/levelSelect/icons/start")
local endIcon = gfx.image.new("images/levelSelect/icons/end")
local blockIcon = gfx.image.new("images/levelSelect/icons/block")
local laserIcon = gfx.image.new("images/levelSelect/icons/laser")
local spinnerIcon = gfx.image.new("images/levelSelect/icons/spinner")
local turretIcon = gfx.image.new("images/levelSelect/icons/turret")
local keyIcon = gfx.image.new("images/levelSelect/icons/key")
local icons = {
    Start = startIcon,
    End = endIcon,
    Block = blockIcon,
    Laser = laserIcon,
    Spinner = spinnerIcon,
    Turret = turretIcon,
    Key = keyIcon
}

local worldIIDs = {}
local worldBaseLevel = {}
local allLevelPreviews = {}
local levelCount = ldtk.get_level_count()
for levelIndex=1,levelCount do
    local levelName = "Level_" .. levelIndex
    LEVEL_INDEX_TO_IID[levelIndex] = ldtk.get_level_iid(levelName)
    local previewImage = gfx.image.new(previewWidth, previewHeight)
    gfx.pushContext(previewImage)
        gfx.setColor(gfx.kColorWhite)
        for layerName, layer in pairs(ldtk.get_layers(levelName)) do
            if layer.tiles then
                local tiles = layer.tiles
                local width = layer.tilemap_width
                local height = math.floor(#tiles / width)
                for h=1, height do
                    for w=1, width do
                        local idx = (h - 1) * width + w
                        local curTile = tiles[idx]
                        if curTile ~= 0 then
                            local previewX, previewY = (w-1)*tileSize, (h-1)*tileSize
                            wallIcon:draw(previewX, previewY)
                        end
                    end
                end
            end
        end

        for _, entity in ipairs(ldtk.get_entities(levelName)) do
            local entityX, entityY = entity.position.x / tileScale, entity.position.y / tileScale
            local entityName = entity.name

            local icon = icons[entityName]
            if entityName == "Block" then
                local width = entity.size.width / tileScale
                local height = entity.size.height / tileScale
                local topLeftX, topLeftY = entityX - width / 2, entityY - height / 2
                for w=0,width/tileSize-1 do
                    for h=0,height/tileSize-1 do
                       blockIcon:draw(topLeftX + w*tileSize, topLeftY + h*tileSize)
                    end
                end
            elseif entityName == "Laser" then
                local fields = entity.fields
                local tailX, tailY = fields.tail.cx * tileScale + tileSize / 2, fields.tail.cy * tileScale + tileSize / 2
                icon:drawAnchored(entityX, entityY, 0.5, 0.5)
                icon:drawAnchored(tailX, tailY, 0.5, 0.5)
                gfx.drawLine(entityX, entityY, tailX, tailY)
            elseif icon then
                icon:drawAnchored(entityX, entityY, 0.5, 0.5)
            end
        end

        local levelDepth = ldtk.get_depth(levelName) + 1
        local levelIID = ldtk.get_level_iid(levelName)
        local levelPreviews = allLevelPreviews[levelDepth]
        local levelIIDs = worldIIDs[levelDepth]
        if not levelPreviews then
            levelPreviews = {}
            allLevelPreviews[levelDepth] = levelPreviews
            worldBaseLevel[levelDepth] = levelIndex
            levelIIDs = {}
            worldIIDs[levelDepth] = levelIIDs
        end
        table.insert(levelPreviews, previewImage)
        table.insert(levelIIDs, levelIID)
    gfx.popContext()
end

LEVEL_IID_BY_WORLD = worldIIDs

local previewX, previewY = 200, 124
local previewGap = 35
local previewBorder = gfx.image.new("images/levelSelect/previewBorder")
local borderWidth, borderHeight = previewBorder:getSize()
local borderDrawX, borderDrawY = 6, 24

local worldPreviews = {}

for worldDepth, levelPreviews in pairs(allLevelPreviews) do
    local worldLevelCount = #levelPreviews
    local allPreviewsWidth = worldLevelCount * borderWidth + (worldLevelCount - 1) * previewGap
    local previewImage = gfx.image.new(allPreviewsWidth, borderHeight)
    local drawX = 0
    gfx.pushContext(previewImage)
        for i=1, worldLevelCount do
            local preview = levelPreviews[i]
            previewBorder:draw(drawX, 0)
            preview:draw(drawX + borderDrawX, borderDrawY)
            drawX += previewGap + borderWidth
        end
    gfx.popContext()
    worldPreviews[worldDepth] = previewImage
end

local flagImage = gfx.image.new("images/levelSelect/levelCompleteFlag")
local flagX, flagY = 15, 0
local timeX, timeY = 108, 4
local levelTimes = LEVEL_TIMES
local function getPreviewWithLevelTimes(worldDepth)
    local levelIIDs = worldIIDs[worldDepth]
    local previewImage = worldPreviews[worldDepth]:copy()
    local worldLevelCount = #allLevelPreviews[worldDepth]
    local drawX = 0
    gfx.pushContext(previewImage)
        for i=1, worldLevelCount do
            local levelIID = levelIIDs[i]
            local levelTime = levelTimes[levelIID]
            local timeText = "--:--.---"
            if levelTime then
                timeText = utilities.formatTime(levelTime)
                flagImage:draw(drawX + flagX, flagY)
            end
            font:drawText(timeText, drawX + timeX, timeY)
            drawX += previewGap + borderWidth
        end
    gfx.popContext()
    return previewImage
end

local function getCompletedLevelsCount(worldDepth)
    local levelIIDs = worldIIDs[worldDepth]
    local worldLevelCount = #allLevelPreviews[worldDepth]
    local completedLevels = 0
    for i=1, worldLevelCount do
        local levelIID = levelIIDs[i]
        local levelTime = levelTimes[levelIID]
        if levelTime then
            completedLevels += 1
        end
    end
    return completedLevels, worldLevelCount
end

LevelSelectScene = {}
class('LevelSelectScene').extends()

function LevelSelectScene:init(nextLevel)
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    local starsImage = assets.getImage("images/decoration/stars")
    local stars = gfx.sprite.new(starsImage)
    stars:moveTo(200, 120)
    stars:add()

    local worldIndex = SELECTED_WORLD
    self.worldIndex = worldIndex
    utilities.animatedSprite(365, 45, planetImagetables[worldIndex], 100, true)

    self.levelCount = #allLevelPreviews[worldIndex]
    self.baseLevel = worldBaseLevel[worldIndex]
    self.selectedLevel = CUR_LEVEL - self.baseLevel + 1
    if LAST_SELECTED_LEVEL[worldIndex] then
        self.selectedLevel = LAST_SELECTED_LEVEL[worldIndex]
    else
        LAST_SELECTED_LEVEL[worldIndex] = self.selectedLevel
    end
    local previewImage = getPreviewWithLevelTimes(worldIndex)
    self.levelsSprite = gfx.sprite.new(previewImage)
    self.levelsSprite:setCenter(0.0, 0.5)
    local targetX = previewX - borderWidth / 2 - (self.selectedLevel - 1) * (borderWidth + previewGap)
    self.levelsSprite:moveTo(targetX, previewY)
    self.levelsSprite:add()

    local flags = 0
    for _, time in pairs(levelTimes) do
        if time then
            flags += 1
        end
    end

    local justCompletedLevel = JUST_COMPLETED_LEVEL
    JUST_COMPLETED_LEVEL = nil

    local flagSpriteX, flagSpriteY = 6, 6
    local flagIcon = assets.getImage("images/levelSelect/flagIcon")
    local flagSprite = gfx.sprite.new(flagIcon)
    flagSprite:setCenter(0, 0)
    flagSprite:moveTo(flagSpriteX, flagSpriteY)
    flagSprite:add()
    local flagCount = flags
    if justCompletedLevel then
        flagCount -= 1
    end
    local flagText = gfx.sprite.spriteWithText(tostring(flagCount), 50, 50, nil, nil, nil, nil, font)
    flagText:setCenter(0, 0)
    flagText:moveTo(22, 6)
    flagText:add()

    local burstX, burstY = previewX - borderWidth / 2 + 23, previewY - 57
    if justCompletedLevel or nextLevel then
        local gameCompleted = false
        if justCompletedLevel then
            nextLevel = justCompletedLevel + 1
        end
        if flags >= levelCount then
            if not GAME_END_SHOWN_1_0_0 then
                gameCompleted = true
                GAME_END_SHOWN_1_0_0 = true
            end
        end

        self.animating = true
        local animationDelay = 700
        if justCompletedLevel then
            pd.timer.performAfterDelay(500, function ()
                audioManager.play(audioManager.sfx.levelCleared)
                local movingFlagX, movingFlagY = burstX - 7, burstY - 18
                local movingFlag = gfx.sprite.new(flagImage)
                movingFlag:setCenter(0, 0)
                movingFlag:moveTo(movingFlagX, movingFlagY)
                movingFlag:add()
                Utilities.animatedSprite(burstX, burstY, assets.getImagetable("images/levelSelect/burst"), 17, false)
                local flagTimer = pd.timer.new(700, 0.0, 1.0, pd.easingFunctions.inExpo)
                flagTimer.updateCallback = function()
                    movingFlag:moveTo(movingFlagX + (flagSpriteX - movingFlagX)*flagTimer.value, movingFlagY + (flagSpriteY - movingFlagY)*flagTimer.value)
                end
                flagTimer.timerEndedCallback = function()
                    audioManager.play(audioManager.sfx.flagAcquired)
                    movingFlag:remove()
                    local flagTextImage = gfx.imageWithText(tostring(flags), 50, 50, nil, nil, nil, nil, font)
                    flagText:setImage(flagTextImage)
                end
            end)
            animationDelay += 500
        elseif nextLevel then
            pd.timer.performAfterDelay(500, function ()
                audioManager.play(audioManager.sfx.levelCleared)
            end)
        end

        local maxWorldLevel = 10
        local selectedLevel = nextLevel - self.baseLevel + 1
        pd.timer.performAfterDelay(animationDelay, function()
            self.animating = false
            if selectedLevel > maxWorldLevel then
                SceneManager.switchScene(WorldSelectScene)
            elseif selectedLevel <= self.levelCount then
                self.selectedLevel = selectedLevel
                CUR_LEVEL = nextLevel
                LAST_SELECTED_LEVEL[worldIndex] = self.selectedLevel
                self:updateName()
            else
                if gameCompleted then
                    -- SceneManager.switchScene(GameCompletedScene)
                    SceneManager.switchScene(WorldSelectScene)
                else
                    SceneManager.switchScene(WorldSelectScene)
                end
            end
        end)
    end

    local completedLevels = getCompletedLevelsCount(worldIndex)
    local progressBarHeight = 8
    local progressBarCellSize = 32
    local progressBarDrawX, progressBarDrawY = 6, 6
    local progressBarBorderImage = assets.getImage("images/levelSelect/progressBar")
    local progressBarImage = gfx.image.new(progressBarBorderImage:getSize())
    gfx.pushContext(progressBarImage)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(progressBarDrawX, progressBarDrawY, completedLevels*progressBarCellSize, progressBarHeight)
        progressBarBorderImage:draw(0, 0)
    gfx.popContext()
    self.progressBarSprite = gfx.sprite.new(progressBarImage)
    self.progressBarSprite:setCenter(0.5, 0.0)
    self.progressBarSprite:moveTo(200, 210)
    self.progressBarSprite:add()

    self.nameSprite = gfx.sprite.new(gfx.image.new(200, 120))
    self.nameSprite:setCenter(0.5, 0.5)
    self.nameSprite:moveTo(200, 26)
    self.nameSprite:add()
    self:updateName()

    self.enteringScene = true
    self.exitingScene = false

    self.crankTracker = CrankTracker(120)
end

function LevelSelectScene:update()
    local targetX = self:getTargetX()
    if math.abs(self.levelsSprite.x - targetX) < 0.5 then
        self.levelsSprite:moveTo(targetX, previewY)
    else
        self.levelsSprite:moveTo(lerp(self.levelsSprite.x, targetX, smoothSpeed), previewY)
    end

    if self.enteringScene then
        if not sceneManager.isTransitioning() then
            self.enteringScene = false
        else
            return
        end
    end

    if self.exitingScene or self.animating then
        return
    end

    if pd.buttonJustPressed(pd.kButtonLeft) then
        if self.keyRepeatTimer then
            self.keyRepeatTimer:remove()
        end
        self.keyRepeatTimer = pd.timer.keyRepeatTimer(function()
            self:moveLeft()
        end)
    elseif pd.buttonJustReleased(pd.kButtonLeft) then
        if self.keyRepeatTimer then
            self.keyRepeatTimer:remove()
        end
    end

    if pd.buttonJustPressed(pd.kButtonRight) then
        if self.keyRepeatTimer then
            self.keyRepeatTimer:remove()
        end
        self.keyRepeatTimer = pd.timer.keyRepeatTimer(function()
            self:moveRight()
        end)
    elseif pd.buttonJustReleased(pd.kButtonRight) then
        if self.keyRepeatTimer then
            self.keyRepeatTimer:remove()
        end
    end

    local crankTicks = self.crankTracker:getCrankTicksAbsolute()
    if crankTicks == -1 then
        self:moveLeft()
    elseif crankTicks == 1 then
        self:moveRight()
    elseif pd.buttonJustPressed(pd.kButtonA) then
        local exitingScene = sceneManager.switchScene(GameScene, nil, nil)
        if exitingScene then
            audioManager.play(audioManager.sfx.select)
            self.exitingScene = true
            CUR_LEVEL = self.baseLevel + self.selectedLevel - 1
        end
    elseif pd.buttonJustPressed(pd.kButtonB) then
        local exitingScene = sceneManager.switchScene(WorldSelectScene, nil, nil)
        if exitingScene then
            audioManager.play(audioManager.sfx.select)
            self.exitingScene = true
        end
    end
end

function LevelSelectScene:moveLeft()
    if self.selectedLevel > 1 then
        audioManager.play(audioManager.sfx.navigate)
        self.selectedLevel -= 1
        CUR_LEVEL = self.baseLevel + self.selectedLevel - 1
        LAST_SELECTED_LEVEL[self.worldIndex] = self.selectedLevel
        self:updateName()
    end
end

function LevelSelectScene:moveRight()
    if self.selectedLevel < self.levelCount then
        audioManager.play(audioManager.sfx.navigate)
        self.selectedLevel += 1
        CUR_LEVEL = self.baseLevel + self.selectedLevel - 1
        LAST_SELECTED_LEVEL[self.worldIndex] = self.selectedLevel
        self:updateName()
    end
end

function LevelSelectScene:getTargetX()
    return previewX - borderWidth / 2 - (self.selectedLevel - 1) * (borderWidth + previewGap)
end

function LevelSelectScene:updateName()
    local levelName = ldtk.get_custom_data("Level_" .. self.baseLevel + self.selectedLevel - 1, "Name")
    local nameImage = gfx.imageWithText(levelName --[[@as string]], 400, 50, nil, nil, nil, kTextAlignment.center, titleFont)
    self.nameSprite:setImage(nameImage)
end