--!nocheck
-- TODO STM-151: Re-enable Luau Type Checks when Luau bugs are fixed
local FFlagToolboxUsePageInfoInsteadOfAssetContext = game:GetFastFlag("ToolboxUsePageInfoInsteadOfAssetContext2")
local FFlagToolboxHomeViewAnalyticsUpdate = game:GetFastFlag("ToolboxHomeViewAnalyticsUpdate")

local HttpService = game:GetService("HttpService")

local Plugin = script.Parent.Parent.Parent.Parent

local FFlagToolboxAudioDiscoveryRound2 =
	require(Plugin.Core.Util.Flags.AudioDiscovery).FFlagToolboxAudioDiscoveryRound2()

local Packages = Plugin.Packages
local Cryo = require(Packages.Cryo)
local Framework = require(Packages.Framework)
local Dash = Framework.Dash

local PageInfoHelper = require(Plugin.Core.Util.PageInfoHelper)
local getUserId = require(Plugin.Core.Util.getUserId)
local Constants = require(Plugin.Core.Util.Constants)
local DebugFlags = require(Plugin.Core.Util.DebugFlags)

local Analytics = require(script.Parent.Analytics)
local Senders = require(script.Parent.Senders)

type Array<T> = { [number]: T }
type Object<T> = { [string]: T }

type AssetContext = {
	category: string,
	toolboxTab: string,
	sort: string,
	searchKeyword: string,
	searchId: string?,
	page: number?,
	position: number?,
	pagePosition: number?,
}

export type AssetData = {
	Asset: {
		Id: number,
		TypeId: number,
	},
	-- TODO STM-151: Ideally this should be optional, but Luau type guards are not working (reported)
	Context: AssetContext,
}

type PageInfo = {
	searchTerm: string,
	targetPage: number,
	searchId: string?,
}

type TSenders = {
	sendEventDeferred: (string, string, string, Object<string>) -> any,
}

export type NavigationData = {
	navBreadcrumbs: string?,
	navSwimlane: string?,
	navSeeAll: boolean?,
	navSeeAllCategories: boolean?,
}

local AssetAnalytics = {}
AssetAnalytics.__index = AssetAnalytics

AssetAnalytics.InsertRemainsCheckDelays = { 30, 120, 600 }

local EVENT_TARGET = "studio"
local EVENT_CONTEXT = "Marketplace"

--[[
    Handles tracking analytics for the lifecycle of assets inserted from Toolbox.
]]
function AssetAnalytics.new(senders: TSenders?)
	local self = {
		-- TODO STM-49: Cleanup old search records
		_searches = {},
		senders = senders or Senders,
	}

	return setmetatable(self, AssetAnalytics)
end

--[[
    Returns an AssetAnalytics instance with stubbed out senders
]]
function AssetAnalytics.mock()
	local sendEventDeferredCalls = {}
	local stubSenders: any = {
		sendEventDeferredCalls = sendEventDeferredCalls,
		sendEventDeferred = function(...)
			table.insert(sendEventDeferredCalls, { ... })
		end,
	}
	return AssetAnalytics.new(stubSenders)
end

function AssetAnalytics.getNavigationContext(navigation: any, swimlaneCategory: string): NavigationData
	local function stackContainsView(viewName, successCallback)
		return function(view)
			if view == viewName then
				successCallback()
				return
			end
		end
	end

	local navBreadcrumbs = navigation:getBreadcrumbRoute()

	local containSeeAll = false
	table.foreach(
		navBreadcrumbs,
		stackContainsView(Constants.NAVIGATION.RESULTS, function()
			containSeeAll = true
		end)
	)

	local containSeeAllSubcategory = false
	table.foreach(
		navBreadcrumbs,
		stackContainsView(Constants.NAVIGATION.ALL_SUBCATEGORIES, function()
			containSeeAllSubcategory = true
		end)
	)

	return {
		navBreadcrumbs = HttpService:JSONEncode(navBreadcrumbs),
		navSwimlane = swimlaneCategory,
		navSeeAll = containSeeAll,
		navSeeAllSubcategory = containSeeAllSubcategory,
	}
end

function AssetAnalytics.schedule(delayS: number, callback: () -> any)
	delay(delayS, callback)
end

