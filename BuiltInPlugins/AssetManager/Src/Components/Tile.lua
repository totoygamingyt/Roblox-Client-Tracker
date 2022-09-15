local Plugin = script.Parent.Parent.Parent

local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)

local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Util = Framework.Util
local StyleModifier = Util.StyleModifier
local GetTextSize = Util.GetTextSize

local UI = Framework.UI
local DragSource = UI.DragSource
local Pane = UI.Pane
local Tooltip = UI.Tooltip

local PopUpButton = require(Plugin.Src.Components.PopUpButton)
local enableAudioImport = require(Plugin.Src.Util.AssetManagerUtilities).enableAudioImport
local enableVideoImport = require(Plugin.Src.Util.AssetManagerUtilities).enableVideoImport

local SetEditingAssets = require(Plugin.Src.Actions.SetEditingAssets)

local GetAssetPreviewData = require(Plugin.Src.Thunks.GetAssetPreviewData)
local OnAssetDoubleClick = require(Plugin.Src.Thunks.OnAssetDoubleClick)
local OnAssetRightClick = require(Plugin.Src.Thunks.OnAssetRightClick)
local OnAssetSingleClick = require(Plugin.Src.Thunks.OnAssetSingleClick)

local ReviewStatus = require(Plugin.Src.Util.ReviewStatus)
local ModerationUtil = require(Plugin.Src.Util.ModerationUtil)

local FFlagAssetManagerEnableModelAssets = game:GetFastFlag("AssetManagerEnableModelAssets")

local ModernIcons = require(Plugin.Src.Util.ModernIcons)
local FFlagHighDpiIcons = game:GetFastFlag("SVGLuaIcons") and not game:GetService("StudioHighDpiService"):IsNotHighDPIAwareBuild()

local AssetManagerService = game:GetService("AssetManagerService")
local ContentProvider = game:GetService("ContentProvider")

local Tile = Roact.PureComponent:extend("Tile")

local function stripText(text)
	local newText = string.gsub(text, "%s+", "")
	newText = string.gsub(newText, "\n", "")
	newText = string.gsub(newText, "\t", "")
	return newText
end

local ICON_SIZE = 150

