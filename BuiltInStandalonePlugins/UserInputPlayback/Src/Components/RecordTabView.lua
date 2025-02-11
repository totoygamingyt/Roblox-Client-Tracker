--[[
	RecordTabView: Contains a FilterSettingsUIGroup, DeviceEmulationInfoUIGroup, and a record button
]]

local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices

local UI = Framework.UI
local Button = UI.Button
local Pane = UI.Pane
local Decoration = UI.Decoration
local TextLabel = Decoration.TextLabel
local HoverArea = UI.HoverArea

local Util = Framework.Util
local StyleModifier = Util.StyleModifier

local FilterSettingsUIGroup = require(Plugin.Src.Components.FilterSettingsUIGroup)
local DeviceEmulationInfoUIGroup = require(Plugin.Src.Components.DeviceEmulationInfoUIGroup)
local ChooseRecordingNamePopUp = require(Plugin.Src.Components.ChooseRecordingNamePopUp)
local Enums = require(Plugin.Src.Util.Enums)
local DMBridge = require(Plugin.Src.Util.DMBridge)

local SetScreenSize = require(Plugin.Src.Actions.RecordTab.SetScreenSize)
local SetEmulationDeviceId = require(Plugin.Src.Actions.RecordTab.SetEmulationDeviceId)
local SetEmulationDeviceOrientation = require(Plugin.Src.Actions.RecordTab.SetEmulationDeviceOrientation)
local SetPluginState = require(Plugin.Src.Actions.Common.SetPluginState)

local RecordTabView = Roact.PureComponent:extend("TabView")

function RecordTabView:init()
	self.state = {
		SaveRecordingDialogVisible = false,
		SaveRecordingDialogMessageLocalizationKey = nil,
		SaveRecordingDialogMessageLocalizationArgs = nil,
	}

	self.onRecordingButtonClicked = function()
		local pluginState = self.props.PluginState
		if pluginState == Enums.PluginState.Default then
			if DMBridge.getIsPlayMode() then
				-- Immediately start recording
				DMBridge.onStartRecordingButtonClicked()
			else
				self.props.SetPluginState(Enums.PluginState.ShouldStartRecording)
			end

		elseif pluginState == Enums.PluginState.Recording then
			DMBridge.onStopRecordingButtonClicked()
		
		elseif pluginState == Enums.PluginState.ShouldStartRecording then
			self.props.SetPluginState(Enums.PluginState.Default)
		end
	end

	self.setSaveRecordingDialogVisible = function(messageKey: string, args:{[string]: string})
		self:setState({
			SaveRecordingDialogVisible = true,
			SaveRecordingDialogMessageLocalizationKey = messageKey,
			SaveRecordingDialogMessageLocalizationArgs = args,
		})
	end

	self.onSaveRecordingDialogCancel = function()
		self:setState({
			SaveRecordingDialogVisible = false,
		})
		DMBridge.onSaveRecordingDialogCancel()
	end

	self.onSaveRecordingDialogSave = function(input:string)
		self:setState({
			SaveRecordingDialogVisible = false,
		})
		DMBridge.onSaveRecordingDialogSave(input)
	end
		
end

function RecordTabView:didMount()
	local actionsDict: DMBridge.RecordTabActionsType = {
		SetEmulationDeviceId = self.props.SetEmulationDeviceId,
		SetEmulationDeviceOrientation = self.props.SetEmulationDeviceOrientation,
		SetCurrentScreenSize = self.props.SetCurrentScreenSize,
		SetSaveRecordingDialogVisible = self.setSaveRecordingDialogVisible,
	}
	DMBridge.connectRecordTabEventListenersWithActions(actionsDict)
	DMBridge.onRecordTabShown()
end

function RecordTabView:willUnmount()
	DMBridge.disconnectRecordTabEventListeners()
	DMBridge.onRecordTabHidden()
	self.props.SetPluginState(Enums.PluginState.Default)
end

