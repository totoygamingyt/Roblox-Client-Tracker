--[[
	A container that sets up full assets functionality. It sets up asset insertion, AssetPreview, and messageBoxes.

	Required Props:
		callback TryOpenAssetConfig: invoke assetConfig page with an assetId.

	Optional Props:
		int LayoutOrder
		UDim2 Position
		function renderTopContent: function that returns a roact element which is the content located above the infinite grid.
		UDim2 Size
]]
local FFlagToolboxGetItemsDetailsUsesSingleApi = game:GetFastFlag("ToolboxGetItemsDetailsUsesSingleApi")
local FFlagToolboxAssetCategorization = game:GetFastFlag("ToolboxAssetCategorization")

local Plugin = script.Parent.Parent.Parent

local Packages = Plugin.Packages
local Roact = require(Packages.Roact)
local RoactRodux = require(Packages.RoactRodux)

local Util = Plugin.Core.Util
local ContextGetter = require(Util.ContextGetter)
local getStartupAssetId = require(Util.getStartupAssetId)

local Category = require(Plugin.Core.Types.Category)

local getNetwork = ContextGetter.getNetwork

local AssetGrid = require(Plugin.Core.Components.AssetGrid)
local PermissionsConstants = require(Plugin.Core.Components.AssetConfiguration.Permissions.PermissionsConstants)
local AssetLogicWrapper = require(Plugin.Core.Components.AssetLogicWrapper)

local GetAssetPreviewDataForStartup = require(Plugin.Core.Thunks.GetAssetPreviewDataForStartup)

local Framework = require(Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Settings = require(Plugin.Core.ContextServices.Settings)

local NextPageRequest = require(Plugin.Core.Networking.Requests.NextPageRequest)
local PostAssetCheckPermissions = require(Plugin.Core.Networking.Requests.PostAssetCheckPermissions)

type _ExternalProps = {
	LayoutOrder : number?,
	Position : number?,
	RenderTopContent : (() -> any)?,
	Size : UDim2?,
}

type _InternalProps = {
	-- Props from AssetLogicWrapper
	CanInsertAsset : (() -> boolean)?,
	ParentAbsolutePosition : Vector2,
	ParentSize : Vector2,
	TryInsert : (
		(
			assetData : any,
			assetWasDragged : boolean,
			insertionMethod : string
		) -> any
	),
	TryOpenAssetConfig : (
		(
			assetId : number?,
			flowType : string,
			instances : any,
			assetTypeEnum : Enum.AssetType
		) -> any
	),
	-- mapStateToProps
	assetIds : any,
	categoryName : string,
	currentUserPackagePermissions : any,
	idToAssetMap : any,
	-- mapDispatchToProps
	dispatchPostAssetCheckPermissions : (
		(
			networkInterface: any,
			assetIds: { number }
		) -> any
	),
	getAssetPreviewDataForStartup : (
		(
			assetId: number,
			tryInsert: any,
			localization: any,
			api: any
		) -> any
	),
	nextPage : (
		(
			networkInterface: any,
			settings: any
		) -> any
	),
}

export type AssetGridContainerProps = _ExternalProps & _InternalProps

local AssetGridContainer = Roact.PureComponent:extend("AssetGridContainer")

AssetGridContainer.defaultProps = {
	Size = UDim2.new(1, 0, 1, 0),
}

function AssetGridContainer:init(props)
	self.requestNextPage = function()
		local networkInterface = getNetwork(self)
		local settings = self.props.Settings:get("Plugin")
		self.props.nextPage(networkInterface, settings)
	end
end

function AssetGridContainer:didMount()
	local assetIdStr = getStartupAssetId()
	local assetId = tonumber(assetIdStr)

	if assetId then
		local props = self.props
		if FFlagToolboxGetItemsDetailsUsesSingleApi then
			props.getAssetPreviewDataForStartup(assetId, props.TryInsert, props.Localization, getNetwork(self))
		else
			props.getAssetPreviewDataForStartup(assetId, props.TryInsert, props.Localization, props.API:get())
		end
	end
end

function AssetGridContainer:render()
	local props : AssetGridContainerProps = self.props

	local assetIds = props.assetIds
	local layoutOrder = props.LayoutOrder
	local position = props.Position
	local renderTopContent = props.RenderTopContent
	local size = props.Size
	local parentAbsolutePosition = props.ParentAbsolutePosition
	local parentSize = props.ParentSize

	-- Props from AssetLogicWrapper
	local canInsertAsset = props.CanInsertAsset
	local tryInsert = props.TryInsert
	local tryOpenAssetConfig = props.TryOpenAssetConfig

	-- TODO: Move to AssetFetcher?
	local isPackages = Category.categoryIsPackage(props.categoryName)
	if isPackages and #assetIds ~= 0 then
		local assetIdList = {}
		local index = 1
		while index < PermissionsConstants.MaxPackageAssetIdsForHighestPermissionsRequest and assetIds[index] ~= nil do
			local assetId = assetIds[index]
			if not self.props.currentUserPackagePermissions[assetId] then
				table.insert(assetIdList, assetId)
			end
			index = index + 1
		end

		if #assetIdList ~= 0 then
			self.props.dispatchPostAssetCheckPermissions(getNetwork(self), assetIdList)
		end
	end

	return Roact.createElement(AssetGrid, {
		AssetIds = assetIds,
		AssetMap = if FFlagToolboxAssetCategorization then props.idToAssetMap else nil,
		LayoutOrder = layoutOrder,
		Position = position,
		RenderTopContent = renderTopContent,
		RequestNextPage = self.requestNextPage,
		Size = size,

		-- Props from AssetLogicWrapper
		CanInsertAsset = canInsertAsset,
		ParentAbsolutePosition = parentAbsolutePosition,
		ParentSize = parentSize,
		TryInsert = tryInsert,
		TryOpenAssetConfig = tryOpenAssetConfig,
	})
end

AssetGridContainer = withContext({
	API = if FFlagToolboxGetItemsDetailsUsesSingleApi then nil else ContextServices.API,
	Localization = ContextServices.Localization,
	Settings = Settings,
})(AssetGridContainer)

local function mapStateToProps(state, props)
	state = state or {}
	local assets = state.assets or {}
	local pageInfo = state.pageInfo or {}
	local categoryName = pageInfo.categoryName or Category.DEFAULT.name

	return {
		assetIds = assets.idsToRender or {},
		categoryName = categoryName,
		currentUserPackagePermissions = state.packages.permissionsTable or {},
		idToAssetMap = if FFlagToolboxAssetCategorization then assets.idToAssetMap else nil,
	}
end

local function mapDispatchToProps(dispatch)
	return {
		dispatchPostAssetCheckPermissions = function(networkInterface, assetIds)
			dispatch(PostAssetCheckPermissions(networkInterface, assetIds))
		end,
		getAssetPreviewDataForStartup = function(assetId, tryInsert, localization, api)
			-- TODO when removing FFlagToolboxGetItemsDetailsUsesSingleApi: rename api to networkInterface
			dispatch(GetAssetPreviewDataForStartup(assetId, tryInsert, localization, api))
		end,
		nextPage = function(networkInterface, settings)
			dispatch(NextPageRequest(networkInterface, settings))
		end,
	}
end

AssetGridContainer = AssetLogicWrapper(AssetGridContainer)

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(AssetGridContainer)
