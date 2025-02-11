local CorePackages = game:GetService("CorePackages")
local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")

local Action = require(CorePackages.AppTempCommon.Common.Action)
local t = require(CorePackages.Packages.t)
local maybeAssert = require(RobloxGui.Modules.InGameChat.BubbleChat.Helpers.maybeAssert)

return Action(script.Name, function(userId, newState)
	maybeAssert(tonumber(userId) ~= nil)
	maybeAssert(t.string(newState))

	return {
		userId = tostring(userId),
		newState = newState,
	}
end)
