--[[
	The Nav Bar displays a path that is determined from a linked list of tables that have a each have a Parent.
	Each element in the path is clickble to set the current view to the one that corresponds to that screen.
	The path element that corresponds to the current screen will not be clickable.

	Required Props:
		UDim2 Size: The size of this component within it's parent.
		number LayoutOrder: The position of this component in it's parent.
]]
local Plugin = script.Parent.Parent.Parent

local Cryo = require(Plugin.Packages.Cryo)
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)

local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local LinkText = Framework.UI.LinkText

local Util = Framework.Util
local GetTextSize = Util.GetTextSize
local LayoutOrderIterator = Util.LayoutOrderIterator
local StyleModifier = Util.StyleModifier

local SetRecentViewToggled = require(Plugin.Src.Actions.SetRecentViewToggled)
local SetScreen = require(Plugin.Src.Actions.SetScreen)

local Screens = require(Plugin.Src.Util.Screens)

local NavBar = Roact.PureComponent:extend("NavBar")

local NavBarPadding = 12

function NavBar:getCurrentPath(currentScreen)
	local path = {}
	local startingScreen = currentScreen

	local isFolderScreen = currentScreen.Path == Screens.MAIN.Path

	local navBarWidth = self.NavBar.current and self.NavBar.current.AbsoluteSize.X or 0

	while currentScreen ~= nil do
		if self.state.contentWidth + NavBarPadding > navBarWidth then
			self.preTruncContentWidth = self.state.contentWidth
			if (currentScreen.Path ~= startingScreen.Path or isFolderScreen) and not self.truncatedPathParts[currentScreen.Path] then
				self.truncatedPathParts[currentScreen.Path] = true
			end
		elseif self.preTruncContentWidth + NavBarPadding <= navBarWidth then
			self.truncatedPathParts = {}
		end
		table.insert(path, 1, currentScreen)

		currentScreen = Screens[currentScreen.Parent]
	end

	return path
end

function NavBar:buildPathComponents(props, theme, localization, dispatch)
	local pathComponents = {}

	local currentScreen = props.CurrentScreen

	local recentViewToggled = props.RecentViewToggled
	local dispatchSetRecentViewToggled = props.dispatchSetRecentViewToggled

	local path = self:getCurrentPath(currentScreen)

	local count = 1
	local layoutIndex = LayoutOrderIterator.new()
	local startingScreenPath = currentScreen.Path

	for index, screen in ipairs(path) do
		local isStartingElement = screen.Path == startingScreenPath
		local isTopLevel = screen.Path == Screens.MAIN.Path

		local gameName = props.UniverseName ~= "" and props.UniverseName
			or localization:getText("NavBar", "GamePlaceholderName")
		local pathPartText = isTopLevel and gameName or localization:getText("Folders", screen.Path)

		local textTruncate = self.truncatedPathParts[screen.Path] and Enum.TextTruncate.AtEnd or nil

		local size = nil

		if self.truncatedPathParts[screen.Path] then
			size = UDim2.new(theme.NavBar.TruncatedTextScale, 0, 1, 0)
		end

		pathComponents[screen.Path] = Roact.createElement(LinkText, {
			Size = size,
			Text = pathPartText,

			Style = "NavBar",
			StyleModifier = isStartingElement and StyleModifier.Disabled or Roact.None,

			OnClick = function()
				if not isStartingElement then
					dispatch(true, screen)
					if recentViewToggled then
						dispatchSetRecentViewToggled(false)
					end
				end
			end,

			TextTruncate = textTruncate,

			LayoutOrder = layoutIndex:getNextOrder(),
		})

		if index ~= #path then
			local textExtents = GetTextSize(">", theme.FontSizeLarge, theme.Font)
			local textDimensions = UDim2.fromOffset(textExtents.X, textExtents.Y)

			pathComponents["PathSeparator-" .. count] = Roact.createElement("TextLabel", {
				Size = textDimensions,
				BackgroundTransparency = 1,
				Text = ">",
				TextColor3 = theme.TextColor,
				TextSize = theme.FontSizeLarge,
				Font = theme.Font,
				LayoutOrder = layoutIndex:getNextOrder(),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Bottom,
			})
		end

		if startingScreenPath == Screens.MAIN.Path then
			local gameIDText = "[" .. localization:getText("NavBar", "ID", {gameId = game.GameId}) .. "]"

			local textExtents = GetTextSize(gameIDText, theme.FontSizeMedium, theme.Font)
			local textDimensions = UDim2.fromOffset(textExtents.X, textExtents.Y)

			pathComponents["UniverseId"] = Roact.createElement("TextBox", {
				Size = textDimensions,
				LayoutOrder = layoutIndex:getNextOrder(),
				BackgroundTransparency = 1,

				Text = gameIDText,
				TextColor3 = theme.SubTextColor,
				TextSize = theme.FontSizeSmall,
				Font = theme.Font,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextEditable = false,
				ClearTextOnFocus = false,
			})
		end
		count = count + 1
	end

	return pathComponents
