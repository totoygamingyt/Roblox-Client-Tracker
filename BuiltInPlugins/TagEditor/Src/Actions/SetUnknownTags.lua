local Plugin = script.Parent.Parent.Parent
local _Types = require(Plugin.Src.Types)

return function(data: _Types.Array<_Types.Tag>)
	return {
		type = "SetUnknownTags",
		data = data,
	}
end
