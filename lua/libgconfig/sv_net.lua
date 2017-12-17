
util.AddNetworkString("gConfigSend")

function gConfig.sendValue(addon, item, value, ply)
	net.Start("gConfigSend")
		net.WriteString(addon)
		net.WriteString(item)
		net.WriteType(value)
		net.WriteEntity(ply)
	net.Broadcast()
end