end

function NavBar:init()
	self.state = {
		contentWidth = 0,
		currentScreen = "",
	}

	self.preTruncContentWidth = 0
	self.truncatedPathParts = {}

	self.Layout = Roact.createRef()
	self.NavBar = Roact.createRef()
end

function NavBar:didMount()
	self:setState({
		contentWidth = self.Layout.current and self.Layout.current.AbsoluteContentSize.X or 0,
	})
end

function NavBar:didUpdate()
	local props = self.props
	local screen = props.CurrentScreen
	if screen ~= self.state.currentScreen then
		self:setState({
			currentScreen = screen,
			contentWidth = self.Layout.current and self.Layout.current.AbsoluteContentSize.X or 0,
		})
	end
end

function NavBar:render()
	local props = self.props
	local localization = self.props.Localization
	local theme = props.Stylizer

	local size = props.Size
	local layoutOrder = props.LayoutOrder

	local dispatchSetScreen = props.dispatchSetScreen

	local navPathComponents = self:buildPathComponents(props, theme, localization, dispatchSetScreen)

	local NavBarChildren = {
		GameBarLayout = Roact.createElement("UIListLayout",{
			Padding = UDim.new(0, theme.NavBar.Padding),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,

			[Roact.Ref] = self.Layout,
		}),

		GameBarPadding = Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, theme.NavBar.Padding),
		}),
	}

	NavBarChildren = Cryo.Dictionary.join(NavBarChildren, navPathComponents)

	local NavBarContents = Roact.createElement("Frame", {
			Size = size,
			LayoutOrder = layoutOrder,

			BackgroundColor3 = theme.NavBar.BackgroundColor,
			BorderSizePixel = 0,

			[Roact.Change.AbsoluteSize] = function()
				self:setState({
					contentWidth = self.Layout.current and self.Layout.current.AbsoluteContentSize.X or 0,
				})
			end,
			[Roact.Ref] = self.NavBar,
		}, NavBarChildren)

	return NavBarContents
end

NavBar = withContext({
	Stylizer = ContextServices.Stylizer,
	Localization = ContextServices.Localization,
})(NavBar)

local function mapStateToProps(state, props)
	local screen = state.Screen or {}
	local currentScreen = screen.currentScreen

	return {
		UniverseName = state.AssetManagerReducer.universeName,
		CurrentScreen = currentScreen,
		RecentViewToggled = state.AssetManagerReducer.recentViewToggled,
	}
end

local function mapDispatchToProps(dispatch)
	return {
		dispatchSetRecentViewToggled = function(toggled)
			dispatch(SetRecentViewToggled(toggled))
		end,
		dispatchSetScreen = function(enabled, screen)
			if enabled then
				dispatch(SetScreen(screen))
			end
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(NavBar)
