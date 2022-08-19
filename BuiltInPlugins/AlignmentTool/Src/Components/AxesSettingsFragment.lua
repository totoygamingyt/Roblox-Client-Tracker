--[[
	Fragment containing alignment space and axes settings.

	Required Props:
		string AlignmentSpace: The space to align in, either "World" or "Local".
		table EnabledAxes: A map of string ("X", "Y", "Z") to boolean.
		callback OnAlignmentSpaceChanged: Called when the alignment space changes.
		callback OnEnabledAxesChanged: Called when an axis is enabled or disabled.
]]

local Plugin = script.Parent.Parent.Parent

local Dash = require(Plugin.Packages.Dash)
local FitFrameOnAxis = require(Plugin.Packages.FitFrame).FitFrameOnAxis
local Roact = require(Plugin.Packages.Roact)

local Framework = require(Plugin.Packages.Framework)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local UI = Framework.UI
local Checkbox = UI.Checkbox
local RadioButton = UI.RadioButton

local Util = Framework.Util
local LayoutOrderIterator = Util.LayoutOrderIterator

local AlignmentSpace = require(Plugin.Src.Utility.AlignmentSpace)

local join = Dash.join

local AxesSettingsFragment = Roact.PureComponent:extend("AxesSettingsFragment")

function AxesSettingsFragment:init(initialProps)
	assert(type(initialProps.AlignmentSpace) == "string", "Missing required property AlignmentSpace.")
	assert(type(initialProps.EnabledAxes) == "table", "Missing required property EnabledAxes.")
	assert(type(initialProps.OnAlignmentSpaceChanged) == "function", "Missing required property OnAlignmentSpaceChanged.")
	assert(type(initialProps.OnEnabledAxesChanged) == "function", "Missing required property OnEnabledAxesChanged.")

	self.setAlignmentSpace = function(alignmentSpace)
		local props = self.props
		if props.OnAlignmentSpaceChanged then
			props.OnAlignmentSpaceChanged(alignmentSpace)
		end
	end

	self.toggleAxis = function(axisId)
		local props = self.props
		if props.OnEnabledAxesChanged then
			local enabledAxes = join(props.EnabledAxes, {
				[axisId] = not props.EnabledAxes[axisId],
			})
			props.OnEnabledAxesChanged(enabledAxes)
		end
	end
end

function AxesSettingsFragment:render()
	local props = self.props

	local enabledAxes = props.EnabledAxes
	local localization = props.Localization
	local theme = props.Stylizer

	local layoutOrderIterator = LayoutOrderIterator.new()

	local axesCheckboxComponents = {}

	local axisIds = {"X", "Y", "Z"}
	for _, axisId in ipairs(axisIds) do
		local isSelected = enabledAxes and enabledAxes[axisId] or false
		local text = localization:getText("AxesSettingsFragment", axisId)

		axesCheckboxComponents[axisId] = Roact.createElement(Checkbox, {
			Key = axisId,
			Checked = isSelected,
			Disabled = false,
			LayoutOrder = layoutOrderIterator:getNextOrder(),
			Text = text,
			OnClick = self.toggleAxis,
		})
	end

	local function renderRadioButton(key, layoutOrder)
		return Roact.createElement(RadioButton, {
			Disabled = false,
			Key = key,
			LayoutOrder = layoutOrder,
			Selected = (props.AlignmentSpace == key),
			Text = localization:getText("AxesSettingsFragment", key),
			OnClick = self.setAlignmentSpace,
		})
	end

	return Roact.createFragment({
		AlignmentSpaceButtons = Roact.createElement(FitFrameOnAxis, {
			axis = FitFrameOnAxis.Axis.Both,
			contentPadding = theme.SectionContentPadding,
			BackgroundTransparency = 1,
			FillDirection = Enum.FillDirection.Horizontal,
			LayoutOrder = 1,
		}, {
			WorldSpaceButton = renderRadioButton(AlignmentSpace.World, 1),
			LocalSpaceButton = renderRadioButton(AlignmentSpace.Local, 2),
		}),

		AxisCheckboxes = Roact.createElement(FitFrameOnAxis, {
			axis = FitFrameOnAxis.Axis.Both,
			contentPadding = theme.SectionContentPadding,
			BackgroundTransparency = 1,
			FillDirection = Enum.FillDirection.Horizontal,
			LayoutOrder = 1,
		}, axesCheckboxComponents),
	})
end

AxesSettingsFragment = withContext({
	Localization = ContextServices.Localization,
	Stylizer = ContextServices.Stylizer,
})(AxesSettingsFragment)

return AxesSettingsFragment
