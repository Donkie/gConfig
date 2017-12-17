
gConfig.metso = include("metso/metso.lua")
gConfig.db = gConfig.metso.create({
	driver = "sqlite"
})
gConfig.msgInfo("Loaded database")

function gConfig.SaveValue(addon, item, value, ply, comment)
	gConfig.msgInfo("gConfig.SaveValue(%q, %q, %q, %q, %q)", addon, item, tostring(value), ply:Nick(), comment)
end
