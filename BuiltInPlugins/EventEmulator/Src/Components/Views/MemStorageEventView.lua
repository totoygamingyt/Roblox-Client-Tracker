--[[
	Input Fields:

	Required Props:
		Theme Theme: A Theme ContextItem, which is provided via withContext.
		table Parameters: User-inputted/default text for Namespace, Detail, and DetailType
		function OnChange: A function that passes an identifier and new usr input to the parent

	Optional Props:

	Style Values:
		table Layout: consistent values for either horizontal or vertical UIListLayout
]]

local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)

local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local Components = Plugin.Src.Components
local ButtonArray = require(Components.ButtonArray)
local TextInput = require(Components.TextInput)

local Actions = Plugin.Src.Actions
local SetMemStoragePair = require(Actions.SetMemStoragePair)
local AddHistoryItem = require(Actions.AddHistoryItem)

local Constants = require(Plugin.Src.Util.Constants)
local ORDERING = Constants.MEM_STORAGE_ORDER
local INPUT_PANE_LAYOUT = Constants.INPUT_PANE_LAYOUT
local ROUTES = Constants.ROUTES.MemStorage
local OPERATION_SUCCESSFUL = Constants.OPERATION_SUCCESSFUL
local VIEW_ID = Constants.VIEW_ID.MemStorage

local UI = Framework.UI
local RadioButtonList = UI.RadioButtonList
local Pane = UI.Pane

local Operations = Plugin.Src.Operations
local MemStorageEventRequest = require(Operations.MemStorageEventRequest)

local MemStorageEventView = Roact.PureComponent:extend("MemStorageEventView")

function MemStorageEventView:init()
	self.state = {
		SelectedRoute = ROUTES.GetValue,
	}

	self.createRoutes = function ()
		local buttons = {}

		for _, text in pairs(ROUTES) do -- Using the value for both key and texts
			table.insert(buttons, { 	-- makes the routes easier to match up
				Key = text,
				Text = text,
			})
		end

		return buttons
	end

	self.Router = function (route)
		self:setState({
			SelectedRoute = route,
		})
	end

	self.OnChange = function (source, textbox)
		self.props.SetMemStoragePair({
			[source] = textbox,
		})
	end

	local empty = {
		Key = "",
		Value = "",
	}

	self.onClearClicked = function ()
		self.props.SetMemStoragePair(empty)
	end

	self.onSaveClicked = function ()
		self.props.AddHistoryItem(self.props.CurrentEventName, self.props.KeyValuePair)
	end

	self.onSendClicked = function ()
		local key = self.props.KeyValuePair.Key
		local value = self.props.KeyValuePair.Value
		local route = self.state.SelectedRoute or ""

		if route == ROUTES.GetValue then
			MemStorageEventRequest.GetValue(key)
		end
		if route == ROUTES.SetValue then
			local success = MemStorageEventRequest.SetValue(key, value)
			if success then
				print(OPERATION_SUCCESSFUL)
			end
		end
		if route == ROUTES.NewEntry then
			local success = MemStorageEventRequest.SetValue(key, value)
			if success then
				print(OPERATION_SUCCESSFUL)
			end
		end
	end
end

function MemStorageEventView:render()
	local props = self.props
	local kvPair = props.KeyValuePair

	local theme = props.Stylizer
	local layout = theme.Layout

	return Roact.createElement(Pane, {
		Size = UDim2.new(1, 0, 1, 0),
		LayoutOrder = INPUT_PANE_LAYOUT.View,
	}, {
		Layout = Roact.createElement("UIListLayout", layout.Vertical),
		Switch = Roact.createElement(RadioButtonList, {
			Buttons = self.createRoutes(),
			OnClick = self.Router,
			SelectedKey = ROUTES.GetValue,
			LayoutOrder = ORDERING.Switch,
		}),
		Key = Roact.createElement(TextInput, {
			LayoutOrder = ORDERING.Key,
			Label = "Key",
			Text = kvPair.Key,
			OnChange = function (...)
				self.OnChange("Key", ...)
			end,
		}),
		Value = Roact.createElement(TextInput, {
			LayoutOrder = ORDERING.Value,
			Label = "Value",
			Text = kvPair.Value,
			OnChange = function (...)
				self.OnChange("Value", ...)
			end,
		}),
		Activators = Roact.createElement(ButtonArray, {
			OnClearClicked = self.onClearClicked,
			OnSaveClicked = self.onSaveClicked,
			OnSendClicked = self.onSendClicked,
		}),
	})
end


MemStorageEventView = withContext({
	Stylizer = ContextServices.Stylizer,
})(MemStorageEventView)



return RoactRodux.connect(
	function(state, props)
		return {
			KeyValuePair = state.Status.MemStoragePair,
			CurrentEventName = state.Status.CurrentEventName,
		}
	end,
	function(dispatch)
		return {
			SetMemStoragePair = function (pair)
				dispatch(SetMemStoragePair(pair))
			end,
			AddHistoryItem = function (eventName, data)
				dispatch(AddHistoryItem(VIEW_ID, eventName, data))
			end
		}
	end
)(MemStorageEventView)
