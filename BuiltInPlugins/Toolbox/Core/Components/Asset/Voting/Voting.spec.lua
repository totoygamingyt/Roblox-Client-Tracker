return function()
	local Plugin = script.Parent.Parent.Parent.Parent.Parent

	local Packages = Plugin.Packages
	local Roact = require(Packages.Roact)

	local MockWrapper = require(Plugin.Core.Util.MockWrapper)

	local Voting = require(Plugin.Core.Components.Asset.Voting.Voting)

	local votes = { { 0, 0 }, { 50, 0 }, { 0, 50 }, { 80, 20 } }

	local function createTestVoting(upVotes, downVotes, container, name)
		local element = Roact.createElement(MockWrapper, {}, {
			Voting = Roact.createElement(Voting, {
				voting = {
					UpVotes = upVotes,
					DownVotes = downVotes,
					ShowVotes = true,
					VoteCount = upVotes + downVotes,
					UpVotePercent = upVotes / (upVotes + downVotes),
				},
			}),
		})

		return Roact.mount(element, container or nil, name or "")
	end

	it("should create and destroy without errors", function()
		local instance = createTestVoting(150, 10)
		Roact.unmount(instance)
	end)

	itSKIP("should have a bar showing ratio of up to down votes", function()
		for _, voteTotals in ipairs(votes) do
			local upVotes = voteTotals[1]
			local downVotes = voteTotals[2]
			local totalVotes = upVotes + downVotes
			local ratio = (totalVotes ~= 0) and upVotes / totalVotes or 1

			local container = Instance.new("Folder")
			local instance = createTestVoting(upVotes, downVotes, container, "Voting")
			local ratioBar = container.Voting.VoteBar.Background.UpVotes
			local size = ratioBar.Size.X.Scale
			expect(math.abs(size - ratio) <= 0.01).to.equal(true)
			Roact.unmount(instance)
		end
	end)
end
