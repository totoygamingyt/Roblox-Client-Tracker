return function()
	local Plugin = script.Parent.Parent.Parent.Parent.Parent
	local Roact = require(Plugin.Packages.Roact)
	local mockContext = require(Plugin.Src.Util.mockContext)

	local MaterialVariantCreator = require(script.Parent)

	local materialVariant

	local function createTestElement(props: MaterialVariantCreator.Props?)
		props = props or {
			SetStudsPerTileError = function() end,
			MaterialVariantTemp = materialVariant,
		}

		return mockContext({
			MaterialVariantCreator = Roact.createElement(MaterialVariantCreator, props)
		})
	end

	beforeEach(function()
		materialVariant = Instance.new("MaterialVariant")
	end)

	afterEach(function()
		materialVariant:Destroy()
		materialVariant = nil
	end)

	it("should create and destroy without errors", function()
		local element = createTestElement()
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)

	it("should render correctly", function()
		local container = Instance.new("Folder")
		local element = createTestElement({
			ErrorName = "ErrorName",
			ErrorBaseMaterial = "ErrorBaseMaterial",
			SetStudsPerTileError = function() end,
			MaterialVariantTemp = materialVariant,
		})
		local instance = Roact.mount(element, container)

		local main = container:FindFirstChildOfClass("Frame")
		expect(main).to.be.ok()
		Roact.unmount(instance)
	end)
end
