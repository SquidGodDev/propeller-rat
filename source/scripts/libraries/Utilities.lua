function math.clamp(value, min, max)
	if (min > max) then
		min, max = max, min
	end
	return math.max(min, math.min(max, value))
end

function math.ring(value, min, max)
	if (min > max) then
		min, max = max, min
	end
	return min + (value - min) % (max - min)
end

function math.ringInt(value, min, max)
	return math.ring(value, min, max + 1)
end

function math.sign(value)
	return (value >= 0 and 1) or -1
end