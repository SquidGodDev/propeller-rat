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

function Utilities.animatedSprite(x, y, imagetable, frameTime, repeats, startFrame, endFrame)
    if type(imagetable) == 'string' then
        imagetable = gfx.imagetable.new(imagetable)
    end
    assert(imagetable)
    local sprite = gfx.sprite.new(imagetable[1])
    sprite:moveTo(x, y)
    sprite:add()
    sprite.animationLoop = gfx.animation.loop.new(frameTime, imagetable, repeats)
    sprite.animationLoop.startFrame = startFrame and startFrame or 1
    sprite.animationLoop.endFrame = endFrame and endFrame or #imagetable
    sprite.update = function(self)
        self:setImage(self.animationLoop:image())
        if not self.animationLoop:isValid() then
            self:remove()
        end
    end
    return sprite
end