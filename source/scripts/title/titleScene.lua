local pd <const> = playdate
local gfx <const> = playdate.graphics

local audioManager <const> = AudioManager

local li = {
    p = gfx.image.new("images/title/letters/p"),
    r = gfx.image.new("images/title/letters/r"),
    o = gfx.image.new("images/title/letters/o"),
    l = gfx.image.new("images/title/letters/l"),
    e = gfx.image.new("images/title/letters/e"),
    a = gfx.image.new("images/title/letters/a"),
    t = gfx.image.new("images/title/letters/t"),
    rat = gfx.image.new("images/title/letters/rat")
}

local font = FONT
local backgroundImage = gfx.image.new("images/decoration/stars")

local ratChance = 0.05

local moveTime = 1500
local offScreenY = 300
local topRowY = 30
local bottomRowY = 84
local ratChar = 9

local letterOrder = {li.p, li.r, li.o, li.p, li.e, li.l, li.l, li.e, li.r, li.r, li.a, li.t}
local xPositions = {59, 97, 124, 164, 201, 240, 256, 271, 310, 153, 182, 220}

local DEBUG_MODE_ENABLED <const> = true
local buttonQueueMax = 7
local debugQueueMatch = {"up", "right", "down", "left", "b", "b", "b"}

TitleScene = {}
class('TitleScene').extends()

function TitleScene:init()
    self.transitioning = false

    audioManager.playSong(audioManager.songs.cosmicDust)

    gfx.setBackgroundColor(gfx.kColorBlack)
    gfx.clear()

    local backgroundSprite = gfx.sprite.new(backgroundImage)
    backgroundSprite:moveTo(200, 120)
    backgroundSprite:add()

    for i=1, #letterOrder do
        local letterX = xPositions[i]
        local letterY = i <= ratChar and topRowY or bottomRowY
        local letterImage = letterOrder[i]
        if i == ratChar and math.random() < ratChance then
            letterImage = li.rat
        end
        local letterSprite = gfx.sprite.new(letterImage)
        letterSprite:setCenter(0, 0)
        letterSprite:moveTo(letterX, offScreenY)
        letterSprite:add()

        local delayTime = i * 100
        pd.timer.performAfterDelay(delayTime, function()
            local moveTimer = pd.timer.new(moveTime, offScreenY, letterY, pd.easingFunctions.outBack)
            moveTimer.updateCallback = function()
                letterSprite:moveTo(letterX, moveTimer.value)
            end
        end)

        if i == #letterOrder then
            pd.timer.performAfterDelay(delayTime + 1000, function()
                local startText = gfx.sprite.spriteWithText("Press A to start", 400, 40, nil, nil, nil, kTextAlignment.center, font)
                startText:moveTo(200, 200)
                startText:add()

                local blinkerTimer = pd.timer.new(500, function()
                    startText:setVisible(not startText:isVisible())
                end)
                blinkerTimer.repeats = true
            end)
        end
    end

    self.debugModeSprite = gfx.sprite.spriteWithText("GAME IN DEBUG MODE", 200, 30, nil, nil, nil, nil, font)
    self.debugModeSprite:moveTo(200, 120)
    if DRAW_FPS or UNLOCK_ALL_WORLDS then
        self.debugModeSprite:add()
    end

    self.buttonQueue = {}

    self.enteringScene = true
end

function TitleScene:update()
    if not SceneManager.isTransitioning() then
        self.enteringScene = false
    else
        return
    end

    if pd.buttonJustPressed(pd.kButtonA) and not self.transitioning then
        SceneManager.switchScene(WorldSelectScene)
        self.transitioning = true
        audioManager.play(audioManager.sfx.select)
    end

    if pd.buttonJustPressed(pd.kButtonUp) then
        self:addToButtonQueue("up")
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        self:addToButtonQueue("right")
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        self:addToButtonQueue("down")
    elseif pd.buttonJustPressed(pd.kButtonLeft) then
        self:addToButtonQueue("left")
    elseif pd.buttonJustPressed(pd.kButtonB) then
        self:addToButtonQueue("b")
    end
end

function TitleScene:addToButtonQueue(button)
    if #self.buttonQueue >= buttonQueueMax then
        table.remove(self.buttonQueue, 1)
    end
    table.insert(self.buttonQueue, button)
    if #self.buttonQueue == buttonQueueMax then
        local matched = true
        for i=1,#self.buttonQueue do
            if self.buttonQueue[i] ~= debugQueueMatch[i] then
                matched = false
            end
        end
        if matched and DEBUG_MODE_ENABLED then
            if UNLOCK_ALL_WORLDS then
                UNLOCK_ALL_WORLDS = false
                DRAW_FPS = false
                if pd.isSimulator then
                    LEVEL_PASS_KEY = false
                end
                self.debugModeSprite:remove()
                audioManager.play(audioManager.sfx.navigate)
            else
                UNLOCK_ALL_WORLDS = true
                DRAW_FPS = true
                if pd.isSimulator then
                    LEVEL_PASS_KEY = true
                end
                self.debugModeSprite:add()
                audioManager.play(audioManager.sfx.select)
            end
        end
    end
end