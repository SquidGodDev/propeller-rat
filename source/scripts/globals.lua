local pd <const> = playdate
local gfx <const> = pd.graphics

-- Core
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- Libraries
import "scripts/libraries/LDtk"
import "scripts/libraries/Utilities"
import "scripts/libraries/SceneManager"

-- Game
import "scripts/player/player"

-- Hazards
import "scripts/hazards/hazard"
import "scripts/hazards/spinner"
import "scripts/hazards/block"
import "scripts/hazards/turret"

-- Pickups
import "scripts/pickups/pickup"
import "scripts/pickups/levelEnd"

-- Levels
import "scripts/levels/level"

import "scripts/game/gameScene"

TAGS = {
    player = 1,
    hazard = 2,
    pickup = 3
}

Z_INDEXES = {
    transition = 1000,
}

pd.display.setRefreshRate(50)

DRAW_FPS = true