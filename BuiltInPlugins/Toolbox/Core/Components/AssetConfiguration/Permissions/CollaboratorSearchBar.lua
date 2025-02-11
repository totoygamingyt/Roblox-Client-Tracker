--[[
	Search Bar Component

	Implements a search bar component with a text box that dynamically moves as you type, and a button to request a search.

	Necessary Properties:
		DefaultText = string, default text to show in the empty search bar.
		NoResultsText = string, text to show when there is no search results
		Enabled = bool, is the search bar enabled?

		table Results : table of search results to display 
			format should be 
			{
				"Users" = {
					{Icon=RoactElement, Name="UsernameA", Key=theirUserId},
					{Icon=RoactElement, Name="UsernameB", Key=theirUserId},
				},
				"Groups" = {
					...
				},
			}

		LoadingMore = bool, true if making web request for more results to display loading animation
		MaxItems = int, the maximum number of entries that can display at a time.
			If this is less than the number of entries in the dropdown, a scrollbar will appear.
		HeaderHeight = int, the height of headers in dropdown in pixels
		ItemHeight = int, the height of each entry in the dropdown, in pixels.
		TextPadding = int, the amount of padding, in pixels, around the text elements.
		ShowRibbon = bool, whether to show a colored ribbon next to the currently
			hovered dropdown entry. Usually should be enabled for Light theme only.
		ScrollBarPadding = int, the padding which appears on either side of the scrollbar.
		ScrollBarThickness = int, the horizontal width of the scrollbar.

		onSearchRequested(string searchTerm) = function, callback for when the user presses the enter key
			or clicks the search button
		onTextChanged(string text) = function, callback for when the text was changed
		OnItemClicked(item) = function, A callback when the user selects an item in the dropdown.
			Returns the full item from the results array.

	Optional Properties:
		LayoutOrder = num, default to 0, optional layout order for UI layouts
]]
local Plugin = script.Parent.Parent.Parent.Parent.Parent

local Packages = Plugin.Packages
local Roact = require(Packages.Roact)
local Framework = require(Packages.Framework)

local Util = Plugin.Core.Util
local Constants = require(Util.Constants)
local Images = require(Util.Images)
local ContextHelper = require(Util.ContextHelper)
local withTheme = ContextHelper.withTheme
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local TextService = game:GetService("TextService")

local LayoutOrderIterator = Framework.Util.LayoutOrderIterator
local DropdownMenu = Framework.UI.DropdownMenu
local LoadingIndicator = Framework.UI.LoadingIndicator
local PermissionsDirectory = Plugin.Core.Components.AssetConfiguration.Permissions
local CollaboratorSearchItem = require(PermissionsDirectory.CollaboratorSearchItem)

local COLLABORATOR_SEARCH_ITEM_HEIGHT = 50
local THUMBNAIL_SIZE = 32
local SEARCH_BAR_HEIGHT = 40
local SEARCH_BAR_BUTTON_ICON_SIZE = 20
local CLEAR_BUTTON_ICON_SIZE = 24
local TEXT_PADDING = 16
local RIBBON_WIDTH = 5
local VERTICAL_OFFSET = 2
-- in ms
local TEXT_SEARCH_THRESHOLD = 500

local CollaboratorSearchBar = Roact.PureComponent:extend("CollaboratorSearchBar")

local function stripSearchTerm(searchTerm)
	return searchTerm and searchTerm:gsub("\n", " ") or ""
end

