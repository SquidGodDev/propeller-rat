local pd <const> = playdate
local gfx <const> = pd.graphics

Utilities = {}
local utilities <const> = Utilities

-- Math constants
local max <const> = math.max
local min <const> = math.min
local abs <const> = math.abs
local ceil <const> = math.ceil

-- Playdate constants
local getCrankPosition <const> = pd.getCrankPosition

function math.clamp(_value, _min, _max)
	if (_min > _max) then
		_min, _max = _max, _min
	end
	return max(_min, min(_max, _value))
end

function math.ring(_value, _min, _max)
	if (_min > _max) then
		_min, _max = _max, _min
	end
	return _min + (_value - _min) % (_max - _min)
end

local ring <const> = math.ring
function math.ringInt(_value, _min, _max)
	return ring(_value, _min, _max + 1)
end

function math.sign(_value)
	return (_value >= 0 and 1) or -1
end

local sign <const> = math.sign
function math.zeroSign(_value)
	return (_value == 0 and 0) or sign(_value)
end

-- ==========================================================
-- Sprite/image utilities                                   |
-- ==========================================================

local kImageUnflipped <const> = gfx.kImageUnflipped
local spriteNew <const> = gfx.sprite.new
local spriteSetImage <const> = gfx.sprite.setImage
local spriteMoveTo <const> = gfx.sprite.moveTo
local spriteAdd <const> = gfx.sprite.add
local spriteRemove <const> = gfx.sprite.remove

local animationLoopNew <const> = gfx.animation.loop.new
local animationLoopImage <const> = gfx.animation.loop.image
local animationLoopIsValid <const> = gfx.animation.loop.isValid

function Utilities.animatedSprite(x, y, imagetable, frameTime, repeats, startFrame, endFrame, flip)
    if type(imagetable) == 'string' then
        imagetable = gfx.imagetable.new(imagetable)
    end
    assert(imagetable)
    flip = flip or kImageUnflipped
    local sprite = spriteNew(imagetable[1])
    spriteMoveTo(sprite, x, y)
    spriteAdd(sprite)
    local animationLoop = animationLoopNew(frameTime, imagetable, repeats)
    animationLoop.startFrame = startFrame or 1
    animationLoop.endFrame = endFrame or #imagetable
    local curFrame = animationLoop.startFrame
    sprite.update = function()
        local frame = animationLoop.frame
        if frame ~= curFrame then
            curFrame = frame
            spriteSetImage(sprite, animationLoopImage(animationLoop), flip)
        end
        if not animationLoopIsValid(animationLoop) then
            spriteRemove(sprite)
        end
    end
    return sprite
end

function Utilities.formatTime(seconds)
    if seconds >= 5999.999 then
        seconds = 5999.999
    end

    local minutes = math.floor(seconds / 60)
    local remainingSeconds = math.floor(seconds) % 60
    local milliseconds = math.floor((seconds - math.floor(seconds)) * 1000)

    return string.format("%02d:%02d.%03d", minutes, remainingSeconds, milliseconds)
end

function Utilities.imageWithText(string, font)
	local textImage = gfx.image.new(font:getTextWidth(string), font:getHeight())
	gfx.pushContext(textImage)
        font:drawText(string, 0, 0)
    gfx.popContext()
    return textImage
end

function Utilities.spriteWithText(string, font)
   local textImage = utilities.imageWithText(string, font)
   return gfx.sprite.new(textImage)
end

-- ==========================================================
-- Timing Utilities                                         |
-- ==========================================================

local performAfterDelay <const> = pd.timer.performAfterDelay
Chain = {}
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

-- ==========================================================
-- Input Utilities                                          |
-- ==========================================================

CrankTracker = {}
class('CrankTracker').extends()

function CrankTracker:init(tickAngle)
    self.tickAngle = tickAngle
    self.crankTotal = 0
    self.lastCrankPos = getCrankPosition()
    self.tickOffset = (tickAngle / 2) - (self.lastCrankPos % tickAngle)
end

function CrankTracker:getCrankTicksAbsolute()
	local curCrankPos = pd.getCrankPosition()

	local difference = curCrankPos - self.lastCrankPos
	if difference > 180 or difference < -180 then
		if self.lastCrankPos >= 180 then
			self.lastCrankPos -= 360
		else
			self.lastCrankPos += 360
		end

	end

	local thisSegment = ceil((curCrankPos + self.tickOffset) / self.tickAngle)
	local lastSegment = ceil((self.lastCrankPos + self.tickOffset) / self.tickAngle)

	local segmentBoundariesCrossed = thisSegment - lastSegment

	self.lastCrankPos = curCrankPos

	return segmentBoundariesCrossed
end

function CrankTracker:getCrankTicksRelative()
    local curCrankPos = getCrankPosition()
    local difference = curCrankPos - self.lastCrankPos
	if difference > 180 then
        difference -= 360
    elseif difference < -180 then
        difference += 360
    end
    self.lastCrankPos = curCrankPos

    local crankTotal = self.crankTotal
    if difference ~= 0 then
        if sign(crankTotal) ~= sign(difference) then
            crankTotal = difference
        else
            crankTotal += difference
        end
    end

    local tickAngle = self.tickAngle
    if abs(crankTotal) >= tickAngle then
        local tickDirection = sign(crankTotal)
        crankTotal %= tickAngle
        self.crankTotal = crankTotal
        return tickDirection
    end

    self.crankTotal = crankTotal
    return 0
end
