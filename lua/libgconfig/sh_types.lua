
local types = {}
gConfig.Types = types
function gConfig.addType(typeName, match, gui, serialize, unserialize)
	if types[typeName] then
		gConfig.msgError("Type %q already declared", typeName)
		return
	end

	types[typeName] = {
		name = typeName,
		match = match,
		gui = gui,
		serialize = serialize,
		unserialize = unserialize,
	}
end

function gConfig.isValidType(typeName)
	return types[typeName] != nil
end

local function genericStringMatch(value, options)
	assert(isstring(value), "Type \"String\" must be a string, got " .. type(value))

	local len = utf8.len(value)
	if not len then return false end -- Contained invalid UTF-8 sequence
	if options.min and len < options.min then return false end
	if options.max and len > options.max then return false end
	if options.pattern and not string.match(value, options.pattern) then return false end

	return true
end

gConfig.addType("Boolean",
function(value, options)
	assert(isbool(value), "Type \"Boolean\" must be a boolean, got " .. type(value))

	return true
end, function()
end, function(value)
	return value and "1" or "0"
end, function(value)
	return tobool(value)
end)

gConfig.addType("String",
function(value, options)
	return genericStringMatch(value, options)
end, function()
end, function(value)
	return value
end, function(value)
	return value
end)

gConfig.addType("Text",
function(value, options)
	return genericStringMatch(value, options)
end, function()
end, function(value)
	return value
end, function(value)
	return value
end)

gConfig.addType("Integer",
function(value, options)
	assert(isnumber(value), "Type \"Integer\" must be a number, got " .. type(value))

	value = math.Round(value)

	if options.min and value < options.min then return false end
	if options.max and value > options.max then return false end

	return true, value
end, function()
end, function(value)
	return tostring(math.Round(value))
end, function(value)
	return tonumber(value)
end)

gConfig.addType("Number",
function(value, options)
	assert(isnumber(value), "Type \"Number\" must be a number, got " .. type(value))

	if options.precision then
		value = math.Round(value, options.precision)
	end
	if options.min and value < options.min then return false end
	if options.max and value > options.max then return false end

	return true, value
end, function()
end, function(value)
	return tostring(value)
end, function(value)
	return tonumber(value)
end)

gConfig.addType("Enum",
function(value, options)
	assert(isnumber(value) or isstring(value), "Type \"Enum\" must be a number or string, got " .. type(value))

	if not options.data then error("Enum typeOptions.data is required") end

	if not options.data[value] then return false end
	if not options.allowEmpty and not value then return false end

	return true
end, function()
end, function(value)
	local typ
	if isstring(value) then
		typ = "s"
	elseif isnumber(value) then
		typ = "n"
	else
		error("Can't serialize enum type " .. type(value))
	end

	return string.format("%s:%s", typ, tostring(value))
end, function(value)
	local typ = value:sub(1, 1)
	local strVal = value:sub(3, -1)

	if typ == "n" then
		return tonumber(strVal)
	elseif typ == "s" then
		return strVal
	else
		error("Failed to unserialize enum, value: " .. value)
	end
end)