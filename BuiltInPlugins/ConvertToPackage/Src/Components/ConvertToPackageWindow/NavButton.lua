--[[
	NavButton
	A simple button for menu navigation

	Necessary Props:
		isPrimary boolean, sets the button as "primary", this changes the colors and removes border
		onClick callback, called when the button is clicked
		titleText string, set the text of the button

		Size UDim2, size of the button
		Position UDim2, position of the button
		LayoutOrder number, layout order of the button
]]
local Plugin = script.Parent.Parent.Parent.Parent

local Packages = Plugin.Packages
local Framework = require(Packages.Framework)
local Roact = require(Packages.Roact)
local UILibrary = require(Packages.UILibrary)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local Util = Plugin.Src.Util
local Constants = require(Util.Constants)

local SharedFlags = Framework.SharedFlags
local FFlagRemoveUILibraryRoundFrame = SharedFlags.getFFlagRemoveUILibraryRoundFrame()

if FFlagRemoveUILibraryRoundFrame then
	return nil
end

local RoundFrame = UILibrary.Component.RoundFrame

local NavButton = Roact.Component:extend("NavButton")

function NavButton:init(props)
	self:setState({
		hovered = false,
		pressed = false,
	})
	self.onMouseEnter = function()
		self:setState({ hovered = true })
	end

	self.onMouseLeave = function()
		self:setState({ hovered = false })
	end

	self.onMouseButton1Down = function()
		self:setState({ pressed = true })
	end

	self.onMouseButton1Up = function()
		self:setState({ pressed = false })
	end
end

function NavButton:render()
	local props = self.props
	local style = props.Stylizer
	local colors = props.isPrimary and style.nav.mainButton or style.nav.button

	local backgroundColor
	if self.state.hovered and self.state.pressed then
		backgroundColor = colors.pressBackground
	elseif self.state.hovered then
		backgroundColor = colors.hoverBackground
	else
		backgroundColor = colors.background
	end

	return Roact.createElement(RoundFrame, {
		Size = props.Size,
		Position = props.Position,
		LayoutOrder = props.LayoutOrder,
		BackgroundColor3 = backgroundColor,
		BorderSizePixel = props.isPrimary and 0 or 1,
		[Roact.Event.MouseButton1Down] = self.onMouseButton1Down,
		[Roact.Event.MouseButton1Up] = self.onMouseButton1Up,
		OnActivated = props.onClick,
		OnMouseEnter = self.onMouseEnter,
		OnMouseLeave = self.onMouseLeave
	}, {
		Title = Roact.createElement("TextLabel", {
			Text = props.titleText,
			Font = Constants.FONT,
			TextSize = Constants.FONT_SIZE_LARGE,
			BackgroundTransparency = 1,
			TextColor3 = colors.textColor,
			Size = UDim2.new(1, 0, 1, 0),
		})
	})
end

NavButton = withContext({
	Stylizer = ContextServices.Stylizer,
})(NavButton)

return NavButton
