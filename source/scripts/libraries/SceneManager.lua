local pd <const> = playdate
local gfx <const> = playdate.graphics

local transitionTime = 500
local transitionMidFrame = 20

local transitionImage = nil

local newScene = nil

SceneManager = {}

local timerUpdate = pd.timer.updateTimers
local spriteUpdate = gfx.sprite.update

function SceneManager.switchScene(scene)
    if transitionImage then
        return
    end

    newScene = scene

    startTransition()
end

function SceneManager.startingScene(scene)
    scene.init()
    setSceneUpdate(scene)
end

function loadNewScene()
    cleanupScene()
    newScene:init()
    setSceneUpdate(newScene)
end

function setSceneUpdate(scene)
    local drawFps = DRAW_FPS
    pd.update = function()
        spriteUpdate()
        scene:update()
        timerUpdate()
        if drawFps then
            pd.drawFPS(0, 228)
        end
        if transitionImage then
            transitionImage:drawIgnoringOffset(0, 0)
        end
    end
end

function cleanupScene()
    gfx.sprite.removeAll()
    gfx.setDrawOffset(0, 0)
    local allTimers = pd.timer.allTimers()
    for _, timer in ipairs(allTimers) do
        timer:remove()
    end
end

function startTransition()
    local transitionTimer = createTransitionTimer(400, 0)

    transitionTimer.timerEndedCallback = function()
        loadNewScene()
        transitionTimer = createTransitionTimer(0, 400)
        transitionTimer.timerEndedCallback = function()
            transitionImage = nil
        end
    end
end

function createTransitionTimer(startRadius, endRadius)
    local transitionTimer = pd.timer.new(transitionTime, startRadius, endRadius)
    transitionTimer.easingFunction = pd.easingFunctions.inCubic
    transitionTimer.updateCallback = function(timer)
        transitionImage = gfx.image.new(400, 240)
        gfx.pushContext(transitionImage)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillCircleAtPoint(200, 120, timer.value)
        gfx.popContext()
    end
    return transitionTimer
end