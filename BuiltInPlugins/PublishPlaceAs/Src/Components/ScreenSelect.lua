--[[
	Let the user select a universe to write this place into

	Allow the user to go back to publishing a new place
]]

local Plugin = script.Parent.Parent.Parent

local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)

local Constants = require(Plugin.Src.Resources.Constants)

local screenMap = {
	[Constants.SCREENS.CREATE_NEW_GAME] = require(Plugin.Src.Components.ScreenCreateNewGame),
	[Constants.SCREENS.CHOOSE_GAME] = require(Plugin.Src.Components.ScreenChooseGame),
	[Constants.SCREENS.CHOOSE_PLACE] = require(Plugin.Src.Components.ScreenChoosePlace),
	[Constants.SCREENS.PUBLISH_SUCCESSFUL] = require(Plugin.Src.Components.ScreenPublishSuccessful),
	[Constants.SCREENS.PUBLISH_FAIL] = require(Plugin.Src.Components.ScreenPublishFail),
	[Constants.SCREENS.PUBLISH_MANAGEMENT] = require(Plugin.Src.Components.ScreenPublishManagement),
}
for screen,_ in pairs(Constants.SCREENS) do
	assert(screenMap[screen] ~= nil, string.format("ScreenSelect.lua does not handle screen %s", screen))
end

local function ScreenSelect(props)
	local onClose = props.OnClose
	local isPublish = props.IsPublish
	local closeMode = props.CloseMode

	local screen = props.Screen

	return Roact.createElement(screenMap[screen], {
		OnClose = onClose,
		IsPublish = isPublish,
		CloseMode = closeMode,
	})
end

local function mapStateToProps(state, props)
	local screen = state.Screen.screen
	return {
		Screen = screen,
	}
end

return RoactRodux.connect(mapStateToProps)(ScreenSelect)
