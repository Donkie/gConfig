
util.AddNetworkString("gConfigSend")
util.AddNetworkString("gConfigSendValue")

function gConfig.sendValue(addon, item, value, ply)
	net.Start("gConfigSend")
		net.WriteString(addon)
		net.WriteString(item)
		net.WriteType(value)
		if IsValid(ply) then
			net.WriteBool(true)
			net.WriteEntity(ply)
		else
			net.WriteBool(false)
		end
	net.Broadcast()
end

net.Receive("gConfigSendValue", function(_, ply)
	if (ply.gConfigNextSendValue or 0) > CurTime() then
		gConfig.msgPlayerWarning(ply, "Please wait before doing that again.")
		return
	end
	ply.gConfigNextSendValue = CurTime() + 2

	local addon = net.ReadString()
	local id = net.ReadString()
	local newValue = net.ReadType()

	if not gConfig.exists(addon) then return end -- Invalid config

	local config = gConfig.get(addon)

	if not config.items[id] then return end -- Invalid item

	local success, errMsg = config:set(id, newValue, ply, comment or "")
	if not success then
		gConfig.msgPlayerWarning(ply, "Update failed with reason: %s", errMsg)
		return
	end
end)
