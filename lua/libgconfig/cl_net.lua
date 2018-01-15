
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
