local pd <const> = playdate
local gfx <const> = playdate.graphics

local audioManager <const> = AudioManager

local lazyLoadAssets = Assets.lazyLoad
local ms = pd.getCurrentTimeMilliseconds

local transitionImage = nil

local newScene = nil

SceneManager = {}
SceneManager.transitioning = false

local timerUpdate = pd.timer.updateTimers
local spriteUpdate = gfx.sprite.update

local newImage <const> = gfx.image.new
local pushContext <const> = gfx.pushContext
local popContext <const> = gfx.popContext
local setColor <const> = gfx.setColor
local fillCircleAtPoint <const> = gfx.fillCircleAtPoint
local kColorBlack <const> = gfx.kColorBlack
local kColorWhite <const> = gfx.kColorWhite

local function setSceneUpdate(scene)
    local drawFps = DRAW_FPS
    pd.update = function()
        local frameStart = ms()
        spriteUpdate()
        scene:update()
        timerUpdate()
        if drawFps then
            pd.drawFPS(0, 228)
        end
        if transitionImage then
            transitionImage:drawIgnoringOffset(0, 0)
        end
        audioManager.clearPlayedThisFrame()
        lazyLoadAssets(frameStart)
    end
end

local function cleanupScene()
    gfx.sprite.removeAll()
    gfx.setDrawOffset(0, 0)
    pd.display.setOffset(0, 0)
    local systemMenu = pd.getSystemMenu()
    systemMenu:removeAllMenuItems()
    AudioManager.setMusicVolMenuOption()
    local allTimers = pd.timer.allTimers()
    for _, timer in ipairs(allTimers) do
        timer:remove()
    end
end

local function loadNewScene(args)
    if not newScene then
        return
    end

    cleanupScene()
    local sceneInstance = newScene(table.unpack(args))
    setSceneUpdate(sceneInstance)
end

function SceneManager.isTransitioning()
    return SceneManager.transitioning
end

function SceneManager.switchScene(scene, xIn, yIn, ...)
    if transitionImage then
        return false
    end

    SceneManager.transitioning = true
    newScene = scene
    local args = {...}

    SceneManager.startTransition(xIn, yIn, loadNewScene, args)
    return true
end

function SceneManager.startingScene(scene)
    local sceneInstance = scene()
    setSceneUpdate(sceneInstance)
end

function SceneManager.startTransition(xIn, yIn, callback, args)
    xIn = xIn and xIn or 200
    yIn = yIn and yIn or 120
    local xOut = xIn
    local yOut = yIn

    audioManager.play(audioManager.sfx.transitionOut)
    local transitionTime = 500
    local startRadius, endRadius = 0, 500
    local transitionTimer = pd.timer.new(transitionTime, endRadius, startRadius, pd.easingFunctions.outCubic)
    transitionImage = newImage(400, 240)
    transitionTimer.updateCallback = function()
        local transitionMask = newImage(400, 240, kColorWhite)
        pushContext(transitionMask)
            setColor(kColorBlack)
            fillCircleAtPoint(xOut, yOut, transitionTimer.value)
        popContext()
        transitionImage:setMaskImage(transitionMask)
    end

    transitionTimer.timerEndedCallback = function()
        if callback then
            callback(args)
        end

        audioManager.play(audioManager.sfx.transitionIn)
        transitionTimer = pd.timer.new(transitionTime, startRadius, endRadius, pd.easingFunctions.inCubic)
        transitionImage = newImage(400, 240, kColorBlack)
        local transitionMask = newImage(400, 240, kColorWhite)
        transitionTimer.updateCallback = function()
            pushContext(transitionMask)
                setColor(kColorBlack)
                fillCircleAtPoint(xOut, yOut, transitionTimer.value)
            popContext()
            transitionImage:setMaskImage(transitionMask)
        end

        transitionTimer.timerEndedCallback = function()
            SceneManager.transitioning = false
            transitionImage = nil
        end
    end
end
