--[[
	AssetUpload - Displays a loading bar before moving onto AssetUploadResult screen

	Necessary Props:
		Size UDim2, the size of the window
		onClose callback, called when the user presses the "cancel" button
]]
local Plugin = script.Parent.Parent.Parent.Parent

local Packages = Plugin.Packages
local Roact = require(Packages.Roact)
local RoactRodux = require(Packages.RoactRodux)
local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local Util = Plugin.Src.Util
local Constants = require(Util.Constants)

local Actions = Plugin.Src.Actions
local SetCurrentScreen = require(Actions.SetCurrentScreen)

local Components = Plugin.Src.Components
local LoadingBar = require(Components.ConvertToPackageWindow.LoadingBar)
local AssetThumbnailPreview = require(Components.ConvertToPackageWindow.AssetThumbnailPreview)

local PREVIEW_PADDING = 48
local PREVIEW_SIZE = 150
local PREVIEW_TITLE_PADDING = 12
local PREVIEW_TITLE_HEIGHT = 24

local LOADING_BAR_WIDTH = 400
local LOADING_BAR_HEIGHT = 6
local LOADING_BAR_Y_POS = 314

local LOADING_TIME = 0.5
local LOADING_PERCENT = 0.92

local AssetUpload = Roact.PureComponent:extend("AssetUpload")

function AssetUpload:init(props)
	self.state = {
		isLoading = true
	}
end

function AssetUpload:render()
	local props = self.props
	local localization = props.Localization
	local style = props.Stylizer
	local assetName = props.assetName

	return Roact.createElement("Frame", {
		BackgroundColor3 = style.typeValidation.background,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Size = props.Size,
	}, {
		ModelPreview = Roact.createElement(AssetThumbnailPreview, {
			titleHeight = PREVIEW_TITLE_HEIGHT,
			titlePadding = PREVIEW_TITLE_PADDING,
			title = assetName,
			Position = UDim2.new(0.5, -PREVIEW_SIZE/2, 0, PREVIEW_PADDING),
			Size = UDim2.new(
				0, PREVIEW_SIZE,
				0, PREVIEW_SIZE + PREVIEW_TITLE_PADDING + PREVIEW_TITLE_HEIGHT
			),
		}),

		LoadingBar = Roact.createElement(LoadingBar, {
			loadingText = localization:getText("Action", "Converting"),
			loadingTime = LOADING_TIME,
			holdPercent = LOADING_PERCENT,
			Size = UDim2.new(0, LOADING_BAR_WIDTH, 0, LOADING_BAR_HEIGHT),
			Position = UDim2.new(0.5, -LOADING_BAR_WIDTH/2, 0, LOADING_BAR_Y_POS),
			onFinish = props.uploadSucceeded ~= nil and props.onNext or nil,
		}),
	})
end

AssetUpload = withContext({
	Localization = ContextServices.Localization,
	Stylizer = ContextServices.Stylizer,
})(AssetUpload)

local function mapStateToProps(state, props)
	state = state or {}

	return {
		uploadSucceeded = state.AssetConfigReducer.uploadSucceeded,
		assetId = state.AssetConfigReducer.assetId,
		assetName = state.AssetConfigReducer.assetName
	}
end

local function mapDispatchToProps(dispatch)
	return {
		onNext = function()
			dispatch(SetCurrentScreen(Constants.SCREENS.UPLOAD_ASSET_RESULT))
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(AssetUpload)