local Plugin = script.Parent.Parent.Parent.Parent
local Rodux = require(Plugin.Packages.Rodux)
local MainReducer = require(Plugin.Src.Reducers.MainReducer)

local MetaBreakpointManagerListener = require(Plugin.Src.Util.MetaBreakpointManagerListener.MetaBreakpointManagerListener)
local DebugConnectionListener = require(Plugin.Src.Util.DebugConnectionListener.DebugConnectionListener)
local Mocks = Plugin.Src.Mocks
local MockDebuggerConnection = require(Mocks.MockDebuggerConnection)
local MockDebuggerConnectionManager = require(Mocks.MockDebuggerConnectionManager)
local MockMetaBreakpointManager = require(Mocks.MockMetaBreakpointManager)
local MockMetaBreakpoint = require(Mocks.MetaBreakpoint)
local MockDebuggerUIService = require(Mocks.MockDebuggerUIService)
local MockCrossDMScriptChangeListenerService = require(Mocks.MockCrossDMScriptChangeListenerService)

local function fakeDebuggerConnect(store)
	local mainConnectionManager = MockDebuggerConnectionManager.new()
	local mockDebuggerUIService = MockDebuggerUIService.new()
	local mockCrossDMScriptChangeListenerService = MockCrossDMScriptChangeListenerService.new()

	local _mainListener = DebugConnectionListener.new(
		store,
		mainConnectionManager,
		mockDebuggerUIService,
		mockCrossDMScriptChangeListenerService
	)
	local currentMockConnection = MockDebuggerConnection.new(1)
	mainConnectionManager.ConnectionStarted:Fire(currentMockConnection)
end

local function createMockMetaBreakpoint(id, scriptString)
	return MockMetaBreakpoint.new({
		Script = scriptString,
		Line = 123,
		Condition = "conditionString",
		Id = id,
		LogMessage = "testLogMessage",
		Enabled = true,
		Valid = true,
		ContinueExecution = true,
		IsLogpoint = true,
	})
end

return function()
	it("should create and destroy MetaBreakpointManagerListener without errors", function()
		local mainStore = Rodux.Store.new(MainReducer, {})
		fakeDebuggerConnect(mainStore)
		local mockMetaBreakpointManager = MockMetaBreakpointManager.new()
		local mockCrossDMScriptChangeListenerService = MockCrossDMScriptChangeListenerService.new()

		local mainBreakpointListener = MetaBreakpointManagerListener.new(
			mainStore,
			mockMetaBreakpointManager,
			mockCrossDMScriptChangeListenerService
		)
		expect(mainBreakpointListener)
		mainBreakpointListener:destroy()
	end)

	it("should add, modify, and remove MetaBreakpoints", function()
		local mainStore = Rodux.Store.new(MainReducer, {})
		fakeDebuggerConnect(mainStore)
		local mockMetaBreakpointManager = MockMetaBreakpointManager.new()
		local mockCrossDMScriptChangeListenerService = MockCrossDMScriptChangeListenerService.new()

		local mainBreakpointListener = MetaBreakpointManagerListener.new(
			mainStore,
			mockMetaBreakpointManager,
			mockCrossDMScriptChangeListenerService
		)

		-- added breakpoint should show up
		local metaBreakpoint1 = createMockMetaBreakpoint(1, "scriptString1")
		mockMetaBreakpointManager.MetaBreakpointAdded:Fire(metaBreakpoint1)
		local state = mainStore:getState()
		expect(state.Breakpoint.MetaBreakpoints[1].scriptName).to.equal("scriptString1")

		-- breakpoint should modify
		local modifiedBreakpoint1 = createMockMetaBreakpoint(1, "modifiedString1")
		mockMetaBreakpointManager.MetaBreakpointChanged:Fire(modifiedBreakpoint1)
		state = mainStore:getState()
		expect(state.Breakpoint.MetaBreakpoints[1].scriptName).to.equal("modifiedString1")

		-- breakpoint should be removed
		mockMetaBreakpointManager.MetaBreakpointRemoved:Fire(modifiedBreakpoint1)
		state = mainStore:getState()
		expect(state.Breakpoint.MetaBreakpoints[1]).to.equal(nil)

		mainBreakpointListener:destroy()
	end)
end
