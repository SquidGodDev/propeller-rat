--[[
	PlayDate SDK Types Meta-File
	A collection of type annotations for the PlayDate SDK
	Compatible with SDK 1.12.3

	This file should NOT actually be imported; VSCode should automatically reference it for type completion.
	Importing this file will likely break things, as some functions are redefined for the sake of providing type definition.

	Originally written by Minalien (https://cohost.org/Minalien).
	Consider this file public domain.

	https://sdk.play.date/1.12.3/Inside%20Playdate.html#api-reference
]]
---@meta

--[[
	Returns the first index of element in the given array-style table. If the table does not contain element, the function returns nil.

	https://sdk.play.date/1.12.3/Inside%20Playdate.html#t-table.indexOfElement
]]
---@param table table
---@param element any
---@return integer|nil
function table.indexOfElement(table, element) end

--[[
	Returns the size of the given table as a multiple values `(arrayCount, hashCount)`.

	https://sdk.play.date/1.12.3/Inside%20Playdate.html#t-table.getsize
]]
---@param table table
---@return integer arrayCount, integer hashCount
function table.getsize(table) end

--[[
	Returns a new Lua table with the array and hash parts preallocated to accommodate arrayCount and hashCount elements respectively.

	https://sdk.play.date/inside-playdate/#t-table.create
]]
---@param arrayCount integer
---@param hashCount integer
---@return table table
function table.create(arrayCount, hashCount) end

--[[
	Returns a shallow copy of the source table. If a destination table is provided, it copies the contents of source into destination and returns destination. The copy will contain references to any nested tables.

	https://sdk.play.date/inside-playdate/#t-table.shallowcopy
]]
---@param source table
---@param destination? table
---@return table
function table.shallowcopy(source, destination) end

--[[
	Returns a deep copy of the source table. The copy will contain copies of any nested tables.

	https://sdk.play.date/inside-playdate/#t-table.deepcopy
]]
---@param source table
---@return table
function table.deepcopy(source) end
