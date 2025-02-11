--[[
	This component shows the sales status and price of published assets

	Necessary props:
		assetTypeEnum, Enum.AssetType
		allowedAssetTypesForRelease, table, information about what asset types can be released
		newAssetStatus, string, from AssetConfigConstants.ASSET_STATUS (what the status for the asset will be in the back-end after we save the changes on this widget)
		currentAssetStatus, string, from AssetConfigConstants.ASSET_STATUS (what the current status for the asset is in the back-end)
		price, number
		minPrice, number
		maxPrice, number
		isPriceValid, bool, changes the behavior of the component.

		onStatusChange, function, sales status has changed
		onPriceChange, function, price has changed
]]

local Plugin = script.Parent.Parent.Parent.Parent

local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")

local Packages = Plugin.Packages
local Roact = require(Packages.Roact)
local RoactRodux = require(Packages.RoactRodux)
local Framework = require(Packages.Framework)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local AssetConfiguration = Plugin.Core.Components.AssetConfiguration
local SalesComponent = require(AssetConfiguration.SalesComponent)
local PriceComponent = require(AssetConfiguration.PriceComponent)

local SetFieldError = require(Plugin.Core.Actions.SetFieldError)

local Separator = Framework.UI.Separator
local GetTextSize = Framework.Util.GetTextSize

local Util = Plugin.Core.Util
local Constants = require(Util.Constants)
local ContextHelper = require(Util.ContextHelper)
local LayoutOrderIterator = require(Util.LayoutOrderIterator)
local AssetConfigUtil = require(Util.AssetConfigUtil)
local AssetConfigConstants = require(Util.AssetConfigConstants)

local withLocalization = ContextHelper.withLocalization

local TOTAL_VERTICAL_PADDING = 60

local SalesPage = Roact.PureComponent:extend("SalesPage")

function SalesPage:init()
	self.frameRef = Roact.createRef()
end

function SalesPage:render()
	return withLocalization(function(localization, localizedContent)
		return self:renderContent(nil, localization, localizedContent)
	end)
end

function SalesPage:didMount()
	local isPriceValid = self.props.isPriceValid
	self.props.setFieldError(AssetConfigConstants.FIELD_NAMES.Price, not isPriceValid)
end

function SalesPage:willUpdate(nextProps, nextState)
	local isPriceValid = self.props.isPriceValid
	if isPriceValid ~= nextProps.isPriceValid then
		self.props.setFieldError(AssetConfigConstants.FIELD_NAMES.Price, not isPriceValid)
	end
end

