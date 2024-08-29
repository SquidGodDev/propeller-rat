local pd <const> = playdate
local gfx <const> = playdate.graphics

local font <const> = FONT

local typeSound = pd.sound.synth.new(pd.sound.kWaveSquare)
typeSound:setADSR(0.0, 0.02915, 0.006710, 0.0)

local dialog = {
    -- World 1
    {
        "wow. my first day at RODENT academy!",
        "still getting used to this propeller...",
        "i hope the orientation world isn't too rough!"
    },
    -- World 2
    {
        ""
    }
}

DialogBox = {}
class('DialogBox').extends()

function DialogBox:init(maxLineLen, lineSpacing)
    self.fontHeight = font:getHeight()
    self.maxLineLen = maxLineLen
    self.lineSpacing = lineSpacing

    self.lineBreakIndexes = nil
end

function DialogBox:setString(string)
    self.string = string
    self.lineBreakIndexes = self:calculateLineBreakIndex(string)
end

function DialogBox:calculateLineBreakIndex(string)
    local maxLineLen <const> = self.maxLineLen
    local lineBreakIndexes = {}
    if #string <= maxLineLen then
        table.insert(lineBreakIndexes, #string)
        return lineBreakIndexes
    end

    for line=1, math.floor((#string - 1) / maxLineLen) do
        for i=line * maxLineLen, (line - 1) * maxLineLen + 1, -1 do
            local char = string:sub(i, i)
            if char == ' ' then
                table.insert(lineBreakIndexes, i - 1)
                break
            end
        end
    end

    table.insert(lineBreakIndexes, #string)
    return lineBreakIndexes
end

function DialogBox:getDialogImage(index)
    local imageWidth = -1
    local imageHeight = 0
    local lines = {}
    for i=1, #self.lineBreakIndexes do
        local lineStartIndex <const> = i > 1 and (self.lineBreakIndexes[i - 1] + 1) or 1
        local lineBreakIndex <const> = self.lineBreakIndexes[i]
        local exit = index <= lineBreakIndex
        local line = self.string:sub(lineStartIndex, exit and index or lineBreakIndex)
        line = line:gsub("^%s+", "") -- Removing leading spaces
        imageWidth = math.max(font:getTextWidth(line), imageWidth)
        imageHeight += self.fontHeight + self.lineSpacing
        table.insert(lines, line)

        if exit then
            break
        end
    end
    local dialogImage = gfx.image.new(imageWidth, imageHeight)
    gfx.lockFocus(dialogImage)
        local drawY = 0
        for i=1, #lines do
            font:drawText(lines[i], 0, drawY)
            drawY += self.fontHeight + self.lineSpacing
        end
    gfx.unlockFocus()
    return dialogImage
end

StoryManager = {}
class('StoryManager').extends()

function StoryManager:init(world)
    self.dialog = dialog[world]

    local gradientImage = gfx.image.new("images/story/gradient")
    self.gradientSprite = gfx.sprite.new(gradientImage)
    self.gradientSprite:setCenter(0, 0)
    self.gradientSprite:moveTo(0, 240)
    self.gradientSprite:setZIndex(Z_INDEXES.dialog)
    self.gradientSprite:setIgnoresDrawOffset(true)
    self.gradientSprite:add()

    local portraitImagetable = gfx.imagetable.new("images/story/ratPortrait")
    self.portraitSprite = gfx.sprite.new(portraitImagetable[1])
    self.portraitSprite:setCenter(0, 0)
    self.portraitSprite:moveTo(10, 240)
    self.portraitSprite:setZIndex(Z_INDEXES.dialog)
    self.portraitSprite:setIgnoresDrawOffset(true)
    self.portraitSprite:add()
    local portraitAnimation = gfx.animation.loop.new(100, portraitImagetable, true)
    self.portraitSprite.update = function()
        self.portraitSprite:setImage(portraitAnimation:image())
    end

    local nameImage = gfx.image.new("images/story/lilDipperName")
    self.nameSprite = gfx.sprite.new(nameImage)
    self.nameSprite:setCenter(0, 0)
    self.nameSprite:moveTo(180, 240)
    self.nameSprite:setZIndex(Z_INDEXES.dialog)
    self.nameSprite:setIgnoresDrawOffset(true)
    self.nameSprite:add()

    self.dialogSprite = gfx.sprite.new()
    self.dialogSprite:setCenter(0, 0)
    self.dialogSprite:moveTo(180, 180)
    self.dialogSprite:setZIndex(Z_INDEXES.dialog)
    self.dialogSprite:setIgnoresDrawOffset(true)
    self.dialogSprite:add()

    local arrowImagetable = gfx.imagetable.new("images/story/downArrow")
    self.arrowSprite = gfx.sprite.new()
    self.arrowSprite:moveTo(380, 225)
    self.arrowSprite:setZIndex(Z_INDEXES.dialog)
    self.arrowSprite:setIgnoresDrawOffset(true)
    local arrowAnimation = gfx.animation.loop.new(200, arrowImagetable, true)
    self.arrowSprite.update = function()
        self.arrowSprite:setImage(arrowAnimation:image())
    end

    local maxDialogLen = 25
    local lineSpacing = 1
    self.dialogBox = DialogBox(maxDialogLen, lineSpacing)

    self.active = false
    self.inputActive = false
    self.curLine = 1
    self.curIndex = 1
    self.typeTimer = nil
end

function StoryManager:isActive()
    return self.active
end

function StoryManager:isInputActive()
    return self.inputActive
end

local function createAnimation(sprite, delay, time, endY, easingFunc, callback)
    easingFunc = easingFunc or pd.easingFunctions.outCubic
    local spriteX = sprite.x
    pd.timer.performAfterDelay(delay, function()
        local animateTimer = pd.timer.new(time, sprite.y, endY, easingFunc)
        animateTimer.updateCallback = function()
            sprite:moveTo(spriteX, animateTimer.value)
        end
        animateTimer.timerEndedCallback = function()
            sprite:moveTo(spriteX, endY)
            if callback then
                callback()
            end
        end
    end)
end

function StoryManager:animateIn()
    self.active = true

    local _, gradientHeight = self.gradientSprite:getSize()
    createAnimation(self.gradientSprite, 0, 1000, 240 - gradientHeight)
    local _, portraitHeight = self.portraitSprite:getSize()
    createAnimation(self.portraitSprite, 500, 1000, 240 - portraitHeight)
    createAnimation(self.nameSprite, 1000, 1000, 150, nil, function()
        self.inputActive = true
        self.curLine = 0
        self.arrowSprite:add()
        self:progress()
    end)
end

function StoryManager:animateOut()
    self.arrowSprite:remove()
    self.active = false
    self.inputActive = false

    local easingFunc = pd.easingFunctions.inCubic
    createAnimation(self.dialogSprite, 0, 700, 240, easingFunc)
    createAnimation(self.portraitSprite, 0, 700, 240, easingFunc)
    createAnimation(self.nameSprite, 300, 700, 240, easingFunc)
    createAnimation(self.gradientSprite, 500, 700, 240, easingFunc, function()
        self.dialogSprite:remove()
        self.portraitSprite:remove()
        self.nameSprite:remove()
        self.gradientSprite:remove()
    end)
end

function StoryManager:progress()
    if self.typeTimer then
        local curLineString = self.dialog[self.curLine]
        self.typeTimer:remove()
        self.typeTimer = nil
        self.dialogSprite:setImage(self.dialogBox:getDialogImage(#curLineString))
    else
        self.curLine += 1
        if self.curLine > #self.dialog then
            self.arrowSprite:remove()
            self:animateOut()
            return
        end

        self.curIndex = 0
        local curLineString = self.dialog[self.curLine]
        self.dialogBox:setString(curLineString)
        local function typeTimerCallback()
            self.curIndex += 1
            local curChar = curLineString:sub(self.curIndex, self.curIndex)
            while curChar == ' ' do
                self.curIndex += 1
                curChar = curLineString:sub(self.curIndex, self.curIndex)
            end
            self.dialogSprite:setImage(self.dialogBox:getDialogImage(self.curIndex))
            typeSound:playMIDINote(76, 0.4, 0.03)
            if self.curIndex >= #curLineString then
                self.typeTimer:remove()
                self.typeTimer = nil
            else
                local typeDelay = 40
                if curChar == '.' then
                    typeDelay = 100
                end
                self.typeTimer = pd.timer.new(typeDelay, typeTimerCallback)
            end
        end
        self.typeTimer = pd.timer.new(40, typeTimerCallback)
    end
end
