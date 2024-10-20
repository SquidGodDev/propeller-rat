local pd <const> = playdate
local gfx <const> = playdate.graphics

local font <const> = FONT

local typeSound = pd.sound.synth.new(pd.sound.kWaveSquare)
typeSound:setADSR(0.0, 0.02915, 0.006710, 0.0)

DIALOG = {
    opening = {
        "wow. my first day at RODENT academy!",
        "still getting used to this propeller...",
        "i hope the orientation world isn't too rough!"
    },
    -- INT-RO 1
    world1complete = {
        "that wasn't too bad!",
        "could go for a snack right about now though",
        "maybe a donut"
    },
    -- Blokiter
    world2start = {
        "i think i see something moving up ahead",
        "what is that?"
    },
    world2complete = {
        "phew. finally passed the second world!",
        "giant moving blocks...",
        "who comes up with these sorts of things?"
    },
    -- Chipkey
    world3start = {
        "someone said they have chips in these levels?",
        "thank goodness - i was feeling kinda hungry",
        "i heard they call them crisps in another world",
    },
    world3complete = {
        "those didn't taste anything like the chips back home",
        "this academy is going to be harder than i thought..."
    },
    -- Turretia
    world4start = {
        "t-t-turrets?",
        "is that, uh, safe?"
    },
    world4complete = {
        "ow.",
        "world four passed >.<"
    },
    -- LAZ-ER 5
    world5start = {
        "i don't think i can handle any more things firing at me...",
        "hopefully this next world doesn't have anything like that"
    },
    world5complete = {
        "phew. i think i barely dodged all those lasers",
        "wait - what's that burning smell?"
    },
    -- Spinturn
    world6start = {
        "oo what is that - a carnival ride?"
    },
    world6complete = {
        "i'm so dizzy...",
        "world... six... passed..."
    },
    -- Mixropa
    world7start = {
        "this looks tough...",
        "i can hardly keep up!"
    },
    world7complete = {
        "passed that one by a whisker!",
        "one more world until i graduate :o",
    },
    -- Hazarmede
    world8start = {
        "the last world...",
        "you got this dipper!!!"
    },
    world8complete = {
        "i did it!!!",
        "can't wait to tell my mischief that i'm a RODENT agent now!",
        "maybe i can improve my times in the other worlds",
        "i'm going to make it to the top of the leaderboards!",
        "or maybe i'll try out the new bonus levels?"
    }
}

DialogBox = {}
class('DialogBox').extends()

function DialogBox:init(lines, dialogSprite, maxLineLen, lineSpacing, finishCallback)
    self.lines = lines
    self.dialogSprite = dialogSprite
    self.fontHeight = font:getHeight()
    self.maxLineLen = maxLineLen
    self.lineSpacing = lineSpacing
    self.finishCallback = finishCallback

    self.lineBreakIndexes = nil
    self.curLine = 0
    self.curIndex = 0
    self.typeTimer = nil

    self.note = 76
    self.centerAlign = false

    self.speedUp = false
end

function DialogBox:update()
    if pd.buttonJustPressed(pd.kButtonA)
    or pd.buttonJustPressed(pd.kButtonB)
    or pd.buttonJustPressed(pd.kButtonRight) then
        self:progress()
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        self:progress(true)
    end

    if pd.buttonIsPressed(pd.kButtonA)
    or pd.buttonIsPressed(pd.kButtonB)
    or pd.buttonIsPressed(pd.kButtonRight) then
        self:setSpeedUp(true)
    else
        self:setSpeedUp(false)
    end
end

function DialogBox:setCenterAlignment()
    self.centerAlign = true
end

function DialogBox:setTypeSFXNote(note)
    self.note = note
end

function DialogBox:setSpeedUp(speedUp)
    self.speedUp = speedUp
end

