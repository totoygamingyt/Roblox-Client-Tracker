local App = script:FindFirstAncestor("App")
local UIBlox = App.Parent
local Core = UIBlox.Core
local Packages = UIBlox.Parent

local t = require(Packages.t)
local Roact = require(Packages.Roact)
local enumerate = require(Packages.enumerate)
local UIBloxConfig = require(Packages.UIBlox.UIBloxConfig)

local Interactable = require(Core.Control.Interactable)

local ControlState = require(Core.Control.Enum.ControlState)
local getContentStyle = require(Core.Button.getContentStyle)
local getIconSize = require(App.ImageSet.getIconSize)
local enumerateValidator = require(UIBlox.Utility.enumerateValidator)
local bindingValidator = require(Core.Utility.bindingValidator)
local validateImage = require(Core.ImageSet.Validator.validateImage)
local validateColorInfo = require(Core.Style.Validator.validateColorInfo)

local withStyle = require(Core.Style.withStyle)
local HoverButtonBackground = require(Core.Button.HoverButtonBackground)
local ImageSetComponent = require(Core.ImageSet.ImageSetComponent)
local IconSize = require(App.ImageSet.Enum.IconSize)

local withSelectionCursorProvider = require(App.SelectionImage.withSelectionCursorProvider)
local CursorKind = require(App.SelectionImage.CursorKind)
local RoactGamepad = require(Packages.RoactGamepad)
local Focusable = RoactGamepad.Focusable
local isCallable = require(UIBlox.Utility.isCallable)

local DEFAULT_BACKGROUND = "UIMuted"

local IconButton = Roact.PureComponent:extend("IconButton")
IconButton.debugProps = enumerate("debugProps", {
	"controlState",
})

IconButton.validateProps = t.strictInterface({
	-- The state change callback for the button
	onStateChanged = t.optional(isCallable),

	-- Is the button visually disabled
	isDisabled = t.optional(t.boolean),

	colorStyleDefault = t.optional(t.string),
	colorStyleHover = t.optional(t.string),

	-- color overrides for the icon default
	colorDefault = t.optional(validateColorInfo),
	-- color overrides for the icon hover
	colorHover = t.optional(validateColorInfo),

	--A Boolean value that determines whether user events are ignored and sink input
	userInteractionEnabled = t.optional(t.boolean),

	-- The activated callback for the button
	onActivated = t.optional(isCallable),

	-- Callback called when the position of the button changes
	onAbsolutePositionChanged = t.optional(isCallable),

	anchorPoint = t.optional(t.Vector2),
	layoutOrder = t.optional(t.number),
	position = t.optional(t.union(t.UDim2, t.table)), -- accept Roact binding as well as UDim2
	size = t.optional(t.union(t.UDim2, t.table)),
	icon = t.optional(validateImage),
	iconSize = t.optional(enumerateValidator(IconSize)),
	iconColor3 = t.optional(t.Color3),
	iconTransparency = t.optional(t.union(t.number, bindingValidator(t.number))),
	showBackground = t.optional(t.boolean),
	backgroundColor = t.optional(validateColorInfo),
	backgroundTransparency = t.optional(t.union(t.number, bindingValidator(t.number))),

	[Roact.Children] = t.optional(t.table),

	-- Override the default controlState
	[IconButton.debugProps.controlState] = t.optional(enumerateValidator(ControlState)),

	-- optional parameters for RoactGamepad
	NextSelectionLeft = t.optional(t.table),
	NextSelectionRight = t.optional(t.table),
	NextSelectionUp = t.optional(t.table),
	NextSelectionDown = t.optional(t.table),
	inputBindings = t.optional(t.table),
	buttonRef = t.optional(t.table),

	[Roact.Change.AbsoluteSize] = t.optional(t.callback),
})

IconButton.defaultProps = {
	anchorPoint = Vector2.new(0, 0),
	layoutOrder = 0,
	position = UDim2.new(0, 0, 0, 0),
	size = nil,
	icon = "",
	iconSize = IconSize.Medium,

	colorStyleDefault = "SystemPrimaryDefault",
	colorStyleHover = "SystemPrimaryDefault",

	iconColor3 = nil,
	iconTransparency = nil,
	showBackground = false,
	backgroundColor = nil,
	backgroundTransparency = nil,

	isDisabled = false,
	userInteractionEnabled = true,

	[IconButton.debugProps.controlState] = nil,
}

