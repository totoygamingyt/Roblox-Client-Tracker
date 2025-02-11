local App = script:FindFirstAncestor("App")
local UIBlox = App.Parent
local Core = UIBlox.Core
local Packages = UIBlox.Parent

local t = require(Packages.t)
local Roact = require(Packages.Roact)

local PrimarySystemButton = require(App.Button.PrimarySystemButton)
local SecondaryButton = require(App.Button.SecondaryButton)
local ControlState = require(Core.Control.Enum.ControlState)

local PlayerTileButton = Roact.PureComponent:extend("PlayerTileButton")
local UIBloxConfig = require(UIBlox.UIBloxConfig)
local enablePlayerTilePaddingFix = UIBloxConfig.enablePlayerTilePaddingFix

PlayerTileButton.validateProps = t.strictInterface({
	buttonHeight = t.optional(t.number),
	buttonWidth = t.optional(t.number),
	icon = t.union(t.string, t.table),
	onActivated = t.optional(t.callback),
	isSecondary = t.optional(t.boolean),
	isDisabled = t.optional(t.boolean),
	tileSize = t.optional(t.UDim2),
	mouseEnter = t.optional(t.callback),
	mouseLeave = t.optional(t.callback),
})

PlayerTileButton.defaultProps = {
	isSecondary = false,
	isDisabled = false,
}

if enablePlayerTilePaddingFix then
	PlayerTileButton.defaultProps.buttonHeight = 36
	PlayerTileButton.defaultProps.buttonWidth = 38
else
	PlayerTileButton.defaultProps.tileSize = UDim2.new(0, 150, 0, 150)
end

function PlayerTileButton:render()
	local isSecondary = self.props.isSecondary
	local onActivated = self.props.onActivated
	local isDisabled = self.props.isDisabled
	local icon = self.props.icon

	local buttonSize
	if enablePlayerTilePaddingFix then
		buttonSize = UDim2.fromOffset(self.props.buttonWidth, self.props.buttonHeight)
	else
		local tileSize = self.props.tileSize

		local BUTTON_HEIGHT = 36
		local OUTER_BUTTON_PADDING = 10
		local MAX_BUTTON_SIZE = tileSize.X.Offset / 2 - (OUTER_BUTTON_PADDING + 5)

		buttonSize = UDim2.new(0, MAX_BUTTON_SIZE, 0, BUTTON_HEIGHT)
	end

	local buttonType = isSecondary and SecondaryButton or PrimarySystemButton
	return Roact.createElement(buttonType, {
		automaticSize = Enum.AutomaticSize.XY,
		position = UDim2.new(1, 0, 1, 0),
		size = buttonSize,
		anchorPoint = Vector2.new(1, 1),
		onActivated = onActivated or function() end,
		isDisabled = isDisabled,
		icon = icon,
		onStateChanged = function(newState, oldState)
			if newState == ControlState.Hover then
				self.props.mouseEnter()
			elseif oldState == ControlState.Hover then
				self.props.mouseLeave()
			end
		end,
	})
end

return PlayerTileButton
