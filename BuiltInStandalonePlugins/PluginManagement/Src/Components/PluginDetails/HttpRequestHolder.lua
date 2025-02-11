
local Plugin = script.Parent.Parent.Parent.Parent
local TextService = game:GetService("TextService")

local PermissionsService = game:GetService("PermissionsService")

local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local FitFrame = require(Plugin.Packages.FitFrame)
local ContextServices = require(Plugin.Packages.Framework).ContextServices
local withContext = ContextServices.withContext
local UI = require(Plugin.Packages.Framework).UI

local SetPluginPermission = require(Plugin.Src.Thunks.SetPluginPermission)
local FluidFitTextLabel = require(Plugin.Src.Components.FluidFitTextLabel)

local PluginAPI2 = require(Plugin.Src.ContextServices.PluginAPI2)

local FitFrameVertical = FitFrame.FitFrameVertical
local Constants = require(Plugin.Src.Util.Constants)
local Checkbox = UI.Checkbox

local truncateMiddleText = require(Plugin.Src.Util.truncateMiddleText)

local HttpRequestHolder = Roact.Component:extend("HttpRequestHolder")

local CHECKBOX_PADDING = 8
local CHECKBOX_WIDTH = 16
local CONTENT_PADDING = 20

HttpRequestHolder.defaultProps = {
	httpPermissions = {},
}

function HttpRequestHolder:init()
	self.frameRef = Roact.createRef()

	self.state = {
		frameWidth = 0,
	}

	self.onCheckboxActivated = function(permission)
		local apiImpl = self.props.API:get()
		local assetId = self.props.assetId
		return self.props.setPluginPermission(apiImpl, assetId, permission)
	end

	self.resizeFrame = function()
		local frameRef = self.frameRef.current
		if not frameRef then
			return
		end
		if self.state.frameWidth ~= frameRef.AbsoluteSize.X then
			self:setState({
				frameWidth = frameRef.AbsoluteSize.X,
			})
		end
	end

	self.getTruncatedText = function(urlText, theme)
		local result = ""
		local titleSize = TextService:GetTextSize(
			urlText,
			16, -- textSize
			theme.Font,
			Vector2.new()
		)

		local maxFrameWidth = self.state.frameWidth - CHECKBOX_WIDTH - Constants.SCROLLBAR_WIDTH_ADJUSTMENT
		if (maxFrameWidth > 0) and (titleSize.X > maxFrameWidth) then
			result = truncateMiddleText(urlText, 16, theme.Font, maxFrameWidth)
		else
			result = urlText
		end
		return result
	end
end

function HttpRequestHolder:didMount()
	self.resizeFrame()
end

function HttpRequestHolder:renderCheckbox(theme, index, permission)
	local fullUrlText = permission.data and permission.data.domain or ""
	local urlText = self.getTruncatedText(fullUrlText, theme)
	local isChecked = permission.allowed

	return Roact.createElement(Checkbox, {
		Checked = isChecked,
		LayoutOrder = index,
		OnClick = function()
			self.onCheckboxActivated(permission)
		end,
		Text = urlText,
	})
end

function HttpRequestHolder:render()
	local localization = self.props.Localization
	local httpPermissions = self.props.httpPermissions
	local layoutOrder = self.props.LayoutOrder

	local theme = self.props.Stylizer

	local checkboxItems = {}
	for index, permission in pairs(httpPermissions) do
		table.insert(checkboxItems, self:renderCheckbox(theme, index, permission))
	end

	return Roact.createElement(FitFrameVertical, {
		BackgroundTransparency = 1,
		contentPadding = UDim.new(0, CONTENT_PADDING),
		LayoutOrder = layoutOrder,
		width = UDim.new(1, 0),
		[Roact.Ref] = self.frameRef,
		[Roact.Change.AbsoluteSize] = self.resizeFrame,
	}, {
		Checkboxes = Roact.createElement(FitFrameVertical, {
			BackgroundTransparency = 1,
			contentPadding = UDim.new(0, CHECKBOX_PADDING),
			LayoutOrder = 0,
			width = UDim.new(1, 0)
		}, checkboxItems ),

		InfoText = Roact.createElement(FluidFitTextLabel, {
			BackgroundTransparency = 1,
			Font = theme.Font,
			LayoutOrder = 1,
			TextSize = 16,
			Text = localization:getText("Details", "HttpRequestInfo"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = theme.InfoTextColor,
		}),
	})
end


HttpRequestHolder = withContext({
	API = PluginAPI2,
	Localization = ContextServices.Localization,
	Stylizer = ContextServices.Stylizer,
})(HttpRequestHolder)


local function mapDispatchToProps(dispatch)
	return {
		setPluginPermission = function(apiImpl, assetId, permission)
			dispatch(SetPluginPermission(PermissionsService, apiImpl, assetId, permission))
		end,
	}
end

return RoactRodux.connect(nil, mapDispatchToProps)(HttpRequestHolder)
