local pd <const> = playdate
local gfx <const> = playdate.graphics

local utilities <const> = Utilities
local assets <const> = Assets
local ldtk <const> = LDtk
local sceneManager <const> = SceneManager
local audioManager <const> = AudioManager

local getDrawOffset <const> = gfx.getDrawOffset
local setDrawOffset <const> = gfx.setDrawOffset

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end
local smoothSpeed <const> = 0.2

local font = FONT
local titleFont = TITLE_FONT

local planetImagetables = PLANET_IMAGETABLES
-- cSpell:disable-next-line
local planetNames = {"INT-RO 1", "Blokiter", "Chipkey", "Turretia", "LAZ-ER 5", "Spinturn", "Mixropa", "Hazarmede"}
local flagRequirements = {0, 8, 16, 24, 32, 40, 58, 68}

assets.preloadImages({
    "images/levelSelect/arrowLeft",
    "images/levelSelect/arrowRight",
    "images/levelSelect/progressBarEmpty",
    "images/levelSelect/progressBarSeparator",
    "images/levelSelect/flagIcon"
})

assets.preloadImagetable("images/levelSelect/lock")

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

local starfield = Starfield(800, 600)

WorldSelectScene = {}
class("WorldSelectScene").extends()

function WorldSelectScene:init()
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    self.starfieldSprite = starfield
    self.starfieldSprite:add()

    self.storyManager = StoryManager(1)
    self.storyManager:animateIn()

    self.unlockingWorld = false

    local deathCountText = gfx.sprite.spriteWithText(tostring(DEATH_COUNT), 100, 30, nil, nil, nil, nil, font)
    local textWidth = deathCountText:getSize()
    deathCountText:setCenter(0, 0)
    deathCountText:setIgnoresDrawOffset(true)
    deathCountText:setZIndex(Z_INDEXES.ui)
    deathCountText:moveTo(400 - textWidth - 3, 9)
    local playerImageTable = assets.getImagetable("images/player/rat")
    local playerIconSprite = gfx.sprite.new(playerImageTable[14])
    playerIconSprite:setCenter(0, 0)
    playerIconSprite:setIgnoresDrawOffset(true)
    playerIconSprite:setZIndex(Z_INDEXES.ui)
    playerIconSprite:moveTo(400 - textWidth - 27, 0)

    if SHOW_DEATH_COUNT then
        deathCountText:add()
        playerIconSprite:add()
    end

    local systemMenu = pd.getSystemMenu()
    systemMenu:addCheckmarkMenuItem("Crash Count", SHOW_DEATH_COUNT, function(value)
        SHOW_DEATH_COUNT = value
        if value then
            deathCountText:add()
            playerIconSprite:add()
        else
            deathCountText:remove()
            playerIconSprite:remove()
        end
    end)

    local levelTimes = LEVEL_TIMES
    local flags = 0
    for _, time in pairs(levelTimes) do
        if time then
            flags += 1
        end
    end
    local flagSpriteX, flagSpriteY = 6, 9
    local flagIcon = assets.getImage("images/levelSelect/flagIcon")
    local flagSprite = gfx.sprite.new(flagIcon)
    flagSprite:setCenter(0, 0)
    flagSprite:moveTo(flagSpriteX, flagSpriteY)
    flagSprite:setIgnoresDrawOffset(true)
    flagSprite:setZIndex(Z_INDEXES.ui)
    flagSprite:add()
    local flagText = gfx.sprite.spriteWithText(tostring(flags), 50, 50, nil, nil, nil, nil, font)
    flagText:setCenter(0, 0)
    flagText:moveTo(22, flagSpriteY)
    flagText:setIgnoresDrawOffset(true)
    flagText:setZIndex(Z_INDEXES.ui)
    flagText:add()

    local lockImagetable = assets.getImagetable("images/levelSelect/lock")
    local completedWorldsCount = 0
    local worldGap = 400
    local worldY = 200
    self.worlds = {}
    local worldUnlockQueue = {}
    for i, planetImagetable in ipairs(planetImagetables) do
        local worldX = i * worldGap
        local planetSprite = utilities.animatedSprite(worldX, worldY, planetImagetable, 100, true)
        table.insert(self.worlds, planetSprite)

        local worldLevelIIDs = LEVEL_IID_BY_WORLD[i]
        local timeTotal = 0.0
        local worldCompleted = true
        local totalLevelCount = #worldLevelIIDs
        local completedLevelCount = 0
        for _, iid in ipairs(worldLevelIIDs) do
            local levelTime = levelTimes[iid]
            if not levelTime then
                worldCompleted = false
            else
                completedLevelCount += 1
                timeTotal += levelTime
            end
        end
        if worldCompleted then
            completedWorldsCount += 1
        end

        local flagWidth = flagIcon:getSize()
        if i ~= 1 and not UNLOCK_ALL_WORLDS then
            if flags >= flagRequirements[i] and not UNLOCKED_WORLDS[i] then
                local unlockData = {
                    index = i,
                    worldX = worldX,
                    worldY = worldY
                }
                self.unlockingWorld = true
                self.selectedWorld = i
                table.insert(worldUnlockQueue, unlockData)
                UNLOCKED_WORLDS[i] = true
            elseif flags < flagRequirements[i] then
                UNLOCKED_WORLDS[i] = false
                local flagCountText = gfx.imageWithText(tostring(flagRequirements[i]), 50, 30, nil, nil, nil, nil, font)
                local flagCountWidth, flagCountHeight = flagCountText:getSize()
                local spaceBuffer = 2
                flagCountWidth += flagWidth + spaceBuffer
                local flagCountImage = gfx.image.new(flagCountWidth, flagCountHeight)
                gfx.pushContext(flagCountImage)
                    flagIcon:draw(0, 0)
                    flagCountText:draw(flagWidth + spaceBuffer, 0)
                gfx.popContext()
                local flagCountSprite = gfx.sprite.new(flagCountImage)
                flagCountSprite:moveTo(worldX, worldY + 25)
                flagCountSprite:add()
                local lockSprite = gfx.sprite.new(lockImagetable[1])
                lockSprite:moveTo(worldX, worldY - 10)
                lockSprite:add()
            end
        end

        local worldTimeText = "--:--.---"
        if worldCompleted then
            worldTimeText = utilities.formatTime(timeTotal)
        end

        local completedLevelsText = string.format("%02d",completedLevelCount) .. "/" .. string.format("%02d",totalLevelCount)
        local completedLevelsSprite = gfx.sprite.spriteWithText(completedLevelsText, 100, 20, nil, nil, nil, nil, font)
        completedLevelsSprite:moveTo(worldX + 1, worldY - 65)
        completedLevelsSprite:add()

        local timeTextWidth, timeTextHeight = 64, 13
        local textImage = gfx.image.new(timeTextWidth, timeTextHeight)
        gfx.pushContext(textImage)
            font:drawText(worldTimeText, 0, 0)
        gfx.popContext()
        local worldTimeSprite = gfx.sprite.new()
        worldTimeSprite:setImage(textImage)
        worldTimeSprite:moveTo(worldX + 1, worldY + 70)
        worldTimeSprite:add()

        worldY = (worldY + 100) % 340
    end

    self.selectedWorld = SELECTED_WORLD

    local unlockDelay = 900
    local unlockGapDelay = 1300
    local curDelay = 0
    for i=#worldUnlockQueue, 1, -1 do
        local unlockData = worldUnlockQueue[i]
        local worldIndex = unlockData.index
        local curWorldX, curWorldY = unlockData.worldX, unlockData.worldY
        pd.timer.performAfterDelay(curDelay, function()
            self.selectedWorld = worldIndex
            utilities.animatedSprite(curWorldX, curWorldY, lockImagetable, 100, false)
        end)
        pd.timer.performAfterDelay(unlockDelay + curDelay, function()
            SELECTED_WORLD = worldIndex
            audioManager.play(audioManager.sfx.unlocked)
            if i == 1 then
                self.unlockingWorld = false
            end
        end)
        curDelay += unlockGapDelay
    end

    self.nameSprite = gfx.sprite.new(gfx.image.new(200, 120))
    self.nameSprite:setCenter(0.5, 0.5)
    self.nameSprite:moveTo(200, 22)
    self.nameSprite:setIgnoresDrawOffset(true)
    self.nameSprite:add()
    self:updateName()

    local arrowLeft = assets.getImage("images/levelSelect/arrowLeft")
    local arrowRight = assets.getImage("images/levelSelect/arrowRight")
    self.leftArrow = gfx.sprite.new(arrowLeft)
    self.leftArrow:moveTo(100, 130)
    self.leftArrow:setIgnoresDrawOffset(true)
    self.leftArrow:add()
    self.leftArrow:setVisible(false)

    self.rightArrow = gfx.sprite.new(arrowRight)
    self.rightArrow:moveTo(300, 130)
    self.rightArrow:setIgnoresDrawOffset(true)
    self.rightArrow:add()
    self.rightArrow:setVisible(false)

    self:updateArrows()

    local curWorld = self.worlds[self.selectedWorld]
    local curWorldX, curWorldY = curWorld.x, curWorld.y
    local targetOffsetX, targetOffsetY = -(curWorldX - 200), -(curWorldY - 125)
    setDrawOffset(targetOffsetX, targetOffsetY)
    self.starfieldSprite:moveTo(targetOffsetX/10, targetOffsetY/10 + 120)

    local progressBarEmpty = assets.getImage("images/levelSelect/progressBarEmpty"):copy()
    local progressBarSeparator = assets.getImage("images/levelSelect/progressBarSeparator")
    local separatorSpace = 320 / #planetImagetables
    gfx.pushContext(progressBarEmpty)
        local drawX, drawY = 6+separatorSpace, 4
        for _=1,#planetImagetables-1 do
            progressBarSeparator:draw(drawX - 4, drawY)
            drawX += separatorSpace
        end
    gfx.popContext()
    local progressBarHeight = 8
    local progressBarDrawX, progressBarDrawY = 6, 6
    local progressBar = gfx.image.new(progressBarEmpty:getSize())
    gfx.pushContext(progressBar)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(progressBarDrawX, progressBarDrawY, completedWorldsCount*separatorSpace, progressBarHeight)
        progressBarEmpty:draw(0, 0)
    gfx.popContext()

    local progressBarSprite = gfx.sprite.new(progressBar)
    progressBarSprite:moveTo(200, 225)
    progressBarSprite:setIgnoresDrawOffset(true)
    progressBarSprite:add()

    self.enteringScene = true
    self.exitingScene = false

    self.crankTracker = CrankTracker(180)
