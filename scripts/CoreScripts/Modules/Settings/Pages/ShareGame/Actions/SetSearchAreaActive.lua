--!nonstrict
local Modules = game:GetService("CorePackages").AppTempCommon
local Action = require(Modules.Common.Action)

return Action(script.Name, function(isActive)
	return {
		isActive = isActive,
	}
end)