return function()
	local Plugin = script.Parent.Parent.Parent.Parent
	local Roact = require(Plugin.Packages.Roact)
	local mockContext = require(Plugin.Src.Util.mockContext)

	local LabeledElementList = require(script.Parent.LabeledElementList)

	local getText = function(key: string)
		return key
	end
	local renderContent = function(key: string)
		return nil
	end

	local function createTestElement(props: LabeledElementList.Props?)
		props = props or {
			GetText = getText,
			Items = { "Item" },
			RenderContent = renderContent,
		}

		return mockContext({
			LabeledElementList = Roact.createElement(LabeledElementList, props)
		})
	end

	it("should create and destroy without errors", function()
		local element = createTestElement()
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)

	it("should render correctly", function()
		local container = Instance.new("Folder")
		local element = createTestElement({
			GetText = getText,
			Items = { "Item" },
			LayoutOrder = 1,
			RenderContent = renderContent,
		})
		local instance = Roact.mount(element, container)

		local main = container:FindFirstChildOfClass("Frame")
		expect(main).to.be.ok()
		Roact.unmount(instance)
	end)
end
