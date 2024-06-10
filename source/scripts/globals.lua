local pd <const> = playdate
local gfx <const> = pd.graphics

math.randomseed(pd.getSecondsSinceEpoch())

DRAW_FPS = true

TAGS = {
    player = 1,
    hazard = 2,
    projectile = 3,
    pickup = 4,
    wall = 5
}

Z_INDEXES = {
    level = 10,
    pickup = 20,
    player = 30,
    hazard = 40,
    projectile = 50,
    ui = 100,
    transition = 1000
}

local earthPlanet = gfx.imagetable.new("images/decoration/earthPlanet")
local lightPlanet = gfx.imagetable.new("images/decoration/lightPlanet")
local darkPlanet = gfx.imagetable.new("images/decoration/darkPlanet")
local moonPlanet = gfx.imagetable.new("images/decoration/moonPlanet")
PLANET_IMAGETABLES = {earthPlanet, lightPlanet, darkPlanet, moonPlanet, earthPlanet, earthPlanet}

FONT = gfx.font.new("data/fonts/m6x11-12")
TITLE_FONT = gfx.font.new("data/fonts/m6x11-26")


-- Save Data
CUR_LEVEL = 1
SELECTED_WORLD = 1
LEVEL_TIMES = {}
COMPLETED_WORLDS = {}

local function loadGameData()
    local gameData = pd.datastore.read()
    if gameData then
        CUR_LEVEL = gameData.curLevel or 1
        SELECTED_WORLD = gameData.selectedWorld or 1
        LEVEL_TIMES = gameData.levelTimes or {}
        COMPLETED_WORLDS = gameData.completedWorlds or {}
    end
end

loadGameData()

local function saveGameData()
    local gameData = {
        curLevel = CUR_LEVEL,
        selectedWorld = SELECTED_WORLD,
        levelTimes = LEVEL_TIMES,
        completedWorlds = COMPLETED_WORLDS
    }

    pd.datastore.write(gameData)
end

function pd.gameWillTerminate()
    saveGameData()
end

function pd.gameWillSleep()
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

if pd.isSimulator then
    sanityChecks()
end
