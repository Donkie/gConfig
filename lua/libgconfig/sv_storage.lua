
gConfig.metso = include("metso/metso.lua")
local dbConfig = include("gconfig.lua")
if not dbConfig or not istable(dbConfig) or not dbConfig.driver then
	gConfig.msgError("Invalid database config!")
	return
end

--TODO: maybe not expose the database object?
gConfig.db = gConfig.metso.create(dbConfig)

gConfig.msgInfo("Loaded database")