function Tile:init()
	self.state = {
		-- StyleModifier must be upper case first character because of how Theme in ContextServices uses it.
		StyleModifier = nil,
		assetFetchStatus = nil,
		assetPreviewButtonHovered = false,
		editText = "",
	}

	self.editing = false

	self.textBoxRef = Roact.createRef()

	self.onMouseEnter = function()
		local props = self.props
		if not props.Enabled then
			return
		end
		if self.state.StyleModifier == nil then
			self:setState({
				StyleModifier = StyleModifier.Hover,
			})
		end
		self:setState({
			assetPreviewButtonHovered = true,
		})
		local assetData = self.props.AssetData
		local isFolder = assetData.ClassName == "Folder"
		local isPlace = assetData.assetType == Enum.AssetType.Place
		if not isFolder and not isPlace then
			local assetPreviewData = self.props.AssetsTable.assetPreviewData[assetData.id]
			-- asset preview data is not loaded or stored
			if type(assetPreviewData) ~= "table" then
				self.props.dispatchGetAssetPreviewData(self.props.API:get(), {assetData.id})
			end
		end
	end

	self.onMouseLeave = function()
		local props = self.props
		if not props.Enabled then
			return
		end
		if self.state.StyleModifier == StyleModifier.Hover then
			self:setState({
				StyleModifier = Roact.None,
			})
		end
		self:setState({
			assetPreviewButtonHovered = false,
		})
	end

	self.onClick = function(input, clickCount)
		local props = self.props
		if not props.Enabled then
			return
		end
		local assetData = props.AssetData
		if clickCount == 0 then
			props.dispatchOnAssetSingleClick(input, assetData)
		elseif clickCount == 1 then
			props.dispatchOnAssetDoubleClick(props.Analytics, assetData)
		end
	end

	self.onDragBegan = function(input)
		local props = self.props
		local assetData = props.AssetData
		props.OnAssetDrag(assetData)
	end

	self.onRightClick = function()
		local props = self.props
		if not props.Enabled then
			return
		end
		local assetData = props.AssetData
		local isFolder = assetData.ClassName == "Folder"
		if isFolder then
			if not props.SelectedAssets[assetData.Screen.LayoutOrder] then
				props.dispatchOnAssetSingleClick(nil, assetData)
			end
		else
			if not props.SelectedAssets[assetData.key] then
				props.dispatchOnAssetSingleClick(nil, assetData)
			end
		end
		props.dispatchOnAssetRightClick(props)
	end

	self.openAssetPreview = function()
		self:setState({
			assetPreviewButtonHovered = false,
		})
		local assetData = self.props.AssetData
		self.props.OnOpenAssetPreview(assetData)
	end

	self.onTextChanged = function(rbx)
		local text = rbx.Text
		if text ~= self.props.AssetData.name then
			self:setState({
				editText = text,
			})
		end
	end

	self.onTextBoxFocusLost = function(rbx, enterPressed, inputObject)
		local props = self.props
		local assetData = props.AssetData
		local newName = self.state.editText
		if utf8.len(newName) ~= 0 and utf8.len(stripText(newName)) ~= 0 then
			if assetData.assetType == Enum.AssetType.Place then
				AssetManagerService:RenamePlace(assetData.id, newName)
			elseif
				assetData.assetType == Enum.AssetType.Image
				or assetData.assetType == Enum.AssetType.MeshPart
				or assetData.assetType == Enum.AssetType.Lua
				or (enableAudioImport() and assetData.assetType == Enum.AssetType.Audio)
				or (enableVideoImport() and assetData.assetType == Enum.AssetType.Video)
			then
				local prefix
				-- Setting asset type to same value as Enum.AssetType since it cannot be passed into function
				if assetData.assetType == Enum.AssetType.Image then
					prefix = "Images/"
				elseif assetData.assetType == Enum.AssetType.MeshPart then
					prefix = "Meshes/"
				elseif assetData.assetType == Enum.AssetType.Lua then
					prefix = "Scripts/"
				elseif (enableAudioImport() and assetData.assetType == Enum.AssetType.Audio) then
					prefix = "Audio/"
				elseif (enableVideoImport() and assetData.assetType == Enum.AssetType.Video) then
					prefix = "Video/"
				elseif FFlagAssetManagerEnableModelAssets and assetData.assetType == Enum.AssetType.Model then
					prefix = "Models/"
				end
				AssetManagerService:RenameAlias(assetData.assetType.Value, assetData.id, prefix .. assetData.name, prefix .. newName)
			end
			props.AssetData.name = newName
		end
		props.dispatchSetEditingAssets({})
		self.editing = false
		-- force re-render to show updated name
		self:setState({
			editText = props.AssetData.name,
		})
	end

	local props = self.props
	local assetData = props.AssetData

	local isFolder = assetData.ClassName == "Folder"
	local assetId = assetData.id
	if not isFolder then
		if assetData.assetType == Enum.AssetType.Place then
			self.thumbnailUrl = string.format("rbxthumb://type=AutoGeneratedAsset&id=%i&w=%i&h=%i", assetId, ICON_SIZE, ICON_SIZE)
		else
			self.thumbnailUrl = string.format("rbxthumb://type=Asset&id=%i&w=%i&h=%i", assetId, ICON_SIZE, ICON_SIZE)
		end
		spawn(function()
			local asset = { self.thumbnailUrl }
			local function setStatus(contentId, status)
				self:setState({
					assetFetchStatus = status
				})
			end
			ContentProvider:PreloadAsync(asset, setStatus)
		end)
	end
end

function Tile:didMount()
	self:setState({
		editText = self.props.AssetData.name
	})
end

function Tile:didUpdate(lastProps, lastState)
	local props = self.props
	local assetData = props.AssetData
	local isEditingAsset = props.EditingAssets[assetData.id]
	if isEditingAsset then
		if self.textBoxRef and self.textBoxRef.current and not self.editing then
			local textBox = self.textBoxRef.current
			textBox:CaptureFocus()
			textBox.SelectionStart = 1
			textBox.CursorPosition = #textBox.Text + 1
			self.editing = true
		end
	end
end

