![](http://f.donkie.co/qSEEF)

A configuration library for Garrysmod addons

# For Server Owners
Install this addon to your addons directory, then follow the instructions in `lua/gconfig.lua`

# For Developers
The config for your addon should be placed in a lua file in the `lua/gconfig/` directory of your addon with a unique name.

## Library interface
_`<return type> <function name>(<(argument type) argument>)`_
### gConfig namespace
------
#### _Config_ gConfig.register(_string_ addonName)
Registers an addon to the gConfig system, returns a _Config_ object.
Throws an error if the addon has already been registered.

#### _Config_ gConfig.get(_string_ addonName)
Returns a _Config_ object from the gConfig system. The addon doesn't have to be registered yet.

#### _void_ gConfig.addType(_string_ typeName, _function_ match(_any_ value), _function_ gui(?), _function_ serialize(_any_ value), _function_ unserialize(_string_ value))
Adds a new type to the gConfig system. (Use a struct instead of a bunch of parameters?)
* **match** should return a _boolean_ wether this value is permitted
* **gui** is called whenever the picker for this needs to be created
* **serialize** is called to serialize the value, return a _string_
* **unserialize** is called to unserialize the value, return _any_

### Config class
------
#### _void_ Config:add(_ConfigStruct_ variables)
Adds a config item to the addons config. See _ConfigStruct_ for the parameters.
Throws an error if an item with this id has already been added.

#### _any_ Config:get(_string_ id, _vararg_ ...)
Returns the value of the config item with this id. If none has been set, returns the default. If default hasn't been set, returns _nil_.
If the config item is of type Function, it will call the function with the vararg parameters.

#### _void_ Config:monitor(_string_ id, _function_ onChange(_string_ id, _any_ oldValue, _any_ newValue))
Calls the supplied onChange function if the value of the config item with this id changes.

### ConfigStruct
------
Type   | Name        | Description
---    | ---         | ---
string | id          | The unique identifier
enum   | realm       | Must be any of `gConfig.Server / gConfig.Shared / gConfig.Client`. A server/shared item can only be edited by authorized players. Only shared/client items are visible to the clientside. All realm types are visible to the serverside. All items are stored on the server/db, never on the clients machine. Client items are unique to each player.
enum   | access      | Must be any of `gConfig.User / gConfig.Admin / gConfig.SuperAdmin / gConfig.None`. The default access level. Only applicable to server/shared items. Setting to None means nobody has access to this by default.
string | name        | A pretty name
string | description | A pretty description
string | type        | The value type
number | lastChange  | [optional] When this config item was added/last changed. Used to warn about outdated config values. A UNIX timestamp.
string | category    | [optional] A category
table  | typeOptions | [optional] A list of options for the chosen type
any    | default     | [optional] The default value
bool   | mapUnique   | [optional] Is this items value based on the current map

### Built-in Types
------
Type         | Name     | Options                                                                                                                                                                                                                                                                                                                               | Description
---          | ---      | ---                                                                                                                                                                                                                                                                                                                                   | ---
string       | String   | <ul><li>_integer_ min - Minimum length</li><li>_integer_ max - Maximum length</li><li>_string_ regex - Must match this regex</li></ul>                                                                                                                                                                                                | A one-line string
string       | Text     | <ul><li>_integer_ min - Minimum length</li><li>_integer_ max - Maximum length</li><li>_string_ regex - Must match this regex</li></ul>                                                                                                                                                                                                | A multiline string
number       | Integer  | <ul><li>_integer_ min - Minimum value</li><li>_integer_ max - Maximum value</li></ul>                                                                                                                                                                                                                                                 | A non-integer number
number       | Number   | <ul><li>_integer_ min - Minimum value</li><li>_integer_ max - Maximum value</li><li>_integer_ precision - Number of decimal places</li></ul>                                                                                                                                                                                          | An integer number
any          | Enum     | <ul><li>_table_ data - A dictionary of allowed values</li><li>_bool_ allowEmpty - Allows the user to select an empty list item</li></ul>                                                                                                                                                                                              | Allows any value in the supplied list. Keys being the returned value, values being the displayed name
color struct | Color    | <ul><li>_bool_ alphaChannel - Enables alpha channel picking</li></ul>                                                                                                                                                                                                                                                                 | A color
vector       | Position |                                                                                                                                                                                                                                                                                                                                       | A world position
string       | Model    | <ul><li>_bool_ playerModel - Only allow models which are valid player models</li><li>_bool_ physics - Only allow models with valid physicmodels</li></ul>                                                                                                                                                                             | A model path
string       | Sound    | <ul><li>_bool_ disallowMP3 - Disallow MP3 files</li><li>_bool_ disallowWAV - Disallow WAV files</li></ul>                                                                                                                                                                                                                             | A sound path
number       | Team     |                                                                                                                                                                                                                                                                                                                                       | A team defined with the team. system (includes DarkRP teams)
function     | Function | ?                                                                                                                                                                                                                                                                                                                                     | A piece of lua code for advanced configuration needs. Going to use RunString with a wrapper function.
table        | List     | <ul><li>_string_ type - The item type</li><li>_table_ typeOptions - A list of options</li><li>_integer_ maxItems - Maximum number of items</li><li>_bool_ unique - Only allow unique values.</li><li>_bool_ lookupTable - Returns the table as a lookup table for faster indexing. Disables nesting support. Forces unique.</li></ul> | A list of items of the chosen type. Returns a sequential array of the data. Supports nested lists.
