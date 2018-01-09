
local types = {}
gConfig.Types = types

local requiredVars = {"name", "match", "gui", "preview", "serialize", "unserialize"}
function gConfig.addType(struct)
	-- Make sure all required variables exist
	for _, var in pairs(requiredVars) do
		if not struct[var] then gConfig.msgError("Missing variable %q for type %q", var, struct.name or "?") return end
	end

	if types[struct.name] then
		gConfig.msgError("Type %q already declared", struct.name)
		return
	end

	types[struct.name] = struct
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

gConfig.addType({
	name = "Boolean",
	match = function(value, options)
		assert(isbool(value), "Type \"Boolean\" must be a boolean, got " .. type(value))

		return true
	end,
	gui = function()
	end,
	preview = function(value, options)
		return value and "Yes" or "No"
	end,
	serialize = function(value)
		return value and "1" or "0"
	end,
	unserialize = function(value)
		return tobool(value)
	end
})

gConfig.addType({
	name = "String",
	match = function(value, options)
		return genericStringMatch(value, options)
	end,
	gui = function()
	end,
	preview = function(value, options)
		return value
	end,
	serialize = function(value)
		return value
	end,
	unserialize = function(value)
		return value
	end
})

gConfig.addType({
	name = "Text",
	match = function(value, options)
		return genericStringMatch(value, options)
	end,
	gui = function()
	end,
	preview = function(value, options)
		return value
	end,
	serialize = function(value)
		return value
	end,
	unserialize = function(value)
		return value
	end
})

gConfig.addType({
	name = "Integer",
	match = function(value, options)
		assert(isnumber(value), "Type \"Integer\" must be a number, got " .. type(value))

		value = math.Round(value)

		if options.min and value < options.min then return false end
		if options.max and value > options.max then return false end

		return true, value
	end,
	gui = function()
	end,
	preview = function(value, options)
		return tostring(value)
	end,
	serialize = function(value)
		return tostring(math.Round(value))
	end,
	unserialize = function(value)
		return tonumber(value)
	end
})

gConfig.addType({
	name = "Number",
	match = function(value, options)
		assert(isnumber(value), "Type \"Number\" must be a number, got " .. type(value))

		if options.precision then
			value = math.Round(value, options.precision)
		end
		if options.min and value < options.min then return false end
		if options.max and value > options.max then return false end

		return true, value
	end,
	gui = function()
	end,
	preview = function(value, options)
		return tostring(value)
	end,
	serialize = function(value)
		return tostring(value)
	end,
	unserialize = function(value)
		return tonumber(value)
	end
})

gConfig.addType({
	name = "Enum",
	match = function(value, options)
		assert(isnumber(value) or isstring(value), "Type \"Enum\" must be a number or string, got " .. type(value))

		if not options.data then error("Enum typeOptions.data is required") end

		if not options.data[value] then return false end
		if not options.allowEmpty and not value then return false end

		return true
	end,
	gui = function()
	end,
	preview = function(value, options)
		return options.data[value]
	end,
	serialize = function(value)
		local typ
		if isstring(value) then
			typ = "s"
		elseif isnumber(value) then
			typ = "n"
		else
			error("Can't serialize enum type " .. type(value))
		end

		return string.format("%s:%s", typ, tostring(value))
	end,
	unserialize = function(value)
		local typ = value:sub(1, 1)
		local strVal = value:sub(3, -1)

		if typ == "n" then
			return tonumber(strVal)
		elseif typ == "s" then
			return strVal
		else
			error("Failed to unserialize enum, value: " .. value)
		end
	end
})
