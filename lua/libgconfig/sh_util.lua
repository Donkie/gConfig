
--[[
utf8 additions
]]
--
-- Converts a relative index to an absolute
-- This is different from the above in that it cares about characters and not bytes
--
local function strRelToAbsChar( str, pos )
	if pos < 0 then
		pos = math.max( pos + utf8.len( str ) + 1, 0 )
	end
	return pos
end

--
-- UTF-8 compilant version of str[idx]
--
function utf8.idx( str, idx )
	idx = strRelToAbsChar( str, idx )

	if idx == 0 then return "" end
	if idx > utf8.len( str ) then return "" end

	local offset = utf8.offset( str, idx - 1 )
	return utf8.char( utf8.codepoint( str, offset ) )
end

--
-- UTF-8 compilant version of string.sub
--
function utf8.sub( str, charstart, charend )
	charstart = strRelToAbsChar( str, charstart )
	charend = strRelToAbsChar( str, charend )

	local buf = {}
	for i = charstart, charend do
		buf[#buf + 1] = utf8.idx( str, i )
	end

	return table.concat( buf )
end

--[[
Compares two values for equality, uses metatable __eq whenever available, otherwise tests the entire tables recursively.
]]
function gConfig.equals(val1, val2)
	if val1 == val2 then return true end
	if type(val1) != type(val2) then return false end
	if not istable(val1) then return false end

	local meta = getmetatable(val1)
	if meta and meta.__eq then
		return val1 == val2
	end

	local keySet = {}
	for k1, v1 in pairs(val1) do
		local v2 = val2[k1]
		if v2 == nil or gConfig.equals(v1, v2) == false then
			return false
		end
		keySet[k1] = true
	end

	for k2, _ in pairs(val2) do
		if not keySet[k2] then return false end
	end

	return true
end

--[[
Shortens the string with an ellipsis (...) if it's longer than len
]]
function gConfig.ellipsis(val, len)
	local str = tostring(val)
	if utf8.len(str) > (len - 3) then
		str = utf8.sub(str, 1, len - 3) .. "..."
	end
	return str
end

--[[
Appends "s" to plural values
]]
function gConfig.plural(str, quantity)
	if quantity == 1 then
		return str
	else
		return string.format("%ss", str)
	end
end

--[[
Player notifications
]]
if SERVER then
	util.AddNetworkString("gConfigMessage")
	function gConfig.msgPlayer(ply, text, clr)
		net.Start("gConfigMessage")
			net.WriteString(text)
			net.WriteColor(clr)
		net.Send(ply)
	end
else
	local function chatPrint(text, clr)
		chat.AddText(gConfig.colors.main, "[gConfig] ", clr, text)
		surface.PlaySound("buttons/button9.wav") -- 14 sounds good too
	end

	net.Receive("gConfigMessage", function()
		local text = net.ReadString()
		local clr = net.ReadColor()

		chatPrint(text, clr)
	end)

	function gConfig.msgPlayer(ply, text, clr)
		chatPrint(text, clr)
	end
end

function gConfig.msgPlayerInfo(ply, text, ...)
	gConfig.msgPlayer(ply, text:format(...), gConfig.colors.info)
end

function gConfig.msgPlayerSuccess(ply, text, ...)
	gConfig.msgPlayer(ply, text:format(...), gConfig.colors.success)
end

function gConfig.msgPlayerWarning(ply, text, ...)
	gConfig.msgPlayer(ply, text:format(...), gConfig.colors.warning)
end

function gConfig.msgPlayerError(ply, text, ...)
	gConfig.msgPlayer(ply, text:format(...), gConfig.colors.error)
end