function RecordTabView:render()
	local props = self.props
	local style = props.Stylizer
	local localization = self.props.Localization
	local state = self.state

	local statusMessage, recordButtonText, recordButtonStyleModifier
	local isUIDisabled
	if props.PluginState == Enums.PluginState.Recording then
		statusMessage = localization:getText("RecordTabView", "StatusMessageRecording")
		recordButtonText = localization:getText("RecordTabView", "RecordButtonStopRecording")
		recordButtonStyleModifier = StyleModifier.Pressed
		isUIDisabled = true
	elseif props.PluginState == Enums.PluginState.ShouldStartRecording then
		statusMessage = localization:getText("RecordTabView", "StatusMessageShouldRecordOnGamePlayStart")
		recordButtonText = localization:getText("RecordTabView", "RecordButtonReadyToRecord")
		recordButtonStyleModifier = StyleModifier.Selected
		isUIDisabled = false
	elseif props.PluginState == Enums.PluginState.Default then
		statusMessage = localization:getText("RecordTabView", "StatusMessageNotRecording")
		recordButtonText = localization:getText("RecordTabView", "RecordButtonRecord")
		recordButtonStyleModifier = nil
		isUIDisabled = false
	elseif props.PluginState == Enums.PluginState.Disabled then
		statusMessage = localization:getText("RecordTabView", "StatusMessageDisabled")
		recordButtonText = localization:getText("RecordTabView", "RecordButtonRecord")
		recordButtonStyleModifier = StyleModifier.Disabled
		isUIDisabled = true
	end

	return Roact.createElement(Pane, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Padding = style.PaddingPx,
		Layout = Enum.FillDirection.Vertical,
		Spacing = UDim.new(0, style.PaddingPx),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}, {
		FilterSettings = Roact.createElement(FilterSettingsUIGroup, {
			LayoutOrder = 1,
			Disabled = isUIDisabled,
			RoduxStoreContext = "recordTabFilter",
		}),

		DeviceEmulationInfoGroup = Roact.createElement(DeviceEmulationInfoUIGroup, {
			LayoutOrder = 2,
		}),
		
		RecordingButtonContainer = Roact.createElement(Pane, {
			LayoutOrder = 3,
			Style = "CornerBox",
			Size = UDim2.fromOffset(style.UIGroupWidthPx, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Layout = Enum.FillDirection.Vertical,
			Spacing = UDim.new(0, style.PaddingPx),
			Padding = style.PaddingPx,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}, {
			Button = Roact.createElement(Button, {
				Size = style.PrimaryButtonSize,
				LayoutOrder = 1,
				Style = "RoundPrimaryRecordButton",
				StyleModifier = recordButtonStyleModifier,
				Text = recordButtonText,
				OnClick = self.onRecordingButtonClicked,
			}, {
				Roact.createElement(HoverArea, {Cursor = "PointingHand"}),
			}),

			StatusTextLabel = Roact.createElement(TextLabel, {
				Text = statusMessage,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
				Style = "StatusTextLabel",
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
		}),

		ChooseRecordingNamePopUp = state.SaveRecordingDialogVisible and Roact.createElement(ChooseRecordingNamePopUp, {
			DefaultInputValue = localization:getText("RecordTabView", "DefaultRecordingName"),
			OnSaveButtonPressed = self.onSaveRecordingDialogSave,
			OnCancelButtonPressed = self.onSaveRecordingDialogCancel,
			MessageLocalizationKey = state.SaveRecordingDialogMessageLocalizationKey,
			MessageLocalizationArgs = state.SaveRecordingDialogMessageLocalizationArgs,
		})
	})
end

RecordTabView = ContextServices.withContext({
	Plugin = ContextServices.Plugin,
	Stylizer = ContextServices.Stylizer,
	Localization = ContextServices.Localization,
})(RecordTabView)

local function mapStateToProps(state, props)
	return {
		PluginState = state.common.pluginState,
	}
end

local function mapDispatchToProps(dispatch)
	return {
		SetCurrentScreenSize = function(value)
			dispatch(SetScreenSize(value))
		end,
		SetEmulationDeviceId = function(value)
			dispatch(SetEmulationDeviceId(value))
		end,
		SetEmulationDeviceOrientation = function(value)
			dispatch(SetEmulationDeviceOrientation(value))
		end,
		SetPluginState = function(value)
			dispatch(SetPluginState(value))
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(RecordTabView)
