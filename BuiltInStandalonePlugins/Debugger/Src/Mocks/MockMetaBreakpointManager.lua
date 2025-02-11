local main = script.Parent.Parent.Parent
local Framework = require(main.Packages.Framework)
local Signal = Framework.Util.Signal

local MockMetaBreakpointManager = {}
MockMetaBreakpointManager.__index = MockMetaBreakpointManager

function MockMetaBreakpointManager.new()
	local self = {}
	setmetatable(self, MockMetaBreakpointManager)
	self.MetaBreakpointAdded = Signal.new()

	self.MetaBreakpointAdded:Connect(function(metaBreakpoint)
		self.MockMetaBreakpointsById[metaBreakpoint.Id] = metaBreakpoint
	end)
	self.MetaBreakpointChanged = Signal.new()
	self.MetaBreakpointSetChanged = Signal.new()
	self.MetaBreakpointRemoved = Signal.new()

	self.MockMetaBreakpointsById = {}
	self.MockSetMetaBreakpointById = function(id, breakpoint)
		self.MockMetaBreakpointsById[id] = breakpoint
	end

	self.deletedBreakpoints = {}
	return self
end

function MockMetaBreakpointManager:RemoveBreakpointById(id: number)
	self.deletedBreakpoints[id] = true
end

function MockMetaBreakpointManager:GetBreakpointById(id: number)
	return self.MockMetaBreakpointsById[id]
end

return MockMetaBreakpointManager
