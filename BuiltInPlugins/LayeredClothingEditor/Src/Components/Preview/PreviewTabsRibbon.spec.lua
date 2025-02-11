return function()
	local Plugin = script.Parent.Parent.Parent.Parent
	local Roact = require(Plugin.Packages.Roact)

	local TestRunner = require(Plugin.Src.Util.TestRunner)
	local runComponentTest = TestRunner.runComponentTest

	local PreviewTabsRibbon = require(script.Parent.PreviewTabsRibbon)
	it("should create and destroy without errors", function()
		runComponentTest(Roact.createElement(PreviewTabsRibbon))
	end)

	it("should render correctly", function ()
		runComponentTest(
			Roact.createElement(PreviewTabsRibbon, {
			}),
			function(container)
				local frame = container:FindFirstChildOfClass("Frame")
				local avatars = frame.Tabs["1"]

				expect(frame).to.be.ok()
				expect(avatars).to.be.ok()
			end
		)
	end)
end