function SalesPage:renderContent(theme, localization, localizedContent)
	theme = self.props.Stylizer

	local props = self.props

	local size = props.size
	local newAssetStatus = props.newAssetStatus
	local currentAssetStatus = props.currentAssetStatus
	local onStatusChange = props.onStatusChange
	local assetTypeEnum = props.assetTypeEnum
	local allowedAssetTypesForRelease = props.allowedAssetTypesForRelease
	local price = props.price
	local minPrice = props.minPrice
	local maxPrice = props.maxPrice
	local feeRate = props.feeRate
	local onPriceChange = props.onPriceChange
	local isPriceValid = props.isPriceValid

	local layoutOrder = props.layoutOrder
	local canChangeSalesStatus = AssetConfigUtil.isReadyForSale(newAssetStatus)
	-- If it's marketplace buyable asset, and if the sales tab are avaialble. You can always toggle it.
	if AssetConfigUtil.isBuyableMarketplaceAsset(assetTypeEnum) then
		canChangeSalesStatus = true
	end

	-- When we are on this page, sales and price default to available.
	-- If the asset is buyable on the marketplace and the user is not whitelisted, we hide the price.
	-- The sales option will only be able to toggle between Free and OffSale.
	local showPrice = allowedAssetTypesForRelease[assetTypeEnum.Name]

	local premiumBenefitsLink
	local premiumBenefitsSize
	if AssetConfigUtil.isCatalogAsset(props.assetTypeEnum) then
		premiumBenefitsLink = string.format(ContentProvider.BaseUrl .. "catalog/configure?id=%d#!/sales", props.assetId)
		premiumBenefitsSize = GetTextSize(localizedContent.Sales.PremiumBenefits, nil, nil, Vector2.new(0, 0))
	end

	local orderIterator = LayoutOrderIterator.new()

	return Roact.createElement("ScrollingFrame", {
		Size = size,

		BackgroundTransparency = 1,
		BorderSizePixel = 0,

		LayoutOrder = layoutOrder,

		[Roact.Ref] = self.frameRef,
	}, {
		Padding = Roact.createElement("UIPadding", {
			PaddingTop = UDim.new(0, TOTAL_VERTICAL_PADDING*0.5),
			PaddingBottom = UDim.new(0, TOTAL_VERTICAL_PADDING*0.5),
			PaddingLeft = UDim.new(0, 30),
			PaddingRight = UDim.new(0, 30),
		}),

		UIListLayout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 32),

			[Roact.Change.AbsoluteContentSize] = function(rbx)
				if self.frameRef.current then
					self.frameRef.current.CanvasSize = UDim2.new(size.X.Scale, size.X.Offset, 0, rbx.AbsoluteContentSize.y + TOTAL_VERTICAL_PADDING)
				end
			end
		}),

		SalesStatus = Roact.createElement(SalesComponent, {
			Title = localizedContent.Sales.Sale,
			AssetTypeEnum = assetTypeEnum,
			NewAssetStatus = newAssetStatus,
			CurrentAssetStatus = currentAssetStatus,
			OnStatusChange = onStatusChange,
			CanChangeSalesStatus = canChangeSalesStatus,

			LayoutOrder = orderIterator:getNextOrder(),
		}),

		Separator1 = Roact.createElement(Separator, {
			LayoutOrder = orderIterator:getNextOrder(),
		}),

		PriceComponent = showPrice and Roact.createElement(PriceComponent, {
			AssetTypeEnum = assetTypeEnum,
			AllowedAssetTypesForRelease = allowedAssetTypesForRelease,
			NewAssetStatus = newAssetStatus,

			Price = price,
			MinPrice = minPrice,
			MaxPrice = maxPrice,
			FeeRate = feeRate,
			IsPriceValid = isPriceValid,

			OnPriceChange = onPriceChange,

			LayoutOrder = orderIterator:getNextOrder(),
		}),

		Separator2 = AssetConfigUtil.isCatalogAsset(props.assetTypeEnum)
			and Roact.createElement(Separator, {
				LayoutOrder = orderIterator:getNextOrder(),
			}) or nil,

		PremiumBenefitsLink = AssetConfigUtil.isCatalogAsset(props.assetTypeEnum)
			and Roact.createElement("TextButton", {
				LayoutOrder = orderIterator:getNextOrder(),
				BackgroundTransparency = 1,
				Font = Constants.FONT,
				Text = localizedContent.Sales.PremiumBenefits,
				Size = UDim2.fromOffset(premiumBenefitsSize.X, premiumBenefitsSize.Y),
				TextColor3 = theme.link,
				TextSize = Constants.FONT_SIZE_MEDIUM,
				TextYAlignment = Enum.TextYAlignment.Center,
				[Roact.Event.Activated] = function()
					GuiService:OpenBrowserWindow(premiumBenefitsLink)
				end,
			}) or nil,
	})
end

local function mapStateToProps(state, props)
	state = state or {}

	local stateToProps = {
		assetId = state.assetId,
		assetTypeEnum = state.assetTypeEnum,
	}

	return stateToProps
end

local function mapDispatchToProps(dispatch)
	return {
		setFieldError = function(fieldName, hasError)
			dispatch(SetFieldError(AssetConfigConstants.SIDE_TABS.Sales, fieldName, hasError))
		end,
	}
end


SalesPage = withContext({
	Stylizer = ContextServices.Stylizer,
})(SalesPage)


return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(SalesPage)
