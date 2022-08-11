local Players = game:GetService("Players")
local CorePackages = game:GetService("CorePackages")
local CoreGui = game:GetService("CoreGui")

local Modules = CoreGui.RobloxGui.Modules
local ThrottleUserId = require(CorePackages.AppTempCommon.LuaApp.Utils.ThrottleUserId)
local ShareInviteLinkABTestManager = require(Modules.Settings.ShareInviteLinkABTestManager)

local GetFFlagShareInviteLinkContextMenuV1ABTestEnabled = require(Modules.Settings.Flags.GetFFlagShareInviteLinkContextMenuV1ABTestEnabled)

game:DefineFastFlag("ShareInviteLinkContextMenuV1Enabled", false)
game:DefineFastInt("ShareInviteLinkContextMenuV1RolloutPercentage", 0)

return function()
	local localPlayer = Players.LocalPlayer

	if not localPlayer or not localPlayer.UserId then
		return false
	end

	if GetFFlagShareInviteLinkContextMenuV1ABTestEnabled() then
		return ShareInviteLinkABTestManager.default:isShareInviteLinkEnabled()
	end

	local rolloutPercent = game:GetFastInt("ShareInviteLinkContextMenuV1RolloutPercentage")
	return game:GetFastFlag("ShareInviteLinkContextMenuV1Enabled") or ThrottleUserId(rolloutPercent, localPlayer.UserId)
end
