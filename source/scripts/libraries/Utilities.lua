local max <const> = math.max
local min <const> = math.min

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
	return _value == 0 and 0 or sign(_value)
end

local pd <const> = playdate
local gfx <const> = pd.graphics

Utilities = {}

function Utilities.animatedSprite(x, y, imagetable, frameTime, repeats, startFrame, endFrame, flip)
    if type(imagetable) == 'string' then
        imagetable = Assets.getImagetable(imagetable)
    end
    assert(imagetable)
    flip = flip or gfx.kImageUnflipped
    local sprite = gfx.sprite.new(imagetable[1])
    sprite:moveTo(x, y)
    sprite:add()
    local animationLoop = gfx.animation.loop.new(frameTime, imagetable, repeats)
    animationLoop.startFrame = startFrame or 1
    animationLoop.endFrame = endFrame or #imagetable
    local curFrame = animationLoop.startFrame
    sprite.update = function()
        local frame = animationLoop.frame
        if frame ~= curFrame then
            curFrame = frame
            sprite:setImage(animationLoop:image(), flip)
        end
        if not animationLoop:isValid() then
            sprite:remove()
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