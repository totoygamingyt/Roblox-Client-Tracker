--[[
	Used to set the horizontal zoom extents.

	TODO: Deprecated with GetFFlagCurveEditor
]]

local Action = require(script.Parent.Action)

return Action(script.Name, function(scroll, zoom)
	return {
		scroll = scroll,
		zoom = zoom,
	}
end)