function Tile:render()
	local props = self.props
	local pluginStyle = props.Stylizer

	local localization = props.Localization

	local enabled = props.Enabled

	local size = pluginStyle.Size

	local assetData = props.AssetData

	local backgroundColor = pluginStyle.BackgroundColor
	local backgroundTransparency = pluginStyle.BackgroundTransparency
	local borderSizePixel = pluginStyle.BorderSizePixel

	local textColor = pluginStyle.Text.Color
	local textFont = pluginStyle.Font
	local textSize = pluginStyle.Text.Size
	local textBGTransparency = pluginStyle.Text.BackgroundTransparency
	local textTruncate = pluginStyle.Text.TextTruncate
	local textXAlignment = pluginStyle.Text.XAlignment
	local textYAlignment = pluginStyle.Text.YAlignment

	local textFrameSize = pluginStyle.Text.Frame.Size
	local textFramePos = pluginStyle.Text.Frame.Position

	local editText = self.state.editText
	local isEditingAsset = props.EditingAssets[assetData.id]
	local editTextWrapped = pluginStyle.EditText.TextWrapped
	local editTextClearOnFocus = pluginStyle.EditText.ClearTextOnFocus
	local editTextXAlignment = pluginStyle.Text.XAlignment

	local editTextFrameBackgroundColor = pluginStyle.EditText.Frame.BackgroundColor
	local editTextFrameBorderColor = pluginStyle.EditText.Frame.BorderColor

	local editTextSize = GetTextSize(editText, textSize, textFont, Vector2.new(pluginStyle.Size.X.Offset, math.huge))
	local editTextPadding
	if editTextSize.X < pluginStyle.Size.X.Offset then
		editTextPadding = pluginStyle.EditText.TextPadding
	else
		editTextPadding = 0
	end

	local name = assetData.name
	local displayName = assetData.name
	local nameSize = GetTextSize(assetData.name, textSize, textFont,
		Vector2.new(textFrameSize.X.Offset, math.huge))
	if nameSize.Y > textFrameSize.Y.Offset then
		-- using hardcoded values for now since tile size is constant
		displayName = string.sub(assetData.name, 1, 12) .. "..." ..
			string.sub(assetData.name, string.len(assetData.name) - 5)
	end

	local isFolder = assetData.ClassName == "Folder"
	local isPlace = assetData.assetType == Enum.AssetType.Place

	local image
	if isFolder and FFlagHighDpiIcons then
		image = ModernIcons.getIconForCurrentTheme(assetData.Screen.Image)
	elseif isFolder then
		image = assetData.Screen.Image
	else
		image = self.state.assetFetchStatus == Enum.AssetFetchStatus.Success and self.thumbnailUrl
			or pluginStyle.Image.PlaceHolder
	end

	local imageFrameSize = pluginStyle.Image.FrameSize
	local imageSize = pluginStyle.Image.ImageSize
	local imagePos = pluginStyle.Image.Position
	local imageFolderPos = pluginStyle.Image.FolderPosition
	local imageFolderAnchorPos = pluginStyle.Image.FolderAnchorPosition
	local imageBGColor = pluginStyle.Image.BackgroundColor

	local createAssetPreviewButton = not isFolder and not isPlace
	local showAssetPreviewButton = self.state.assetPreviewButtonHovered
	local magnifyingGlass = pluginStyle.AssetPreview.Image
	if FFlagHighDpiIcons then
		magnifyingGlass = ModernIcons.getIconForCurrentTheme(ModernIcons.IconEnums.Zoom)
	end
	local assetPreviewButtonOffset = pluginStyle.AssetPreview.Button.Offset

	local isRootPlace = assetData.isRootPlace
	local rootPlaceImageSize = pluginStyle.Image.StartingPlace.Size
	local rootPlaceIcon = pluginStyle.Image.StartingPlace.Icon
	if FFlagHighDpiIcons then
		rootPlaceIcon = ModernIcons.getIconForCurrentTheme(ModernIcons.IconEnums.Spawn)
	end
	local rootPlaceIconXOffset = pluginStyle.Image.StartingPlace.XOffset
	local rootPlaceIconYOffset = pluginStyle.Image.StartingPlace.YOffset

	local layoutOrder = props.LayoutOrder

	local thumbnailContainer = isFolder and "Frame" or "ImageLabel"
	local thumbnailContainerProps = {
		Size = imageFrameSize,
		Position = imagePos,

		BackgroundTransparency = 0,
		BackgroundColor3 = imageBGColor,
		BorderSizePixel = 0,
	}

	if not isFolder then
		thumbnailContainerProps.Image = image
	end

	local displayModerationStatus
	local moderationImage
	local moderationStatusImageSize
	local moderationStatusIconXOffset
	local moderationStatusIconYOffset
	local moderationTooltip
	if not isFolder then
		local moderationData = props.ModerationData
		if moderationData and next(moderationData) ~= nil then
			-- fetch moderation data then set icon/textbox size
			local isPending = moderationData.reviewStatus == ReviewStatus.Pending
			local isApproved = ModerationUtil.isApprovedAsset(moderationData)
			displayModerationStatus = isPending or not isApproved
			if displayModerationStatus then
				if isPending then
					moderationImage = pluginStyle.Image.ModerationStatus.Pending
				elseif not isApproved then
					moderationImage = pluginStyle.Image.ModerationStatus.Rejected
				end
				moderationStatusImageSize = pluginStyle.Image.ModerationStatus.Size
				moderationStatusIconXOffset = pluginStyle.Image.ModerationStatus.XOffset
				moderationStatusIconYOffset = pluginStyle.Image.ModerationStatus.YOffset
				moderationTooltip = ModerationUtil.getModerationTooltip(localization, moderationData)
			end
		end
	end

	return Roact.createElement(DragSource, {
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = layoutOrder,
		OnClick = self.onClick,
		OnRightClick = self.onRightClick,
		OnDragBegan = self.onDragBegan,
	}, {
		Button = Roact.createElement(Pane, {
			BackgroundColor = backgroundColor,
			Size = size,
			Transparency = backgroundTransparency,

			[Roact.Event.MouseEnter] = self.onMouseEnter,
			[Roact.Event.MouseLeave] = self.onMouseLeave,
		}, {
			ThumbnailContainer = Roact.createElement(thumbnailContainer, thumbnailContainerProps, {
				AssetPreviewButton = createAssetPreviewButton and Roact.createElement(PopUpButton, {
					Position = UDim2.new(1, -assetPreviewButtonOffset, 0, assetPreviewButtonOffset),

					Image = magnifyingGlass,
					ShowIcon = showAssetPreviewButton,
					OnClick = self.openAssetPreview,
					OnRightClick = self.onRightClick,
				}),

				RootPlaceImage = isRootPlace and Roact.createElement("ImageLabel", {
					Size = UDim2.new(0, rootPlaceImageSize, 0, rootPlaceImageSize),
					Position = UDim2.new(0, rootPlaceIconXOffset, 0, rootPlaceIconYOffset),

					Image = rootPlaceIcon,
					BackgroundTransparency = 1,
				}),

				ModerationStatusImage = displayModerationStatus and Roact.createElement("ImageLabel", {
					Size = UDim2.new(0, moderationStatusImageSize, 0, moderationStatusImageSize),
					Position = UDim2.new(0, moderationStatusIconXOffset, 0, moderationStatusIconYOffset),

					Image = moderationImage,
					BackgroundTransparency = 1,
				}, {
					ModerationTooltip = Roact.createElement(Tooltip, {
						Text = moderationTooltip,
						Enabled = enabled,
					}),
				}),

				FolderImage = isFolder and Roact.createElement("ImageLabel", {
					Size = imageSize,
					Image = image,
					Position = imageFolderPos,
					AnchorPoint = imageFolderAnchorPos,

					BackgroundTransparency = 1,
				})
			}),

			Name = not isEditingAsset and Roact.createElement("TextLabel", {
				Size = textFrameSize,
				Position = textFramePos,

				Text = displayName,
				TextColor3 = textColor,
				Font = textFont,
				TextSize = textSize,

				BackgroundTransparency = textBGTransparency,
				TextXAlignment = textXAlignment,
				TextYAlignment = textYAlignment,
				TextTruncate = textTruncate,
				TextWrapped = true,
			}),

			RenameTextBox = isEditingAsset and Roact.createElement("TextBox",{
				Size = UDim2.new(0, editTextSize.X + editTextPadding,
					0, editTextSize.Y),
				Position = textFramePos,

				BackgroundColor3 = editTextFrameBackgroundColor,
				BorderColor3 = editTextFrameBorderColor,

				Text = editText,
				TextColor3 = textColor,
				Font = textFont,
				TextSize = textSize,

				TextXAlignment = editTextXAlignment,
				TextTruncate = Enum.TextTruncate.None,
				TextWrapped = editTextWrapped,
				ClearTextOnFocus = editTextClearOnFocus,

				[Roact.Ref] = self.textBoxRef,

				[Roact.Change.Text] = self.onTextChanged,
				[Roact.Event.FocusLost] = self.onTextBoxFocusLost,
			}),

			NameTooltip = Roact.createElement(Tooltip, {
				Text = name,
				Enabled = enabled,
			}),

			DEPRECATED_Tooltip = enabled and Roact.createElement(Tooltip, {
				Text = name,
				Enabled = true,
			}),
		})
	})
