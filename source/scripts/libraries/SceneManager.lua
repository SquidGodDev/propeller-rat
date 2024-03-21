local pd <const> = playdate
local gfx <const> = playdate.graphics

local audioManager <const> = AudioManager

local lazyLoadAssets = Assets.lazyLoad
local ms = pd.getCurrentTimeMilliseconds

local transitionImage = nil

local newScene = nil

local drawQueue = {}
local uiQueue = {}

SceneManager = {}

local timerUpdate = pd.timer.updateTimers
local spriteUpdate = gfx.sprite.update
local drawUpdate = function()
    for i=#drawQueue, 1, -1 do
        local drawObject = drawQueue[i]
        local drawUpdate = drawObject.update
        local remove = drawUpdate(drawObject)
        if remove then
            table.remove(drawQueue, i)
        end
    end
end
local uiUpdate = function()
    for i=#uiQueue, 1, -1 do
        local drawObject = uiQueue[i]
        local uiUpdate = drawObject.update
        local remove = uiUpdate(drawObject)
        if remove then
            table.remove(uiQueue, i)
        end
    end
end

function SceneManager.switchScene(scene, xIn, yIn, xOut, yOut)
    if transitionImage then
        return
    end

    newScene = scene

    SceneManager.startTransition(xIn, yIn, xOut, yOut, loadNewScene)
end

function SceneManager.startingScene(scene)
    local sceneInstance = scene()
    setSceneUpdate(sceneInstance)
end

function SceneManager.addToDrawQueue(drawObject)
    table.insert(drawQueue, drawObject)
end

function SceneManager.addToUiQueue(drawObject)
    table.insert(uiQueue, drawObject)
end

function loadNewScene()
    cleanupScene()
    local sceneInstance = newScene()
    setSceneUpdate(sceneInstance)
end

function setSceneUpdate(scene)
    local drawFps = DRAW_FPS
    pd.update = function()
        spriteUpdate()
        scene:update()
        timerUpdate()
        drawUpdate()
        uiUpdate()
        if drawFps then
            pd.drawFPS(0, 228)
        end
        if transitionImage then
            transitionImage:drawIgnoringOffset(0, 0)
        end

        lazyLoadAssets(ms())
    end
end

function cleanupScene()
    gfx.sprite.removeAll()
    gfx.setDrawOffset(0, 0)
    pd.display.setOffset(0, 0)
    drawQueue = {}
    uiQueue = {}
    local systemMenu = pd.getSystemMenu()
    systemMenu:removeAllMenuItems()
    local allTimers = pd.timer.allTimers()
    for _, timer in ipairs(allTimers) do
        timer:remove()
    end
end

function SceneManager.startTransition(xIn, yIn, xOut, yOut, callback)
    xIn = xIn and xIn or 200
    yIn = yIn and yIn or 120
    xOut = xOut and xOut or xIn
    yOut = yOut and yOut or yIn

    audioManager.play(audioManager.sfx.transitionOut)
    local transitionTime = 1000
    local startRadius, endRadius = 0, 500
    transitionTimer = pd.timer.new(transitionTime, endRadius, startRadius, pd.easingFunctions.outCubic)
    transitionTimer.updateCallback = function()
        transitionImage = gfx.image.new(400, 240, gfx.kColorBlack)
        local transitionMask = gfx.image.new(400, 240, gfx.kColorWhite)
        gfx.pushContext(transitionMask)
            gfx.setColor(gfx.kColorBlack)
            gfx.fillCircleAtPoint(xOut, yOut, transitionTimer.value)
        gfx.popContext()
        transitionImage:setMaskImage(transitionMask)
    end

    transitionTimer.timerEndedCallback = function()
        if callback then
            callback()
        end

        audioManager.play(audioManager.sfx.transitionIn)
        transitionTimer = pd.timer.new(transitionTime, startRadius, endRadius, pd.easingFunctions.inCubic)
        transitionTimer.updateCallback = function()
            transitionImage = gfx.image.new(400, 240, gfx.kColorBlack)
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