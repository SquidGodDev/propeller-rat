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

class('TitleScene').extends()

function TitleScene:init()
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
            moveTimer.updateCallback = function(timer)
                letterSprite:moveTo(letterX, timer.value)
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
end

function TitleScene:update()
    if pd.buttonJustPressed(pd.kButtonA) then
        SceneManager.switchScene(WorldSelectScene)
    end
end