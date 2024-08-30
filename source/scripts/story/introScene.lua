local pd <const> = playdate
local gfx <const> = playdate.graphics

local font <const> = FONT
local planetImagetables = PLANET_IMAGETABLES
local utilities <const> = Utilities
local assets <const> = Assets
assets.preloadImages({
    "images/decoration/stars"
})

local introLines = {
    "The year is 23XX. Humans have achieved interstellar travel, but challenges with on-board repairs in the tight spaces around the engine bay have resulted in countless spacecraft failures.",
    "The energy source powering faster than light travel disrupts nearby transistors, making robots an infeasible solution.",
    "In response, the interplanetary RODENT (Rats Operating Delicate ENgineering Tasks) academy program was established.",
    "Every spacecraft is now required to house a RODENT agent who has passed the strict training circuit composed of courses housed in satellites spread across the orbits of 8 different worlds.",
    "Here, we follow the story of a one such recruit..."
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

    local maxDialogLen = 35
    local lineSpacing = 1
    self.dialogBox = DialogBox(introLines, self.dialogSprite, maxDialogLen, lineSpacing, function()
        if not self.animatingOut then
            self.animatingOut = true
            SceneManager.switchScene(WorldSelectScene)
        end
    end)
    self.dialogBox:setTypeSFXNote(70)
    self.dialogBox:setCenterAlignment()
    pd.timer.performAfterDelay(500, function()
        self.dialogBox:progress()
        self.arrowSprite:add()
        self:updateArrowPos()
    end)
end

function IntroScene:update()
    if pd.buttonJustPressed(pd.kButtonA)
    or pd.buttonJustPressed(pd.kButtonB)
    or pd.buttonJustPressed(pd.kButtonDown)
    or pd.buttonJustPressed(pd.kButtonRight) then
        self.dialogBox:progress()
    end
    self:updateArrowPos()
end

function IntroScene:updateArrowPos()
    local _, dialogSpriteHeight = self.dialogSprite:getSize()
    self.arrowSprite:moveTo(self.dialogSprite.x, self.dialogSprite.y + dialogSpriteHeight/2 + 20)
end
