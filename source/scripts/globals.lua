local pd <const> = playdate
local gfx <const> = pd.graphics

math.randomseed(pd.getSecondsSinceEpoch())

TAGS = {
    player = 1,
    hazard = 2,
    projectile = 3,
    pickup = 4,
    wall = 5
}

Z_INDEXES = {
    helpText = 5,
    level = 10,
    pickup = 20,
    player = 30,
    hazard = 40,
    projectile = 50,
    ui = 100,
    dialog = 200,
    transition = 1000
}

local earthPlanet = gfx.imagetable.new("images/decoration/earthPlanet")
local lightPlanet = gfx.imagetable.new("images/decoration/lightPlanet")
local darkPlanet = gfx.imagetable.new("images/decoration/darkPlanet")
local moonPlanet = gfx.imagetable.new("images/decoration/moonPlanet")
local cloudPlanet = gfx.imagetable.new("images/decoration/cloudPlanet")
local lightMoonPlanet = gfx.imagetable.new("images/decoration/lightMoonPlanet")
local sunPlanet = gfx.imagetable.new("images/decoration/sunPlanet")
local gasPlanet = gfx.imagetable.new("images/decoration/gasPlanet")
PLANET_IMAGETABLES = {earthPlanet, lightPlanet, darkPlanet, moonPlanet, cloudPlanet, lightMoonPlanet, sunPlanet, gasPlanet}

FONT = gfx.font.new("data/fonts/m6x11-12")
TITLE_FONT = gfx.font.new("data/fonts/m6x11-26")

-- DEBUG
local debugMode = false
DRAW_FPS = debugMode
UNLOCK_ALL_WORLDS = debugMode
LEVEL_PASS_KEY = debugMode

-- Save Data
CUR_LEVEL = 1
SELECTED_WORLD = 1
LAST_SELECTED_LEVEL = {}
LEVEL_TIMES = {}
UNLOCKED_WORLDS = {}
CUR_MUSIC_VOL = "Med"
DEATH_COUNT = 0
SHOW_DEATH_COUNT = false
GAME_END_SHOWN_1_0_0 = false

-- Global Data
JUST_COMPLETED_LEVEL = nil

local function loadGameData()
    local gameData = pd.datastore.read()
    if gameData then
        CUR_LEVEL = gameData.curLevel or CUR_LEVEL
        SELECTED_WORLD = gameData.selectedWorld or SELECTED_WORLD
        LAST_SELECTED_LEVEL = gameData.lastSelectedLevel or LAST_SELECTED_LEVEL
        LEVEL_TIMES = gameData.levelTimes or LEVEL_TIMES
        UNLOCKED_WORLDS = gameData.unlockedWorlds or UNLOCKED_WORLDS
        CUR_MUSIC_VOL = gameData.curMusicVol or CUR_MUSIC_VOL
        DEATH_COUNT = gameData.deathCount or DEATH_COUNT
        SHOW_DEATH_COUNT = gameData.showDeathCount or SHOW_DEATH_COUNT
        GAME_END_SHOWN_1_0_0 = gameData.gameEndShown100 or GAME_END_SHOWN_1_0_0
    end
end

loadGameData()

local function saveGameData()
    local gameData = {
        curLevel = CUR_LEVEL,
        selectedWorld = SELECTED_WORLD,
        lastSelectedLevel = LAST_SELECTED_LEVEL,
        levelTimes = LEVEL_TIMES,
        unlockedWorlds = UNLOCKED_WORLDS,
        curMusicVol = CUR_MUSIC_VOL,
        deathCount = DEATH_COUNT,
        showDeathCount = SHOW_DEATH_COUNT,
        gameEndShown100 = GAME_END_SHOWN_1_0_0
    }

    pd.datastore.write(gameData)
end

function pd.gameWillTerminate()
    saveGameData()
end

function pd.deviceWillSleep()
    saveGameData()
end

-- Level IDs
LEVEL_INDEX_TO_IID = {}
LEVEL_IID_BY_WORLD = {}

-- Core
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"
import "CoreLibs/animation"
import "CoreLibs/crank"

import "scripts/tests"
import "scripts/audio/audioManager"

-- Libraries
import "scripts/libraries/LDtk"
import "scripts/libraries/Utilities"
import "scripts/libraries/Assets"
import "scripts/libraries/SceneManager"

-- Game
import "scripts/player/player"

-- Hazards
import "scripts/hazards/hazard"
import "scripts/hazards/spinner"
import "scripts/hazards/block"
import "scripts/hazards/turret"
import "scripts/hazards/laser"

-- Pickups
import "scripts/pickups/pickup"
import "scripts/pickups/levelEnd"
import "scripts/pickups/key"

-- Levels
import "scripts/levels/level"

import "scripts/game/gameScene"

-- Title
import "scripts/title/starfield"
import "scripts/title/titleScene"
import "scripts/title/levelSelectScene"
import "scripts/title/worldSelectScene"
import "scripts/title/gameCompletedScene"

-- Story
import "scripts/story/storyManager"
import "scripts/story/introScene"

if pd.isSimulator then
    SANITY_CHECKS()
end
