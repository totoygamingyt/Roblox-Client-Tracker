--[[
	Shows the Preview Panel grid

	Required Props:
		table Localization: A Localization ContextItem, which is provided via withContext.
		table API: Roblox API from Devframework for calling end points
		table PrebuiltAssetsInfo: from the rodux state, info about each prebuilt asset (name/description etc)
		callback GetPrebuiltAssetsInfo: function provided via dispatch to get name/description etc info for prebuilt assets
		callback FinishSelectingFromExplorer: function to call when we have finished adding an item as a new tile
		callback UpdatePreviewAssetsSelected: function provided via dispatch to add/remove an asset from the selected assets
		string SelectedTab: the preview tab selection (this is an entry from PreviewConstants.TABS_KEYS)
		table SelectedAssets: which assets are selected in the grid, which is provided via mapStateToProps.
		callback StartSelectingFromExplorer: function to start selecting from explorer, which mapDispatchToProps provides
		Plugin Plugin: A Plugin ContextItem, which is provided via withContext.
		string SelectorMode: enum to decide which selector should be on, which is provided via mapStateToProps
		table UserAddedAssets: the table of assets added by the user
		callback UpdateUserAddedAssets: function called when user added assets are changed

	Optional Props:
		Stylizer Stylizer: A Stylizer ContextItem, which is provided via withContext.
		number layoutOrder: render order of component in layout
		number zIndex: the z sorting order of the component
		Instance EditingItem: layered clothes item that is editing now, which is provided via mapStateToProps.
		table EditingItemContext: An EditingItemContext, which is provided via withContext.
		table AssetServiceWrapper: An AssetServiceWrapper context item, provided via withContext.
]]
local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Cryo = require(Plugin.Packages.Cryo)
local AvatarToolsShared = require(Plugin.Packages.AvatarToolsShared)

local Components = AvatarToolsShared.Components
local ConfirmCancelDialog = Components.ConfirmCancelDialog
local ConfirmDialog = Components.ConfirmDialog
local ScrollableGrid = Components.ScrollableGrid
local AssetThumbnailTiles = Components.AssetThumbnailTiles
local InstanceSelectorTile = Components.InstanceSelectorTile

local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local Util = Framework.Util
local LayoutOrderIterator = Util.LayoutOrderIterator
local Typecheck = Util.Typecheck
local deepCopy = Util.deepCopy

local UpdatePreviewAssetsSelected = require(Plugin.Src.Thunks.UpdatePreviewAssetsSelected)
local GetPrebuiltAssetsInfo = require(Plugin.Src.Thunks.GetPrebuiltAssetsInfo)
local StartSelectingFromExplorer = require(Plugin.Src.Thunks.StartSelectingFromExplorer)
local FinishSelectingFromExplorer = require(Plugin.Src.Thunks.FinishSelectingFromExplorer)

local EditingItemContext = require(Plugin.Src.Context.EditingItemContext)
local AssetServiceWrapper = require(Plugin.Src.Context.AssetServiceWrapper)

local Constants = require(Plugin.Src.Util.Constants)
local PreviewConstantsInterface = require(Plugin.Src.Util.PreviewConstantsInterface)
local ShowDialog = require(Plugin.Src.Util.ShowDialog)

local Grid = Roact.PureComponent:extend("Grid")
Typecheck.wrap(Grid, script)

local function getSelectedIds(self)
	local props = self.props
	local selectedAssets = props.SelectedAssets
	local selectedTab = props.SelectedTab

	local selectedAssetsforTab = selectedAssets[selectedTab] or {}

	return Cryo.List.toSet(Cryo.Dictionary.keys(selectedAssetsforTab))
end

function Grid:init()
	self.gridRef = Roact.createRef()

	self.onClickAddNewInstance = function()
		local props = self.props
		local selectedTab = props.SelectedTab
		local localization = props.Localization
		local tabInfo = PreviewConstantsInterface.getTabInfo(selectedTab)
		if tabInfo then
			local localizedText = localization:getText(Constants.LOCALIZATION_KEYS.Preview, tabInfo.PanelBlockerLocalizationKey)
			props.StartSelectingFromExplorer(Constants.SELECTOR_MODE.Preview, localizedText)
		end
	end

	self.isSelectedInstanceValid = function(item)
		local props = self.props

		local selectedTab = props.SelectedTab
		local editingItem = props.EditingItemContext:getItem()

		local tabInfo = PreviewConstantsInterface.getTabInfo(selectedTab)
		if not tabInfo.IsSelectedInstanceValid(item) then
			return false
		end

		local isPreviewModel = item:FindFirstAncestor("LayeredClothingEditorPreview") ~= nil
		local isEditingItem = item == editingItem
		local isMannequin = item == editingItem.Parent

		return not (isPreviewModel or isEditingItem or isMannequin)
	end

	self.onInstanceSelectorValidSelection = function(instance)
		local props = self.props
		ShowDialog(props.Plugin, props.Localization, ConfirmCancelDialog,{
			Text = self.props.Localization:getText(Constants.LOCALIZATION_KEYS.Preview, "ConfirmAddTile", {
				itemName = instance.Name,
			}),
			OnConfirm = function()
				local props = self.props
				local selectedTab = props.SelectedTab

				self.props.FinishSelectingFromExplorer(instance)
				props.UpdateUserAddedAssets(selectedTab, instance:Clone())
			end,
		})
	end

	self.onInstanceSelectorInvalidSelection = function(instance)
		local props = self.props
		local localization = props.Localization
		local selectedTab = props.SelectedTab
		local tabInfo = PreviewConstantsInterface.getTabInfo(selectedTab)

		if tabInfo then
			ShowDialog(props.Plugin, props.Localization, ConfirmDialog,{
				Text = localization:getText(Constants.LOCALIZATION_KEYS.Preview, tabInfo.InvalidAddLocalizationKey),
			})
		end
	end
