local pd <const> = playdate
local gfx <const> = pd.graphics

local assets <const> = Assets
local utilities <const> = Utilities
local audioManager <const> = AudioManager

assets.preloadImages({
    "images/title/gameCompleted/thanksForPlaying",
    "images/decoration/stars"
})

local font = FONT

local levelTimes = LEVEL_TIMES

GameCompletedScene = {}
class('GameCompletedScene').extends()

function GameCompletedScene:init()
    local backgroundImage = assets.getImage("images/decoration/stars")
    local backgroundSprite = gfx.sprite.new(backgroundImage)
    backgroundSprite:moveTo(200, 120)
    backgroundSprite:add()

    local thanksForPlayingImage = assets.getImage("images/title/gameCompleted/thanksForPlaying")
    local thanksForPlayingSprite = gfx.sprite.new(thanksForPlayingImage)
    thanksForPlayingSprite:moveTo(200, 300)
    thanksForPlayingSprite:add()
    local thanksForPlayingY = 45
    local animateTime = 1500
    audioManager.play(audioManager.sfx.celebrate)
    local animateTimer = pd.timer.new(animateTime, thanksForPlayingSprite.y, thanksForPlayingY, pd.easingFunctions.outBack)
    animateTimer.updateCallback = function()
        thanksForPlayingSprite:moveTo(200, animateTimer.value)
    end

    local levelTimeTotal = 0
    for _, levelTime in pairs(levelTimes) do
        levelTimeTotal += levelTime
    end
    local hours = math.floor(levelTimeTotal / (60 * 60))
    local minutes = math.floor(levelTimeTotal / 60)
    local remainingSeconds = math.floor(levelTimeTotal) % 60
    -- local milliseconds = math.floor((levelTimeTotal - math.floor(levelTimeTotal)) * 1000)

    local textX = 200
    local numberX = 340

    local drawFont = font
    local worldTimeY = 100
    local worldTextSprite = utilities.spriteWithText("Best Times Total:", drawFont)
    worldTextSprite:setCenter(1.0, 0.0)
    worldTextSprite:moveTo(textX, worldTimeY)
    local worldTimeString = string.format("%02dh:%02dm:%02ds", hours, minutes, remainingSeconds)
    local worldTimeSprite = utilities.spriteWithText(worldTimeString, drawFont)
    worldTimeSprite:setCenter(1.0, 0.0)
    worldTimeSprite:moveTo(numberX, worldTimeY)

    local crashCountY = 150
    local crashTextSprite = utilities.spriteWithText("Crash Count:", drawFont)
    crashTextSprite:setCenter(1.0, 0.0)
    crashTextSprite:moveTo(textX, crashCountY)
    local crashCountSprite = utilities.spriteWithText(tostring(DEATH_COUNT), drawFont)
    crashCountSprite:setCenter(1.0, 0.0)
    crashCountSprite:moveTo(numberX, crashCountY)

    local backSprite = utilities.spriteWithText("B to Return", drawFont)
    backSprite:setVisible(false)
    backSprite:moveTo(200, 200)
    backSprite:add()

    Chain():link(2000, function()
        worldTextSprite:add()
        audioManager.play(audioManager.sfx.thud)
    end):link(500, function()
        worldTimeSprite:add()
        audioManager.play(audioManager.sfx.thud)
    end):link(500, function()
        crashTextSprite:add()
        audioManager.play(audioManager.sfx.thud)
    end):link(500, function()
        crashCountSprite:add()
        audioManager.play(audioManager.sfx.thud)
        self.animationFinished = true
        local blinkTimer = pd.timer.new(500, function()
            if not backSprite:isVisible() then
                audioManager.play(audioManager.sfx.blip)
            end
            backSprite:setVisible(not backSprite:isVisible())
        end)
        blinkTimer.repeats = true
    end)

    self.animationFinished = false
end

function GameCompletedScene:update()
    if not self.animationFinished then
        return
    end

    if pd.buttonJustPressed(pd.kButtonA) or pd.buttonJustPressed(pd.kButtonB) then
        SceneManager.switchScene(WorldSelectScene)
    end
end