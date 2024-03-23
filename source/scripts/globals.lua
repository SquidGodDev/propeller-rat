local pd <const> = playdate
local gfx <const> = pd.graphics

TAGS = {
    player = 1,
    hazard = 2,
    projectile = 3,
    pickup = 4,
    wall = 5
}

Z_INDEXES = {
    level = 10,
    player = 20,
    hazard = 30,
    projectile = 40,
    transition = 1000
}

CUR_LEVEL = 1

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

-- Levels
import "scripts/levels/level"

import "scripts/game/gameScene"

-- Title
import "scripts/title/levelSelectScene"

-- pd.display.setRefreshRate(50)

if pd.isSimulator then
    sanityChecks()
end

DRAW_FPS = true
