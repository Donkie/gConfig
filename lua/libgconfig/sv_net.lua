
util.AddNetworkString("gConfigSend")

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
