function sanityChecks()
    local ldtk = LDtk
    local levelCount = ldtk.get_level_count()
    for i=1, levelCount do
        local level = "Level_" .. i
        local levelName = ldtk.get_custom_data(level, "Name")
        assert(levelName, level .. " has no name")

        local hasStart = false
        local hasEnd = false
        for _, entity in ipairs(ldtk.get_entities(level)) do
            local entityName = entity.name

            if entityName == "Start" then
                hasStart = true
            elseif entityName == "End" then
                hasEnd = true
            end
        end

        assert(hasStart, level .. " has no start")
        assert(hasEnd, level .. " has no end")
    end
end