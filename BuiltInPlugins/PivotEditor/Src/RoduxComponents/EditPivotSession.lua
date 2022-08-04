local Plugin = script.Parent.Parent.Parent

local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local DraggerFramework = Plugin.Packages.DraggerFramework

local ContextServices = require(Plugin.Packages.Framework).ContextServices
local withContext = ContextServices.withContext

local DraggerToolComponent = require(DraggerFramework.DraggerTools.DraggerToolComponent)
local MoveHandles = require(DraggerFramework.Handles.MoveHandles)
local RotateHandles = require(DraggerFramework.Handles.RotateHandles)
local PivotHandle = require(Plugin.Src.DraggerSchemaPivot.PivotHandle)

local DraggerSchema = require(Plugin.Src.DraggerSchemaPivot.DraggerSchema)
local DraggerContext_Pivot = require(Plugin.Src.DraggerSchemaPivot.DraggerContext_Pivot)
local SelectionUpdaterBound = require(Plugin.Src.RoduxComponents.SelectionUpdaterBound)
local BeginSelectingPivot = require(Plugin.Src.Actions.BeginSelectingPivot)
local DoneSelectingPivot = require(Plugin.Src.Actions.DoneSelectingPivot)

local EditingMode = require(Plugin.Src.Utility.EditingMode)
local StatusMessage = require(Plugin.Src.Utility.StatusMessage)

local ToastNotification = require(Plugin.Src.Utility.ToastNotification)

local EditPivotSession = Roact.PureComponent:extend("EditPivotSession")

local ANALYTICS_NAME = "EditPivot"

-- Control which StatusMessages are user facing
local function shouldShowNotification(statusMessage)
	if statusMessage == StatusMessage.None or statusMessage == StatusMessage.NoSelection then
		return false
	else
		return true
	end
end

function EditPivotSession:didMount()
	local showIndicator = self.props.statusMessage == StatusMessage.None
	self._oldShowPivot = self._draggerContext:setPivotIndicator(showIndicator)
end

function EditPivotSession:_getCurrentDraggerHandles()
	if self.props.editingMode == EditingMode.Transform then
		return {
			MoveHandles.new(self._draggerContext, {
				Outset = 0.5,
				ShowBoundingBox = false,
				Summonable = false,
				MustPositionAtPivot = true,
			}, DraggerSchema.MoveHandlesImplementation.new(self._draggerContext, ANALYTICS_NAME)),
			RotateHandles.new(self._draggerContext, {
				ShowBoundingBox = false,
				Summonable = false,
			}, DraggerSchema.RotateHandlesImplementation.new(self._draggerContext, ANALYTICS_NAME)),
			PivotHandle.new(self._draggerContext),
		}
	else
		-- Only use the DraggerFramework for selecting objects in
		-- EditingMode.None, no handles to show.
		return {}
	end
end

function EditPivotSession:render()
	local editingMode = self.props.editingMode
	local elements = {}

	local pluginInstance = self.props.Plugin:get()
	local mouse = pluginInstance:GetMouse()
	self._draggerContext = self.props.DraggerContext
	if not self._draggerContext then
		self._draggerContext = DraggerContext_Pivot.new(
			pluginInstance, game, settings(), DraggerSchema.Selection.new())
	end

	if editingMode == EditingMode.Transform or editingMode == EditingMode.None then
		local allowFreeformDrag = editingMode == EditingMode.Transform

		elements.DraggerToolComponent = Roact.createElement(DraggerToolComponent, {
			Mouse = mouse,
			DraggerContext = self._draggerContext,
			DraggerSchema = DraggerSchema,
			DraggerSettings = {
				AnalyticsName = ANALYTICS_NAME,
				AllowDragSelect = false,
				AllowFreeformDrag = allowFreeformDrag,
				ShowLocalSpaceIndicator = false,
				HandlesList = self:_getCurrentDraggerHandles(),
			},
		})
	end

	elements.SelectionUpdaterBound = Roact.createElement(SelectionUpdaterBound)

	return Roact.createFragment(elements)
end

function EditPivotSession:willUpdate(nextProps, nextState)
	local nextStatusMessage = nextProps.statusMessage
	local showIndicator = nextStatusMessage == StatusMessage.None
	self._draggerContext:setPivotIndicator(showIndicator)

	local statusMessage = self.props.statusMessage
	if statusMessage ~= nextStatusMessage then
		-- If the status is being cleared (set to StatusMessage.None), hide the
		-- last status message when the status is cleared.
		if statusMessage ~= StatusMessage.None then
			-- Has no effect if the notification has already disappeared.
			self.props.ToastNotification:hideNotification(statusMessage)
		end

		if shouldShowNotification(nextStatusMessage) then
			local localization = self.props.Localization
			local message = localization:getText("Notification", nextStatusMessage)
			self.props.ToastNotification:showNotification(message, nextStatusMessage)
		end
	end
end

function EditPivotSession:willUnmount()
	self._draggerContext:setPivotIndicator(self._oldShowPivot)
end

EditPivotSession = withContext({
	Localization = ContextServices.Localization,
	Plugin = ContextServices.Plugin,
	ToastNotification = ToastNotification,
})(EditPivotSession)

local function mapStateToProps(state, _)
	return {
		editingMode = state.editingMode,
		statusMessage = state.statusMessage,
		targetObject = state.targetObject,
	}
end

local function mapDispatchToProps(dispatch)
	return {
		beginSelectingPivot = function(editingMode, message)
			dispatch(BeginSelectingPivot(editingMode, message))
		end,
		doneSelectingPivot = function()
			dispatch(DoneSelectingPivot())
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(EditPivotSession)
