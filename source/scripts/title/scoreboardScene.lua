local pd <const> = playdate
local gfx <const> = pd.graphics

local utilities <const> = Utilities
local assets <const> = Assets

local planetImagetables = PLANET_IMAGETABLES
local planetNames = PLANET_NAMES

ScoreboardScene = {}
class('ScoreboardScene').extends()

function ScoreboardScene:init()
    local systemMenu = pd.getSystemMenu()
    systemMenu:addMenuItem("World Select", function()
        SceneManager.switchSceneOverride(WorldSelectScene)
    end)

    local starsImage = assets.getImage("images/decoration/stars")
    local stars = gfx.sprite.new(starsImage)
    stars:moveTo(200, 120)
    stars:add()

    local worldIndex = SELECTED_WORLD
    self.worldIndex = worldIndex
    utilities.animatedSprite(365, 45, planetImagetables[worldIndex], 100, true)

    local titleString = "World " .. SELECTED_WORLD .. " - " .. planetNames[SELECTED_WORLD]
    local worldNameSprite = utilities.spriteWithText(titleString, TITLE_FONT)
    worldNameSprite:moveTo(200, 20)
    worldNameSprite:add()

    local playerImageTable = assets.getImagetable("images/player/rat")
    local loadingIcon = utilities.animatedSprite(200, 120, playerImageTable, 50, true, 1, 12)
    local loadingText = utilities.spriteWithText("LOADING", FONT)
    loadingText:moveTo(200, 155)
    loadingText:add()

    local boardID = "world" .. SELECTED_WORLD
    ---@diagnostic disable-next-line: undefined-field
    pd.scoreboards.getScores(boardID, function(status, result)
        loadingIcon:remove()
        loadingText:remove()
        if status.code == "ERROR" then
            local errorMessage = utilities.spriteWithText(status.message, FONT)
            errorMessage:moveTo(200, 120)
            errorMessage:add()
            return
        end
        for i=1, 10 do
            local rank = string.format("%02d", i)
            local name = "---"
            local time = "--:--.---"
            if result and result.scores then
                local entry = result.scores[i]
                if entry then
                    rank = string.format("%02d", entry.rank)
                    name = string.format("%-20s", entry.player)
                    time = utilities.formatTime(entry.value / 1000)
                end
            end
            local scoreboardString = rank .. ". " .. name
            local entrySprite = utilities.spriteWithText(scoreboardString, FONT)
            entrySprite:setCenter(0, 0)
            local displayX = 45
            local displayY = (i-1)* 20 + 37
            entrySprite:moveTo(displayX, displayY)
            entrySprite:add()

            local timeSprite = utilities.spriteWithText(": " .. time, FONT)
            timeSprite:setCenter(0, 0)
            timeSprite:moveTo(displayX + 220, displayY)
            timeSprite:add()
        end
    end)

    self.transitioning = false
end

function ScoreboardScene:update()
    if pd.buttonJustPressed(pd.kButtonB) and not self.transitioning then
        self.transitioning = true
        SceneManager.switchScene(WorldSelectScene)
    end
end

