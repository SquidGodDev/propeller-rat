local pd <const> = playdate
local gfx <const> = playdate.graphics

local ldtk <const> = LDtk

local assets <const> = Assets
assets.preloadImages({
    "images/levelSelect/previewBorder",
    "images/decoration/stars"
})
assets.preloadImagetable("images/decoration/planet")

local lerp <const> = function(a, b, t)
    return a * (1-t) + b * t
end
local smoothSpeed <const> = 0.15

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
local icons = {
    Start = startIcon,
    End = endIcon,
    Block = blockIcon,
    Laser = laserIcon,
    Spinner = spinnerIcon,
    Turret = turretIcon
}

local levelPreviews = {}
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
        levelPreviews[levelIndex] = previewImage
    gfx.popContext()
end

local previewX, previewY = 200, 140
local previewGap = 35
local previewBorder = gfx.image.new("images/levelSelect/previewBorder")
local borderWidth, borderHeight = previewBorder:getSize()
local borderDrawX, borderDrawY = 6, 6
local allPreviewsWidth = levelCount * borderWidth + (levelCount - 1) * previewGap
local allPreviews = gfx.image.new(allPreviewsWidth, borderHeight)

local drawX = 0
gfx.pushContext(allPreviews)
    for i=1, levelCount do
        local preview = levelPreviews[i]
        previewBorder:draw(drawX, 0)
        preview:draw(drawX + borderDrawX, borderDrawY)
        drawX += previewGap + borderWidth
    end
gfx.popContext()

class('LevelSelectScene').extends()

function LevelSelectScene:init()
    self.selectedLevel = CUR_LEVEL

    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    local starsImage = Assets.getImage("images/decoration/stars")
    local stars = gfx.sprite.new(starsImage)
    stars:moveTo(200, 120)
    stars:add()

    Utilities.animatedSprite(365, 45, "images/decoration/planet", 100, true)

    self.levelsSprite = gfx.sprite.new(allPreviews)
    self.levelsSprite:setCenter(0.0, 0.5)
    self.levelsSprite:moveTo(self:getTargetX(), previewY)
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

    local crankTicks = pd.getCrankTicks(3)
    if pd.buttonJustPressed(pd.kButtonLeft) or crankTicks == -1 then
        self.selectedLevel = math.clamp(self.selectedLevel - 1, 1, levelCount)
        self:updateName()
    elseif pd.buttonJustPressed(pd.kButtonRight) or crankTicks == 1 then
        self.selectedLevel = math.clamp(self.selectedLevel + 1, 1, levelCount)
        self:updateName()
    elseif pd.buttonJustPressed(pd.kButtonA) then
        self.transitioning = true
        CUR_LEVEL = self.selectedLevel
        SceneManager.switchScene(GameScene)
    end
end

function LevelSelectScene:getTargetX()
    return previewX - borderWidth / 2 - (self.selectedLevel - 1) * (borderWidth + previewGap)
end

function LevelSelectScene:getSelectedLevel()
    local _, row, col = gridview:getSelection()
    return columnCount * (row - 1) + col
end

function LevelSelectScene:updateName()
    local levelName = ldtk.get_custom_data("Level_" .. self.selectedLevel, "Name")
    local nameImage = gfx.imageWithText(levelName, 400, 50, nil, nil, nil, kTextAlignment.center, titleFont)
    self.nameSprite:setImageDrawMode(gfx.kDrawModeFillWhite)
    self.nameSprite:setImage(nameImage)
end