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

Config:add({
	id = "integertest",
	realm = gConfig.Server,
	access = gConfig.Admin,
	name = "Integer Test",
	description = "This tests an integer value",
	category = "Test",
	type = "Integer",
	typeOptions = {
		min = 0,
		max = 100
	}
})

Config:add({
	id = "numbertest",
	realm = gConfig.Server,
	access = gConfig.Admin,
	name = "Number Test",
	description = "This tests a number value",
	category = "Test",
	type = "Number",
	typeOptions = {
		min = -100,
		max = 100,
		decimals = 2
	}
})

Config:add({
	id = "enumtest",
	realm = gConfig.Server,
	access = gConfig.Admin,
	name = "Enum Test",
	description = "This tests an enum value",
	category = "Test",
	default = "key1",
	type = "Enum",
	typeOptions = {
		data = {
			key1 = "Enum 1",
			key2 = "Enum 2",
			key3 = "Enum 3",
		},
		allowEmpty = false,
	}
})

Config:add({
	id = "enumtest2",
	realm = gConfig.Server,
	access = gConfig.Admin,
	name = "Enum Test 2",
	description = "This tests an enum value with allowEmpty",
	category = "Test",
	type = "Enum",
	typeOptions = {
		data = {
			key1 = "Enum 1",
			key2 = "Enum 2",
			key3 = "Enum 3",
		},
		allowEmpty = true,
	}
})
