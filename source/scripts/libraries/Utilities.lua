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
        imagetable = gfx.imagetable.new(imagetable)
    end
    assert(imagetable)
    flip = flip or gfx.kImageUnflipped
    local sprite = gfx.sprite.new(imagetable[1])
    sprite:moveTo(x, y)
    sprite:add()
    local animationLoop = gfx.animation.loop.new(frameTime, imagetable, repeats)
    animationLoop.startFrame = startFrame or 1
    animationLoop.endFrame = endFrame or #imagetable
    sprite.update = function()
        sprite:setImage(animationLoop:image(), flip)
        if not animationLoop:isValid() then
            sprite:remove()
        end
    end
    return sprite
end