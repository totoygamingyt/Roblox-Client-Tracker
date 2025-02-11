--[[
	A dialog which prompts the user if they want to purchase a plugin.
	Diplays only when the user has enough robux to purchase.

	Props:
		string Name = The name of the product to be purchased.
		string Creator = The creator of the product to be purchased.
		Content Thumbnail = The thumbnail image displayed within the dialog.
		int Cost = The Robux cost of the product to be purchased.
		int Balance = The current user's Robux balance.

		function OnButtonClicked = A callback for when a button is clicked.
			Passes true if the user wants to buy the plugin.
		function OnClose = A callback for when the dialog is closed.
]]

local Plugin = script.Parent.Parent.Parent.Parent
local Packages = Plugin.Packages

local Roact = require(Packages.Roact)
local PurchaseDialog = require(Plugin.Core.Components.PurchaseFlow.PurchaseDialog)

local ContextHelper = require(Plugin.Core.Util.ContextHelper)
local withLocalization = ContextHelper.withLocalization

local BuyPluginDialog = Roact.PureComponent:extend("BuyPluginDialog")

function BuyPluginDialog:render()
	return withLocalization(function(localization, localizedContent)
		local props = self.props
		local onButtonClicked = props.OnButtonClicked
		local onClose = props.OnClose
		local thumbnail = props.Thumbnail
		local name = props.Name
		local creator = props.Creator
		local cost = props.Cost
		local balance = props.Balance
		local primaryString = "RoundPrimary"

		return Roact.createElement(PurchaseDialog, {
			Buttons = {
				{ Key = false, Text = localizedContent.PurchaseFlow.Cancel },
				{ Key = true, Text = localizedContent.PurchaseFlow.Buy, Style = primaryString },
			},
			OnButtonClicked = onButtonClicked,
			OnClose = onClose,
			Title = localizedContent.PurchaseFlow.BuyTitle,
			Prompt = localization:getLocalizedBuyPrompt(name, creator, cost),
			Thumbnail = thumbnail,
			Balance = balance,
		})
	end)
end

return BuyPluginDialog
