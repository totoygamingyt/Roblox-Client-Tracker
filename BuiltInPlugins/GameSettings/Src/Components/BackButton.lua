--[[
	A back button with a little separator below it.
]]
local FFlagGameSettingsRemoveFitContent = game:GetFastFlag("GameSettingsRemoveFitContent")

local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)

local Framework = require(Plugin.Packages.Framework)
local UI = Framework.UI
local Pane = UI.Pane
local Separator = UI.Separator

local FitToContent
if not FFlagGameSettingsRemoveFitContent then
	local UILibrary = require(Plugin.Packages.UILibrary)
	local createFitToContent = UILibrary.Component.createFitToContent
	FitToContent = createFitToContent("Frame", "UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	})
end

local BACK_BUTTON_IMAGE = "rbxasset://textures/GameSettings/ArrowLeft.png"
local BACK_BUTTON_SIZE = 24

return function(props)
	local layoutOrder = props.LayoutOrder
	local onActivated = props.OnActivated

	local children = {
		Padding = Roact.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 4),
		}),

		BackButton = Roact.createElement("ImageButton", {
			BackgroundTransparency = 1,
			Image = BACK_BUTTON_IMAGE,
			Size = UDim2.new(0, BACK_BUTTON_SIZE, 0, BACK_BUTTON_SIZE),
			Rotation = 90,
			LayoutOrder = 1,
			[Roact.Event.Activated] = onActivated,
		}),

		Separator = Roact.createElement(Separator, {
			LayoutOrder = 2,
		}),
	}

	if FFlagGameSettingsRemoveFitContent then
		return Roact.createElement(Pane, {
			AutomaticSize = Enum.AutomaticSize.Y,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			LayoutOrder = layoutOrder,
			Layout = Enum.FillDirection.Vertical,
			Spacing = UDim.new(0, 8),
		}, children)
	else
		return Roact.createElement(FitToContent, {
			BackgroundTransparency = 1,
			LayoutOrder = layoutOrder
		}, children)
	end
end
