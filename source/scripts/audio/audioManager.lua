local pd <const> = playdate
local sp <const> = pd.sound.sampleplayer.new
local fp <const> = pd.sound.fileplayer.new

local playedThisFrame = {}
local currentlyPlayingSong

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
    teleporterPowerUp = sp("sound/level/teleporterPowerUp"),
    chipPickUp = sp("sound/level/chipPickUp"),
    release = sp("sound/level/release"),
    navigate = sp("sound/ui/navigate"),
    select = sp("sound/ui/select"),
    error = sp("sound/ui/error"),
    unlocked = sp("sound/ui/unlocked"),
    transitionOut = sp("sound/ui/transitionOut"),
    transitionIn = sp("sound/ui/transitionIn")
}

local lowVol = 0.1
local medVol = 0.2
local highVol = 0.4
AudioManager.songs = {
    cosmicDust = fp("sound/music/CosmicDust")
}
AudioManager.songs.cosmicDust:setVolume(medVol)
AudioManager.volume = medVol

AudioManager.playSong = function(song)
    if song == currentlyPlayingSong then
        return
    end

    if currentlyPlayingSong then
        local previousSong = currentlyPlayingSong
        previousSong:setVolume(0, nil, 1.0, function()
            previousSong:stop()
        end)
    end

    currentlyPlayingSong = song
    AudioManager.updateMusicVol(CUR_MUSIC_VOL)
    song:play(0)
end

AudioManager.setMusicVolMenuOption = function()
    local menu = pd.getSystemMenu()
    menu:addOptionsMenuItem("Music", {"Off", "Low", "Med", "High"}, CUR_MUSIC_VOL, function(value)
        if currentlyPlayingSong then
            CUR_MUSIC_VOL = value
            AudioManager.updateMusicVol(value)
        end
    end)
end

AudioManager.updateMusicVol = function(value)
    local volume = 0.0
    if value == "Low" then
        volume = lowVol
    elseif value == "Med" then
        volume = medVol
    elseif value == "High" then
        volume = highVol
    end
    currentlyPlayingSong:setVolume(volume)
end

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