local Plugin = script.Parent.Parent.Parent

local Packages = Plugin.Packages
local Roact = require(Packages.Roact)
local Framework = require(Plugin.Packages.Framework)
local ContextItem = Framework.ContextServices.ContextItem

local Symbol = require(Plugin.Src.Util.Symbol)
local NetworkSymbol = Symbol.named("NetworkInterface")

local NetworkContext = Roact.PureComponent:extend("NetworkContext")

function NetworkContext:init(props)
	self._context[NetworkSymbol] = props.networkInterface
end

function NetworkContext:render()
	return Roact.oneChild(self.props[Roact.Children])
end

return ContextItem:createSimple("Network")
