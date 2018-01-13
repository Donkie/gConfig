
util.AddNetworkString("gConfigSend")
util.AddNetworkString("gConfigSendValue")
util.AddNetworkString("gConfigRequestHistory")
util.AddNetworkString("gConfigSendHistory")

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

local function rateLimit(ply)
	if (ply.gConfigNextMessage or 0) > SysTime() then
		gConfig.msgPlayerWarning(ply, "Please wait before doing that again.")
		return true
	end
	ply.gConfigNextMessage = SysTime() + 2
	return false
end

net.Receive("gConfigSendValue", function(_, ply)
	if rateLimit(ply) then return end

	local addon = net.ReadString()
	local id = net.ReadString()
	local comment = net.ReadString()
	local newValue = net.ReadType()

	if not gConfig.exists(addon) then return end -- Invalid config

	local config = gConfig.get(addon)

	if not config.items[id] then return end -- Invalid item

	local success, errMsg = config:set(id, newValue, ply, comment)
	if not success then
		gConfig.msgPlayerWarning(ply, "Update failed with reason: %s", errMsg)
		return
	end
end)

net.Receive("gConfigRequestHistory", function(_, ply)
	if rateLimit(ply) then return end

	local addon = net.ReadString()
	local id = net.ReadString()

	if not gConfig.exists(addon) then return end -- Invalid config

	local config = gConfig.get(addon)

	if not config.items[id] then return end -- Invalid item

	if not config:hasAccess(id, ply) then return end

	gConfig.GetHistory(addon, id, function(historyTbl)
		if not IsValid(ply) then return end

		net.Start("gConfigSendHistory")
			net.WriteString(addon)
			net.WriteString(id)
			net.WriteUInt(#historyTbl, 8)
			for i = 1, #historyTbl do
				local row = historyTbl[i]

				net.WriteUInt(row.date, 32)
				net.WriteString(row.author)
				net.WriteString(row.authorsid)
				net.WriteString(row.comment)
				net.WriteType(row.value)
			end
		net.Send(ply)
	end)
end)
