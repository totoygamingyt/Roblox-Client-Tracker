--[[
	This component is responsible for managing the AssetConfiguration page or not.
	This component will listen to StudioService's signal to bring up the assetComfiguration
	page.

	Necesaary Props:
	assetId, number, will be used to request assetConfig data on didMount.
	If nil we will be considering publshing an new asset.

	store = A store object to be used by Rodux.StoreProvider.
	theme = A theme object to be used by a ThemeProvider.
	networkInterface = A networkInterface object to be used by a NetworkProvider.
	localization = A localization object to be used by a LocalizationProvider.
	plugin = A plugin object to be used by a PluginProvider.
]]
local FFlagDebugBuiltInPluginModalsNotBlocking = game:GetFastFlag("DebugBuiltInPluginModalsNotBlocking")

local Plugin = script.Parent.Parent.Parent.Parent

local Packages = Plugin.Packages
local Roact = require(Packages.Roact)

local Components = Plugin.Core.Components
local Dialog = require(Components.PluginWidget.Dialog)
local ScreenSelect = require(Components.AssetConfiguration.ScreenSelect)

local Providers = Plugin.Core.Providers
local ModalProvider = require(Providers.ModalProvider)
local NetworkProvider = require(Providers.NetworkProvider)
local ThemeProvider = require(Providers.ThemeProvider)
local LocalizationProvider = require(Providers.LocalizationProvider)
local getAssetConfigTheme = require(Plugin.Core.Themes.getAssetConfigTheme)

local makeTheme = require(Plugin.Core.Util.makeTheme)

local ContextServices = require(Packages.Framework).ContextServices

local ASSET_CONFIG_WIDTH = 960
local ASSET_CONFIG_HEIGHT = 640
local ASSET_CONFIG_MIN_WIDTH = 800
local ASSET_CONFIG_MIN_HEIGHT = 500

local AssetConfigWrapper = Roact.PureComponent:extend("AssetConfigWrapper")

function AssetConfigWrapper:init(props)
	self.state = {
		popUpGui = nil,
	}

	self.popUpRefFunc = function(ref)
		self.popUpGuiRef = ref
	end


	self.onClose = function(rbx)
		if self.props.onAssetConfigDestroy then
			self.props.onAssetConfigDestroy()
		end
	end
end

function AssetConfigWrapper:didMount()
	self:setState({
		popUpGui = self.popUpGuiRef
	})
end

function AssetConfigWrapper:render()
	local props = self.props
	local state = self.state

	local assetId = props.assetId
	local assetTypeEnum = props.assetTypeEnum

	local theme = props.theme
	local networkInterface = props.networkInterface
	local localization = props.localization
	local plugin = props.plugin

	return Roact.createElement(Dialog, {
		Title = "Asset Configuration",

		Resizable = true,
		MinSize = Vector2.new(ASSET_CONFIG_MIN_WIDTH, ASSET_CONFIG_MIN_HEIGHT),
		Size = Vector2.new(ASSET_CONFIG_WIDTH, ASSET_CONFIG_HEIGHT),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Modal = not FFlagDebugBuiltInPluginModalsNotBlocking,
		InitialEnabled = true,
		plugin = plugin,

		[Roact.Change.Enabled] = self.onClose,
		[Roact.Ref] = self.popUpRefFunc,
		[Roact.Event.AncestryChanged] = self.onAncestryChanged,
	}, {
		ContextServices = state.popUpGui and ContextServices.provide({
			ContextServices.Focus.new(state.popUpGui),
			makeTheme(getAssetConfigTheme()),
		}, {
			ThemeProvider = Roact.createElement(ThemeProvider, {
				theme = theme,
			}, {
				LocalizationProvider = Roact.createElement(LocalizationProvider, {
					localization = localization
				}, {
					NetworkProvider = Roact.createElement(NetworkProvider, {
						networkInterface = networkInterface
					}, {
						ModalProvider = Roact.createElement(ModalProvider, {
							pluginGui = state.popUpGui,
						}, {
							ScreenSelect = Roact.createElement(ScreenSelect, {
								assetId = assetId,
								assetTypeEnum = assetTypeEnum,

								onClose = self.onClose,

								pluginGui = state.popUpGui,
							})
						})
					})
				})
			})
		})
	})
end

return AssetConfigWrapper
