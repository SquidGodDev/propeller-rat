local pd <const> = playdate
local gfx <const> = pd.graphics

local ldtk <const> = LDtk

class('Level').extends(gfx.sprite)

function Level:init(levelIndex)
    local levelName = "Level_" .. levelIndex

    for layerName, layer in pairs(ldtk.get_layers(levelName)) do
        if layer.tiles then
            local tilemap = ldtk.create_tilemap(levelName, layerName)

            local layerSprite = gfx.sprite.new()
            layerSprite:setTilemap(tilemap)
            layerSprite:moveTo(0, 0)
            layerSprite:setCenter(0, 0)
            layerSprite:setZIndex(Z_INDEXES.level + layer.zIndex)
            layerSprite:add()

            local emptyTiles = ldtk.get_empty_tileIDs(levelName, "Solid", layerName)
            if emptyTiles then
                local wallSprites = gfx.sprite.addWallSprites(tilemap, emptyTiles)
                for i=1, #wallSprites do
                    local wallSprite = wallSprites[i]
                    wallSprite:setTag(TAGS.wall)
                    wallSprite:setGroups(TAGS.wall)
                end
            end
        end
    end

    local levelEnd
    local keys = {}
    for _, entity in ipairs(ldtk.get_entities(levelName)) do
        local entityX, entityY = entity.position.x, entity.position.y
        local entityName = entity.name

        if entityName == "Start" then
            self.startX, self.startY = entityX, entityY
        elseif entityName == "End" then
            levelEnd = LevelEnd(entityX, entityY)
        elseif entityName == "Block" then
            Block(entityX, entityY, entity)
        elseif entityName == "Turret" then
            Turret(entityX, entityY, entity)
        elseif entityName == "Spinner" then
            Spinner(entityX, entityY, entity)
        elseif entityName == "Laser" then
            Laser(entityX, entityY, entity)
        elseif entityName == "Key" then
            table.insert(keys, Key(entityX, entityY))
        end
    end

    for i=1,#keys do
        local key = keys[i]
        key:setLevelEnd(levelEnd)
    end
    levelEnd:setKeyCount(#keys)
end

function Level:getStartPos()
    return self.startX, self.startY
end