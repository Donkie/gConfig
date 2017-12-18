
--[[
Enums
]]
gConfig.Server = 0
gConfig.Shared = 1
gConfig.Client = 2

gConfig.User       = 0
gConfig.Admin      = 1
gConfig.SuperAdmin = 2
gConfig.None       = 3

--[[
Config Object
]]
local configs = {}

local configmeta = {}
configmeta.__index = configmeta

local requiredVars = {"id", "realm", "access", "name", "description", "type"}
function configmeta:add(struct)
	if not self.registered then
		gConfig.msgError("[%s] Addon not registered yet (use gConfig.register)", self.name)
		return
	end

	-- Make sure all required variables exist
	for _, var in pairs(requiredVars) do
		if not struct[var] then gConfig.msgError("[%s] missing variable %q for item %q", self.name, var, struct.id or "?") return end
	end

	-- Test the variables
	local id = struct.id
	if self.items[id] then
		gConfig.msgError("[%s] Config item %q has already been added", self.name, id)
		return
	end

	if #id > 16 then
		gConfig.msgError("[%s] Config item %q's id can't be longer than 16 characters", self.name, id)
		return
	end

	if not gConfig.Types[struct.type] then
		gConfig.msgError("[%s] Invalid type %q for config item %q", self.name, struct.type, id)
		return
	end

	-- Finish
	struct.typeOptions = struct.typeOptions or {}
	struct.order = self.itemCount

	self.items[id] = struct

	self.itemCount = self.itemCount + 1
end

function configmeta:get(id, ...)
	if not self.items[id] then
		gConfig.msgError("[%s] Tried to get value of invalid item id %q", self.name, id)
		debug.Trace()
		return
	end

	local value
	if self.data[id] != nil then
		-- Use user set value
		value = self.data[id]
	else
		-- Use default
		value = self.items[id].default
	end

	-- If it's a function, call it and use its return value
	if isfunction(value) then
		value = value(...)
	end

	return value
end

function configmeta:monitor(id, onChange)
	self.monitors[id] = self.monitors[id] or {}
	table.insert(self.monitors[id], onChange)
end

function configmeta:hasAccess(id, ply)
	if CLIENT then return true end

	local item = self.items[id]
	local accessLevel = item.access

	local defaultAccess = false
	if accessLevel == gConfig.User then
		defaultAccess = true
	elseif accessLevel == gConfig.Admin then
		defaultAccess = ply:IsAdmin()
	elseif accessLevel == gConfig.SuperAdmin then
		defaultAccess = ply:IsSuperAdmin()
	elseif accessLevel == gConfig.None then
		defaultAccess = false
	end

	-- TODO: add check for per-ply/per-group access

	return defaultAccess
end

function configmeta:set(id, value, ply)
	local item = self.items[id]
	assert(item, "id not valid")

	local realm = item.realm
	if SERVER then
		if realm == gConfig.Client then error("Client variables can't be set on server") end
	else
		if realm != gConfig.Client then error("Server/shared variables can't be set on client") end
	end

	-- Test access
	if not self:hasAccess(id, ply) then
		return false, "no access"
	end

	-- Test match
	local typ = gConfig.Types[item.type]

	local isValid, newVal = typ.match(value, item.typeOptions)

	if not isValid then
		return false, "invalid value"
	end

	if newVal then value = newVal end

	-- Check for change
	local old = self.data[id]
	if gConfig.equals(old, value) then
		return false, "no change"
	end

	-- Finish
	local comment = ""
	gConfig.SaveValue(self.name, id, value, ply, comment)

	self.data[id] = value

	if SERVER and realm == gConfig.Shared then
		-- Send to clients
		gConfig.sendValue(self.name, id, value, ply)
	end

	if self.monitors[id] then
		for _, f in pairs(self.monitors[id]) do
			f(id, old, value)
		end
	end

	if SERVER then
		gConfig.msgInfo("[%s] %s has set %q to %q", self.name, ply:Nick(), item.name, gConfig.ellipsis(value, 100))
	else
		gConfig.msgInfo("[%s] %q has been set to %q", self.name, item.name, gConfig.ellipsis(value, 100))
	end
end

local function createConfigObject(addonName)
	if #addonName > 32 then
		gConfig.msgError("Addon name %q can't be longer than 32 characters", addonName)
		return
	end

	local t = setmetatable({}, configmeta)
	t.name = addonName
	t.items = {}
	t.itemCount = 0
	t.monitors = {}
	t.data = {}

	return t
end

--[[
gConfig namespace
]]
function gConfig.register(addonName)
	--Get the file path of the addon
	local t = debug.getinfo(2)
	local addonPath = t.source

	local config
	if configs[addonName] then
		config = configs[addonName]

		if config.registered then
			if config.path == addonPath then
				gConfig.msgInfo("Reloading config %q", addonName)

				config.items = {}
				config.itemCount = 0
			else
				gConfig.msgError("Config %q has already been registered", addonName)
				return
			end
		end
	else
		config = createConfigObject(addonName)
		configs[addonName] = config
	end

	config.registered = true
	config.path = addonPath
	return config
end

function gConfig.get(addonName)
	if configs[addonName] then
		return configs[addonName]
	else
		local config = createConfigObject(addonName)
		configs[addonName] = config
		return config
	end
end
