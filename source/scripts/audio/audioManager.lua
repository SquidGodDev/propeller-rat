local pd <const> = playdate
local sp <const> = pd.sound.sampleplayer.new

local playedThisFrame = {}

AudioManager = {}
local audioManager <const> = AudioManager

AudioManager.sfx = {
    laser = sp("sound/level/laser"),
    teleport = sp("sound/level/teleport"),
    squeak1 = sp("sound/level/squeak1"),
    squeak2 = sp("sound/level/squeak2"),
    squeak3 = sp("sound/level/squeak3"),
    squeak4 = sp("sound/level/squeak4"),
    bounce = sp("sound/level/bounce"),
    shoot = sp("sound/level/shoot"),
    smash = sp("sound/level/smash"),
    navigate = sp("sound/ui/navigate"),
    select = sp("sound/ui/select"),
    error = sp("sound/ui/error"),
    transitionOut = sp("sound/ui/transitionOut"),
    transitionIn = sp("sound/ui/transitionIn")
}

AudioManager.play = function(sound, count)
    if not sound or playedThisFrame[sound] then
        return
    end
    playedThisFrame[sound] = true
    local sample = sound:copy()
    if count then
        sample:play(count)
    else
        sample:play()
    end
    return sample
end

AudioManager.playRandom = function(sounds)
    local sound = sounds[math.random(#sounds)]
    audioManager.play(sound)
end

AudioManager.fadeOut = function(sound, time)
    time = time or 1000 -- ms
    local timer = pd.timer.new(time, 1.0, 0)
    timer.updateCallback = function()
        sound:setVolume(timer.value)
    end
    timer.timerEndedCallback = function()
        sound:stop()
    end
end

AudioManager.clearPlayedThisFrame = function()
    playedThisFrame = {}
end