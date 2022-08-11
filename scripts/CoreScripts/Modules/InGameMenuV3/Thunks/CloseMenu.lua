--!nonstrict
local GuiService = game:GetService("GuiService")

local InGameMenu = script.Parent.Parent
local SocialDependencies = require(InGameMenu.SocialDependencies)
local SetMenuOpenAction = require(InGameMenu.Actions.SetMenuOpen)
local SendAnalytics = require(InGameMenu.Utility.SendAnalytics)
local Constants = require(InGameMenu.Resources.Constants)
local SetCurrentPage = require(InGameMenu.Actions.SetCurrentPage)
local RoduxShareLinks = SocialDependencies.RoduxShareLinks
local ClearShareInviteLink = RoduxShareLinks.Actions.ClearShareInviteLink
local PerfUtils = require(InGameMenu.Utility.PerfUtils)

local GetFFlagShareInviteLinkContextMenuV3Enabled = require(InGameMenu.Flags.GetFFlagShareInviteLinkContextMenuV3Enabled)
return function(store)
	PerfUtils.menuClose()
	GuiService:SetMenuIsOpen(false, "InGameMenu")
	GuiService.SelectedCoreObject = nil
	store:dispatch(SetMenuOpenAction(false))
	store:dispatch(SetCurrentPage(Constants.InitalPageKey))
	if GetFFlagShareInviteLinkContextMenuV3Enabled() then
		store:dispatch(ClearShareInviteLink())
	end
	SendAnalytics(Constants.AnalyticsMenuCloseName, Constants.AnalyticsMenuActionName, {})
end
