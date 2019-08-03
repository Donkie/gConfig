
function gConfig.loadFolder(dir, forceShared)
	local files, _ = file.Find(dir .. "/*.lua", "LUA")
	for _, f in pairs(files) do
		if f == "loader.lua" then continue end

		local iscl = f:match("^cl_") != nil
		local issh = f:match("^sh_") != nil or forceShared
		local issv = f:match("^sv_") != nil

		local fullpath = string.format("%s/%s", dir, f)

		if SERVER then
			if iscl or issh then
				AddCSLuaFile(fullpath)
			end

			if issh or issv then
				gConfig.msgInfo("Loading %s", fullpath)
				include(fullpath)
			end
		else
			if iscl or issh then
				gConfig.msgInfo("Loading %s", fullpath)
				include(fullpath)
			end
		end

		if not iscl and not issh and not issv then
			gConfig.msgWarning("Ignored %s", fullpath)
		end
	end
end

gConfig.loadFolder("libgconfig")
gConfig.loadFolder("gconfig", true)

local function loadGamemodeConfigs()
	gConfig.loadFolder(GAMEMODE.FolderName .. "/gamemode/gconfig", true)

	gConfig.filesLoaded = true
end

if GAMEMODE then
	loadGamemodeConfigs()
else -- Wait for gamemode to load
	hook.Add("OnGamemodeLoaded", "gConfigWaitForGamemode", loadGamemodeConfigs)
end

hook.Add("Think", "gConfigWaitForLoad", function()
	if gConfig.filesLoaded and gConfig.dbReady then
		hook.Run("gConfigLoaded")
		hook.Remove("Think", "gConfigWaitForLoad")
	end
end)
