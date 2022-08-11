--[[
	The main plugin component.
	Consists of the PluginWidget, Toolbar, Button, and Roact tree.
]]

local main = script.Parent.Parent
local _Types = require(main.Src.Types)
local Roact = require(main.Packages.Roact)

local Framework = require(main.Packages.Framework)

local ContextServices = Framework.ContextServices

local StudioUI = Framework.StudioUI
local PluginToolbar = StudioUI.PluginToolbar
local PluginButton = StudioUI.PluginButton

local Components = main.Src.Components
local ImportPrompt = require(Components.ImportPrompt)
local MeshImportDialog = require(Components.MeshImportDialog)
local ProgressWidget = require(Components.ProgressWidget)
local ErrorWidget = require(Components.ErrorWidget)

local MainPlugin = Roact.PureComponent:extend("MainPlugin")

function MainPlugin:init(props)
	self.state = {
		hasImportSettings = false,
		promptRequested = false,
		uploadInProgress = false,
		importOpenError = false,
	}

	self.promptClosed = function(succeeded, closed)
		assert(self.state.promptRequested)
		self:setState({
			hasImportSettings = succeeded and not closed,
			importOpenError = not succeeded and not closed,
			promptRequested = false,
		})
	end

	self.toggleEnabled = function()
		assert(not self.state.promptRequested, "Import prompt already requested")

		if self.state.hasImportSettings then
			self.onClose()
		else
			self:setState({
				promptRequested = true,
			})
		end
	end

	self.onClose = function()
		self:setState({
			hasImportSettings = false,
			promptRequested = false,
			uploadInProgress = false,
			importOpenError = false,
		})
	end

	self.onCancel = function(session)
		self.onClose()
		session:Cancel()
	end

	self.onImport = function(session)
		self.onClose()
		self:setState({
			uploadInProgress = true,
		})
		session:Upload()
	end
end

function MainPlugin:renderButtons(toolbar)
	local active = self.state.hasImportSettings
	local enabled = not self.state.promptRequested

	return {
		Toggle = Roact.createElement(PluginButton, {
			Active = active,
			Enabled = enabled,
			Toolbar = toolbar,
			Title = self.props.Localization:getText("Plugin", "Button"),
			Tooltip = self.props.Localization:getText("Plugin", "Description"),
			Icon = "rbxasset://textures/AssetImport/Import.png",
			OnClick = self.toggleEnabled,
			ClickableWhenViewportHidden = true,
		}),
	}
end

function MainPlugin:render()
	local props = self.props
	local state = self.state
	local localization = props.Localization

	local hasImportSettings = state.hasImportSettings
	local shouldShowPrompt = not state.hasImportSettings and state.promptRequested
	local shouldShowProgress = state.uploadInProgress
	local importOpenError = state.importOpenError

	return ContextServices.provide({
		props.Plugin,
		props.Mouse,
		props.Store,
		props.Theme,
		localization,
		props.Analytics,
	}, {
		Toolbar = Roact.createElement(PluginToolbar, {
			Title = localization:getText("Plugin", "Toolbar"),
			RenderButtons = function(toolbar)
				return self:renderButtons(toolbar)
			end,
		}),

		Dialog = hasImportSettings and Roact.createElement(MeshImportDialog, {
			Resizable = true,
			Title = localization:getText("Plugin", "WindowTitle"),
			OnClose = self.onCancel,
			OnImport = self.onImport,
			Localization = localization,
		}),

		Prompt = shouldShowPrompt and Roact.createElement(ImportPrompt, {
			OnPromptClosed = self.promptClosed,
		}),

		ProgressWidget = shouldShowProgress and Roact.createElement(ProgressWidget, {
			OnClose = self.onClose,
			Title = localization:getText("Upload", "WindowTitle"),
		}),

		ErrorWidget = importOpenError and Roact.createElement(ErrorWidget, {
			OnClose = self.onClose,
			Title = localization:getText("Error", "WindowTitle"),
		}),
	})
end

return MainPlugin
