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
local planetNames = {"Citer 12", "Koyopa", "Hairu", "ESO-317", "Yuchi", "Dagon", "Ceres b"}

assets.preloadImages({
    "images/levelSelect/arrowLeft",
    "images/levelSelect/arrowRight"
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

class("WorldSelectScene").extends()

function WorldSelectScene:init()
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    self.starfieldSprite = starfield
    self.starfieldSprite:add()

    self.worldCompleted = 0

    local completedWorlds = {}
    local worldGap = 400
    local worldY = 200
    self.worlds = {}
    local levelTimes = LEVEL_TIMES
    for i, planetImagetable in ipairs(planetImagetables) do
        local worldX = i * worldGap
        local planetSprite = utilities.animatedSprite(worldX, worldY, planetImagetable, 100, true)
        table.insert(self.worlds, planetSprite)

        worldLevelIIDs = LEVEL_IID_BY_WORLD[i]
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
        completedWorlds[i] = worldCompleted

        local lockImagetable = assets.getImagetable("images/levelSelect/lock")
        if i ~= 1 and not UNLOCK_ALL_WORLDS then
            if completedWorlds[i-1] and (completedWorlds[i-1] ~= COMPLETED_WORLDS[i-1]) then
                self.worldCompleted = i
                pd.timer.performAfterDelay(900, function()
                    audioManager.play(audioManager.sfx.unlocked)
                end)
                utilities.animatedSprite(worldX, worldY, lockImagetable, 100, false)
            elseif not completedWorlds[i - 1] then
                local lockSprite = gfx.sprite.new(lockImagetable[1])
                lockSprite:moveTo(worldX, worldY)
                lockSprite:add()
            end
        end

        local worldTimeText = "--:--.---"
        if worldCompleted then
            worldTimeText = utilities.formatTime(timeTotal)
        end

        local completedLevelsText = string.format("%02d",completedLevelCount) .. "/" .. totalLevelCount
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

    COMPLETED_WORLDS = completedWorlds

    self.selectedWorld = SELECTED_WORLD

    self.nameSprite = gfx.sprite.new(gfx.image.new(200, 120))
    self.nameSprite:setCenter(0.5, 0.5)
    self.nameSprite:moveTo(200, 32)
    self.nameSprite:setIgnoresDrawOffset(true)
    self.nameSprite:add()
    self:updateName()

    local arrowLeft = assets.getImage("images/levelSelect/arrowLeft")
    local arrowRight = assets.getImage("images/levelSelect/arrowRight")
    self.leftArrow = gfx.sprite.new(arrowLeft)
    self.leftArrow:moveTo(100, 140)
    self.leftArrow:setIgnoresDrawOffset(true)
    self.leftArrow:add()
    self.leftArrow:setVisible(false)

    self.rightArrow = gfx.sprite.new(arrowRight)
    self.rightArrow:moveTo(300, 140)
    self.rightArrow:setIgnoresDrawOffset(true)
    self.rightArrow:add()
    self.rightArrow:setVisible(false)

    self:updateArrows()

    local curWorld = self.worlds[self.selectedWorld]
    local curWorldX, curWorldY = curWorld.x, curWorld.y
    local targetOffsetX, targetOffsetY = -(curWorldX - 200), -(curWorldY - 140)
    setDrawOffset(targetOffsetX, targetOffsetY)
    self.starfieldSprite:moveTo(targetOffsetX/10, targetOffsetY/10 + 120)

    self.enteringScene = true
    self.exitingScene = false
end

function WorldSelectScene:update()
    local curWorld = self.worlds[self.selectedWorld]
    local curWorldX, curWorldY = curWorld.x, curWorld.y
    local targetOffsetX, targetOffsetY = -(curWorldX - 200), -(curWorldY - 140)
    local drawOffsetX, drawOffsetY = getDrawOffset()
    local smoothedX = lerp(drawOffsetX, targetOffsetX, smoothSpeed)
    local smoothedY = lerp(drawOffsetY, targetOffsetY, smoothSpeed)
    setDrawOffset(smoothedX, smoothedY)
    self.starfieldSprite:moveTo(smoothedX/10, smoothedY/10 + 120)

    if self.enteringScene then
        if not sceneManager.isTransitioning() then
            self.enteringScene = false
            -- Clear crank ticks
            pd.getCrankTicks(2)
            if self.worldCompleted ~= 0 then
                SELECTED_WORLD = self.worldCompleted
                self.selectedWorld = self.worldCompleted
            end
        else
            return
        end
    end

    if self.exitingScene then
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

    local crankTicks = pd.getCrankTicks(2)
    if crankTicks == -1 then
        self:moveLeft()
    elseif crankTicks == 1 then
        self:moveRight()
    elseif pd.buttonJustPressed(pd.kButtonA) then
        if self.selectedWorld == 1 or COMPLETED_WORLDS[self.selectedWorld - 1] or UNLOCK_ALL_WORLDS then
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
    self.nameSprite:setImageDrawMode(gfx.kDrawModeFillWhite)
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