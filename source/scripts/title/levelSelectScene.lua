local pd <const> = playdate
local gfx <const> = playdate.graphics

local ldtk <const> = LDtk

local font = gfx.font.new("data/fonts/arial-narrow-8-20")
local titleFont = gfx.font.new("data/fonts/m6x11-26")

local iconBorder = gfx.image.new("images/title/levelIconBorder")
local cursor = gfx.image.new("images/title/levelSelectCursor")

local gridview = pd.ui.gridview.new(iconBorder:getSize())
local columnCount = 6
gridview:setNumberOfColumns(columnCount)
gridview:setCellPadding(0, 20, 0, 24)
gridview:setNumberOfRows(3)

local gridviewSprite = gfx.sprite.new()
gridviewSprite:setCenter(0, 0)
gridviewSprite:moveTo(23, 51)

local nameSprite = gfx.sprite.new()
nameSprite:setCenter(0.5, 0.5)
nameSprite:moveTo(200, 26)

function gridview:drawCell(_, row, column, selected, x, y, width, height)
    if selected then
        cursor:draw(x, y)
    end
    iconBorder:draw(x + 7, y + 7)
    local levelNum = columnCount * (row - 1) + column
    gfx.pushContext()
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        local xOffset = (levelNum / 10 > 1) and 26 or 27
        font:drawTextAligned(levelNum, x + xOffset, y + 7, kTextAlignment.center)
    gfx.popContext()
end

class('LevelSelectScene').extends()

function LevelSelectScene:init()
    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    self.selectedLevel = self:getSelectedLevel()
    self:updateName()

    gridviewSprite:add()
    nameSprite:add()

    self.transitioning = false
end

function LevelSelectScene:update()
    if self.transitioning then
        return
    end

    local selectedLevel = self:getSelectedLevel()
    if self.selectedLevel ~= selectedLevel then
        self.selectedLevel = selectedLevel
        self:updateName()
    end

    if pd.buttonJustPressed(pd.kButtonUp) then
        gridview:selectPreviousRow(false)
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        gridview:selectNextRow(false)
    elseif pd.buttonJustPressed(pd.kButtonLeft) then
        gridview:selectPreviousColumn(true)
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        gridview:selectNextColumn(true)
    elseif pd.buttonJustPressed(pd.kButtonA) then
        self.transitioning = true
        CUR_LEVEL = self.selectedLevel
        local x, y, width, height = gridview:getCellBounds(gridview:getSelection())
        local transitionX = gridviewSprite.x + x + width * 2/3
        local transitionY = gridviewSprite.y + y + height * 2/3
        SceneManager.switchScene(GameScene, transitionX, transitionY, 200, 120)
    end

    local gridviewImage = gfx.image.new(384, 192)
    gfx.pushContext(gridviewImage)
        gridview:drawInRect(0, 0, 384, 192)
    gfx.popContext()
    gridviewSprite:setImage(gridviewImage)
end

function LevelSelectScene:getSelectedLevel()
    local _, row, col = gridview:getSelection()
    return columnCount * (row - 1) + col
end

function LevelSelectScene:updateName()
    local levelName = ldtk.get_custom_data("Level_" .. self.selectedLevel, "Name")
    local nameImage = gfx.imageWithText(levelName, 400, 50, nil, nil, nil, kTextAlignment.center, titleFont)
    nameSprite:setImageDrawMode(gfx.kDrawModeFillWhite)
    nameSprite:setImage(nameImage)
end