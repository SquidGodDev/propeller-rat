function sanityChecks()
    local ldtk = LDtk
    local levelCount = ldtk.get_level_count()

    local levelNames = {}

    for i=1, levelCount do
        local level = "Level_" .. i
        local levelName = ldtk.get_custom_data(level, "Name")
        assert(levelName, level .. " has no name")

        local duplicateName = levelNames[levelName]
        assert(duplicateName == nil, level .. " has the same name as " .. (duplicateName or "") .. ": " .. levelName)
        levelNames[levelName] = level

        local startCount = 0
        local endCount = 0
        for _, entity in ipairs(ldtk.get_entities(level)) do
            local entityName = entity.name

            if entityName == "Start" then
                startCount += 1
            elseif entityName == "End" then
                endCount += 1
            end
        end

        assert(startCount == 1, level .. " has " .. startCount .. " start entities")
        assert(endCount == 1, level .. " has " .. endCount .. " end entities")
    end
end