function IconButton:init()
	self:setState({
		controlState = ControlState.Initialize,
	})

	self.onStateChanged = function(oldState, newState)
		self:setState({
			controlState = newState,
		})
		if self.props.onStateChanged then
			self.props.onStateChanged(oldState, newState)
		end
	end

	local iconSizeToSizeScale = {
		[IconSize.Small] = 1,
		[IconSize.Medium] = 2,
		[IconSize.Large] = 3,
		[IconSize.XLarge] = 4,
		[IconSize.XXLarge] = 5,
	}
	self.getSize = function(iconSizeMeasurement)
		if self.props.size then
			return self.props.size
		end

		local iconSize = self.props.iconSize
		local extents = iconSizeMeasurement + 4 * iconSizeToSizeScale[iconSize]
		return UDim2.fromOffset(extents, extents)
	end
end

function IconButton:render()
	return withStyle(function(style)
		return withSelectionCursorProvider(function(getSelectionCursor)
			return self:renderWithProviders(style, getSelectionCursor)
		end)
	end)
end

function IconButton:renderWithProviders(style, getSelectionCursor)
	local iconSizeMeasurement = getIconSize(self.props.iconSize)
	local size = self.getSize(iconSizeMeasurement)
	local showBackground = self.props.showBackground
	local currentState = self.props[IconButton.debugProps.controlState] or self.state.controlState

	local iconStateColorMap = {
		[ControlState.Default] = self.props.colorStyleDefault,
		[ControlState.Hover] = self.props.colorStyleHover,
	}

	local iconStyle = getContentStyle(iconStateColorMap, currentState, style)
	local backgroundColor
	if self.props.backgroundColor == nil then
		backgroundColor = style.Theme[DEFAULT_BACKGROUND]
	else
		backgroundColor = self.props.backgroundColor
	end

	return Roact.createElement(Focusable[Interactable], {
		AnchorPoint = self.props.anchorPoint,
		LayoutOrder = self.props.layoutOrder,
		Position = self.props.position,
		Size = size,

		isDisabled = self.props.isDisabled,
		onStateChanged = self.onStateChanged,
		userInteractionEnabled = self.props.userInteractionEnabled,
		BackgroundTransparency = 1,
		AutoButtonColor = false,

		[Roact.Change.AbsoluteSize] = self.props[Roact.Change.AbsoluteSize],
		[Roact.Change.AbsolutePosition] = self.props.onAbsolutePositionChanged,
		[Roact.Event.Activated] = self.props.onActivated,

		[Roact.Ref] = self.props.buttonRef,
		NextSelectionLeft = self.props.NextSelectionLeft,
		NextSelectionRight = self.props.NextSelectionRight,
		NextSelectionUp = self.props.NextSelectionUp,
		NextSelectionDown = self.props.NextSelectionDown,
		inputBindings = self.props.inputBindings,
		SelectionImageObject = getSelectionCursor(CursorKind.RoundedRectNoInset),
	}, {
		sizeConstraint = Roact.createElement("UISizeConstraint", {
			MinSize = Vector2.new(iconSizeMeasurement, iconSizeMeasurement),
		}),
		imageLabel = Roact.createElement(ImageSetComponent.Label, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(iconSizeMeasurement, iconSizeMeasurement),
			BackgroundTransparency = 1,
			Image = self.props.icon,
			ImageColor3 = self.props.iconColor3 or iconStyle.Color,
			ImageTransparency = self.props.iconTransparency or iconStyle.Transparency,
		}, self.props[Roact.Children]),
		hoverBackground = currentState == ControlState.Hover and Roact.createElement(HoverButtonBackground) or nil,
		background = showBackground and Roact.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = backgroundColor.Color,
			BackgroundTransparency = self.props.backgroundTransparency or backgroundColor.Transparency,
			ZIndex = 0,
		}, {
			corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		}) or nil,
	})
end

return IconButton