if not FFlagToolboxUsePageInfoInsteadOfAssetContext then
	function AssetAnalytics.addContextToAssetResults(assetResults: Array<Object<any>>, pageInfo: PageInfo)
		local context = AssetAnalytics.pageInfoToContext(pageInfo)
		for _, asset in pairs(assetResults) do
			local contextClone = Cryo.Dictionary.join(context)
			asset.Context = contextClone
		end
	end

	function AssetAnalytics.pageInfoToContext(pageInfo: PageInfo): AssetContext
		if DebugFlags.shouldDebugWarnings() and not pageInfo.searchId then
			warn("no searchId in pageInfo, analytics won't be tracked for asset")
		end

		return {
			category = "Studio",
			currentCategory = PageInfoHelper.getCategoryForPageInfo(pageInfo),
			toolboxTab = PageInfoHelper.getCurrentTab(pageInfo),
			sort = PageInfoHelper.getSortTypeForPageInfo(pageInfo),
			searchKeyword = pageInfo.searchTerm,
			page = pageInfo.targetPage,
			searchId = pageInfo.searchId,
		}
	end
end

function AssetAnalytics.getAssetCategoryName(assetTypeId: number)
	for _, item in ipairs(Enum.AssetType:GetEnumItems()) do
		if item.Value == assetTypeId then
			return item.Name
		end
	end
	return ""
end

function AssetAnalytics.isAssetTrackable(assetData: AssetData, assetAnalyticsContext)
	if FFlagToolboxUsePageInfoInsteadOfAssetContext then
		return assetData
			and assetData.Asset
			and assetData.Asset.Id
			and assetAnalyticsContext
			and assetAnalyticsContext.searchId
	else
		return assetData and assetData.Asset and assetData.Asset.Id and assetData.Context and assetData.Context.searchId
	end
end

function AssetAnalytics.getTrackingAttributes(assetData: AssetData, assetAnalyticsContext)
	local context
	local searchId
	if FFlagToolboxUsePageInfoInsteadOfAssetContext then
		local assetContext = assetData.Context or {}
		context = Cryo.Dictionary.join(assetAnalyticsContext, assetContext)
		searchId = assetAnalyticsContext.searchId
	else
		context = assetData.Context
		searchId = assetData.Context.searchId
	end

	local attributes = Cryo.Dictionary.join(context, {
		assetID = assetData.Asset.Id,
		assetType = AssetAnalytics.getAssetCategoryName(assetData.Asset.TypeId),
		-- TODO STM-49: Do we get userId for free in EventIngest?
		userID = getUserId(),
		placeID = Analytics.getPlaceId(),
		platformID = Analytics.getPlatformId(),
		clientID = Analytics.getClientId(),
		searchID = searchId,
		studioSid = Analytics.getStudioSessionId(),
		isEditMode = Analytics.getIsEditMode(),

		-- Legacy fields kept for S&D (see STM-215)
		label = assetData.Asset.Id,
		value = 0,

		isVerifiedCreator = assetData.Creator.IsVerifiedCreator,
		isEndorsed = assetData.Asset.IsEndorsed,
		hasScripts = assetData.Asset.HasScripts,
	})

	-- We track "ID" as standard
	attributes.searchId = nil

	-- Senders expects string attributes
	for key, val in pairs(attributes) do
		attributes[key] = tostring(val)
	end

	return attributes
end

--[[
    Log an impression of an asset, if the asset has not already been viewed in the current view context
    this will trigger the MarketplaceAssetImpression analytic.
]]
function AssetAnalytics:logImpression(assetData: AssetData, assetAnalyticsContext: any, navigationData: NavigationData?)
	if not AssetAnalytics.isAssetTrackable(assetData, assetAnalyticsContext) then
		return
	end

	local assetId = assetData.Asset.Id
	local searchId
	if FFlagToolboxUsePageInfoInsteadOfAssetContext then
		searchId = assetAnalyticsContext.searchId
	else
		local context = assetData.Context
		searchId = context.searchId
	end

	if not self._searches[searchId] then
		self._searches[searchId] = {
			impressions = {},
		}
	end

	local search = self._searches[searchId]

	local trackingAttributes
	if FFlagToolboxUsePageInfoInsteadOfAssetContext then
		trackingAttributes = AssetAnalytics.getTrackingAttributes(assetData, assetAnalyticsContext)
	else
		trackingAttributes = AssetAnalytics.getTrackingAttributes(assetData)
	end

	trackingAttributes = Dash.join(trackingAttributes, navigationData or {})

	if not search.impressions[assetId] then
		self.senders.sendEventDeferred(EVENT_TARGET, EVENT_CONTEXT, "MarketplaceAssetImpression", trackingAttributes)
		Analytics.incrementAssetImpressionCounter()

		search.impressions[assetId] = true
	end
