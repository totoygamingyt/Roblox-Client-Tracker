--[[
	Component that wraps its provided children with a store provider,
	and a ScreenGui.
]]
local CorePackages = game:GetService("CorePackages")

local Roact = require(CorePackages.Roact)
local Rodux = require(CorePackages.Rodux)
local RoactRodux = require(CorePackages.RoactRodux)
local AppDarkTheme = require(CorePackages.AppTempCommon.LuaApp.Style.Themes.DarkTheme)
local AppFont = require(CorePackages.AppTempCommon.LuaApp.Style.Fonts.Gotham)
local UIBlox = require(CorePackages.UIBlox)

local InspectAndBuyFolder = script.Parent.Parent
local Reducer = require(InspectAndBuyFolder.Reducers.InspectAndBuyReducer)
local Constants = require(InspectAndBuyFolder.Constants)
local CompactView = require(InspectAndBuyFolder.CompactView)
local WideView = require(InspectAndBuyFolder.WideView)

local InspectAndBuyContext = require(InspectAndBuyFolder.Components.InspectAndBuyContext)

local TestContainer = Roact.Component:extend("TestContainer")

function TestContainer:init()
	self.store = self.props.overrideStore or Rodux.Store.new(Reducer, {}, {
		Rodux.thunkMiddleware,
	})

	self.views = {}
	self.views[Constants.View.Compact] = CompactView
	self.views[Constants.View.Wide] = WideView
end

function TestContainer:render()
	assert(#self.props[Roact.Children] > 0,
		"TestContainer: no children provided, nothing will be tested")

	-- include theme provider for shimmer panels used in the asset list
	local appStyle = {
		Theme = AppDarkTheme,
		Font = AppFont,
	}

	return Roact.createElement(InspectAndBuyContext.Provider, {
		value = self.views
	}, {
		Roact.createElement(RoactRodux.StoreProvider, {
			store = self.store,
		}, {
			ThemeProvider = Roact.createElement(UIBlox.Style.Provider, {
				style = appStyle,
			}, {
				InspectMenu = Roact.createElement("ScreenGui", {}, self.props[Roact.Children])
			})
		})
	})
end

return TestContainer
