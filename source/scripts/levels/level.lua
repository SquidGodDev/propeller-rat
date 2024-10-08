local pd <const> = playdate
local gfx <const> = pd.graphics

local ldtk <const> = LDtk

local font = FONT

local spriteMoveTo <const> = gfx.sprite.moveTo

Level = {}
class('Level').extends(gfx.sprite)

function Level:init(levelIndex, laserManager, turretManager, hazardManager)
    self.laserManager = laserManager
    self.turretManager = turretManager
    self.hazardManager = hazardManager

    local levelName = "Level_" .. levelIndex

    for layerName, layer in pairs(ldtk.get_layers(levelName)) do
        if layer.tiles then
            local tilemap = ldtk.create_tilemap(levelName, layerName)

            if not tilemap then
                return
            end

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
                    wallSprite:setGroups({TAGS.wall})
                end
            end
        end
    end

    self.hazards = {}
    local levelEnd
    local keys = {}
    local keyPosY = {}
    for _, entity in ipairs(ldtk.get_entities(levelName)) do
        local entityX, entityY = entity.position.x, entity.position.y
        local entityName = entity.name

        if entityName == "Start" then
            self.startX, self.startY = entityX, entityY
        elseif entityName == "End" then
            levelEnd = LevelEnd(entityX, entityY)
        elseif entityName == "Block" then
            hazardManager:addHazard(Block(entityX, entityY, entity))
        elseif entityName == "Turret" then
            local fields = entity.fields
            local xSpeed, ySpeed = fields.xSpeed, fields.ySpeed
            local time = fields.time
            local startDelay = fields.startDelay
            turretManager:addTurret(entityX, entityY, xSpeed, ySpeed, time, startDelay)
        elseif entityName == "Spinner" then
            table.insert(self.hazards, Spinner(entityX, entityY, entity))
        elseif entityName == "Laser" then
            local fields = entity.fields
            local delay = fields.delay
            local interval = fields.interval
            local tailX, tailY = fields.tail.cx * 16 + 8, fields.tail.cy * 16 + 8
            laserManager:addLaser(entityX, entityY, tailX, tailY, delay, interval)
        elseif entityName == "Key" then
            table.insert(keys, Key(entityX, entityY))
            table.insert(keyPosY, entityY)
        elseif entityName == "HelpText" then
            local text = entity.fields.text
            local helpTextSprite = gfx.sprite.spriteWithText(text, 400, 30, nil, nil, nil, nil, font)
            helpTextSprite:setCenter(0.5, 0.0)
            helpTextSprite:moveTo(entityX, entityY)
            helpTextSprite:setZIndex(Z_INDEXES.helpText)
            helpTextSprite:add()
        end
    end

    for i=1,#keys do
        local key = keys[i]
        key:setLevelEnd(levelEnd)
    end
    levelEnd:setKeyCount(#keys)

    local bobTimer = pd.timer.new(1000, -4, 4)
    bobTimer.repeats = true
    bobTimer.reverses = true
    bobTimer.updateCallback = function()
        for i=1,#keys do
            local key = keys[i]
            spriteMoveTo(key, key.x, keyPosY[i] + bobTimer.value)
        end
    end
end

function Level:getStartPos()
    return self.startX, self.startY
end

function Level:stopLevelHazards()
    self.laserManager:stop()
    self.turretManager:stop()
    self.hazardManager:stop()
    for _, hazard in ipairs(self.hazards) do
        hazard:stop()
    end
end
