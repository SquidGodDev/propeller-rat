local pd <const> = playdate
local gfx <const> = playdate.graphics

local ldtk <const> = LDtk

local getDrawOffset <const> = gfx.getDrawOffset
local setDrawOffset <const> = gfx.setDrawOffset

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end
local smoothSpeed <const> = 0.2

local titleFont = gfx.font.new("data/fonts/m6x11-26")

local planetImagetables = PLANET_IMAGETABLES
local planetNames = {"World 1", "World 2", "World 3", "World 4"}

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

    local curWorld = self.worlds[self.selectedWorld]
    local curWorldX, curWorldY = curWorld.x, curWorld.y
    local targetOffsetX, targetOffsetY = -(curWorldX - 200), -(curWorldY - 140)
    setDrawOffset(targetOffsetX, targetOffsetY)
    self.starfieldSprite:moveTo(targetOffsetX/10, targetOffsetY/10 + 120)
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

    if pd.buttonJustPressed(pd.kButtonLeft) then
        self.selectedWorld = math.clamp(self.selectedWorld - 1, 1, #self.worlds)
        self:updateName()
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        self.selectedWorld = math.clamp(self.selectedWorld + 1, 1, #self.worlds)
        self:updateName()
    elseif pd.buttonJustPressed(pd.kButtonA) then
        SELECTED_WORLD = self.selectedWorld
        CUR_LEVEL = baseLevels[SELECTED_WORLD]
        SceneManager.switchScene(LevelSelectScene)
    end
end

function WorldSelectScene:updateName()
    local name = planetNames[self.selectedWorld]
    local nameImage = gfx.imageWithText(name --[[@as string]], 400, 50, nil, nil, nil, kTextAlignment.center, titleFont)
    self.nameSprite:setImageDrawMode(gfx.kDrawModeFillWhite)
    self.nameSprite:setImage(nameImage)
end