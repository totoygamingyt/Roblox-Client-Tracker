--!strict
type Array<T> = { [number]: T }

return function()
	local FFlagToolboxImmediateEvents = game:GetFastFlag("ToolboxImmediateEvents")

	local AssetAnalytics = require(script.Parent.AssetAnalytics) :: any

	local SEARCH_ID = "4581e024-c0f4-4d22-a107-18282b426833"

	local function getStubPageInfo()
		return {
			searchTerm = "abc",
			targetPage = 1,
			searchId = SEARCH_ID,
			categoryName = "MyModels",
			categories = {
				{
					category = "MyModelsExceptPackage",
					name = "MyModels",
					ownershipType = 1,
					assetType = 0,
				},
			},
			sortIndex = 1,
			sorts = {
				{
					sort = "Relevance",
					name = "Relevance",
				},
			},
		}
	end

	local function getStubAnalyticsContextInfo()
		return {
			category = "Studio",
			currentCategory = "MyModelsExceptPackage",
			page = 1,
			sort = "Relevance",
			searchId = SEARCH_ID,
			searchKeyword = "abc",
			toolboxTab = "Inventory",
		}
	end

	local function getStubAssets(): Array<any>
		return {
			{
				Asset = {
					Id = 123,
					TypeId = Enum.AssetType.Model.Value,
				},
				Creator = {},
			},
			{
				Asset = {
					Id = 124,
					TypeId = Enum.AssetType.Model.Value,
				},
				Creator = {},
			},
		}
	end

	it("getAssetCategoryName", function()
		expect(AssetAnalytics.getAssetCategoryName(Enum.AssetType.Model.Value)).to.equal("Model")
		expect(AssetAnalytics.getAssetCategoryName(-1)).to.equal("")
	end)

	it("logImpression", function()
		local stubPageInfo = getStubPageInfo()
		local assets = getStubAssets()

		local assetAnalytics = AssetAnalytics.mock()
		local stubSenders: any = assetAnalytics.senders
		local sendEventDeferredCalls = stubSenders.sendEventDeferredCalls

		-- luau can't figure this out without an explicit cast
		local stubAnalyticsContextInfo: any
		stubAnalyticsContextInfo = getStubAnalyticsContextInfo()
		stubAnalyticsContextInfo.searchId = nil
		-- Ignores assets with no context
		assetAnalytics:logImpression(assets[1], stubAnalyticsContextInfo)
		expect(#sendEventDeferredCalls).to.equal(0)

		stubAnalyticsContextInfo.searchId = SEARCH_ID

		-- Logs an impression for a search
		assetAnalytics:logImpression(assets[1], stubAnalyticsContextInfo)
		expect(#sendEventDeferredCalls).to.equal(1)
		expect(sendEventDeferredCalls[1][1]).to.equal("studio")
		expect(sendEventDeferredCalls[1][2]).to.equal("Marketplace")
		expect(sendEventDeferredCalls[1][3]).to.equal("MarketplaceAssetImpression")
		expect(sendEventDeferredCalls[1][4].assetID).to.equal(tostring(assets[1].Asset.Id))
		expect(sendEventDeferredCalls[1][4].category).to.equal("Studio")
		expect(sendEventDeferredCalls[1][4].currentCategory).to.equal("MyModelsExceptPackage")

		expect(sendEventDeferredCalls[1][4].page).to.equal("1")
		expect(sendEventDeferredCalls[1][4].assetType).to.equal("Model")

		-- Does not log an impression twice for the same search
		assetAnalytics:logImpression(assets[1], stubAnalyticsContextInfo)
		expect(#sendEventDeferredCalls).to.equal(1)

		-- Logs a new impression for a different asset in the same search
		assetAnalytics:logImpression(assets[2], stubAnalyticsContextInfo)
		expect(#sendEventDeferredCalls).to.equal(2)

		-- Logs a new impression if the asset is seen in a new search
		stubAnalyticsContextInfo.searchId = "foo"
		assetAnalytics:logImpression(assets[1], stubAnalyticsContextInfo)
		expect(#sendEventDeferredCalls).to.equal(3)
	end)

	it("logPreview", function()
		local stubPageInfo = getStubPageInfo()
		local assets = getStubAssets()

		local stubAnalyticsContextInfo = getStubAnalyticsContextInfo()

		local assetAnalytics = AssetAnalytics.mock()
		local stubSenders: any = assetAnalytics.senders
		local sendEventDeferredCalls = stubSenders.sendEventDeferredCalls

		-- Ignores assets with no context
		assetAnalytics:logPreview(assets[1], stubAnalyticsContextInfo)
		expect(#sendEventDeferredCalls).to.equal(1)
		expect(sendEventDeferredCalls[1][1]).to.equal("studio")
		expect(sendEventDeferredCalls[1][2]).to.equal("Marketplace")
		expect(sendEventDeferredCalls[1][3]).to.equal("MarketplaceAssetPreview")
		expect(sendEventDeferredCalls[1][4].assetID).to.equal(tostring(assets[1].Asset.Id))
		expect(sendEventDeferredCalls[1][4].currentCategory).to.equal("MyModelsExceptPackage")
		expect(sendEventDeferredCalls[1][4].category).to.equal("Studio")
		expect(sendEventDeferredCalls[1][4].page).to.equal("1")
		expect(sendEventDeferredCalls[1][4].assetType).to.equal("Model")
	end)

	describe("logInsert", function()
		local oldDelays
		local delays

		local oldSchedule
		local scheduleStub
		local scheduleCalls: Array<any>

		-- TODO STM-151: Re-enable Luau Type Checks when Luau bugs are fixed
		local assetAnalytics: any
		local sendCalls

		local insertionMethod = "ClickInsert"

		local stubParent
		local stubInstance

		local function runScheduleTo(seconds: number)
			local n = #scheduleCalls
			for i = 1, n do
				local job: any = scheduleCalls[i]
				if job and job[1] <= seconds then
					job[2]()
					scheduleCalls[i] = nil
				end
			end
		end

		beforeEach(function()
			oldDelays = AssetAnalytics.InsertRemainsCheckDelays
			delays = { 30, 600 }
			AssetAnalytics.InsertRemainsCheckDelays = delays

			oldSchedule = AssetAnalytics.schedule
			scheduleCalls = {}
			scheduleStub = function(...)
				table.insert(scheduleCalls, { ... })
			end
			AssetAnalytics.schedule = scheduleStub

			assetAnalytics = AssetAnalytics.mock()

			local stubSenders: any = assetAnalytics.senders
			sendCalls = if FFlagToolboxImmediateEvents then stubSenders.sendEventImmediatelyCalls else stubSenders.sendEventDeferredCalls

			stubInstance = Instance.new("Part")
			stubParent = Instance.new("Model")
			stubInstance.Parent = stubParent
		end)

		afterEach(function()
			AssetAnalytics.InsertRemainsCheckDelays = oldDelays
			AssetAnalytics.schedule = oldSchedule

			if stubParent then
				stubParent:Destroy()
			end
		end)

		it("logs and schedules nothing if asset is not trackable", function()
			local assets = getStubAssets()

			-- luau can't figure this out without an explicit cast
			local stubAnalyticsContextInfo: any
			stubAnalyticsContextInfo = getStubAnalyticsContextInfo()
			stubAnalyticsContextInfo.searchId = nil
			assetAnalytics:logInsert(assets[1], insertionMethod, stubInstance, stubAnalyticsContextInfo)

			expect(#sendCalls).to.equal(0)
			expect(#scheduleCalls).to.equal(0)
		end)

		describe("with trackable asset context", function()
			local asset

			beforeEach(function()
				local stubPageInfo = getStubPageInfo()
				local assets = getStubAssets()
				
				asset = assets[1]
			end)

			it("schedules nothing if instance is not passed", function()
				local stubAnalyticsContextInfo = getStubAnalyticsContextInfo()
				assetAnalytics:logInsert(asset, insertionMethod, nil, stubAnalyticsContextInfo)

				expect(#sendCalls).to.equal(1)
				expect(#scheduleCalls).to.equal(0)
			end)

			it("logs insert and schedules and logs remains events", function()
				local stubAnalyticsContextInfo = getStubAnalyticsContextInfo()
				assetAnalytics:logInsert(asset, insertionMethod, stubInstance, stubAnalyticsContextInfo)


				expect(#sendCalls).to.equal(1)
				expect(sendCalls[1][1]).to.equal("studio")
				expect(sendCalls[1][2]).to.equal("Marketplace")
				expect(sendCalls[1][3]).to.equal("MarketplaceInsert")
				expect(sendCalls[1][4].assetID).to.equal(tostring(asset.Asset.Id))
				expect(sendCalls[1][4].method).to.equal(insertionMethod)

				expect(#scheduleCalls).to.equal(#delays)
				expect(scheduleCalls[1][1]).to.equal(delays[1])
				expect(scheduleCalls[2][1]).to.equal(delays[2])

				-- Run all scheduled tracks
				runScheduleTo(delays[#delays])
				expect(#sendCalls).to.equal(3)

				expect(sendCalls[2][1]).to.equal("studio")
				expect(sendCalls[2][2]).to.equal("Marketplace")

				expect(sendCalls[2][3]).to.equal("InsertRemains" .. tostring(delays[1]))
				expect(sendCalls[2][4].assetID).to.equal(tostring(asset.Asset.Id))
				expect(sendCalls[2][4].method).to.equal(insertionMethod)

				expect(sendCalls[3][1]).to.equal("studio")
				expect(sendCalls[3][2]).to.equal("Marketplace")
				expect(sendCalls[3][3]).to.equal("InsertRemains" .. tostring(delays[2]))
				expect(sendCalls[3][4].assetID).to.equal(tostring(asset.Asset.Id))
				expect(sendCalls[3][4].method).to.equal(insertionMethod)
			end)

			it("logs remains, then deleted event if deleted in interim", function()
				local stubAnalyticsContextInfo = getStubAnalyticsContextInfo()
				assetAnalytics:logInsert(asset, insertionMethod, stubInstance, stubAnalyticsContextInfo)

				expect(#sendCalls).to.equal(1)
				expect(sendCalls[1][1]).to.equal("studio")
				expect(sendCalls[1][2]).to.equal("Marketplace")
				expect(sendCalls[1][3]).to.equal("MarketplaceInsert")
				expect(sendCalls[1][4].assetID).to.equal(tostring(asset.Asset.Id))
				expect(sendCalls[1][4].method).to.equal(insertionMethod)

				expect(#scheduleCalls).to.equal(#delays)
				expect(scheduleCalls[1][1]).to.equal(delays[1])
				expect(scheduleCalls[2][1]).to.equal(delays[2])

				-- Run the first scheduled track
				runScheduleTo(delays[1])
				expect(#sendCalls).to.equal(2)
				expect(sendCalls[2][1]).to.equal("studio")
				expect(sendCalls[2][2]).to.equal("Marketplace")
				expect(sendCalls[2][3]).to.equal("InsertRemains" .. tostring(delays[1]))
				expect(sendCalls[2][4].assetID).to.equal(tostring(asset.Asset.Id))
				expect(sendCalls[2][4].method).to.equal(insertionMethod)

				-- Destroy the instance and run to the next scheduled track, which should be a deleted event
				stubInstance:Destroy()
				runScheduleTo(delays[2])
				expect(#sendCalls).to.equal(3)
				expect(sendCalls[3][1]).to.equal("studio")
				expect(sendCalls[3][2]).to.equal("Marketplace")
				expect(sendCalls[3][3]).to.equal("InsertDeleted" .. tostring(delays[2]))
				expect(sendCalls[3][4].assetID).to.equal(tostring(asset.Asset.Id))
				expect(sendCalls[3][4].method).to.equal(insertionMethod)
			end)

			it("only logs a single event for multiple root-level instances", function()
				local instances: Array<any> = { stubInstance, Instance.new("Part") }
				local stubAnalyticsContextInfo = getStubAnalyticsContextInfo()
				assetAnalytics:logInsert(asset, insertionMethod, instances, stubAnalyticsContextInfo)

				expect(#sendCalls).to.equal(1)
				expect(#scheduleCalls).to.equal(#delays)

				runScheduleTo(delays[#delays])
				expect(#sendCalls).to.equal(3)
			end)
		end)
	end)
end