function DialogBox:progress(skip)
    if self.typeTimer then
        if skip then
            local curLineString = self.lines[self.curLine]
            self.typeTimer:remove()
            self.typeTimer = nil
            self.dialogSprite:setImage(self:getDialogImage(#curLineString))
        end
        return
    end
    self.curLine += 1
    if self.curLine > #self.lines then
        self.finishCallback()
        return
    end

    self.curIndex = 0
    local curLineString = self.lines[self.curLine]
    self:setString(curLineString)
    local function typeTimerCallback()
        self.curIndex += 1
        local curChar = curLineString:sub(self.curIndex, self.curIndex)
        while curChar == ' ' do
            self.curIndex += 1
            curChar = curLineString:sub(self.curIndex, self.curIndex)
        end
        self.dialogSprite:setImage(self:getDialogImage(self.curIndex))
        typeSound:playMIDINote(self.note, 0.4, 0.03)
        if self.curIndex >= #curLineString then
            self.typeTimer:remove()
            self.typeTimer = nil
        else
            local typeDelay = 40
            if curChar == '.' then
                typeDelay = 100
            elseif curChar == '-' or curChar == ',' or curChar == '(' or curChar == ')' then
                typeDelay = 80
            end
            if self.speedUp then
                self.curIndex += 1
                typeDelay = 0
            end
            self.typeTimer = pd.timer.new(typeDelay, typeTimerCallback)
        end
    end
    self.typeTimer = pd.timer.new(40, typeTimerCallback)
end

function DialogBox:setString(string)
    self.string = string
    self.lineBreakIndexes = self:calculateLineBreakIndexes(string)
end

function DialogBox:calculateLineBreakIndexes(string)
    local maxLineLen <const> = self.maxLineLen
    local lineBreakIndexes = {}
    if #string <= maxLineLen then
        table.insert(lineBreakIndexes, #string)
    else
        local lastSpace = 1
        local curStringLen = 0
        local i = 1
        while i<#string do
            local char = string:sub(i, i)
            if char == ' ' then
                lastSpace = i
            end
            curStringLen += 1
            if curStringLen >= maxLineLen then
                curStringLen = 0
                i = lastSpace
                table.insert(lineBreakIndexes, lastSpace)
            end
            i += 1
        end
        -- for line=1, math.floor((#string - 1) / maxLineLen) do
        --     for i=line * maxLineLen, (line - 1) * maxLineLen + 1, -1 do
        --         local char = string:sub(i, i)
        --         if char == ' ' then
        --             table.insert(lineBreakIndexes, i - 1)
        --             break
        --         end
        --     end
        -- end
        table.insert(lineBreakIndexes, #string)
    end

    local maxLineWidth = 0
    for i=1, #lineBreakIndexes do
        local lineStartIndex <const> = i > 1 and (lineBreakIndexes[i - 1] + 1) or 1
        local lineBreakIndex <const> = lineBreakIndexes[i]
        local line = string:sub(lineStartIndex, lineBreakIndex)
        maxLineWidth = math.max(maxLineWidth, font:getTextWidth(line))
    end
    self.imageWidth = maxLineWidth
    self.imageHeight = self.fontHeight + (#lineBreakIndexes-1)*(self.lineSpacing + self.fontHeight)
    local emptyImage = gfx.image.new(self.imageWidth, self.imageHeight)
    self.dialogSprite:setImage(emptyImage)

    return lineBreakIndexes
end

function DialogBox:getDialogImage(index)
    local lines = {}
    for i=1, #self.lineBreakIndexes do
        local lineStartIndex <const> = i > 1 and (self.lineBreakIndexes[i - 1] + 1) or 1
        local lineBreakIndex <const> = self.lineBreakIndexes[i]
        local exit = index <= lineBreakIndex
        local line = self.string:sub(lineStartIndex, exit and index or lineBreakIndex)
        line = line:gsub("^%s+", "") -- Removing leading spaces
        table.insert(lines, line)

        if exit then
            break
        end
    end
    local dialogImage = gfx.image.new(self.imageWidth, self.imageHeight)
    gfx.lockFocus(dialogImage)
        local drawY = 0
        local centerAlignment = kTextAlignment.center
        for i=1, #lines do
            if self.centerAlign then
                font:drawTextAligned(lines[i], self.imageWidth/2, drawY, centerAlignment)
            else
                font:drawText(lines[i], 0, drawY)
            end
            drawY += self.fontHeight + self.lineSpacing
        end
    gfx.unlockFocus()
    return dialogImage
end

StoryManager = {}
class('StoryManager').extends()

function StoryManager:init(lines)
    if not lines then
        return
    end
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
    self.dialogBox = DialogBox(lines, self.dialogSprite, maxDialogLen, lineSpacing, function()
        self:animateOut()
    end)

    self.active = false
    self.inputActive = false

    self.shown = false
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
    if self.shown then
        return
    end

    self.active = true
    self.shown = true

    local _, gradientHeight = self.gradientSprite:getSize()
    createAnimation(self.gradientSprite, 0, 1000, 240 - gradientHeight)
    local _, portraitHeight = self.portraitSprite:getSize()
    createAnimation(self.portraitSprite, 500, 1000, 240 - portraitHeight)
    createAnimation(self.nameSprite, 1000, 1000, 150, nil, function()
        self.inputActive = true
        self.arrowSprite:add()
        self.dialogBox:progress()
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

function StoryManager:update()
    self.dialogBox:update()
end
