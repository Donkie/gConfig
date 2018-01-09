local Config = gConfig.register("Test Addon")

Config:add({
	id = "booltest",
	realm = gConfig.Server,
	access = gConfig.Admin,
	name = "Boolean Test",
	description = "This tests a boolean value",
	category = "Test",
	type = "Boolean",
})

Config:add({
	id = "stringtest",
	realm = gConfig.Server,
	access = gConfig.Admin,
	name = "String Test",
	description = "This tests a string value",
	category = "Test",
	type = "String",
	typeOptions = {
		min = 3,
		max = 10,
		pattern = "^[a-zA-Z]+$",
		patternHelp = "Only letters"
	}
})

Config:add({
	id = "texttest",
	realm = gConfig.Server,
	access = gConfig.Admin,
	name = "Text Test",
	description = "This tests a text value",
	category = "Test",
	type = "Text",
	typeOptions = {
		max = 300
	}
})
