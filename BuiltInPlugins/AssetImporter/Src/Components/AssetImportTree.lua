local Plugin = script.Parent.Parent.Parent

local Framework = require(Plugin.Packages.Framework)
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Localization = ContextServices.Localization
local Stylizer = ContextServices.Stylizer

local UI = Framework.UI
local Checkbox = UI.Checkbox
local CheckboxTreeView = UI.CheckboxTreeView
local Image = UI.Decoration.Image
local Pane = UI.Pane
local Separator = UI.Separator
local Tooltip = UI.Tooltip

local Util = Framework.Util
local LayoutOrderIterator = Util.LayoutOrderIterator

local TreeViewToolbar = require(Plugin.Src.Components.TreeViewToolbar)

local SetSelectedSettingsItem = require(Plugin.Src.Actions.SetSelectedSettingsItem)
local SetTreeExpansion = require(Plugin.Src.Actions.SetTreeExpansion)
local SetInstanceMap = require(Plugin.Src.Actions.SetInstanceMap)
local UpdateChecked = require(Plugin.Src.Thunks.UpdateChecked)
local UpdatePreviewInstance = require(Plugin.Src.Thunks.UpdatePreviewInstance)
local StatusLevel = require(Plugin.Src.Utility.StatusLevel)
local trimFilename = require(Plugin.Src.Utility.trimFilename)

local getFFlagAssetImportSessionCleanup = require(Plugin.Src.Flags.getFFlagAssetImportSessionCleanup)

local SEPARATOR_WEIGHT = 1
local ICON_DIMENSION = 20

local AssetImportTree = Roact.PureComponent:extend("AssetImportTree")

local function generateChecked(instances)
	local checked = {}

	local function percolateDown(itemList: {ImporterBaseSettings})
		for _, instance in pairs(itemList) do
			checked[instance] = true

			local children = instance:GetChildren()
			if #children > 0 then
				percolateDown(children)
			end
		end
	end

	percolateDown(instances)

	return checked
end

local function generateStatuses(instances: {ImporterBaseSettings})
	local statuses = {}

	local function getInstanceStatuses(settingsInstance)
		local statusTable = settingsInstance:GetStatuses()
		local errorList = statusTable.Errors
		local warningList = statusTable.Warnings

		local subErrors = 0
		local subWarnings = 0

		for _, child in pairs(settingsInstance:GetChildren()) do
			getInstanceStatuses(child)
			subErrors += statuses[child].errorsCount + statuses[child].subErrorsCount
			subWarnings += statuses[child].warningsCount + statuses[child].subWarningsCount
		end

		statuses[settingsInstance] = {
			errorsCount = #errorList,
			warningsCount = #warningList,
			subErrorsCount = subErrors,
			subWarningsCount = subWarnings
		}
	end

	for _, instance in pairs(instances) do
		getInstanceStatuses(instance)
	end

	return statuses
end

local function getStatusImage(status, statusType, expanded, layoutOrderIterator, localization)
	local statusIcon, statusName, statusesCount, subtreeStatusesCount

	if statusType == StatusLevel.Error then
		statusIcon = "rbxasset://textures/StudioSharedUI/alert_error@2x.png"
		statusName = localization:getText("AssetImportTree", "Errors")
		statusesCount = status.errorsCount
		subtreeStatusesCount = status.subErrorsCount
	elseif statusType == StatusLevel.Warning then
		statusIcon = "rbxasset://textures/StudioSharedUI/alert_warning@2x.png"
		statusName = localization:getText("AssetImportTree", "Warnings")
		statusesCount = status.warningsCount
		subtreeStatusesCount = status.subWarningsCount
	end

	local message
	if statusesCount > 0 then
		local containsString = localization:getText("AssetImportTree", "Contains")
		message = string.format(containsString, statusesCount, statusName)
	elseif subtreeStatusesCount > 0 and not expanded then
		local descendantContainsString = localization:getText("AssetImportTree", "Descendants")
		message = string.format(descendantContainsString, subtreeStatusesCount, statusName)
	else
		return nil
	end

	return Roact.createElement(Image, {
		LayoutOrder = layoutOrderIterator:getNextOrder(),
		Style = {
			Image = statusIcon,
		},
		Size = UDim2.new(0, ICON_DIMENSION, 0, ICON_DIMENSION),
	}, {
		Tooltip = Roact.createElement(Tooltip, {
			Text = message
		})
	})
end

-- TODO: Rework ancestry and getChildren for cleaner traversal of instance tree
local function toggleAncestors(item, checkedStates, ancestry, getChildren, updateChecked)
	local function toggleAncestorsRecursive(item)
		local parent = ancestry[item]
		if not parent or updateChecked[item] == nil then
			return
		end

		local allChildrenChecked = true
		local anyChildChecked = false

		for _, child in ipairs(getChildren(parent)) do
			local checked = updateChecked[child]

			if checked == nil then
				checked = checkedStates[child] or false
			end

			allChildrenChecked = allChildrenChecked and (checked ~= Checkbox.Indeterminate and checked)
			anyChildChecked = anyChildChecked or (checked == Checkbox.Indeterminate or checked)
		end

		if allChildrenChecked then
			if checkedStates[parent] == true then
				return
			elseif (parent:IsA("ImporterGroupSettings") or parent:IsA("ImporterRootSettings")) then
				updateChecked[parent] = true
			end
		elseif not anyChildChecked then
			if checkedStates[parent] == false then
				return
			elseif (parent:IsA("ImporterGroupSettings") or parent:IsA("ImporterRootSettings")) then
				updateChecked[parent] = false
			end
		end

		toggleAncestorsRecursive(parent)
	end
	toggleAncestorsRecursive(item)
