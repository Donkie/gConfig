# gConfig
A configuration library for Garrysmod addons

## Proposed library interface
_`<return type> <function name>(<(argument type) argument>)`_
### gConfig namespace
------
#### _Config_ gConfig.register(_string_ addonName)
Registers an addon to the gConfig system, returns a _Config_ object.
Throws an error if the addon has already been registered.

#### _Config_ gConfig.get(_string_ addonName)
Returns a _Config_ object from the gConfig system. The addon doesn't have to be registered yet.

### Config class
------
#### _void_ Config:add(_ConfigStruct_ variables)
Adds a config item to the addons config. See _ConfigStruct_ for the parameters.
Throws an error if an item with this id has already been added.

#### _any_ Config:get(_string_ id)
Returns the value of the config item with this id. If none has been set, returns the default. If default hasn't been set, returns _nil_.

#### _void_ Config:monitor(_string_ id, _function_ onChange(_string_ id, _any_ oldValue, _any_ newValue))
Calls the supplied onChange function if the value of the config item with this id changes.

### ConfigStruct
------
Type | Name | Description
--- | --- | ---
string | id | The unique identifier
enum | realm | Must be any of `gConfig.Server / gConfig.Shared / gConfig.Client`. A server/shared item can only be edited by authorized players. Only shared/client items are visible to the clientside. All realm types are visible to the serverside. All items are stored on the server/db, never on the clients machine. Client items are unique to each player.
enum | access | Must be any of `gConfig.User / gConfig.Admin / gConfig.SuperAdmin / gConfig.None`. The default access level. Only applicable to server/shared items. Setting to None means nobody has access to this by default.
string | name | A pretty name
string | description | A pretty description
string | type | The value type
table | typeOptions | [optional] A list of options for the chosen type
any | default | [optional] The default value
