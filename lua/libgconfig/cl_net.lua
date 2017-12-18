
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

	if config.monitors[id] then
		for _, f in pairs(config.monitors[id]) do
			f(id, old, value)
		end
	end

	if LocalPlayer():IsAdmin() then
		if IsValid(ply) then
			gConfig.msgInfo("[%s] %s has set %q to %q", addon, ply:Nick(), item.name, gConfig.ellipsis(value, 100))
		else
			gConfig.msgInfo("[%s] %q has been set to %q", addon, item.name, gConfig.ellipsis(value, 100))
		end
	end
end
net.Receive("gConfigSend", receiveData)