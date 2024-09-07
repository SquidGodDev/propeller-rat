local pd <const> = playdate
local gfx <const> = playdate.graphics

local planetImagetables = PLANET_IMAGETABLES
local utilities <const> = Utilities
local assets <const> = Assets
assets.preloadImages({
    "images/decoration/stars"
})

local introLines = {
    "The year is 23XX. Humans have finally achieved interstellar travel.",
    "However, difficulties with on-board repairs in the tight spaces around the engine bay have made long distance travel challenging.",
    "The energy source powering the \"Faster Than Light\" engine disrupts nearby transistors, making the use of robots infeasible.",
    "In response, the interplanetary RODENT (Rats Operating Delicate ENgineering Tasks) Academy was established.",
    "Recruits are trained to manuever around the narrow engine bay through a series of agility courses set across multiple worlds.",
    "Rats all across the galaxy gather with their ambitions set on becoming a prestigious RODENT agent.",
    "Here, we follow the story of one such hopeful recruit..."
}

IntroScene = {}
class('IntroScene').extends()

function IntroScene:init()
    local starsImage = assets.getImage("images/decoration/stars")
    local stars = gfx.sprite.new(starsImage)
    stars:moveTo(200, 120)
    stars:add()

    utilities.animatedSprite(365, 45, planetImagetables[1], 100, true)

    self.dialogSprite = gfx.sprite.new()
    self.dialogSprite:moveTo(200, 120)
    self.dialogSprite:add()

    self.animatingOut = false

    local arrowImagetable = gfx.imagetable.new("images/story/downArrow")
    self.arrowSprite = gfx.sprite.new()
    self.arrowSprite:setZIndex(Z_INDEXES.dialog)
    self.arrowSprite:setIgnoresDrawOffset(true)
    local arrowAnimation = gfx.animation.loop.new(200, arrowImagetable, true)
    self.arrowSprite.update = function()
        self.arrowSprite:setImage(arrowAnimation:image())
    end

    local maxDialogLen = 40
    local lineSpacing = 1
    self.dialogBox = DialogBox(introLines, self.dialogSprite, maxDialogLen, lineSpacing, function()
        if not self.animatingOut then
            self.animatingOut = true
            SHOWN_DIALOGS["intro"] = true
            SceneManager.switchScene(WorldSelectScene)
        end
    end)
    self.dialogBox:setTypeSFXNote(65)
    self.dialogBox:setCenterAlignment()
    pd.timer.performAfterDelay(500, function()
        self.dialogBox:progress()
        self.arrowSprite:add()
        self:updateArrowPos()
    end)
end

function IntroScene:update()
    self.dialogBox:update()

    self:updateArrowPos()
end

function IntroScene:updateArrowPos()
    local _, dialogSpriteHeight = self.dialogSprite:getSize()
    self.arrowSprite:moveTo(self.dialogSprite.x, self.dialogSprite.y + dialogSpriteHeight/2 + 20)
end
