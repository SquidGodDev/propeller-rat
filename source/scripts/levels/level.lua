local pd <const> = playdate
local gfx <const> = pd.graphics

class('Level').extends(gfx.sprite)

function Level:init(levelIndex)
    local levelData = LEVEL_DATA[levelIndex]
    self.startX = levelData.startPos[1]
    self.startY = levelData.startPos[2]

    local levelImage = gfx.image.new("images/levels/" .. levelData.name)
    self:setImage(levelImage)
    self:setCenter(0, 0)
    self:moveTo(0, 0)
    self:add()

    LevelEnd(levelData.endPos[1], levelData.endPos[2])

    for _, hazard in ipairs(levelData.hazards) do
        local hazardInstance = hazard[1](table.unpack(hazard[2]))
        hazardInstance:setLevelImage(levelImage)
    end
end

function Level:getStartPos()
    return self.startX, self.startY
end

function Level:getLevelImage()
    return self:getImage()
end