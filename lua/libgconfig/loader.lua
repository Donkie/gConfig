
local function loadFolder(dir)
	local files, _ = file.Find(dir .. "/*.lua", "LUA")
	for _, f in pairs(files) do
		if f == "loader.lua" then continue end

		local iscl = f:match("^cl_") != nil
		local issh = f:match("^sh_") != nil
		local issv = f:match("^sv_") != nil

		local fullpath = string.format("%s/%s", dir, f)

		if SERVER then
			if iscl or issh then
				AddCSLuaFile(filepath)
			end

			if issh or issv then
				gConfig.msgInfo(string.format("Loading %s", fullpath))
				include(fullpath)
			end
		else
			if iscl or issh then
				gConfig.msgInfo(string.format("Loading %s", fullpath))
				include(fullpath)
			end
		end

		if not iscl and not issh and not issv then
			gConfig.msgWarning(string.format("Ignored %s", fullpath))
		end
	end
end

loadFolder("libgconfig")
loadFolder("gconfig")