end

local function getUserAddedAssets(self, selectedTab)
	local props = self.props
	local userAddedAssets = props.UserAddedAssets

	return userAddedAssets and userAddedAssets[selectedTab] or {}
end

local function getUserAddedAssetIds(self, selectedTab)
	local userAddedAssetsForTab = getUserAddedAssets(self, selectedTab)

	local ids = {}

	for _, asset in ipairs(userAddedAssetsForTab) do
		table.insert(ids, asset.uniqueId)
	end

	return ids
end

local function combineAssetInfo(self, selectedTab)
	local props = self.props

	local prebuiltAssetsInfo = deepCopy(props.PrebuiltAssetsInfo)
	local userAddedAssetsForTab = getUserAddedAssets(self, selectedTab)
	local tabInfo = PreviewConstantsInterface.getTabInfo(selectedTab)
	if tabInfo then
		local guids = getUserAddedAssetIds(self, selectedTab)
		local assetIds = tabInfo.AssetIds or {}
		local bundleIds = tabInfo.BundleIds or {}

		for _, id in pairs(assetIds) do
			local info = prebuiltAssetsInfo[id]
			if info then
				info.ThumbnailType = "Asset"
			end
		end

		for _, id in pairs(bundleIds) do
			local info = prebuiltAssetsInfo[id]
			if info then
				info.ThumbnailType = "BundleThumbnail"
			end
		end

		local userAddedAssetsById = {}
		for _, asset in ipairs(userAddedAssetsForTab) do
			userAddedAssetsById[asset.uniqueId] = {
				Name = asset.instance.Name,
				ThumbnailType = "",
			}
		end

		local combinedAssetInfo = Cryo.Dictionary.join(prebuiltAssetsInfo, userAddedAssetsById)
		local combinedAssetIds = Cryo.List.join(guids, assetIds, bundleIds)

		return combinedAssetIds, combinedAssetInfo
	end
end

function Grid:render()
	local props = self.props
	local size = props.size
	local layoutOrder = props.layoutOrder
	local theme = props.Stylizer
	local selectedTab = props.SelectedTab

	local orderIterator = LayoutOrderIterator.new()

	local children = {}
	local tabInfo = PreviewConstantsInterface.getTabInfo(selectedTab)
	if tabInfo then
		children = Cryo.Dictionary.join(children, {
			AddNewTile = Roact.createElement(InstanceSelectorTile, {
				Image = theme.AddNewImage,
				ImageSize = theme.SmallImageSize,
				LayoutOrder = orderIterator:getNextOrder(),
				IsSelectedInstanceValid = self.isSelectedInstanceValid,
				OnClickAddNewInstance = self.onClickAddNewInstance,
				OnInstanceSelectorValidSelection = self.onInstanceSelectorValidSelection,
				OnInstanceSelectorInvalidSelection = self.onInstanceSelectorInvalidSelection
			})
		})

		local ids, info = combineAssetInfo(self, selectedTab)
		children = Cryo.Dictionary.join(children, AssetThumbnailTiles({
			AssetIds = ids,
			AssetsInfo = info,
			LayoutOrder = orderIterator:getNextOrder(),
			SelectedTiles = getSelectedIds(self),
			DefaultThumbnail = theme.DefaultTileImages[selectedTab],
			OnThumbnailClick = function(id, selected)
				self.props.UpdatePreviewAssetsSelected(id, not selected)
			end,
		}))
	end

	return Roact.createElement(ScrollableGrid, {
		Size = size,
		CellSize = theme.TileSize,
		LayoutOrder = layoutOrder,
	}, children)
end

function Grid:didMount()
	local props = self.props
	local API = props.API

	local assetService = self.props.AssetServiceWrapper:get()

	local arrayOfAssetIds = PreviewConstantsInterface.getAllAssetIds()
	local arrayOfBundleIds = PreviewConstantsInterface.getAllBundleIds()
	self.props.GetPrebuiltAssetsInfo(API, assetService, arrayOfAssetIds, arrayOfBundleIds)
end


Grid = withContext({
	Stylizer = ContextServices.Stylizer,
	Localization = ContextServices.Localization,
	API = ContextServices.API,
	Plugin = ContextServices.Plugin,
	EditingItemContext = EditingItemContext,
	AssetServiceWrapper = AssetServiceWrapper,
})(Grid)

local function mapStateToProps(state, props)
	local previewAssets = state.previewAssets
	local previewStatus = state.previewStatus
	local selectItem = state.selectItem

	return {
		PrebuiltAssetsInfo = previewAssets.prebuiltAssetsInfo,
		SelectedTab = previewStatus.selectedTab,
		SelectedAssets = previewStatus.selectedAssets,
		SelectorMode = selectItem.selectorMode,
		EditingItem = selectItem.editingItem,
	}
end

local function mapDispatchToProps(dispatch)
	return {
		StartSelectingFromExplorer = function(mode, message)
			dispatch(StartSelectingFromExplorer(mode, message))
		end,
		GetPrebuiltAssetsInfo = function(robloxApi, assetService, arrayOfAssetIds, arrayOfBundleIds)
			dispatch(GetPrebuiltAssetsInfo(robloxApi, assetService, arrayOfAssetIds, arrayOfBundleIds))
		end,
		UpdatePreviewAssetsSelected = function(id, addAsset)
			dispatch(UpdatePreviewAssetsSelected(id, addAsset))
		end,
		FinishSelectingFromExplorer = function(item)
			dispatch(FinishSelectingFromExplorer())
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(Grid)