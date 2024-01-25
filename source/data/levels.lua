LEVEL_DATA = {
    {
        name = "level1",
        startPos = {32, 60},
        endPos = {296, 60},
        hazards = {}
    },
    {
        name = "level2",
        startPos = {42, 32},
        endPos = {168, 136},
        hazards = {}
    },
    {
        name = "level3",
        startPos = {32, 60},
        endPos = {296, 60},
        hazards = {
            {Block, {96, 16, 16, 16, 0, 1}},
            {Block, {96 + 48, 80, 16, 16, 0, -1}},
            {Block, {96 + 48 * 2, 16, 16, 16, 0, 1}},
            {Block, {96 + 48 * 3, 80, 16, 16, 0, -1}}
        }
    }
}