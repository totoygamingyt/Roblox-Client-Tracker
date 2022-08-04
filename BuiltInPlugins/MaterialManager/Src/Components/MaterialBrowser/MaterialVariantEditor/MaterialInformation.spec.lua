local Plugin = script.Parent.Parent.Parent.Parent.Parent
local _Types = require(Plugin.Src.Types)
local Roact = require(Plugin.Packages.Roact)
local Framework = require(Plugin.Packages.Framework)
local mockContext = require(Plugin.Src.Util.mockContext)

local join = Framework.Dash.join

local MaterialInformation = require(script.Parent.MaterialInformation)

return function()
	local TestMaterial

	local function createTestElement(props: {}?)
		local materialInformationProps: MaterialInformation.Props = join({
			OpenPrompt = function(type: _Types.MaterialPromptType) end
		}, props or {})

		return mockContext({
			MaterialInformation = Roact.createElement(MaterialInformation, materialInformationProps)
		})
	end

	beforeEach(function()
		TestMaterial = {
			IsBuiltin = true,
			Material = Enum.Material.Plastic,
			MaterialPath = { "Plastic" },
			MaterialType = "Base",
			MaterialVariant = Instance.new("MaterialVariant")
		}
	end)

	afterEach(function()
		if TestMaterial.MaterialVariant then
			TestMaterial.MaterialVariant:Destroy()
		end
		TestMaterial = nil
	end)

	it("should create and destroy without errors", function()
		local element = createTestElement()
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)

	it("should render builtin material correctly", function()
		local container = Instance.new("Folder")
		local element = createTestElement({
			MockMaterial = TestMaterial,
		})
		local instance = Roact.mount(element, container)

		local main = container:FindFirstChildOfClass("Frame")
		expect(main).to.be.ok()
		Roact.unmount(instance)
	end)

	it("should render variant material correctly", function()
		TestMaterial.IsBuiltin = false
		TestMaterial.MaterialVariant:Destroy()
		TestMaterial.MaterialVariant = nil

		local container = Instance.new("Folder")
		local element = createTestElement({
			MockMaterial = TestMaterial,
		})
		local instance = Roact.mount(element, container)

		local main = container:FindFirstChildOfClass("Frame")
		expect(main).to.be.ok()
		Roact.unmount(instance)
	end)
end
