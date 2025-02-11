--!nonstrict
return function()

	local CorePackages = game:GetService("CorePackages")
	local Roact = require(CorePackages.Roact)

	local Root = script.Parent.Parent.Parent

	local getLocalizationContext = require(Root.Localization.getLocalizationContext)
	local Connection = script.Parent

	local TextLocalizer = require(Connection.TextLocalizer)
	local LocalizationContextProvider = require(Connection.LocalizationContextProvider)

	it("should create and destroy without errors", function()
		local textLabelRef = Roact.createRef()

		local testComponent = function(props)
			return Roact.createElement(TextLocalizer, {
				locKey = "CoreScripts.PurchasePrompt.Button.OK",
				render = function(localizedText)
					props.testCallback(localizedText)
					return Roact.createElement("TextLabel", {
						Text = localizedText,
						[Roact.Ref] = textLabelRef
					})
				end,
			})
		end

		local testString = nil
		local element = Roact.createElement(LocalizationContextProvider, {
			localizationContext = getLocalizationContext("en-us")
		}, {
			Component = Roact.createElement(testComponent, {
				testCallback = function(string)
					testString = string
				end,
			})
		})

		local instance = Roact.mount(element)

		expect(type(testString)).to.equal("string")

		expect(textLabelRef.current).to.be.ok()
		expect(textLabelRef.current:IsA("Instance")).to.be.ok()
		expect(textLabelRef.current.Text).to.equal(testString)

		Roact.unmount(instance)
	end)
end
