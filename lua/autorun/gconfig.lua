AddCSLuaFile()
AddCSLuaFile("libgconfig/loader.lua")
AddCSLuaFile("metso/metso.lua")

gConfig = {}
gConfig.colors = {
	main = Color(204, 130, 75),
	info = Color(230, 230, 230),
	success = Color(89, 240, 89),
	warning = Color(240, 174, 89),
	error = Color(240, 89, 89),
}

local realmClr = SERVER and Color(89, 89, 240) or Color(240, 240, 89)
local realmStr = SERVER and "[SV]" or "[CL]"
function gConfig.msg(text, clr)
	MsgC(realmClr, realmStr, gConfig.colors.main, "[gConfig] ", clr, text, "\n")
end

function gConfig.msgInfo(text, ...)
	gConfig.msg(text:format(...), gConfig.colors.info)
end

function gConfig.msgSuccess(text, ...)
	gConfig.msg(text:format(...), gConfig.colors.success)
end

function gConfig.msgWarning(text, ...)
	gConfig.msg(text:format(...), gConfig.colors.warning)
end

function gConfig.msgError(text, ...)
	gConfig.msg(text:format(...), gConfig.colors.error)
end

gConfig.msgInfo("Initializing")

include("libgconfig/loader.lua")
