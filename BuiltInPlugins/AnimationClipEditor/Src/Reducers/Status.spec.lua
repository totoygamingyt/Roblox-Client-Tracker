return function()
	local Plugin = script.Parent.Parent.Parent
	local Rodux = require(Plugin.Packages.Rodux)

	local Status = require(script.Parent.Status)

	local Constants = require(Plugin.Src.Util.Constants)

	local SetRightClickContextInfo = require(Plugin.Src.Actions.SetRightClickContextInfo)
	local SetSelectedKeyframes = require(Plugin.Src.Actions.SetSelectedKeyframes)
	local SetSelectedEvents = require(Plugin.Src.Actions.SetSelectedEvents)
	local SetRootInstance = require(Plugin.Src.Actions.SetRootInstance)
	local SetScrollZoom = require(Plugin.Src.Actions.SetScrollZoom)
	local SetHorizontalScrollZoom = require(Plugin.Src.Actions.SetHorizontalScrollZoom)
	local SetVerticalScrollZoom = require(Plugin.Src.Actions.SetVerticalScrollZoom)
	local SetPlayState = require(Plugin.Src.Actions.SetPlayState)
	local SetClipboard = require(Plugin.Src.Actions.SetClipboard)
	local SetPlayhead = require(Plugin.Src.Actions.SetPlayhead)
	local SetTracks = require(Plugin.Src.Actions.SetTracks)
	local SetEditingLength = require(Plugin.Src.Actions.SetEditingLength)
	local SetShowAsSeconds = require(Plugin.Src.Actions.SetShowAsSeconds)
	local SetShowEvents = require(Plugin.Src.Actions.SetShowEvents)
	local SetEventEditingTick = require(Plugin.Src.Actions.SetEventEditingTick)
	local SetIKEnabled = require(Plugin.Src.Actions.SetIKEnabled)
	local SetStartingPose = require(Plugin.Src.Actions.SetStartingPose)
	local SetIKMode = require(Plugin.Src.Actions.SetIKMode)
	local SetShowTree = require(Plugin.Src.Actions.SetShowTree)
	local GetFFlagFaceControlsEditorUI = require(Plugin.LuaFlags.GetFFlagFaceControlsEditorUI)
	local SetShowFaceControlsEditorPanel = require(Plugin.Src.Actions.SetShowFaceControlsEditorPanel)
	local SetPinnedParts = require(Plugin.Src.Actions.SetPinnedParts)
	local SetMotorData = require(Plugin.Src.Actions.SetMotorData)
	local SetIsDirty = require(Plugin.Src.Actions.SetIsDirty)
	local SetAnimationImportProgress = require(Plugin.Src.Actions.SetAnimationImportProgress)
	local SetAnimationImportStatus = require(Plugin.Src.Actions.SetAnimationImportStatus)
	local SetSelectedTracks = require(Plugin.Src.Actions.SetSelectedTracks)
	local MoveSelectedTrack = require(Plugin.Src.Thunks.MoveSelectedTrack)
	local SetTool = require(Plugin.Src.Actions.SetTool)
	local ToggleWorldSpace = require(Plugin.Src.Actions.ToggleWorldSpace)
	local SetActive = require(Plugin.Src.Actions.SetActive)

	local GetFFlagCurveEditor = require(Plugin.LuaFlags.GetFFlagCurveEditor)
	local GetFFlagFixSelectionRightArrow = require(Plugin.LuaFlags.GetFFlagFixSelectionRightArrow)

	local testRightClickInfo = {
		InstanceName = "Root",
		TrackName = "Track1",
		Tick = 15,
		Track = {
			Keyframes = {1, 15},
			Data = {
				[1] = {
					Value = CFrame.new(0, 1, 0),
					EasingStyle = Enum.PoseEasingStyle.Linear,
					EasingDirection = Enum.PoseEasingDirection.In,
				},
				[15] = {
					Value = CFrame.new(0, 1, 0),
					EasingStyle = Enum.PoseEasingStyle.Linear,
					EasingDirection = Enum.PoseEasingDirection.In,
				},
			}
		}
	}

	local function createTestStore()
		local middlewares = {Rodux.thunkMiddleware}
		local store = Rodux.Store.new(Status, nil, middlewares)
		return store
	end

	it("should return a table with the correct members", function()
		local state = Status(nil, {})

		expect(type(state)).to.equal("table")
		expect(state.SelectedKeyframes).to.be.ok()
		expect(type(state.SelectedKeyframes)).to.equal("table")
		expect(state.SelectedEvents).to.be.ok()
		expect(type(state.SelectedEvents)).to.equal("table")
		expect(state.Playhead).to.be.ok()
		expect(type(state.Playhead)).to.equal("number")
		expect(state.Tracks).to.be.ok()
		expect(type(state.Tracks)).to.equal("table")
		expect(state.UnusedTracks).to.be.ok()
		expect(type(state.UnusedTracks)).to.equal("table")
		expect(state.EditingLength).to.be.ok()
		expect(state.ShowAsSeconds).to.be.ok()
		expect(state.SnapMode).to.be.ok()
		expect(state.ShowEvents).to.be.ok()
		expect(state.IsDirty).to.be.ok()
		expect(state.Tool).to.be.ok()
		expect(state.WorldSpace).to.be.ok()
		expect(state.Active).to.be.ok()
	end)

	describe("SetSelectedKeyframes", function()
		it("should replace the SelectedKeyframes table", function()
			local store = createTestStore()
			local selectedKeyframes = store:getState().SelectedKeyframes
			expect(#selectedKeyframes).to.equal(0)

			store:dispatch(SetSelectedKeyframes({TestKey = "TestValue"}))
			selectedKeyframes = store:getState().SelectedKeyframes
			expect(selectedKeyframes.TestKey).to.equal("TestValue")
		end)
	end)

	describe("SetSelectedEvents", function()
		it("should replace the SelectedEvents table", function()
			local store = createTestStore()
			local selectedEvents = store:getState().SelectedEvents
			expect(#selectedEvents).to.equal(0)

			store:dispatch(SetSelectedEvents({TestKey = "TestValue"}))
			selectedEvents = store:getState().SelectedEvents
			expect(selectedEvents.TestKey).to.equal("TestValue")
		end)
	end)

	describe("SetClipboard", function()
		it("should replace the Clipboard table", function()
			local store = createTestStore()
			local clipboard = store:getState().Clipboard
			expect(#clipboard).to.equal(0)

			store:dispatch(SetClipboard({TestKey = "TestValue"}))
			clipboard = store:getState().Clipboard
			expect(clipboard.TestKey).to.equal("TestValue")
		end)
	end)

	describe("SetPlayhead", function()
		it("should set the Playhead position", function()
			local store = createTestStore()
			store:dispatch(SetPlayhead(5))
			local state = store:getState()
			expect(state.Playhead).to.equal(5)
		end)
	end)

	describe("SetRightClickContextInfo", function()
		it("should set RightClickContextInfo", function()
			local store = createTestStore()
			store:dispatch(SetRightClickContextInfo(testRightClickInfo))
			local state = store:getState()
			expect(state.RightClickContextInfo.InstanceName).to.equal("Root")
			expect(state.RightClickContextInfo.TrackName).to.equal("Track1")
			expect(state.RightClickContextInfo.Tick).to.equal(15)
			expect(#state.RightClickContextInfo.Track.Keyframes).to.equal(2)
		end)
	end)

	describe("SetRootInstance", function()
		it("should set RootInstance", function()
			local store = createTestStore()
			local instance = Instance.new("Model")
			instance.Name = "Test"
			store:dispatch(SetRootInstance(instance))
			local state = store:getState()
			expect(state.RootInstance.Name).to.equal(instance.Name)
		end)
	end)

	describe("SetPlayState", function()
		it("should set PlayState", function()
			local store = createTestStore()
			store:dispatch(SetPlayState(Constants.PLAY_STATE.Reverse))
			local state = store:getState()
			expect(state.PlayState).to.equal(Constants.PLAY_STATE.Reverse)
		end)
	end)

	describe("SetScrollZoom", function()
		it("should set Scroll and Zoom values", function()
			local store = createTestStore()
			if GetFFlagCurveEditor() then
				store:dispatch(SetHorizontalScrollZoom(0.1, 0.2))
				store:dispatch(SetVerticalScrollZoom(0.3, 0.4))
				local state = store:getState()
				expect(state.HorizontalScroll).to.equal(0.1)
				expect(state.HorizontalZoom).to.equal(0.2)
				expect(state.VerticalScroll).to.equal(0.3)
				expect(state.VerticalZoom).to.equal(0.4)
			else
				store:dispatch(SetScrollZoom(0.5, 0.4))
				local state = store:getState()
				expect(state.Scroll).to.equal(0.5)
				expect(state.Zoom).to.equal(0.4)
			end
		end)
	end)

	describe("SetTracks", function()
		it("should replace the current Tracks table", function()
			local store = createTestStore()
			store:dispatch(SetTracks({TestKey = "TestValue"}))
			local tracks = store:getState().Tracks
			expect(tracks.TestKey).to.equal("TestValue")
		end)

		it("should replace the current UnusedTracks table", function()
			local store = createTestStore()
			store:dispatch(SetTracks({TestKey = "TestValue"}, {OtherKey = "OtherValue"}))
			local unused = store:getState().UnusedTracks
			expect(unused.OtherKey).to.equal("OtherValue")
		end)
	end)

	describe("SetEditingLength", function()
		it("should set the animation length in the editor", function()
			local store = createTestStore()
			store:dispatch(SetEditingLength(100))
			local state = store:getState()
			expect(state.EditingLength).to.equal(100)
		end)
	end)

	describe("SetShowAsSeconds", function()
		it("should set ShowAsSeconds", function()
			local store = createTestStore()
			store:dispatch(SetShowAsSeconds(false))
			local state = store:getState()
			expect(state.ShowAsSeconds).to.equal(false)
		end)
	end)

	describe("SetShowEvents", function()
		it("should set ShowEvents", function()
			local store = createTestStore()
			store:dispatch(SetShowEvents(false))
			local state = store:getState()
			expect(state.ShowEvents).to.equal(false)
			store:dispatch(SetShowEvents(true))
			state = store:getState()
			expect(state.ShowEvents).to.equal(true)
		end)
	end)

	describe("SetEventEditingTick", function()
		it("should set the tick where events are being edited", function()
			local store = createTestStore()
			store:dispatch(SetEventEditingTick(3))
			local state = store:getState()
			expect(state.EventEditingTick).to.equal(3)
		end)

		it("should remove the frame if nil is passed", function()
			local store = createTestStore()
			store:dispatch(SetEventEditingTick(3))
			store:dispatch(SetEventEditingTick())
			local state = store:getState()
			expect(state.EventEditingTick).never.to.be.ok()
		end)
	end)

	describe("SetIKEnabled", function()
		it("should set IKEnabled", function()
			local store = createTestStore()
			store:dispatch(SetIKEnabled(true))
			local state = store:getState()
			expect(state.IKEnabled).to.equal(true)
		end)
	end)

	describe("SetMotorData", function()
		it("should set motor data", function()
			local store = createTestStore()
			local part0 = Instance.new("Part")
			local part1 = Instance.new("Part")
			local testData = {
				[part1] = {
					Name = "Test",
					Parent = part1,
					Part0 = part0,
					Part1 = part1,
					C0 = CFrame.new(1, 0, 0),
					C1 = CFrame.new(0, 1, 0),
				}
			}
			store:dispatch(SetMotorData(testData))
			local state = store:getState()
			expect(state.MotorData[part1].Name).to.equal("Test")
		end)
	end)

	describe("SetIsDirty", function()
		it("should set whether the animation has been saved", function()
			local store = createTestStore()
			store:dispatch(SetIsDirty(true))
			local state = store:getState()
			expect(state.IsDirty).to.equal(true)
		end)
	end)

	describe("SetAnimationImportProgress", function()
		it("should set the animation import progress", function()
			local store = createTestStore()
			local testValue = 0.5
			store:dispatch(SetAnimationImportProgress(testValue))
			local state = store:getState()
			expect(state.AnimationImportProgress).to.equal(testValue)
		end)
	end)

	describe("SetAnimationImportStatus", function()
		it("should set the animation import status", function()
			local store = createTestStore()
			local testValue = Constants.ANIMATION_FROM_VIDEO_STATUS.Pending
			store:dispatch(SetAnimationImportStatus(testValue))
			local state = store:getState()
			expect(state.AnimationImportStatus).to.equal(testValue)
		end)
	end)

	describe("SetSelectedTracks", function()
		it("should set selectedTracks", function()
			local store = createTestStore()
			if GetFFlagCurveEditor() then
				store:dispatch(SetSelectedTracks({{"TestTrack"}}))
			else
				store:dispatch(SetSelectedTracks({"TestTrack"}))
			end
			local state = store:getState()
			if GetFFlagCurveEditor() then
				expect(state.SelectedTracks[1][1]).to.equal("TestTrack")
			else
				expect(state.SelectedTracks[1]).to.equal("TestTrack")
			end

			store:dispatch(SetSelectedTracks())
			state = store:getState()
			if GetFFlagFixSelectionRightArrow() then
				expect(#state.SelectedTracks).to.equal(0)
			else
				expect(state.SelectedTracks).never.to.be.ok()
			end
		end)
	end)

	describe("MoveSelectedTrack", function()
		it("should move the selected track", function()
			local store = createTestStore()
			store:dispatch(SetTracks({
				{ Name = "TestTrack1", },
				{ Name = "TestTrack2", },
				{ Name = "TestTrack3", },
			}))
			if GetFFlagCurveEditor() then
				store:dispatch(SetSelectedTracks({{"TestTrack1"}}))
			else
				store:dispatch(SetSelectedTracks({"TestTrack1"}))
			end
			store:dispatch(MoveSelectedTrack(1))
			local state = store:getState()
			if GetFFlagCurveEditor() then
				expect(state.SelectedTracks[1][1]).to.equal("TestTrack2")
			else
				expect(state.SelectedTracks[1]).to.equal("TestTrack2")
			end
			store:dispatch(MoveSelectedTrack(-1))
			state = store:getState()
			if GetFFlagCurveEditor() then
				expect(state.SelectedTracks[1][1]).to.equal("TestTrack1")
			else
				expect(state.SelectedTracks[1]).to.equal("TestTrack1")
			end
		end)

		it("should clamp the selection", function()
			local store = createTestStore()
			store:dispatch(SetTracks({
				{ Name = "TestTrack1", },
				{ Name = "TestTrack2", },
				{ Name = "TestTrack3", },
			}))
			if GetFFlagCurveEditor() then
				store:dispatch(SetSelectedTracks({{"TestTrack1"}}))
			else
				store:dispatch(SetSelectedTracks({"TestTrack1"}))
			end
			store:dispatch(MoveSelectedTrack(-1))
			local state = store:getState()
			if GetFFlagCurveEditor() then
				expect(state.SelectedTracks[1][1]).to.equal("TestTrack1")
			else
				expect(state.SelectedTracks[1]).to.equal("TestTrack1")
			end
			store:dispatch(MoveSelectedTrack(4))
			state = store:getState()
			if GetFFlagCurveEditor() then
				expect(state.SelectedTracks[1][1]).to.equal("TestTrack3")
			else
				expect(state.SelectedTracks[1]).to.equal("TestTrack3")
			end
		end)
	end)

	describe("SetTool", function()
		it("should set the current Tool", function()
			local store = createTestStore()
			store:dispatch(SetTool(Enum.RibbonTool.Rotate))
			local state = store:getState()
			expect(state.Tool).to.equal(Enum.RibbonTool.Rotate)
		end)
	end)

	describe("ToggleWorldSpace", function()
		it("should toggle the value of WorldSpace", function()
			local store = createTestStore()
			local val = store.WorldSpace
			store:dispatch(ToggleWorldSpace())
			local state = store:getState()
			expect(state.WorldSpace).to.equal(not val)
		end)
	end)

	describe("SetIKMode", function()
		it("should set the IK Mode", function()
			local store = createTestStore()
			store:dispatch(SetIKMode(Constants.IK_MODE.BodyPart))
			local state = store:getState()
			expect(state.IKMode).to.equal(Constants.IK_MODE.BodyPart)
		end)
	end)

	describe("SetPinnedParts", function()
		it("should set pinned parts", function()
			local part = Instance.new("Part")
			local pinnedParts = {
				[part] = true
			}
			local store = createTestStore()
			store:dispatch(SetPinnedParts(pinnedParts))
			local state = store:getState()
			expect(state.PinnedParts[part]).to.equal(true)
			part:Destroy()
		end)
	end)

	describe("SetShowTree", function()
		it("should set ShowTree", function()
			local store = createTestStore()
			store:dispatch(SetShowTree(true))
			local state = store:getState()
			expect(state.ShowTree).to.equal(true)
		end)
	end)

	if GetFFlagFaceControlsEditorUI() then
		describe("SetShowFaceControlsEditorPanel", function()
			it("should set ShowFaceControlsEditorPanel", function()
				local store = createTestStore()
				store:dispatch(SetShowFaceControlsEditorPanel(true))
				local state = store:getState()
				expect(state.ShowFaceControlsEditorPanel).to.equal(true)
			end)
		end)
	end
	describe("SetActive", function()
		it("should set Active", function()
			local store = createTestStore()
			store:dispatch(SetActive(true))
			local state = store:getState()
			expect(state.Active).to.equal(true)
		end)
	end)

	describe("SetStartingPose", function()
		it("should set starting pose", function()
			local store = createTestStore()
			store:dispatch(SetStartingPose({["Part"] = CFrame.new()}))
			local state = store:getState()
			expect(state.StartingPose["Part"]).to.be.ok()
		end)
	end)
end
