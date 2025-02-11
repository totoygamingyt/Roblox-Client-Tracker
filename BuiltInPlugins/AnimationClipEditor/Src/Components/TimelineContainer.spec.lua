return function()
	local Plugin = script.Parent.Parent.Parent
	local Roact = require(Plugin.Packages.Roact)

	local MockWrapper = require(Plugin.Src.Context.MockWrapper)
	local Constants = require(Plugin.Src.Util.Constants)

	local TimelineContainer = require(script.Parent.TimelineContainer)

	local function createTestTimelineContainer()
		return Roact.createElement(MockWrapper, {}, {
			TimelineContainer = Roact.createElement(TimelineContainer, {
				LayoutOrder = 0,
				ParentSize = Vector2.new(1000, 500),
				StartTick = 0,
				EndTick = Constants.TICK_FREQUENCY,
				Playhead = 0,
				TrackPadding = Constants.TRACK_PADDING_SMALL,
				FrameRate = Constants.DEFAULT_FRAMERATE,
				OnToggleEditorClicked = function() end,
			})
		})
	end

	it("should create and destroy without errors", function()
		local element = createTestTimelineContainer()
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)

	it("should render correctly", function()
		local container = Instance.new("Folder")
		local element = createTestTimelineContainer()
		local instance = Roact.mount(element, container)

		local frame = container:FindFirstChildOfClass("Frame")
		expect(frame).to.be.ok()
		expect(frame.Timeline).to.be.ok()
		expect(frame.Timeline.Ticks).to.be.ok()
		Roact.unmount(instance)
	end)
end