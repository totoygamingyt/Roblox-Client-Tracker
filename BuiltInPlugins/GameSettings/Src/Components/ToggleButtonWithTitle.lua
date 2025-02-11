--[[
	ToggleButtonWithTitle Displays a TitledFrame with ToggleButton

	Props:
		string Description: An optional secondary title to place above this section.
		string Title: The title to place to the left of this section.
		callback OnClick: The function that will be called when this button is clicked to turn on and off.

	Optional Props:
		boolean Disabled: Whether or not this button can be clicked.
		number LayoutOrder: The layout order of this component.
		boolean Selected: whether the button should be on or off.
		boolean ShowWarning: whether the description text is shown as warning text
]]
local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local Cryo = require(Plugin.Packages.Cryo)

local Framework = require(Plugin.Packages.Framework)

local SharedFlags = Framework.SharedFlags
local FFlagRemoveUILibraryTitledFrame = SharedFlags.getFFlagRemoveUILibraryTitledFrame()

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local Util = Framework.Util

local UI = Framework.UI
local TitledFrame = if FFlagRemoveUILibraryTitledFrame then UI.TitledFrame else Framework.StudioUI.TitledFrame
local ToggleButton = UI.ToggleButton
local TextWithInlineLink = UI.TextWithInlineLink
local TextLabel = UI.Decoration.TextLabel

local FitTextLabel
if not FFlagRemoveUILibraryTitledFrame then
	FitTextLabel = Util.FitFrame.FitTextLabel
end

local LayoutOrderIterator = Util.LayoutOrderIterator

local ToggleButtonWithTitle = Roact.PureComponent:extend("ToggleButtonWithTitle")

function ToggleButtonWithTitle:init()
	self.state = {
		descriptionWidth = 0,
	}

	self.descriptionRef = Roact.createRef()

	self.onResize = function()
		local descriptionWidthContainer = self.descriptionRef.current
		if not descriptionWidthContainer then
			return
		end

		self:setState({
			descriptionWidth = descriptionWidthContainer.AbsoluteSize.X
		})
	end
end

function ToggleButtonWithTitle:render()
	local props = self.props
	local theme = props.Stylizer

	local descriptionWidth = self.state.descriptionWidth

	local description = props.Description
	local disabled = props.Disabled
	local layoutOrder = props.LayoutOrder
	local selected = props.Selected
	local title = props.Title
	local onClick = props.OnClick
	local showWarning = props.ShowWarning
	local linkProps = props.LinkProps

	local layoutIndex = LayoutOrderIterator.new()

	return Roact.createElement(TitledFrame, {
		Title = title,
		LayoutOrder = layoutOrder,
	}, {
		ToggleButton = Roact.createElement(ToggleButton, {
			Disabled = disabled,
			Selected = selected,
			LayoutOrder = layoutIndex:getNextOrder(),
			OnClick = onClick,
			Size = theme.settingsPage.toggleButtonSize,
		}),

		Description = props.Description and
			Roact.createElement(if FFlagRemoveUILibraryTitledFrame then TextLabel else FitTextLabel, Cryo.Dictionary.join(showWarning and theme.fontStyle.SmallError or theme.fontStyle.Subtext, {
				AutomaticSize = if FFlagRemoveUILibraryTitledFrame then Enum.AutomaticSize.XY else nil,
				BackgroundTransparency = 1,
				LayoutOrder = layoutIndex:getNextOrder(),
				TextTransparency = props.Disabled and 0.5 or 0,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Text = description,
				TextWrapped = true,
				width = UDim.new(0, descriptionWidth),
			})),

		LinkText = props.LinkProps and Roact.createElement(TextWithInlineLink, Cryo.Dictionary.join(linkProps, {
			LinkPlaceholder = "[link]",
			MaxWidth = descriptionWidth,
			LayoutOrder = layoutIndex:getNextOrder(),
			TextProps = Cryo.Dictionary.join(theme.fontStyle.Subtext, {
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		})),

		DescriptionWidth = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = layoutIndex:getNextOrder(),
			Size = UDim2.new(1,0,0,0),
			[Roact.Ref] = self.descriptionRef,
			[Roact.Change.AbsoluteSize] = self.onResize,
		}),
	})
end

ToggleButtonWithTitle = withContext({
	Stylizer = ContextServices.Stylizer,
})(ToggleButtonWithTitle)

return ToggleButtonWithTitle
