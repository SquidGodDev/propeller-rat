local pd <const> = playdate
local sp <const> = pd.sound.sampleplayer.new

AudioManager = {}

AudioManager.sfx = {
    laser = sp("sound/level/laser"),
    teleport = sp("sound/level/teleport"),
    propeller = sp("sound/level/propeller"),
    navigate = sp("sound/ui/navigate"),
    select = sp("sound/ui/select"),
    transitionOut = sp("sound/ui/transitionOut"),
    transitionIn = sp("sound/ui/transitionIn")
}

AudioManager.play = function(sound, count)
    if not sound then
        return
    end
    local sample = sound:copy()
    if count then
        sample:play(count)
    else
        sample:play()
    end
    return sample
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