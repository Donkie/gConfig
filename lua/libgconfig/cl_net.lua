
local function receiveData()
	local addon = net.ReadString()
	local id = net.ReadString()
	local value = net.ReadType()
	local wasPlayer = net.ReadBool()
	local ply
	if wasPlayer then
		ply = net.ReadEntity()
	end

	local config = gConfig.get(addon)
	local item = config.items[id]
	assert(item, "received data for invalid item id " .. id)

	local old = config.data[id]
	if gConfig.equals(old, value) then return end -- Maybe not needed

	config.data[id] = value

	config:runMonitors(id, old, value)

	if LocalPlayer():IsAdmin() then
		if IsValid(ply) then
			gConfig.msgInfo("[%s] %s has set %q to %q", addon, ply:Nick(), item.name, gConfig.ellipsis(value, 100))
		else
			gConfig.msgInfo("[%s] %q has been set to %q", addon, item.name, gConfig.ellipsis(value, 100))
		end
	end
end
net.Receive("gConfigSend", receiveData)

local function receiveFullUpdate(len)
	local addonCount = 0
	local itemCount = 0

	while net.ReadBool() do
		addonCount = addonCount + 1
		local addon = net.ReadString()
		local config = gConfig.get(addon)

		while net.ReadBool() do
			itemCount = itemCount + 1
			local id = net.ReadString()
			local value = net.ReadType()

			config.data[id] = value
		end
	end

	gConfig.msgInfo("Received %i config %s for %i %s in %s of data",
		itemCount, gConfig.plural("item", itemCount),
		addonCount, gConfig.plural("addon", addonCount),
		string.NiceSize(math.Round(len / 8)))

	hook.Run("gConfigValuesLoaded")
end
net.Receive("gConfigSendFullUpdate", receiveFullUpdate)

function gConfig.setValue(config, id, newValue, comment)
	local item = config.items[id]

	if item.realm == gConfig.Client then
		config:set(id, newValue, LocalPlayer(), comment)
	else
		net.Start("gConfigSendValue")
			net.WriteString(config.name)
			net.WriteString(id)
			net.WriteString(comment or "")
			net.WriteType(newValue)
		net.SendToServer()
	end
end

function gConfig.requestFullUpdate(config)
	net.Start("gConfigRequestFullUpdate")
		net.WriteString(config.name)
	net.SendToServer()
end

local curHistoryCallback -- TODO: Better system for this
function gConfig.requestHistory(config, configItemId, callback)
	local item = config.items[configItemId]

	if item.realm == gConfig.Client then
		local itemType = gConfig.Types[item.type]

		-- fetch history from client db
		gConfig.GetHistory(config.name, configItemId, function(historyTbl)
			for i = 1, #historyTbl do
				local row = historyTbl[i]
				row.previewValue = itemType.preview(row.value, item.typeOptions)
			end

			callback(historyTbl)
		end)
	else

		-- request history from server db
		net.Start("gConfigRequestHistory")
			net.WriteString(config.name)
			net.WriteString(configItemId)
		net.SendToServer()

		curHistoryCallback = {
			configName = config.name,
			configItemId = configItemId,
			callback = callback,
		}
	end
end

net.Receive("gConfigSendHistory", function()
	if not curHistoryCallback then return end

	local addon = net.ReadString()
	local configItemId = net.ReadString()

	if curHistoryCallback.configName != addon or
		curHistoryCallback.configItemId != configItemId then return end

	if not gConfig.exists(addon) then return end

	local config = gConfig.get(addon)
	local item = config.items[configItemId]
	local itemType = gConfig.Types[item.type]

	local rows = {}
	for i = 1, net.ReadUInt(8) do
		local date = net.ReadUInt(32)
		local author = net.ReadString()
		local authorsid = net.ReadString()
		local comment = net.ReadString()
		local value = net.ReadType()

		local previewValue = itemType.preview(value, item.typeOptions)

		rows[i] = {
			date = date,
			author = author,
			authorsid = authorsid,
			comment = comment,
			value = value,
			previewValue = previewValue,
		}
	end

	curHistoryCallback.callback(rows)
end)


