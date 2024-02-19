local pd <const> = playdate
local gfx <const> = pd.graphics

local ldtk <const> = LDtk

class('Level').extends(gfx.sprite)

function Level:init(levelIndex)
    local levelName = "Level_" .. levelIndex

    local levelImage = gfx.image.new(ldtk.get_level_bg_path(levelName))
    self:setImage(levelImage)
    self:setCenter(0, 0)
    self:moveTo(0, 0)
    self:add()

    for _, entity in ipairs(ldtk.get_entities(levelName)) do
        local entityX, entityY = entity.position.x, entity.position.y
        local entityName = entity.name

        local hazardInstance = nil
        if entityName == "Start" then
            self.startX, self.startY = entityX, entityY
        elseif entityName == "End" then
            LevelEnd(entityX, entityY)
        elseif entityName == "Block" then
            hazardInstance = Block(entityX, entityY, entity)
        elseif entityName == "Turret" then
            hazardInstance = Turret(entityX, entityY, entity)
        elseif entityName == "Spinner" then
            hazardInstance = Spinner(entityX, entityY)
        end

        if hazardInstance then
            hazardInstance:setLevelImage(levelImage)
        end
    end
end

function Level:getStartPos()
    return self.startX, self.startY
end

function Level:getLevelImage()
    return self:getImage()
end