function CollaboratorSearchBar:init()
	self.state = {
		text = "",

		isFocused = false,
		isContainerHovered = false,
		isClearButtonHovered = false,

		showDropdown = false,
		dropdownItem = nil,

		lastDelay = {},

		lastResults = {},
		mergedItems = {},
	}

	self.textBoxRef = Roact.createRef()

	self.requestSearch = function()
		self.props.onSearchRequested(self.state.text)
	end

	self.onContainerHovered = function()
		self:setState({
			isContainerHovered = true,
		})
	end

	self.onContainerHoverEnded = function()
		self:setState({
			isContainerHovered = false,
		})
	end

	self.onTextChanged = function(rbx)
		local text = stripSearchTerm(rbx.Text)
		local textBox = self.textBoxRef.current
		if self.state.text ~= text then
			self:setState({
				text = text,
			})
			if self.props.onTextChanged then
				self.props.onTextChanged(text)
			end

			local thisDelay = {}
			self.state.lastDelay = thisDelay
			delay(TEXT_SEARCH_THRESHOLD / 1000, function()
				if thisDelay == self.state.lastDelay and text ~= "" then
					self.requestSearch()
					if not self.state.showDropdown and next(self.state.mergedItems) ~= nil then
						self.showDropdown()
					end
				end
			end)

			local textBound = TextService:GetTextSize(text, textBox.TextSize, textBox.Font, Vector2.new(math.huge, math.huge))
			if textBound.x > textBox.AbsoluteSize.x then
				textBox.TextXAlignment = Enum.TextXAlignment.Right 
			else
				textBox.TextXAlignment = Enum.TextXAlignment.Left
			end
		end
	end

	self.onTextBoxFocused = function(rbx)
		local textBox = self.textBoxRef.current

		self:setState({
			isFocused = true,
		})

		if not self.props.Enabled then
			textBox:ReleaseFocus()
		end

		if next(self.state.mergedItems) ~= nil then
			self.showDropdown()
		end
	end

	self.onTextBoxFocusLost = function(rbx, enterPressed, inputObject)
		self:setState({
			isFocused = false,
			isContainerHovered = false,
		})
	end

	self.onClearButtonHovered = function()
		self:setState({
			isClearButtonHovered = true,
		})
	end

	self.onClearButtonHoverEnded = function()
		self:setState({
			isClearButtonHovered = false,
		})
	end

	self.onClearButtonClicked = function()
		local textBox = self.textBoxRef.current
		self:setState({
			isFocused = true,
		})

		-- Update property and not state so our onTextChanged path and its special behavior is run
		textBox.Text = ""
		textBox:CaptureFocus()
		textBox.TextXAlignment = Enum.TextXAlignment.Left


		-- Stop hovering on the clear button so that when it reappears,
		-- it doesn't start in a hover state
		self.onClearButtonHoverEnded()
	end

	self.onItemClicked = function(item)
		self.props.OnItemClicked(item.Key)
		self.hideDropdown()
	end

	self.showDropdown = function()
		self:setState({
			showDropdown = true,
		})
	end

	self.hideDropdown = function()
		if not self.state.isFocused then
			self:setState({
				showDropdown = false,
				dropdownItem = Roact.None, -- MouseLeave does not fire when the element goes away. We need to manually clear this
			})
		end
	end

	-- A store provided by the consumer arbitrates which results are displayed, but is dependent
	-- on this component to updates those results. This store persists between re-opening Asset Config,
	-- so it will show results from last session unless we tell it the text has changed
	if self.props.onTextChanged then
		self.props.onTextChanged("")
	end
end

-- Merge multi level table into single level for display
function CollaboratorSearchBar:mergeResultsTable(results)
	local mergedTable = {}
	if next(results) == nil then
		if not self.props.LoadingMore and self.state.text ~= "" then
			table.insert(mergedTable, "NoResults")
		end
	else
		local keys = {}
		for key,_ in pairs(results) do table.insert(keys, key) end
		table.sort(keys, function(a,b) return results[a].LayoutOrder < results[b].LayoutOrder end)

		for _,key in ipairs(keys) do
			table.insert(mergedTable, key)
			for _,item in ipairs(results[key]) do
				table.insert(mergedTable, item)
			end
		end
	end

	if self.props.LoadingMore then
		table.insert(mergedTable, "LoadingIndicator")
	end

	return mergedTable
end

