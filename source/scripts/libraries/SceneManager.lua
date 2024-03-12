local pd <const> = playdate
local gfx <const> = playdate.graphics

local transitionImage = nil

local newScene = nil

local drawQueue = {}

SceneManager = {}

local timerUpdate = pd.timer.updateTimers
local spriteUpdate = gfx.sprite.update
local drawUpdate = function()
    for i=1, #drawQueue do
        drawQueue[i]()
    end
    drawQueue = {}
end

function SceneManager.switchScene(scene, xIn, yIn, xOut, yOut)
    if transitionImage then
        return
    end

    newScene = scene

    startTransition(xIn, yIn, xOut, yOut)
end

function SceneManager.startingScene(scene)
    scene()
    setSceneUpdate(scene)
end

function SceneManager.addToDrawQueue(drawFunc)
    table.insert(drawQueue, drawFunc)
end

function loadNewScene()
    cleanupScene()
    setSceneUpdate(newScene())
end

function setSceneUpdate(scene)
    local drawFps = DRAW_FPS
    pd.update = function()
        spriteUpdate()
        scene:update()
        timerUpdate()
        drawUpdate()
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
    pd.display.setOffset(0, 0)
    drawQueue = {}
    local systemMenu = pd.getSystemMenu()
    systemMenu:removeAllMenuItems()
    local allTimers = pd.timer.allTimers()
    for _, timer in ipairs(allTimers) do
        timer:remove()
    end
end

function startTransition(xIn, yIn, xOut, yOut)
    xIn = xIn and xIn or 200
    yIn = yIn and yIn or 120
    xOut = xOut and xOut or xIn
    yOut = yOut and yOut or yIn

    local transitionTime = 700
    local startRadius, endRadius = 0, 500
    local transitionTimer = pd.timer.new(transitionTime, startRadius, endRadius, pd.easingFunctions.inCubic)
    transitionTimer.updateCallback = function()
        transitionImage = gfx.image.new(400, 240)
        gfx.pushContext(transitionImage)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(xIn, yIn, transitionTimer.value)
        gfx.popContext()
    end

    transitionTimer.timerEndedCallback = function()
        loadNewScene()

        transitionTimer = pd.timer.new(transitionTime, startRadius, endRadius)
        transitionTimer.updateCallback = function()
            transitionImage = gfx.image.new(400, 240, gfx.kColorWhite)
            local transitionMask = gfx.image.new(400, 240, gfx.kColorWhite)
            gfx.pushContext(transitionMask)
                gfx.setColor(gfx.kColorBlack)
                gfx.fillCircleAtPoint(xOut, yOut, transitionTimer.value)
            gfx.popContext()
            transitionImage:setMaskImage(transitionMask)
        end

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
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(200, 120, timer.value)
        gfx.popContext()
    end
    return transitionTimer
end