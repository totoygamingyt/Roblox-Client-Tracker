-- Removes a key from the Settings Errors table.

local Plugin = script.Parent.Parent.Parent
local Action = require(Plugin.Packages.Framework).Util.Action

return Action(script.Name, function(error)
	return {
		error = error,
	}
end)
