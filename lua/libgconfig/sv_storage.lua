
gConfig.dbReady = nil

gConfig.metso = include("metso/metso.lua")
local dbConfig = include("gconfig.lua")
if not dbConfig or not istable(dbConfig) or not dbConfig.driver then
	gConfig.msgError("Invalid database config!")
	return
end

local db = gConfig.metso.create(dbConfig)

local isSqlite = dbConfig.driver == "sqlite"

local function initialize()
	local queriesCompleted = 0
	local incCompl = function()
		queriesCompleted = queriesCompleted + 1
		if queriesCompleted == 3 then
			gConfig.dbReady = true
			gConfig.msgInfo("Database ready")
		end
	end

	if isSqlite then
		-- auto incremental id columns are not recommended, nor needed, in sqlite databases
		db:query([[
		CREATE TABLE IF NOT EXISTS `gconfig_data` (
			`addon` varchar(32) NOT NULL,
			`item` varchar(16) NOT NULL,
			`date` UNSIGNED int NOT NULL,
			`value` TEXT NOT NULL,
			`userNick` varchar(32),
			`userSteam` char(19),
			`comment` TEXT
		);
		]]):done(incCompl)
	else
		db:query([[
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
		]]):done(incCompl)
	end

	db:query([[
	CREATE TABLE IF NOT EXISTS `gconfig_accessuser` (
		`addon` varchar(32) NOT NULL,
		`item` varchar(16) NOT NULL,
		`userNick` varchar(32),
		`userSteam` char(19) NOT NULL,
		`allow` int(1) NOT NULL,
		PRIMARY KEY (`addon`, `item`, `userSteam`)
	);
	]]):done(incCompl)

	db:query([[
	CREATE TABLE IF NOT EXISTS `gconfig_accessgroup` (
		`addon` varchar(32) NOT NULL,
		`item` varchar(16) NOT NULL,
		`group` varchar(64) NOT NULL,
		`allow` int(1) NOT NULL,
		PRIMARY KEY (`addon`, `item`, `group`)
	);
	]]):done(incCompl)
end

function gConfig.SaveValue(addon, item, value, ply, comment)
	gConfig.msgInfo("gConfig.SaveValue(%q, %q, %q, %q, %q)", addon, item, tostring(value), IsValid(ply) and ply:Nick() or "", comment or "")

	-- Serialize the value
	local config = gConfig.get(addon)
	local itemType = config.items[item].type
	local serialize = gConfig.Types[itemType].serialize
	local valueStr = serialize(value)

	local nick = IsValid(ply) and ply:Nick() or nil
	local steamid = IsValid(ply) and ply:SteamID() or nil

	db:query([[
		INSERT INTO `gconfig_data` (`addon`, `item`, `date`, `value`, `userNick`, `userSteam`, `comment`)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	]], {addon, item, os.time(), valueStr, nick, steamid, comment}):done()
end

function gConfig.GetValues()
	-- Gets the latest value of each addon-item combo
	-- https://stackoverflow.com/a/28090544
	db:query([[
		SELECT a.`addon`, a.`item`, a.`value`
		FROM `gconfig_data` a
		LEFT JOIN `gconfig_data` b
			ON a.addon = b.addon AND a.item = b.item AND a.date < b.date
		WHERE b.date IS NULL
	]]):done(function(data)
		for _, row in pairs(data) do
			local config = gConfig.get(row.addon)
			local itemTbl = config.items[row.item]
			if not itemTbl then continue end

			local itemType = itemTbl.type
			local unserialize = gConfig.Types[itemType].unserialize
			local valueObj = unserialize(row.value)

			config.data[row.item] = valueObj

			-- run monitors here???
		end

		hook.Run("gConfigValuesLoaded")
	end)
end

function gConfig.GetHistory(addon, item, callback)
	assert(gConfig.exists(addon), "invalid config " .. addon)

	local config = gConfig.get(addon)

	local itemTbl = config.items[item]
	assert(istable(itemTbl), "invalid item " .. item)

	local itemType = itemTbl.type
	local unserialize = gConfig.Types[itemType].unserialize

	db:query([[
		SELECT a.`date`, a.`value`, a.`userNick`, a.`userSteam`, a.`comment`
		FROM `gconfig_data` a
		WHERE a.`addon` = ? AND a.`item` = ?
		ORDER BY a.`date` DESC
		LIMIT 255
	]], {addon, item}):done(function(data)
		local rettbl = {}
		for k, row in pairs(data) do
			local valueObj = unserialize(row.value)

			rettbl[k] = {
				date = row.date,
				value = valueObj,
				author = row.userNick,
				authorsid = row.userSteam,
				comment = row.comment,
			}
		end
		callback(rettbl)
	end)
end

initialize()

hook.Add("gConfigLoaded", "LoadgConfigValues", function()
	gConfig.GetValues()
end)
