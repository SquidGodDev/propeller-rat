-- Globals
import "scripts/globals"

local pd <const> = playdate
local gfx <const> = pd.graphics

function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()

    pd.drawFPS(0, 228)
end

SceneManager.startingScene(TitleScene)