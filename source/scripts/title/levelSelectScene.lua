local pd <const> = playdate
local gfx <const> = playdate.graphics

local audioManager <const> = AudioManager

local ldtk <const> = LDtk

local assets <const> = Assets
assets.preloadImages({
    "images/levelSelect/previewBorder",
    "images/decoration/stars"
})

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end
local smoothSpeed <const> = 0.3

local planetImagetables = PLANET_IMAGETABLES

local titleFont = gfx.font.new("data/fonts/m6x11-26")

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

local worldBaseLevel = {}
local allLevelPreviews = {}
local levelCount = ldtk.get_level_count()
for levelIndex=1,levelCount do
    local levelName = "Level_" .. levelIndex
    local previewImage = gfx.image.new(previewWidth, previewHeight)
    gfx.pushContext(previewImage)
        gfx.setColor(gfx.kColorWhite)
        for layerName, layer in pairs(ldtk.get_layers(levelName)) do
            if layer.tiles then
                local tilemap = ldtk.create_tilemap(levelName, layerName)
                local width, height = tilemap:getSize()
                for w=1, width do
                    for h=1, height do
                        local curTile = tilemap:getTileAtPosition(w, h)
                        if curTile then
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
            else
                icon:drawAnchored(entityX, entityY, 0.5, 0.5)
            end
        end

        local levelDepth = ldtk.get_depth(levelName) + 1
        local levelPreviews = allLevelPreviews[levelDepth]
        if not levelPreviews then
            levelPreviews = {}
            allLevelPreviews[levelDepth] = levelPreviews
            worldBaseLevel[levelDepth] = levelIndex
        end
        table.insert(levelPreviews, previewImage)
    gfx.popContext()
end

local previewX, previewY = 200, 140
local previewGap = 35
local previewBorder = gfx.image.new("images/levelSelect/previewBorder")
local borderWidth, borderHeight = previewBorder:getSize()
local borderDrawX, borderDrawY = 6, 6

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

class('LevelSelectScene').extends()

function LevelSelectScene:init()
    audioManager.playSong(audioManager.songs.cosmicDust)

    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    local starsImage = assets.getImage("images/decoration/stars")
    local stars = gfx.sprite.new(starsImage)
    stars:moveTo(200, 120)
    stars:add()

    local worldIndex = SELECTED_WORLD
    Utilities.animatedSprite(365, 45, planetImagetables[worldIndex], 100, true)

    self.levelCount = #allLevelPreviews[worldIndex]
    self.baseLevel = worldBaseLevel[worldIndex]
    self.selectedLevel = CUR_LEVEL - self.baseLevel + 1
    local previewImage = worldPreviews[worldIndex]
    self.levelsSprite = gfx.sprite.new(previewImage)
    self.levelsSprite:setCenter(0.0, 0.5)
    local targetX = previewX - borderWidth / 2 - (self.selectedLevel - 1) * (borderWidth + previewGap)
    self.levelsSprite:moveTo(targetX, previewY)
    self.levelsSprite:add()

    self.nameSprite = gfx.sprite.new(gfx.image.new(200, 120))
    self.nameSprite:setCenter(0.5, 0.5)
    self.nameSprite:moveTo(200, 32)
    self.nameSprite:add()
    self:updateName()

    self.transitioning = false
end

function LevelSelectScene:update()
    local targetX = self:getTargetX()
    if math.abs(self.levelsSprite.x - targetX) < 0.5 then
        self.levelsSprite:moveTo(targetX, previewY)
    else
        self.levelsSprite:moveTo(lerp(self.levelsSprite.x, targetX, smoothSpeed), previewY)
    end

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
        self.keyRepeatTimer:remove()
    end

    if pd.buttonJustPressed(pd.kButtonRight) then
        if self.keyRepeatTimer then
            self.keyRepeatTimer:remove()
        end
        self.keyRepeatTimer = pd.timer.keyRepeatTimer(function()
            self:moveRight()
        end)
    elseif pd.buttonJustReleased(pd.kButtonRight) then
        self.keyRepeatTimer:remove()
    end

    local crankTicks = pd.getCrankTicks(3)
    if crankTicks == -1 then
        self:moveLeft()
    elseif crankTicks == 1 then
        self:moveRight()
    elseif pd.buttonJustPressed(pd.kButtonA) then
        local transitioning = SceneManager.switchScene(GameScene, nil, nil)
        if transitioning then
            audioManager.play(audioManager.sfx.select)
            self.transitioning = true
            CUR_LEVEL = self.baseLevel + self.selectedLevel - 1
        end
    elseif pd.buttonJustPressed(pd.kButtonB) then
        SceneManager.switchScene(WorldSelectScene, nil, nil)
    end
end

function LevelSelectScene:moveLeft()
    audioManager.play(audioManager.sfx.navigate)
    self.selectedLevel = math.clamp(self.selectedLevel - 1, 1, self.levelCount)
    self:updateName()
end

function LevelSelectScene:moveRight()
    audioManager.play(audioManager.sfx.navigate)
    self.selectedLevel = math.clamp(self.selectedLevel + 1, 1, self.levelCount)
    self:updateName()
end

function LevelSelectScene:getTargetX()
    return previewX - borderWidth / 2 - (self.selectedLevel - 1) * (borderWidth + previewGap)
end

function LevelSelectScene:getSelectedLevel()
    local _, row, col = gridview:getSelection()
    return columnCount * (row - 1) + col
end

function LevelSelectScene:updateName()
    local levelName = ldtk.get_custom_data("Level_" .. self.baseLevel + self.selectedLevel - 1, "Name")
    local nameImage = gfx.imageWithText(levelName --[[@as string]], 400, 50, nil, nil, nil, kTextAlignment.center, titleFont)
    self.nameSprite:setImageDrawMode(gfx.kDrawModeFillWhite)
    self.nameSprite:setImage(nameImage)
end