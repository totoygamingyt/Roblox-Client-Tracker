local Plugin = script.Parent.Parent.Parent

local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Framework = require(Plugin.Packages.Framework)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Localization = ContextServices.Localization
local Stylizer = Framework.Style.Stylizer

local Util = Framework.Util
local StyleModifier = Util.StyleModifier

local UI = Framework.UI
local Pane = UI.Pane
local Separator = UI.Separator

local StudioUI = Framework.StudioUI
local StyledDialog = StudioUI.StyledDialog

local AssetImporterUI = require(Plugin.Src.Components.AssetImporterUI)

local MeshImportDialog = Roact.PureComponent:extend("MeshImportDialog")

function MeshImportDialog:init()
	self.onButtonPressed = function(key)
		if key == "Cancel" then
			self.props.OnClose(self.props.AssetImportSession)
		elseif key == "Import" then
			local props = self.props
			local importEnabled = props.SettingsCheckedCount ~= 0 and not props.ErrorNodeChecked
			if importEnabled then
				self.props.OnImport(self.props.AssetImportSession)
			end
		end
	end
end

function MeshImportDialog:render()
	local props = self.props
	local localization = props.Localization

	local dialogWidth = 800
	local dialogHeight = 650

	local importEnabled = props.SettingsCheckedCount ~= 0 and not props.ErrorNodeChecked

	return Roact.createElement(StyledDialog, {
		Enabled = true,
		MinContentSize = Vector2.new(dialogWidth, dialogHeight),
		Modal = true,
		Resizable = true,
		Title = props.Title,
		Buttons = {
			{ Key = "Cancel", Text = localization:getText("Plugin", "Cancel") },
			{ Key = "Import", Text = localization:getText("Plugin", "Import"), Style = "RoundPrimary",
				StyleModifier = not importEnabled and StyleModifier.Disabled or nil },
		},
		OnClose = function() props.OnClose(props.AssetImportSession) end,
		OnButtonPressed = self.onButtonPressed,
		Style = "FullBleed",
	}, {
		Content = Roact.createElement(Pane, {
			Layout = Enum.FillDirection.Vertical,
		}, {
			AssetImporterUI = Roact.createElement(AssetImporterUI, {
				LayoutOrder = 1,
			}),
			Separator = Roact.createElement(Separator, {
				DominantAxis = Enum.DominantAxis.Width,
				LayoutOrder = 2,
			}),
		})
	})
end

MeshImportDialog = withContext({
	Localization = Localization,
	Stylizer = Stylizer,
})(MeshImportDialog)

local function mapStateToProps(state)
	return {
		AssetSettings = state.assetSettings,
		AssetImportSession = state.assetImportSession,
		SettingsCheckedCount = state.settingsCheckedCount,
		ErrorNodeChecked = state.errorNodeChecked,
	}
end

return RoactRodux.connect(mapStateToProps, nil)(MeshImportDialog)
