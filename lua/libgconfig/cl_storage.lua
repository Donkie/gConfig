
gConfig.metso = include("metso/metso.lua")

local db = gConfig.metso.create({
	driver = "sqlite"
})
gConfig.msgInfo("Loaded database")

local function initialize()
	db:query([[
	CREATE TABLE IF NOT EXISTS `gconfig_data` (
		`addon` varchar(32) NOT NULL,
		`item` varchar(16) NOT NULL,
		`date` UNSIGNED int NOT NULL,
		`value` TEXT NOT NULL,
		`comment` TEXT
	);
	]]):done(function()
		gConfig.dbReady = true
		gConfig.msgInfo("Database ready")
	end)
end

function gConfig.SaveValue(addon, item, value, comment)
	gConfig.msgInfo("gConfig.SaveValue(%q, %q, %q, %q)", addon, item, tostring(value), comment or "")

	-- Serialize the value
	local config = gConfig.get(addon)
	local itemType = config.items[item].type
	local serialize = gConfig.Types[itemType].serialize
	local valueStr = serialize(value)

	db:query([[
		INSERT INTO `gconfig_data` (`addon`, `item`, `date`, `value`, `comment`)
		VALUES (?, ?, ?, ?, ?)
	]], {addon, item, os.time(), valueStr, comment}):done()
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
		SELECT a.`date`, a.`value`, a.`comment`
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