end

function AssetImportTree:init()
	self.getChildren = function(item)
		return item:GetChildren()
	end

	self.getContents = function(item)
		if item.ClassName == "ImporterRootSettings" then
			return trimFilename(self.props.FileName), nil
		else
			return item.ImportName, nil
		end
	end

	self.setChecked = function(checked)
		local props = self.props
		props.SetChecked(checked)

		if getFFlagAssetImportSessionCleanup() then
			if props.SelectedSettingsItem then
				local instance = props.AssetImportSession:GetInstance(props.SelectedSettingsItem.Id)
				props.UpdatePreviewInstance(instance)
			end
		else
			local instanceMap = props.AssetImportSession:GetCurrentImportMap()
			props.SetInstanceMap(instanceMap)
		end
	end

	self.SelectItem = function(newSelection)
		local item = next(newSelection)
		self.props.SetSelectedSettingsItem(item)
		if getFFlagAssetImportSessionCleanup() then
			if item then
				self.props.UpdatePreviewInstance(self.props.AssetImportSession:GetInstance(item.Id))
			else
				self.props.UpdatePreviewInstance(nil)
			end
		end
	end

	self.statuses = {}

	self.afterItem = function(props)
		local item = props.Item
		local status = self.statuses[item]

		if status then
			local layoutOrderIterator = LayoutOrderIterator.new()

			local statusesImages = getStatusImage(status, StatusLevel.Error, props.Expanded, layoutOrderIterator, self.props.Localization)
			statusesImages = statusesImages or getStatusImage(status, StatusLevel.Warning, props.Expanded, layoutOrderIterator, self.props.Localization)

			local width = statusesImages and ICON_DIMENSION or 0

			return Roact.createElement(Pane, {
				Size = UDim2.new(0, width, 0, ICON_DIMENSION),
				LayoutOrder = props.LayoutOrder,
				Layout = Enum.FillDirection.Horizontal,
			}, {
				Statuses = statusesImages,
			})
		else
			return nil
		end
	end
end

function AssetImportTree:render()
	local props = self.props

	local style = props.Stylizer

	local toolbarHeight = style.Sizes.ToolbarHeight + SEPARATOR_WEIGHT

	local checked = props.Checked or generateChecked(props.Instances)

	local layoutOrderIterator = LayoutOrderIterator.new()

	self.statuses = generateStatuses(props.Instances)

	return Roact.createElement(Pane, {
		Layout = Enum.FillDirection.Vertical,
	}, {
		Toolbar = Roact.createElement(TreeViewToolbar, {
			Expansion = props.Expansion,
			LayoutOrder = layoutOrderIterator:getNextOrder(),
			OnExpansionChange = props.SetExpansion,
			Size = UDim2.new(1, 0, 0, toolbarHeight),
		}),

		Separator = Roact.createElement(Separator, {
			DominantAxis = Enum.DominantAxis.Width,
			LayoutOrder = layoutOrderIterator:getNextOrder(),
		}),

		TreeView = Roact.createElement(CheckboxTreeView, {
			RootItems = props.Instances or {},
			Selection = props.SelectedSettingsItem and {
				[props.SelectedSettingsItem] = true,
			} or {},
			Expansion = props.Expansion,
			Checked = checked,
			LayoutOrder = layoutOrderIterator:getNextOrder(),
			Size = UDim2.new(1, 0, 1, -toolbarHeight),
			OnSelectionChange = self.SelectItem,
			OnExpansionChange = props.SetExpansion,
			OnCheck = self.setChecked,
			GetChildren = self.getChildren,
			GetContents = self.getContents,
			ExpandableRoot = false,
			AfterItem = self.afterItem,
			ToggleAncestors = toggleAncestors,
			ToggleDescendants = CheckboxTreeView.DownPropagators.toggleAllChildren,
		})
	})
end

AssetImportTree = withContext({
	Localization = Localization,
	Stylizer = Stylizer,
})(AssetImportTree)

local function mapStateToProps(state)
	return {
		AssetImportSession = state.assetImportSession,
		SelectedSettingsItem = state.selectedSettingsItem,
		Expansion = state.settingsExpansion or {},
		Checked = state.settingsChecked or {},
	}
end

local function mapDispatchToProps(dispatch)
	return {
		SetSelectedSettingsItem = function(item)
			dispatch(SetSelectedSettingsItem(item))
		end,
		SetExpansion = function(expansion)
			dispatch(SetTreeExpansion(expansion))
		end,
		SetChecked = function(checked)
			dispatch(UpdateChecked(checked))
		end,
		SetInstanceMap = function(instanceMap)
			dispatch(SetInstanceMap(instanceMap))
		end,
		UpdatePreviewInstance = function(instance)
			dispatch(UpdatePreviewInstance(instance))
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(AssetImportTree)
