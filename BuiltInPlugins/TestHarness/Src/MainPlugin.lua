--[[
	The main plugin component.
	Consists of the PluginWidget, Toolbar, Button, and Roact tree.
]]

local main = script.Parent.Parent
local Roact = require(main.Packages.Roact)
local Rodux = require(main.Packages.Rodux)
local Framework = require(main.Packages.Framework)

local StudioUI = Framework.StudioUI
local DockWidget = StudioUI.DockWidget
local PluginToolbar = StudioUI.PluginToolbar
local PluginButton = StudioUI.PluginButton

local ContextServices = Framework.ContextServices
local Plugin = ContextServices.Plugin
local Mouse = ContextServices.Mouse
local Store = ContextServices.Store

local MainReducer = require(main.Src.Reducers.MainReducer)
local MakeTheme = require(main.Src.Resources.MakeTheme)

local TranslationDevelopmentTable = main.Src.Resources.Localization.TranslationDevelopmentTable
local TranslationReferenceTable = main.Src.Resources.Localization.TranslationReferenceTable
local FFlagFixToolbarButtonForFreshInstallation2 = game:GetFastFlag("FixToolbarButtonForFreshInstallation2")

local MainView = require(main.Src.Components.MainView)

local MainPlugin = Roact.PureComponent:extend("MainPlugin")

function MainPlugin:init(props)
	self.state = {
		enabled = false,
	}

	self.toggleEnabled = function()
		self:setState(function(state)
			return {
				enabled = not state.enabled,
			}
		end)
	end

	self.onClose = function()
		self:setState({
			enabled = false,
		})
	end

	self.onRestore = function(enabled)
		self:setState({
			enabled = enabled
		})
		-- The DevFramework delay the initialization of creating the dockwidget(controlled by "CreateWidgetImmediately")
		-- which cause the onResotre function called later, and override the enabled state of button click.
		-- so we connection and flush the button event here after onRestore
		if not FFlagFixToolbarButtonForFreshInstallation2 then
			self.props.pluginLoaderContext.mainButtonClickedSignal:Connect(self.toggleEnabled)
		end
	end

	if FFlagFixToolbarButtonForFreshInstallation2 then
		self.onDockWidgetCreated = function()
			self.props.pluginLoaderContext.mainButtonClickedSignal:Connect(self.toggleEnabled)
		end
	end

	self.onWidgetEnabledChanged = function(widget)
		self:setState({
			enabled = widget.Enabled
		})
	end

	self.store = Rodux.Store.new(MainReducer, nil, {
		Rodux.thunkMiddleware,
	})

	self.localization = ContextServices.Localization.new({
		stringResourceTable = TranslationDevelopmentTable,
		translationResourceTable = TranslationReferenceTable,
		pluginName = "TestHarness",
	})

	self.button = self.props.pluginLoaderContext.mainButton
end

function MainPlugin:didUpdate()
	self.button:SetActive(self.state.enabled)
end

function MainPlugin:render()
	local props = self.props
	local state = self.state
	local plugin = props.Plugin
	local enabled = state.enabled

	return ContextServices.provide({
		Plugin.new(plugin),
		Store.new(self.store),
		Mouse.new(plugin:getMouse()),
		MakeTheme(),
	}, {
		MainWidget = Roact.createElement(DockWidget, {
			Enabled = enabled,
			Widget = props.pluginLoaderContext.mainDockWidget,
			Title = self.localization:getText("Plugin", "Name"),
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			InitialDockState = Enum.InitialDockState.Bottom,
			Size = Vector2.new(640, 480),
			OnClose = self.onClose,
			OnWidgetRestored = self.onRestore,
			OnWidgetCreated = FFlagFixToolbarButtonForFreshInstallation2 and self.onDockWidgetCreated or nil,
		}, {
			Toolbar = Roact.createElement(MainView),
		}),
	})
end

return MainPlugin
