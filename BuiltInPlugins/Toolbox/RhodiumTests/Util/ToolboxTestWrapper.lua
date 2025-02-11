local Plugin = script.Parent.Parent.Parent
local Packages = Plugin.Packages
local Roact = require(Packages.Roact)

local Util = Plugin.Core.Util
local makeTheme = require(Util.makeTheme)

local Toolbox = require(Plugin.Core.Components.Toolbox)
local Suggestion = require(Plugin.Core.Types.Suggestion)
local Background = require(Plugin.Core.Types.Background)

local ToolboxTestWrapper = Roact.PureComponent:extend("ToolboxTestWrapper")

function ToolboxTestWrapper:init()
	self.state = {
		theme = makeTheme(),
	}
end

function ToolboxTestWrapper:render(props)
	local _theme = self.state.theme

	return Roact.createElement(Toolbox, {
		backgrounds = Background.BACKGROUNDS,
		suggestions = Suggestion.SUGGESTIONS,
		Size = UDim2.new(0, 400, 0, 400),
	})
end

return ToolboxTestWrapper
