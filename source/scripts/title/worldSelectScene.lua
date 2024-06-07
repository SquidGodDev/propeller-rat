local pd <const> = playdate
local gfx <const> = playdate.graphics

local ldtk <const> = LDtk

local audioManager <const> = AudioManager

local getDrawOffset <const> = gfx.getDrawOffset
local setDrawOffset <const> = gfx.setDrawOffset

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end
local smoothSpeed <const> = 0.2

local titleFont = gfx.font.new("data/fonts/m6x11-26")

local planetImagetables = PLANET_IMAGETABLES
local planetNames = {"Citer 12", "Koyopa", "Hairu", "ESO-317", "Yuchi", "Dagon"}

local arrowLeft = gfx.image.new("images/levelSelect/arrowLeft")
local arrowRight = gfx.image.new("images/levelSelect/arrowRight")

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

class("WorldSelectScene").extends()

function WorldSelectScene:init()
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    self.starfieldSprite = Starfield(800, 600)

    local worldGap = 400
    local worldY = 200
    self.worlds = {}
    for i, planetImagetable in ipairs(planetImagetables) do
        local planetSprite = Utilities.animatedSprite(0, 0, planetImagetable, 100, true)
        planetSprite:moveTo(i*worldGap, worldY)
        table.insert(self.worlds, planetSprite)
        worldY = (worldY + 100) % 340
    end

    self.selectedWorld = SELECTED_WORLD

    self.nameSprite = gfx.sprite.new(gfx.image.new(200, 120))
    self.nameSprite:setCenter(0.5, 0.5)
    self.nameSprite:moveTo(200, 32)
    self.nameSprite:setIgnoresDrawOffset(true)
    self.nameSprite:add()
    self:updateName()

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

    self.transitioning = false
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

    if self.transitioning then
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
        local transitioning = SceneManager.switchScene(LevelSelectScene)
        if transitioning then
            audioManager.play(audioManager.sfx.select)
            SELECTED_WORLD = self.selectedWorld
            CUR_LEVEL = baseLevels[SELECTED_WORLD]
            self.transitioning = true
        end
    elseif pd.buttonJustPressed(pd.kButtonB) then
        local transitioning = SceneManager.switchScene(TitleScene)
        if transitioning then
            audioManager.play(audioManager.sfx.select)
            self.transitioning = true
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