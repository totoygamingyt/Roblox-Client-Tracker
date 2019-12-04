local root = script.Parent.Parent.Parent

-- imports
local Rodux = require(root.lib.Rodux)
local Cryo = require(root.lib.Cryo)

local actions = root.src.actions
local SetError = require(actions.SetError)

return Rodux.createReducer({}, {
	[SetError.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			name = action.name,
			message = action.message,
		})
	end,
})