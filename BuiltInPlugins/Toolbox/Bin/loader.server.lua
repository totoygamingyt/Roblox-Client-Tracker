require(script.Parent.defineLuaFlags)

local Plugin = script.Parent.Parent
local isCli = require(Plugin.Core.Util.isCli)

if isCli() then
	return
end

local Packages = Plugin.Packages
local Framework = require(Packages.Framework)
local isHighDpiEnabled = Framework.Util.isHighDpiEnabled
local FFlagHighDpiIcons = game:GetFastFlag("SVGLuaIcons") and isHighDpiEnabled()

local PluginLoaderBuilder = require(Plugin.PluginLoader.PluginLoaderBuilder)
local Constants = require(Plugin.Core.Util.Constants)
local Images = require(Plugin.Core.Util.Images)
local SharedPluginConstants = require(Plugin.SharedPluginConstants)
local StudioService = game:GetService("StudioService")
local StudioAssetService = game:GetService("StudioAssetService")
local MemStorageService = game:GetService("MemStorageService")

local EVENT_ID_OPENASSETCONFIG = "OpenAssetConfiguration"

local FFlagUnifyModelPackagePublish3 = game:GetFastFlag("UnifyModelPackagePublish3")

local args: PluginLoaderBuilder.Args = {
	plugin = plugin,
	pluginName = "Toolbox",
	translationResourceTable = Plugin.LocalizationSource.LocalizedStrings,
	fallbackResourceTable = Plugin.LocalizationSource.SourceStrings,
	overrideLocaleId = nil,
	localizationNamespace = nil,
	getToolbarName = function()
		return "luaToolboxToolbar"
	end,
	buttonInfo = {
		getName = function()
			return "luaToolboxButton"
		end,
		getDescription = function()
			return "Insert items from the toolbox"
		end,
		icon = if FFlagHighDpiIcons then Images.TOOLBOX_ICON else Images.DEPRECATED_TOOLBOX_ICON,
		text = nil,
		clickableWhenViewportHidden = true,
	},
	dockWidgetInfo = {
		dockWidgetPluginGuiInfo = DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Left, --initialDockState,
			true, --initialEnabled,
			false, --initialEnabledShouldOverrideRestore,
			0, --size.X,
			0, --size.Y,
			Constants.TOOLBOX_MIN_WIDTH, --minSize.X,
			Constants.TOOLBOX_MIN_HEIGHT --minSize.Y
		),
		getDockTitle = function(getLocalizedText, namespace, pluginName)
			return getLocalizedText(namespace, pluginName, "General", "ToolboxToolbarName")
		end,
		name = "Toolbox",
		zIndexBehavior = Enum.ZIndexBehavior.Sibling,
	},
	extraTriggers = {
		["StudioAssetService.OnSaveToRoblox"] = if FFlagUnifyModelPackagePublish3 then function()
			return StudioAssetService.OnSaveToRoblox
		end else nil,
		["StudioService.OnSaveToRoblox"] = function()
			return StudioService.OnSaveToRoblox
		end,
		["StudioService.OnImportFromRoblox"] = function()
			return StudioService.OnImportFromRoblox
		end,
		["StudioService.OnOpenManagePackagePlugin"] = function()
			return StudioService.OnOpenManagePackagePlugin
		end,
		["StudioService.OnPublishAsPlugin"] = function()
			return StudioService.OnPublishAsPlugin
		end,
		["MemStorageService." .. EVENT_ID_OPENASSETCONFIG] = function()
			local bindableEvent = Instance.new("BindableEvent")
			MemStorageService:Bind(EVENT_ID_OPENASSETCONFIG, function(...)
				bindableEvent:Fire(...)
			end)
			return bindableEvent.Event
		end,
		["MemStorageService." .. SharedPluginConstants.SHOW_TOOLBOX_PLUGINS_EVENT] = function()
			local bindableEvent = Instance.new("BindableEvent")
			MemStorageService:Bind(SharedPluginConstants.SHOW_TOOLBOX_PLUGINS_EVENT, function(...)
				bindableEvent:Fire(...)
			end)
			return bindableEvent.Event
		end,
	},
	shouldImmediatelyOpen = function()
		local startupAsset = StudioService:GetStartupAssetId()
		if startupAsset and #startupAsset > 0 then
			return true
		end
		return false
	end,
}

local pluginLoaderContext: PluginLoaderBuilder.PluginLoaderContext = PluginLoaderBuilder.build(args)
local success = pluginLoaderContext.pluginLoader:waitForUserInteraction()
if not success then
	-- Plugin destroyed
	return
end

local main = require(script.Parent.main)
main(plugin, pluginLoaderContext)
