return function()
	local HttpService = game:GetService("HttpService")
	local CorePackages = game:GetService("CorePackages")
	local Roact = require(CorePackages.Roact)

	local ProfilerViewEntry = require(script.Parent.ProfilerViewEntry)

	local TEST_DATA = HttpService:JSONDecode(require(script.Parent.TestData))

	it("should create and destroy without errors", function()
		local element = Roact.createElement(ProfilerViewEntry, {
			layoutOrder = 0,
			depth = 0,
			data = TEST_DATA,
			percentageRatio = nil
		})

		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)
end