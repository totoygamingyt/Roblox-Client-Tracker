--[[
	Children of this component should not have a UiListLayout Sibling
--]]

local Plugin = script.Parent.Parent.Parent.Parent.Parent

local Framework = require(Plugin.Packages.Framework)
local Roact = require(Plugin.Packages.Roact)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local ContextItems = require(Plugin.Src.ContextItems)

local DEFAULT_PADDING = UDim.new(0, 12)

local Panel = Roact.PureComponent:extend(script.Name)

function Panel:init(initialProps)
	local padding = initialProps.Padding or DEFAULT_PADDING
	self.mainFrameRef = Roact.createRef()
	self.mainLayoutRef = Roact.createRef()
	self.contentFrameRef = Roact.createRef()
	self.contentLayoutRef = Roact.createRef()

	self.state = {
		padding = padding,
		isExpanded = true,
	}

	self.onExpandedStateChanged = function()
		self:setState({
			isExpanded = not self.state.isExpanded
		})
	end

	self.updateMainSize = function()
		local frame = self.mainFrameRef.current
		local layout = self.mainLayoutRef.current

		if layout and frame then
			frame.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
		end
	end

	self.updateContentSize = function()
		local frame = self.contentFrameRef.current
		local layout = self.contentLayoutRef.current

		if layout and frame then
			-- padding offset needs to be added to pad the bottom of the panel
			frame.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + DEFAULT_PADDING.Offset)
		end
	end
end

function Panel:render()
	local theme = self.props.Theme:get()

	local panelTheme = theme.panelTheme
	local title = self.props.Title or "Title"
	local layoutOrder = self.props.LayoutOrder
	local isSubsection = self.props.isSubsection

	local isExpanded = self.state.isExpanded
	local padding = self.state.padding
	local image = isExpanded and panelTheme.openIcon or panelTheme.closeIcon

	local children = self.props[Roact.Children]
	if children then
		children["UIListLayout"] = Roact.createElement("UIListLayout", {
			Padding = padding,
			SortOrder = Enum.SortOrder.LayoutOrder,
			[Roact.Ref] = self.contentLayoutRef,
			[Roact.Change.AbsoluteContentSize] = self.updateContentSize
		})
	end

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = layoutOrder,
		BackgroundTransparency = 1,
		[Roact.Ref] = self.mainFrameRef,
	}, {
		Layout = Roact.createElement("UIListLayout", {
			Padding = DEFAULT_PADDING,
			SortOrder = Enum.SortOrder.LayoutOrder,
			[Roact.Ref] = self.mainLayoutRef,
			[Roact.Change.AbsoluteContentSize] = self.updateMainSize,
		}),

		ToggleButton = Roact.createElement("ImageButton", {
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = panelTheme.panelColor,
			BorderSizePixel = 0,
			BackgroundTransparency = (isSubsection) and 1 or 0,
			LayoutOrder =  1,
			[Roact.Event.Activated] = self.onExpandedStateChanged,
		}, {
			-- Positions button
			Roact.createElement("ImageLabel",{
				Size = UDim2.new(0, 20, 0, 28),
				BackgroundTransparency = 1,
			}, {
				Roact.createElement("ImageLabel", {
					Image = image,
					Size = UDim2.new(0, 10, 0, 10),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					BackgroundTransparency = 1,
					ScaleType = Enum.ScaleType.Fit,
				}),
			}),
			Roact.createElement("TextLabel", {
				Text = title or "Title",
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 20, 0, 0),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextColor3 = theme.textColor,
				Font = theme.panelTheme.font,
				TextSize = theme.panelTheme.textSize,
			}),
		}),

		-- Children are repacked into a frame.
		Content = isExpanded and Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			[Roact.Ref] = self.contentFrameRef,

		}, children),
	})
end


Panel = withContext({
	Theme = ContextItems.UILibraryTheme,
})(Panel)



return Panel