end

function WorldSelectScene:update()
    local curWorld = self.worlds[self.selectedWorld]
    local curWorldX, curWorldY = curWorld.x, curWorld.y
    local targetOffsetX, targetOffsetY = -(curWorldX - 200), -(curWorldY - 125)
    local drawOffsetX, drawOffsetY = getDrawOffset()
    local smoothedX = lerp(drawOffsetX, targetOffsetX, smoothSpeed)
    local smoothedY = lerp(drawOffsetY, targetOffsetY, smoothSpeed)
    setDrawOffset(smoothedX, smoothedY)
    self.starfieldSprite:moveTo(smoothedX/10, smoothedY/10 + 120)

    if self.enteringScene then
        if not sceneManager.isTransitioning() then
            self.enteringScene = false
        else
            return
        end
    end

    if self.exitingScene or self.unlockingWorld then
        return
    end

    if self.storyManager:isActive() then
        if self.storyManager:isInputActive() then
            if pd.buttonJustPressed(pd.kButtonA)
            or pd.buttonJustPressed(pd.kButtonB)
            or pd.buttonJustPressed(pd.kButtonDown)
            or pd.buttonJustPressed(pd.kButtonRight) then
                self.storyManager:progress()
            end
        end
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
        if self.selectedWorld == 1 or UNLOCKED_WORLDS[self.selectedWorld] or UNLOCK_ALL_WORLDS then
            local exitingScene = sceneManager.switchScene(LevelSelectScene)
            if exitingScene then
                audioManager.play(audioManager.sfx.select)
                SELECTED_WORLD = self.selectedWorld
                CUR_LEVEL = baseLevels[SELECTED_WORLD]
                self.exitingScene = true
            end
        else
            audioManager.play(audioManager.sfx.error)
        end
    elseif pd.buttonJustPressed(pd.kButtonB) then
        local exitingScene = sceneManager.switchScene(TitleScene)
        if exitingScene then
            audioManager.play(audioManager.sfx.select)
            self.exitingScene = true
        end
    end
end

function WorldSelectScene:moveLeft()
    if self.selectedWorld > 1 then
        audioManager.play(audioManager.sfx.navigate)
        self.selectedWorld -= 1
        self:updateName()
        self:updateArrows()
        SELECTED_WORLD = self.selectedWorld
    end
end

function WorldSelectScene:moveRight()
    if self.selectedWorld < #self.worlds then
        audioManager.play(audioManager.sfx.navigate)
        self.selectedWorld += 1
        self:updateName()
        self:updateArrows()
        SELECTED_WORLD = self.selectedWorld
    end
end

function WorldSelectScene:updateName()
    local name = planetNames[self.selectedWorld]
    local nameImage = gfx.imageWithText(name --[[@as string]], 400, 50, nil, nil, nil, kTextAlignment.center, titleFont)
    self.nameSprite:setImage(nameImage)
end

function WorldSelectScene:updateArrows()
    if self.selectedWorld > 1 then
        self.leftArrow:setVisible(true)
    else
        self.leftArrow:setVisible(false)
    end

    if self.selectedWorld < #self.worlds then
        self.rightArrow:setVisible(true)
    else
        self.rightArrow:setVisible(false)
    end
end