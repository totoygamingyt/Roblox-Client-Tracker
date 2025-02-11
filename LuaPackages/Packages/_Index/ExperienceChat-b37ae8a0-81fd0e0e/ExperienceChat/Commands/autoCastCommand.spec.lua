local TextChatService = game:GetService("TextChatService")
local ExperienceChat = script:FindFirstAncestor("ExperienceChat")
local Packages = ExperienceChat.Parent
local globals = require(Packages.Dev.Jest).Globals
local expect = globals.expect
local context = require(ExperienceChat.context)

local autoCastCommand = require(script.Parent.autoCastCommand)

return function()
	describe("autoCastCommand", function()
		beforeAll(function(c)
			local textChannel = Instance.new("TextChannel")
			textChannel.Parent = TextChatService
			local player = game.Players.LocalPlayer
			c.textSource = textChannel:AddUserAsync(player.UserId)

			context.store = "mockStore"

			c.performAutoCast = function(mockCommand, message)
				return autoCastCommand(mockCommand, c.textSource.UserId, message)
					:andThen(function()
						return true
					end)
					:catch(function()
						return false
					end)
			end
		end)

		describe("WHEN alias does not match", function()
			it("SHOULD return Promise.reject when metadata contains Failure", function(c)
				local mockCommand = {
					name = "mockCommand",
					alias = { "/random" },
					clientRun = function()
						return {
							metadata = "Failure",
						}
					end,
				}
				local result = nil
				c.performAutoCast(mockCommand, "/w Player1"):andThen(function(arg)
					result = arg
				end)

				expect(result).toEqual(false)
			end)
		end)

		it("SHOULD return Promise.reject when metadata contains Success", function(c)
			local mockCommand = {
				name = "mockCommand",
				alias = { "/random" },
				clientRun = function()
					return {
						metadata = "Success",
					}
				end,
			}
			local result = nil
			c.performAutoCast(mockCommand, "/w Player1"):andThen(function(arg)
				result = arg
			end)

			expect(result).toEqual(false)
		end)

		describe("WHEN alias does match", function()
			it("SHOULD return Promise.reject when metadata contains Failure", function(c)
				local mockCommand = {
					name = "mockCommand",
					alias = { "/w" },
					clientRun = function()
						return {
							metadata = "Failure",
						}
					end,
				}
				local result = nil
				c.performAutoCast(mockCommand, "/w Player1"):andThen(function(arg)
					result = arg
				end)

				expect(result).toEqual(false)
			end)
		end)

		it("SHOULD return Promise.resolve when metadata contains Success", function(c)
			local mockCommand = {
				name = "mockCommand",
				alias = { "/w" },
				clientRun = function()
					return {
						metadata = "Success",
					}
				end,
			}
			local result = nil
			c.performAutoCast(mockCommand, "/w Player1"):andThen(function(arg)
				result = arg
			end)

			expect(result).toEqual(true)
		end)
	end)
end
