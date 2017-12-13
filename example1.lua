--[[
lua/gconfig/example.lua
]]
local Config = gConfig.register("Example Addon")

Config:add({
	id = "ragdolldamage",
	realm = gConfig.Server,
	access = gConfig.Admin,
	name = "Ragdoll Damage",
	description = "How much damage a ragdoll takes",
	category = "Test",
	type = "Integer",
	typeOptions = {
		min = 0,
		max = 100,
	},
	lastChange = 1513195381,
	default = 5,
})

Config:add({
	id = "allowedteams",
	realm = gConfig.Server,
	access = gConfig.Admin,
	name = "Allowed Teams",
	description = "Which teams are allowed to hurt ragdolls",
	category = "Test",
	type = "List",
	typeOptions = {
		type = "Team",
		lookupTable = true,
	},
	lastChange = 1513195381,
	default = {},
})

--[[
lua/autorun/server/myexampleaddon.lua
]]
local Config = gConfig.get("Example Addon")

hook.Add("OnPlayerShootRagdoll", "Test", function(ply, ragdoll)
	local dmg = Config:get("ragdolldamage")
	local allowedTeams = Config:get("allowedteams")
	if not allowedTeams[ply:Team()] then return end

	ragdoll:TakeDamage(dmg)
end)