function CollaboratorSearchBar:onRenderItem(item, index, activated, theme, searchBarExtents)
	local props = self.props
	local headerHeight = props.HeaderHeight
	local itemHeight = COLLABORATOR_SEARCH_ITEM_HEIGHT
	local noResultsText = props.NoResultsText
	local textPadding = props.TextPadding or TEXT_PADDING

	local searchBarTheme = theme.assetConfig.packagePermissions.searchBar

	if typeof(item) == "string" and (item ~= "LoadingIndicator" and item ~= "NoResults") then
		return Roact.createElement("TextLabel", {
			BackgroundColor3 = searchBarTheme.dropDown.backgroundColor,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Font = Constants.FONT,
			Size = UDim2.new(1, 0, 0, headerHeight),
			Text = item,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			TextSize = 16,
			TextColor3 = searchBarTheme.placeholderText,
		}, {
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, textPadding),
			}),
		})
	elseif item == "NoResults" then
		return Roact.createElement("TextLabel", {
			BackgroundColor3 = searchBarTheme.dropDown.backgroundColor,
			BorderSizePixel = 0,
			Font = Constants.FONT,
			LayoutOrder = index,
			Text = noResultsText,
			TextSize = Constants.FONT_SIZE_TITLE,
			TextColor3 = theme.assetConfig.textColor,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, itemHeight),
		}, {
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, textPadding),
			}),
		})
	elseif item == "LoadingIndicator" then
		return Roact.createElement("Frame", {
			BackgroundColor3 = searchBarTheme.dropDown.backgroundColor,
			BorderSizePixel = 0,
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, itemHeight),
		}, {
			LoadingIndicator = Roact.createElement(LoadingIndicator, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				ZIndex = 3,
			}),
		})
	-- user/group items
	else
		return Roact.createElement(CollaboratorSearchItem, {
			Icon = item.Icon,
			LayoutOrder = index,
			Name = item.Name,
			OnActivated = activated,
			Size = UDim2.new(1, 0, 0, itemHeight),
			TextPadding = textPadding,
		})
	end
end

