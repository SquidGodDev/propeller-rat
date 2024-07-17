local pd <const> = playdate
local performAfterDelay <const> = pd.timer.performAfterDelay

class('Chain').extends()

function Chain:init()
    self.time = 0
end

function Chain:link(time, callback)
    self.time += time
    if callback then
        performAfterDelay(self.time, callback)
    end
    return self
end