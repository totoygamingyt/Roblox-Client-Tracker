return function()
	local Plugin = script.Parent.Parent.Parent
	local Roact = require(Plugin.Packages.Roact)
	local Constants = require(Plugin.Src.Util.Constants)

	local MockWrapper = require(Plugin.Src.Context.MockWrapper)

	local TrackEditor = require(script.Parent.TrackEditor)

	local function createTestTrackEditor()
		return Roact.createElement(MockWrapper, {}, {
			TrackEditor = Roact.createElement(TrackEditor, {
				ZIndex = 1,
				LayoutOrder = 1,
				Size = UDim2.new(0, 1000, 0, 500),
				StartTick = 0,
				EndTick = Constants.TICK_FREQUENCY,
				LastTick = Constants.TICK_FREQUENCY * 2,
				Playhead = 0,
				FrameRate = Constants.DEFAULT_FRAMERATE,
			})
		})
	end

	it("should create and destroy without errors", function()
		local element = createTestTrackEditor()
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)

	it("should render correctly", function()
		local container = Instance.new("Folder")
		local element = createTestTrackEditor()
		local instance = Roact.mount(element, container)

		local frame = container:FindFirstChildOfClass("Frame")
		expect(frame).to.be.ok()
		expect(frame.TimelineContainer).to.be.ok()
		expect(frame.DopeSheetController).to.be.ok()
		expect(frame.IgnoreLayout).to.be.ok()
		expect(frame.IgnoreLayout.TimelineBorder).to.be.ok()
		expect(frame.IgnoreLayout.Scrubber).to.be.ok()
		Roact.unmount(instance)
	end)
end