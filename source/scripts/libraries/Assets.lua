-- Shaun Inman: https://devforum.play.date/t/best-practices-for-managing-lots-of-assets/395/2

Assets = {}

local images = {}
local imagetables = {}
local samples = {}

local unloadedImages = {}
local unloadedImagetables = {}
local unloadedSamples = {}

local push = table.insert
local pop = table.remove

function Assets.preloadImages(list)
	for i=1,#list do
		local path = list[i]
		if not images[path] then
			push(unloadedImages, path)
		end
	end
end
function Assets.preloadImage(path)
    if not images[path] then
        push(unloadedImages, path)
    end
end
function Assets.preloadImagetables(list)
	for i=1,#list do
		local path = list[i]
		if not imagetables[path] then
			push(unloadedImagetables, path)
		end
	end
end
function Assets.preloadImagetable(path)
    if not imagetables[path] then
        push(unloadedImagetables, path)
    end
end
function Assets.preloadSamples(list)
	for i=1,#list do
		local path = list[i]
		if not samples[path] then
			push(unloadedSamples, path)
		end
	end
end
function Assets.preloadSample(path)
    if not samples[path] then
        push(unloadedSamples, path)
    end
end

------------------------

local ms = playdate.getCurrentTimeMilliseconds
local pairs = pairs

local gfx = playdate.graphics
local snd = playdate.sound
local function getImage(path)
	if images[path] then
		return images[path]
	end
	local image = gfx.image.new(path)
	images[path] = image
	return image
end
local function getImagetable(path)
	if imagetables[path] then
		return imagetables[path]
	end
	local imagetable = gfx.imagetable.new(path)
	imagetables[path] = imagetable
	return imagetable
end
local function getSample(path)
	if samples[path] then
		return samples[path]
	end
	local sample = snd.sample.new(path)
	samples[path] = sample
	return sample
end
Assets.getImage = getImage
Assets.getImagetable = getImagetable
Assets.getSample = getSample

------------------------

local frameDuration
local function outOfTime(frameStart)
	return (ms() - frameStart)>=frameDuration
end
function Assets.lazyLoad(frameStart)
	if not frameDuration then
		frameDuration = math.floor(1000 / playdate.display.getRefreshRate()) -- only called once
	end

	local count
	
	count = #unloadedImages
	if count>0 then
		for i=count,1,-1 do
			getImage(pop(unloadedImages))
			if outOfTime(frameStart) then return end
		end
	end
	
	count = #unloadedImagetables
	if count>0 then
		for i=count,1,-1 do
			getImagetable(pop(unloadedImagetables))
			if outOfTime(frameStart) then return end
		end
	end
	
	count = #unloadedSamples
	if count>0 then
		for i=count,1,-1 do
			getSample(pop(unloadedSamples))
			if outOfTime(frameStart) then return end
		end
	end
end