end

Tile = withContext({
	Analytics = ContextServices.Analytics,
	API = ContextServices.API,
	Localization = ContextServices.Localization,
	Mouse = ContextServices.Mouse,
	Plugin = ContextServices.Plugin,
	Stylizer = ContextServices.Stylizer,
})(Tile)

local function mapStateToProps(state, props)
	local assetManagerReducer = state.AssetManagerReducer
	return {
		AssetsTable = assetManagerReducer.assetsTable,
		EditingAssets = assetManagerReducer.editingAssets,
		SelectedAssets = assetManagerReducer.selectedAssets,
	}
end

local function mapDispatchToProps(dispatch)
	return {
		dispatchGetAssetPreviewData = function(apiImpl, assetIds)
			dispatch(GetAssetPreviewData(apiImpl, assetIds))
		end,
		dispatchOnAssetDoubleClick = function(analytics, assetData)
			dispatch(OnAssetDoubleClick(analytics, assetData))
		end,
		dispatchOnAssetRightClick = function(props)
			dispatch(OnAssetRightClick(props))
		end,
		dispatchOnAssetSingleClick = function(obj, assetData)
			dispatch(OnAssetSingleClick(obj, assetData))
		end,
		dispatchSetEditingAssets = function(editingAssets)
			dispatch(SetEditingAssets(editingAssets))
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(Tile)