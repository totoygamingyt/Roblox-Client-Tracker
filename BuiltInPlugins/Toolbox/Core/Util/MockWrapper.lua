local Plugin = script.Parent.Parent.Parent

local Packages = Plugin.Packages
local Roact = require(Packages.Roact)
local Rodux = require(Packages.Rodux)
local TestHelpers = require(Packages.Framework).TestHelpers
local provideMockContext = TestHelpers.provideMockContext

local Localization = require(Plugin.Core.Util.Localization)
local Settings = require(Plugin.Core.Util.Settings)
local ToolboxTheme = require(Plugin.Core.Util.ToolboxTheme)
local ToolboxReducer = require(Plugin.Core.Reducers.ToolboxReducer)
local NetworkInterfaceMock = require(Plugin.Core.Networking.NetworkInterfaceMock)
local AssetAnalyticsContextItem = require(Plugin.Core.Util.Analytics.AssetAnalyticsContextItem)
local AssetAnalytics = require(Plugin.Core.Util.Analytics.AssetAnalytics)

local ExternalServicesWrapper = require(Plugin.Core.Components.ExternalServicesWrapper)
local makeTheme = require(Plugin.Core.Util.makeTheme)

local Framework = require(Packages.Framework)
local Networking = Framework.Http.Networking
local ContextServices = Framework.ContextServices
local Mouse = ContextServices.Mouse
local Signal = Framework.Util.Signal
local SettingsContext = require(Plugin.Core.ContextServices.Settings)
local IXPContext = require(Plugin.Core.ContextServices.IXPContext)
local NavigationContext = require(Plugin.Core.ContextServices.NavigationContext)
local getAssetConfigTheme = require(Plugin.Core.Themes.getAssetConfigTheme)

local CoreTestUtils = require(Plugin.TestUtils.CoreTestUtils)

local function MockWrapper(props)
	local middleware = CoreTestUtils.createThunkMiddleware()

	local store = props.store or Rodux.Store.new(ToolboxReducer, nil, middleware)
	if props.storeSetup then
		props.storeSetup(store)
	end
	local plugin = props.plugin or nil
	local pluginGui = props.pluginGui or nil
	local settings = props.settings or Settings.new(plugin)
	local theme = props.theme or ToolboxTheme.createDummyThemeManager()
	local networkInterface = props.networkInterface or NetworkInterfaceMock.new()
	local localization = props.localization or Localization.createDummyLocalization()
	local ixpContext = props.ixpContext or IXPContext.createMock()

	local mouse = Mouse.new({
		Icon = "rbxasset://SystemCursors/Arrow",
	})

	local focus = ContextServices.Focus.new(props.focus or Instance.new("ScreenGui"))
	local pluginContext = ContextServices.Plugin.new(plugin)
	local settingsContext = SettingsContext.new(settings)
	local themeContext = makeTheme(getAssetConfigTheme())
	local storeContext = ContextServices.Store.new(store)
	local api = ContextServices.API.new({
		networking = Networking.mock(),
	})
	local analytics = ContextServices.Analytics.mock()

	local assetAnalytics = AssetAnalyticsContextItem.new(props.assetAnalytics or AssetAnalytics.mock())

	local SourceStrings = Plugin.LocalizationSource.SourceStrings
	local LocalizedStrings = Plugin.LocalizationSource.LocalizedStrings
	local devFrameworkLocalization = ContextServices.Localization.new({
		stringResourceTable = SourceStrings,
		translationResourceTable = LocalizedStrings,
		pluginName = "Toolbox",
		libraries = {
			[Framework.Resources.LOCALIZATION_PROJECT_NAME] = {
				stringResourceTable = Framework.Resources.SourceStrings,
				translationResourceTable = Framework.Resources.LocalizedStrings,
			},
		},
		overrideGetLocale = function()
			return "en-us"
		end,
		overrideLocaleId = "en-us",
		overrideLocaleChangedSignal = Signal.new(),
	})

	local navigationContext = NavigationContext.new()

	local context = {
		storeContext,
		focus,
		mouse,
		pluginContext,
		settingsContext,
		themeContext,
		api,
		assetAnalytics,
		analytics,
		devFrameworkLocalization,
		ixpContext,
		navigationContext,
	}

	return Roact.createElement(ExternalServicesWrapper, {
		store = store,
		plugin = plugin,
		pluginGui = pluginGui,
		settings = settings,
		theme = theme,
		networkInterface = networkInterface,
		localization = localization,
	}, {
		provideMockContext(context, props[Roact.Children]),
	})
end

return MockWrapper
