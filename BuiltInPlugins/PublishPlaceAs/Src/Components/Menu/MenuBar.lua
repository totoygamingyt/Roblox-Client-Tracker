--[[
	Menu bar that accepts any number of MenuEntries.

	Props:
		table Entries: A table of entries to include in this MenuBar
		number Selected: Index of Entries that is selected
		function selectionChanged: Callback when the selected menu entry changes
]]

local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)

local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local MenuEntry = require(Plugin.Src.Components.Menu.MenuEntry)

local MenuBar = Roact.PureComponent:extend("MenuBar")

function MenuBar:render()
	local props = self.props
	local theme = props.Stylizer
	local localization = props.Localization

	local selected = props.Selected
	local selectionChanged = props.SelectionChanged
	local entries = props.Entries

	assert(type(entries) == "table", "MenuBar.Entries must be a table")

	local menuEntries = {
		Layout = Roact.createElement("UIListLayout", {
			Padding = UDim.new(0, 1),
		})
	}

	for i, entry in ipairs(entries) do
		table.insert(menuEntries, Roact.createElement(MenuEntry, {
			Title = localization:getText("MenuItem", entry),
			Selected = (selected == i),

			-- TODO (kstephan) 2019/08/01 Change error/warning status depending on Rodux state
			ShowError = false,
			ShowWarning = false,

			OnClicked = function()
				selectionChanged(i)
			end,
		}))
	end

	return Roact.createElement("Frame", {
		Size = UDim2.new(0, theme.MENU_BAR_WIDTH, 1, 0),
		BackgroundColor3 = theme.menuBar.backgroundColor,
		BorderSizePixel = 0,
	}, menuEntries)
end

MenuBar = withContext({
	Stylizer = ContextServices.Stylizer,
	Localization = ContextServices.Localization,
})(MenuBar)

return MenuBar