end

--[[
    Log an opening of AssetPreview
]]
function AssetAnalytics:logPreview(assetData: AssetData, assetAnalyticsContext)
	if not AssetAnalytics.isAssetTrackable(assetData, assetAnalyticsContext) then
		return
	end

	self.senders.sendEventDeferred(
		EVENT_TARGET,
		EVENT_CONTEXT,
		"MarketplaceAssetPreview",
		AssetAnalytics.getTrackingAttributes(assetData, assetAnalyticsContext)
	)
end

function AssetAnalytics:logInsert(
	assetData: AssetData,
	insertionMethod: string,
	insertedInstance: Instance? | Array<Instance>?,
	assetAnalyticsContext,
	navigationData: NavigationData?
)
	if not AssetAnalytics.isAssetTrackable(assetData, assetAnalyticsContext) then
		return
	end

	local insertionAttributes = Cryo.Dictionary.join({
		method = insertionMethod,
	}, AssetAnalytics.getTrackingAttributes(assetData, assetAnalyticsContext), navigationData or {})

	self.senders.sendEventDeferred(EVENT_TARGET, EVENT_CONTEXT, "MarketplaceInsert", insertionAttributes)

	if insertedInstance == nil then
		-- We have no way of tracking whether the inserted instance remains or is deleted if it is not supplied
		-- This is the case for plugin insertions
		return
	end

	for _, delay in ipairs(AssetAnalytics.InsertRemainsCheckDelays) do
		AssetAnalytics.schedule(delay, function()
			if type(insertedInstance) == "table" then
				-- Some assets insert multiple root level instances, in which case insertedInstance may be an array
				-- In this case, we only consider the first instance.
				self:logRemainsOrDeleted(delay, insertionAttributes, insertedInstance[1])
			else
				self:logRemainsOrDeleted(delay, insertionAttributes, insertedInstance)
			end
		end)
	end
end

function AssetAnalytics:logRemainsOrDeleted(delay: number, insertionAttributes: Object<any>, insertedInstance: Instance)
	local eventNameStem = (insertedInstance and insertedInstance.Parent) and "InsertRemains" or "InsertDeleted"

	self.senders.sendEventDeferred(EVENT_TARGET, EVENT_CONTEXT, eventNameStem .. tostring(delay), insertionAttributes)
end

function AssetAnalytics:logNavigationButtonInteraction(
	eventName: string,
	searchID: string,
	searchCategory: string,
	subcategoryName: string?,
	navBreadcrumbs: table?,
	toolboxTab: string,
	assetType: number
)
	self.senders.sendEventDeferred(EVENT_TARGET, EVENT_CONTEXT, eventName, {
		searchID = searchID,
		searchCategory = searchCategory,
		subcategoryName = subcategoryName,
		navBreadcrumbs = navBreadcrumbs and HttpService:JSONEncode(navBreadcrumbs) or nil,
		toolboxTab = toolboxTab,
		assetType = assetType,
	})
end

function AssetAnalytics:logPageView(
	searchID: string,
	searchCategory: string,
	subcategoryName: string?,
	navBreadcrumbs: table,
	toolboxTab: string,
	assetType: number
)
	self:logNavigationButtonInteraction(
		"MarketplaceNavigatePageView",
		searchID,
		searchCategory,
		subcategoryName,
		navBreadcrumbs,
		toolboxTab,
		assetType
	)
end

function AssetAnalytics:logGoBack(
	searchID: string,
	searchCategory: string,
	subcategoryName: string?,
	navBreadcrumbs: table,
	toolboxTab: string,
	assetType: number
)
	self:logNavigationButtonInteraction(
		"MarketplaceNavigateViewBack",
		searchID,
		searchCategory,
		subcategoryName,
		navBreadcrumbs,
		toolboxTab,
		assetType
	)
end

if FFlagToolboxAudioDiscoveryRound2 and FFlagToolboxHomeViewAnalyticsUpdate then
	function AssetAnalytics:onCallToActionBannerClicked(creatorId: number)
		self.senders.sendEventDeferred(EVENT_TARGET, EVENT_CONTEXT, "CallToActionBannerClicked", {
			creatorId = creatorId,
		})
	end
end

return AssetAnalytics
