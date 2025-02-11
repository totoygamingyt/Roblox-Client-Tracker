--!nonstrict
return function()
	local CorePackages = game:GetService("CorePackages")
	local Roact = require(CorePackages.Roact)

	local ReportConfirmationContainer = require(script.Parent.ReportConfirmationContainer)
	local simpleMountFrame = require(game.CoreGui.RobloxGui.Modules.NotForProductionUse.UnitTestHelpers.simpleMountFrame)

	local noOp = function()
	end

	describe("lifecycle", function()
		it("SHOULD mount and render without issue", function(context)
			local _, cleanup = simpleMountFrame(Roact.createElement(ReportConfirmationContainer, {
				player = {
					Name = "TheStuff",
					DisplayName = "Stuff",
					UserId = 1,
				},

				voiceChatServiceManager = {
					participants = {},
				},

				closeMenu = noOp,
			}))
			cleanup()
		end)
	end)
end
