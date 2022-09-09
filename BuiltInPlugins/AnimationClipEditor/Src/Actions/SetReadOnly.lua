--!strict
--[[
	Used to communicate to components in the editor
	whether the editor is the currently active plugin.

	Params:
		bool active
]]

local Action = require(script.Parent.Action)

return Action(script.Name, function(readOnly: boolean): {readOnly: boolean}
	return {
		readOnly = readOnly
	}
end)
