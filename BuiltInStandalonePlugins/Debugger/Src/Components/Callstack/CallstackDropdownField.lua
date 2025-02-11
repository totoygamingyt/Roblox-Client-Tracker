local PluginFolder = script.Parent.Parent.Parent.Parent
local Roact = require(PluginFolder.Packages.Roact)
local RoactRodux = require(PluginFolder.Packages.RoactRodux)
local Framework = require(PluginFolder.Packages.Framework)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Localization = ContextServices.Localization
local Analytics = ContextServices.Analytics
local AnalyticsEventNames = require(PluginFolder.Src.Resources.AnalyticsEventNames)

local Stylizer = Framework.Style.Stylizer

local DropdownField = require(PluginFolder.Src.Components.Common.DropdownField)

local Actions = PluginFolder.Src.Actions
local ColumnFilterChange = require(Actions.Callstack.ColumnFilterChange)

local Models = PluginFolder.Src.Models
local Columns = require(Models.Callstack.ColumnEnum)

local flatListToString = require(PluginFolder.Src.Util.flatListToString)

local CallstackDropdownField = Roact.PureComponent:extend("CallstackDropdownField")

local function hasValue(tab, val)
	for _, v in pairs(tab) do
		if v == val then
			return true
		end
	end
	return false
end

function CallstackDropdownField:init()
	self.keyColumns = {
		[1] = "AllColumns",
		[2] = Columns.Frame,
		[3] = Columns.Source,
		[4] = Columns.Function,
		[5] = Columns.Line,
	}

	self.clickCallback = function(enabledColumns)
		self.props.onColumnFilterChange(enabledColumns)
		self.props.Analytics:report(AnalyticsEventNames.CallstackColumnsEdited, flatListToString(enabledColumns))
	end
end

function CallstackDropdownField:render()
	local props = self.props
	local style = props.Stylizer
	local localization = props.Localization

	return Roact.createElement(DropdownField, {
		KeyTexts = self.keyColumns,
		ClickCallback = self.clickCallback,
		KeyStates = props.ColumnStates,
		Localization = localization,
		Style = style,
		Widget = "Callstack",
		DropdownWidth = 200,
		HamburgerMenu = true,
		ShouldShowDropdownIcon = false,
	})
end

CallstackDropdownField = withContext({
	Analytics = Analytics,
	Localization = Localization,
	Stylizer = Stylizer,
})(CallstackDropdownField)

CallstackDropdownField = RoactRodux.connect(function(state, props)
	local enabledColumns = state.Callstack.listOfEnabledColumns
	local newColumnStates = {}
	newColumnStates[2] = hasValue(enabledColumns, Columns.Frame)
	newColumnStates[3] = hasValue(enabledColumns, Columns.Source)
	newColumnStates[4] = hasValue(enabledColumns, Columns.Function)
	newColumnStates[5] = hasValue(enabledColumns, Columns.Line)
	return {
		ColumnStates = newColumnStates,
	}
end, function(dispatch)
	return {
		onColumnFilterChange = function(enabledColumns)
			return dispatch(ColumnFilterChange(enabledColumns))
		end,
	}
end)(CallstackDropdownField)

return CallstackDropdownField
