--[[
	Selects the events at the given tick.
	If multi-selecting, adds this event to the selection.
	Otherwise, replaces the selection.
]]

local Plugin = script.Parent.Parent.Parent.Parent
local Cryo = require(Plugin.Packages.Cryo)
local SetSelectedEvents = require(Plugin.Src.Actions.SetSelectedEvents)

return function(tck, multiSelect)
	return function(store)
		local animationData = store:getState().AnimationData
		local selectedEvents = store:getState().Status.SelectedEvents
		if not animationData or not selectedEvents then
			return
		end

		local events = animationData.Events
		if events == nil then
			return
		end

		if events.Data and events.Data[tck] then
			if multiSelect then
				store:dispatch(SetSelectedEvents(Cryo.Dictionary.join(selectedEvents, {
					[tck] = true,
				})))
			else
				store:dispatch(SetSelectedEvents({
					[tck] = true,
				}))
			end
		end
	end
end
