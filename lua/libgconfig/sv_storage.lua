
gConfig.metso = include("metso/metso.lua")
local dbConfig = include("gconfig.lua")
if not dbConfig or not istable(dbConfig) or not dbConfig.driver then
	gConfig.msgError("Invalid database config!")
	return
end

--TODO: maybe not expose the database object?
gConfig.db = gConfig.metso.create(dbConfig)

gConfig.msgInfo("Loaded database")

local function initialize()
--[[
	CREATE TABLE IF NOT EXISTS `gconfig_data` (
		`id` int NOT NULL AUTO_INCREMENT,
		`addon` varchar(32) NOT NULL,
		`item` varchar(16) NOT NULL,
		`date` UNSIGNED int NOT NULL,
		`value` TEXT NOT NULL,
		`userNick` varchar(32),
		`userSteam` char(19),
		`comment` TEXT,
		PRIMARY KEY (`id`)
	);

	CREATE TABLE IF NOT EXISTS `gconfig_accessuser` (
		`addon` varchar(32) NOT NULL,
		`item` varchar(16) NOT NULL,
		`userNick` varchar(32),
		`userSteam` char(19) NOT NULL,
		`allow` int(1) NOT NULL,
		PRIMARY KEY (`addon`, `item`, `userSteam`)
	);

	CREATE TABLE IF NOT EXISTS `gconfig_accessgroup` (
		`addon` varchar(32) NOT NULL,
		`item` varchar(16) NOT NULL,
		`group` varchar(64) NOT NULL,
		`allow` int(1) NOT NULL,
		PRIMARY KEY (`addon`, `item`, `group`)
	);
]]
end

function gConfig.SaveValue(addon, item, value, ply, comment)
	gConfig.msgInfo("gConfig.SaveValue(%q, %q, %q, %q, %q)", addon, item, tostring(value), IsValid(ply) and ply:Nick() or "", comment or "")
end
