local pd <const> = playdate
local gfx <const> = playdate.graphics

class('Starfield').extends(gfx.sprite)

function Starfield:init(width, height)
    width = width or 400
    height = height or 240
    self.width = width
    self.height = height

    self:setIgnoresDrawOffset(true)
    self:setCenter(0.0, 0.5)

    self:generateStarfield(width, height)
end

function Starfield:generateStarfield(width, height)
    local starCountX = 50
    local starCountY = 30
    local dx = 400 / starCountX
    local dy = 240 / starCountY

    local starCutoff = 0.65

    local xOffset = math.random(1000)
    local yOffset = math.random(1000)
    local starOffsetMax = 4

    local starfieldImage = gfx.image.new(width, height)
    gfx.pushContext(starfieldImage)
        gfx.setColor(gfx.kColorWhite)
        for perlinY=0,width,dy do
            local perlinValues = gfx.perlinArray(math.ceil(starCountX * (height / 240)), xOffset + math.random(), dx, yOffset+perlinY+math.random(), 0, 0, 0, 0, 1, 0)
            for i=1,#perlinValues do
                local perlinValue = perlinValues[i]
                if perlinValue > starCutoff then
                    local starSize = 0.5
                    local starX = (i-1)*dx + math.random(0, starOffsetMax) - starOffsetMax/2
                    local starY = perlinY + math.random(0, starOffsetMax) - starOffsetMax/2
                    gfx.fillCircleAtPoint(starX, starY, starSize)
                end
            end
        end
    gfx.popContext()

    self:setImage(starfieldImage)
end