function CollaboratorSearchBar:render()
	local props = self.props
	local state = self.state
	local theme = props.Stylizer

	local orderIterator = LayoutOrderIterator.new()

	local layoutOrder = props.LayoutOrder or 0

	local text = state.text

	local isFocused = state.isFocused and props.Enabled
	local isContainerHovered = state.isContainerHovered and props.Enabled
	local isClearButtonHovered = state.isClearButtonHovered

	--[[
	By default, TextBoxes let you keep typing infinitely and it will just go out of the bounds
	(unless you set properties like ClipDescendants, TextWrapped)
	Elsewhere, text boxes shift their contents to the left as you're typing past the bounds
	So what you're typing is on the screen

	This is implemented here by:
	- Set ClipsDescendants = true on the container
	- Get the width of the container, subtracting any padding and the width of the button on the right
	- Get the width of the text being rendered (this is calculated in the Roact.Change.Text event)
	- If the text is shorter than the text box size, then:
		- Anchor the text label to the left side of the parent
	- Else
		- Anchor the text label to the right side of the parent
	]]

	local searchBarTheme = theme.assetConfig.packagePermissions.searchBar
	local borderColor
	if isFocused then
		borderColor = searchBarTheme.borderSelected
	elseif isContainerHovered then
		borderColor = searchBarTheme.borderHover
	else
		borderColor = searchBarTheme.border
	end

	local defaultText = props.DefaultText
	local errorText = props.ErrorText
	local noResultsText = props.NoResultsText

	local textBoxOffset = -SEARCH_BAR_HEIGHT * 2

	local showDropdown = state.showDropdown
	local searchBarRef = self.textBoxRef and self.textBoxRef.current
	if searchBarRef then
		searchBarRef = searchBarRef.Parent
	end
	local searchBarExtents
	if searchBarRef then
		local searchBarMin = searchBarRef.AbsolutePosition
		local searchBarSize = searchBarRef.AbsoluteSize
		local searchBarMax = searchBarMin + searchBarSize
		searchBarExtents = Rect.new(searchBarMin.X, searchBarMin.Y, searchBarMax.X, searchBarMax.Y)
	end

	local results = props.Results or {}
	local headerHeight = props.HeaderHeight
	local itemHeight = props.ItemHeight
	local maxItems = props.MaxItems
	local showRibbon = props.ShowRibbon

	local textPadding = props.TextPadding or TEXT_PADDING
	local scrollBarPadding = props.ScrollBarPadding
	local scrollBarThickness = props.ScrollBarThickness
	local maxHeight = maxItems and (maxItems * itemHeight) or nil

	local dropdownItem = state.dropdownItem

	if state.lastResults ~= results then
		state.mergedItems = self:mergeResultsTable(results)
		state.lastResults = results
	end

	return Roact.createElement("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = layoutOrder,
		BackgroundColor3 = theme.inputFields.backgroundColor,
		BorderSizePixel = 0,
	}, {
		UIListLayout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		Background = Roact.createElement("ImageLabel", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Image = Images.ROUNDED_BORDER_IMAGE,
			ImageColor3 = borderColor,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Constants.ROUNDED_FRAME_SLICE,

			[Roact.Event.MouseEnter] = self.onContainerHovered,
			[Roact.Event.MouseMoved] = self.onContainerHovered,
			[Roact.Event.MouseLeave] = self.onContainerHoverEnded,
		}, {
			UIListLayout = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
			}),

			TextBox = Roact.createElement("TextBox", {
				Font = Constants.FONT,
				TextSize = Constants.FONT_SIZE_TITLE,
				TextColor3 = theme.assetConfig.textColor,

				LayoutOrder = orderIterator:getNextOrder(),
				Size = UDim2.new(1, textBoxOffset, 0, SEARCH_BAR_HEIGHT),
				BackgroundTransparency = 1,

				ClearTextOnFocus = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = props.Enabled and text or "",
				TextEditable = props.Enabled,

				PlaceholderText = errorText or defaultText,
				PlaceholderColor3 = errorText and theme.warningColor or searchBarTheme.placeholderText,

				-- Get a reference to the text box so that clicking on the container can call :CaptureFocus()
				[Roact.Ref] = self.textBoxRef,

				[Roact.Change.Text] = self.onTextChanged,
				[Roact.Event.Focused] = self.onTextBoxFocused,
				[Roact.Event.FocusLost] = self.onTextBoxFocusLost,
			} , {
				TextPadding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, textPadding),
				}),

				Dropdown = Roact.createElement(DropdownMenu, {
					Hide = not (showDropdown and searchBarRef),
					Items = self.state.mergedItems,
					OnFocusLost = self.hideDropdown,
					OnItemActivated = self.onItemClicked,
					OnRenderItem = function(item, index, activated)
						return self:onRenderItem(item, index, activated, theme, searchBarExtents)
					end,
					Width = searchBarExtents and searchBarExtents.Width or nil,
				}),
			}),

			ClearButtonFrame = Roact.createElement("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = orderIterator:getNextOrder(),
				Size = UDim2.new(0, SEARCH_BAR_HEIGHT,
					0, SEARCH_BAR_HEIGHT),
			} , {
				ClearButton = Roact.createElement("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, CLEAR_BUTTON_ICON_SIZE, 0, CLEAR_BUTTON_ICON_SIZE),
					BackgroundTransparency = 1,
					Visible = text ~= "",
					Image = isClearButtonHovered and Images.CLEAR_ICON_HOVER or Images.CLEAR_ICON,
					ImageColor3 = searchBarTheme.clearButton.image,

					[Roact.Event.MouseEnter] = self.onClearButtonHovered,
					[Roact.Event.MouseMoved] = self.onClearButtonHovered,
					[Roact.Event.MouseLeave] = self.onClearButtonHoverEnded,
					[Roact.Event.MouseButton1Down] = self.onClearButtonClicked,
				}),
			}),

			ImageFrame = Roact.createElement("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = orderIterator:getNextOrder(),
				Size = UDim2.new(0, SEARCH_BAR_HEIGHT,
					0, SEARCH_BAR_HEIGHT),
			} , {
				Image = Roact.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, SEARCH_BAR_BUTTON_ICON_SIZE,
						0, SEARCH_BAR_BUTTON_ICON_SIZE),
					BackgroundTransparency = 1,
					Image = Images.SEARCH_ICON,
					ImageColor3 = theme.assetConfig.packagePermissions.searchBar.searchIcon,
				}),
			}),
		}),
	})
end

CollaboratorSearchBar = withContext({
	Stylizer = ContextServices.Stylizer,
})(CollaboratorSearchBar)

return CollaboratorSearchBar
