local Plugin = script.Parent.Parent.Parent.Parent

local AnalyticsSenders = require(Plugin.Core.Util.Analytics.Senders)

local AnalyticsTypes = require(Plugin.Core.Types.AnalyticsTypes)
local AnalyticsService = game:GetService("RbxAnalyticsService")
local DebugFlags = require(Plugin.Core.Util.DebugFlags)

local getUserId = require(Plugin.Core.Util.getUserId)

local FFlagToolboxAddVerifiedCreatorToAnalytics = game:GetFastFlag("ToolboxAddVerifiedCreatorToAnalytics")
local FFlagNewPackageAnalyticsWithRefactor2 = game:GetFastFlag("NewPackageAnalyticsWithRefactor2")
local FFlagToolboxTrackHidden = game:GetFastFlag("ToolboxTrackHidden")
local FFlagToolboxAddAnnouncementAnalytics = game:GetFastFlag("ToolboxAddAnnouncementAnalytics")

local getPlaceId = require(Plugin.Core.Util.getPlaceId)

-- TODO CLIDEVSRVS-1689: StudioSession + StudioID
local function getStudioSessionId()
	local sessionId = nil
	pcall(function()
		sessionId = AnalyticsService:GetSessionId()
	end)
	return sessionId
end

local function getClientId()
	local clientId = nil
	pcall(function()
		clientId = AnalyticsService:GetClientId()
	end)
	return clientId
end

local function getPlatformId()
	return 0
end

local Analytics = {}

local isEditMode = game:GetService("RunService"):IsEdit()
local getIsEditMode = function()
	return isEditMode
end
Analytics.getIsEditMode = getIsEditMode

Analytics.getPlaceId = getPlaceId
Analytics.getPlatformId = getPlatformId
Analytics.getClientId = getClientId
Analytics.getStudioSessionId = getStudioSessionId

function Analytics.onTermSearchedWithoutInsertion(categoryName, searchTerm)
	AnalyticsSenders.sendEventImmediately("studio", "toolbox", "termSearchedWithoutInsertion", {
		categoryName = categoryName,
		searchTerm = searchTerm,
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		userId = getUserId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onCreatorSearched(searchTerm, creatorId)
	AnalyticsSenders.sendEventImmediately("studio", "toolbox", "creatorSearched", {
		searchTerm = searchTerm,
		creatorId = creatorId,
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		userId = getUserId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onTryAsset(assetId)
	AnalyticsSenders.sendEventImmediately("studio", "toolbox", "tryAsset", {
		assetId = assetId,
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		userId = getUserId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onTryAssetFailure(assetId)
	AnalyticsSenders.sendEventImmediately("studio", "toolbox", "tryAssetFailure", {
		assetId = assetId,
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		userId = getUserId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onSearchOptionsOpened()
	AnalyticsSenders.sendEventImmediately("studio", "toolbox", "searchOptionsOpened", {
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		userId = getUserId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onCategorySelected(oldCategory, newCategory)
	AnalyticsSenders.sendEventImmediately("studio", "click", "toolboxCategorySelection", {
		oldCategory = oldCategory,
		newCategory = newCategory,
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onAssetInserted(assetId, searchTerm, assetIndex, currentCategory)
	local context = "click"
	local eventName = "toolboxInsert"

	AnalyticsSenders.sendEventImmediately("studio", context, eventName, {
		assetId = assetId,
		searchText = searchTerm,
		assetIndex = assetIndex,
		currentCategory = currentCategory,
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		placeId = getPlaceId(),
		userId = getUserId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onAssetDragInserted(assetId, searchTerm, assetIndex, currentCategory)
	local context = "drag"
	local eventName = "toolboxInsert"

	AnalyticsSenders.sendEventImmediately("studio", context, eventName, {
		assetId = assetId,
		searchText = searchTerm,
		assetIndex = assetIndex,
		currentCategory = currentCategory,
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		placeId = getPlaceId(),
		userId = getUserId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.reportDragInsertFinished(assetId, assetTypeId)
	AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "DragInsertFinished", {
		assetId = assetId,
		assetTypeId = assetTypeId,
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		placeId = getPlaceId(),
		userId = getUserId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.incrementToolboxInsertCounter(assetTypeId)
	AnalyticsSenders.reportCounter(("Studio.ToolboxInsert.%s"):format(tostring(assetTypeId)))
end

function Analytics.incrementToolboxCategoryInsertCounter(categoryName)
	AnalyticsSenders.reportCounter(("Studio.ToolboxCategoryInsert.%s"):format(tostring(categoryName)))
end

function Analytics.incrementWorkspaceInsertCounter()
	AnalyticsSenders.reportCounter("StudioWorkspaceInsertCounter")
end

function Analytics.incrementUploadAssetSuccess(assetTypeId)
	AnalyticsSenders.reportCounter(("Studio.Upload.%s.Success"):format(tostring(assetTypeId)))
end

function Analytics.incrementUploadAssetFailure(assetTypeId)
	AnalyticsSenders.reportCounter(("Studio.Upload.%s.Failure"):format(tostring(assetTypeId)))
end

function Analytics.onSoundPlayedCounter()
	AnalyticsSenders.reportCounter("Studio.ToolboxAudio.Played")
end

function Analytics.onSoundPausedCounter()
	AnalyticsSenders.reportCounter("Studio.ToolboxAudio.Paused")
end

function Analytics.sendResultToKibana(result)
	assert(FFlagNewPackageAnalyticsWithRefactor2)
	AnalyticsSenders.sendResultToKibana(result)
end

function Analytics.incrementAssetImpressionCounter()
	AnalyticsSenders.reportCounter("Studio.ToolboxAsset.Impression")
end

-- AssetPreview
function Analytics.onAssetPreviewSelected(assetId)
	AnalyticsSenders.sendEventDeferred("studio", "toolbox", "assetPreviewOpen", {
		assetId = assetId,
		clientId = getClientId(),
		userId = getUserId(),
		platformId = getPlatformId(),
		isEditMode = getIsEditMode(),
	})
end

-- time, milliseconds
function Analytics.onAssetPreviewEnded(assetId, time)
	AnalyticsSenders.sendEventDeferred("studio", "toolbox", "modelPreviewInteractionDuration", {
		assetId = assetId,
		time = time,
		clientId = getClientId(),
		userId = getUserId(),
		platformId = getPlatformId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onAssetInsertedFromAssetPreview(assetId)
	AnalyticsSenders.sendEventDeferred("studio", "toolbox", "previewInsertion", {
		assetId = assetId,
		clientId = getClientId(),
		userId = getUserId(),
		platformId = getPlatformId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onPluginButtonClickOpen()
	AnalyticsSenders.sendEventDeferred("studio", "toolbox", "MarketplaceOpen", {
		userId = getUserId(),
		placeId = getPlaceId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onPluginButtonClickClose()
	AnalyticsSenders.sendEventDeferred("studio", "toolbox", "MarketplaceClosed", {
		userId = getUserId(),
		placeId = getPlaceId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.onToolboxDisplayed()
	AnalyticsSenders.sendEventDeferred("studio", "toolbox", "MarketplaceImpression", {
		userId = getUserId(),
		placeId = getPlaceId(),
		isEditMode = getIsEditMode(),
	})
end

if FFlagToolboxTrackHidden then
	function Analytics.onToolboxHidden()
		AnalyticsSenders.sendEventDeferred("studio", "Marketplace", "MarketplaceHidden", {
			userId = getUserId(),
			placeId = getPlaceId(),
			isEditMode = getIsEditMode(),
		})
	end
end

function Analytics.onContextMenuClicked(eventName, assetId, assetTypeId, currentCategory)
	AnalyticsSenders.sendEventImmediately("studio", "Marketplace", eventName, {
		assetId = assetId,
		assetTypeId = assetTypeId,
		clientId = getClientId(),
		userId = getUserId(),
		platformId = getPlatformId(),
		studioSid = getStudioSessionId(),
		isEditMode = getIsEditMode(),
		currentCategory = currentCategory,
	})
end

function Analytics.openedFromPluginManagement()
	AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "OpenedFromPluginManagement", {
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		isEditMode = getIsEditMode(),
	})
end

function Analytics.reportAssetClicked(assetId, assetTypeId)
	AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "ReportAssetClicked", {
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		isEditMode = getIsEditMode(),
		assetId = assetId,
		assetTypeId = assetTypeId,
	})
end

function Analytics.reportMeshPartFiltered(assetId)
	AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "MeshPartFiltered", {
		studioSid = getStudioSessionId(),
		clientId = getClientId(),
		isEditMode = getIsEditMode(),
		placeId = getPlaceId(),
		assetId = assetId,
	})
end

function Analytics.onIdVerificationIconClicked(assetId)
	AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "IdVerificationIconClicked", {
		assetId = assetId,
		clientId = getClientId(),
		userId = getUserId(),
		platformId = getPlatformId(),
		studioSid = getStudioSessionId(),
		isEditMode = getIsEditMode(),
	})
end

if FFlagToolboxAddVerifiedCreatorToAnalytics then
	function Analytics.marketplaceSearch(
		keyword,
		isTopKeyword: boolean,
		searchInfo: AnalyticsTypes.SearchInfo
	)
		AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "MarketplaceSearch", {
			studioSid = getStudioSessionId(),
			clientID = getClientId(),
			isEditMode = getIsEditMode(),
			userID = getUserId(),
			ptid = getPlatformId(),
			placeID = getPlaceId(),

			searchKeyword = keyword,
			isTopKeyword = isTopKeyword,

			categoryName = searchInfo.categoryName,
			includeOnlyVerifiedCreators = searchInfo.includeOnlyVerifiedCreators,

			assetType = searchInfo.assetType,
			searchByCreatorID = searchInfo.creatorID,
			searchID = searchInfo.searchId,
			sort = searchInfo.sort,
			toolboxTab = searchInfo.toolboxTab,
		})
	end

	function Analytics.marketplaceAutocompleteSearch(
		keyword,
		prefix,
		keyCount,
		delCount,
		autocompleteShown,
		searchInfo: AnalyticsTypes.SearchInfo
	)
		AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "MarketplaceAutocompleteSearch", {
			studioSid = getStudioSessionId(),
			clientID = getClientId(),
			isEditMode = getIsEditMode(),
			userID = getUserId(),
			ptid = getPlatformId(),
			placeID = getPlaceId(),
	
			searchKeyword = keyword,
			autocompletePrefix = prefix,
			autocompleteKeyCount = keyCount,
			autocompleteDeleteCount = delCount,
			autocompleteShown = autocompleteShown,
		
			assetType = searchInfo.assetType,
			searchByCreatorID = searchInfo.creatorID,
			searchID = searchInfo.searchId,
			sort = searchInfo.sort,
			toolboxTab = searchInfo.toolboxTab,
		})
	end

else
	function Analytics.marketplaceSearch_DEPRECATED(
		keyword,
		prefix,
		keyCount,
		delCount,
		autocompleteShown,
		isTopKeyword: boolean,
		searchInfo: AnalyticsTypes.SearchInfo
	)
		AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "MarketplaceSearch", {
			studioSid = getStudioSessionId(),
			clientID = getClientId(),
			isEditMode = getIsEditMode(),
			userID = getUserId(),
			ptid = getPlatformId(),
			placeID = getPlaceId(),

			searchKeyword = keyword,
			autocompletePrefix = prefix,
			autocompleteKeyCount = keyCount,
			autocompleteDeleteCount = delCount,
			autocompleteShown = autocompleteShown,
			isTopKeyword = isTopKeyword,

			assetType = searchInfo.assetType,
			searchByCreatorID = searchInfo.creatorID,
			searchID = searchInfo.searchId,
			sort = searchInfo.sort,
			toolboxTab = searchInfo.toolboxTab,
		})
	end
end

function Analytics.onToolboxWidgetInteraction(widgetSize)
	AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "ToolboxWidgetInteraction", {
		clientId = getClientId(),
		userId = getUserId(),
		platformId = getPlatformId(),
		studioSid = getStudioSessionId(),
		isEditMode = getIsEditMode(),
		widgetWidth = widgetSize.X,
		widgetHeight = widgetSize.Y,
	})
end

if FFlagToolboxAddAnnouncementAnalytics then
	function Analytics.AnnouncementViewed(
		announcementButtonKey,
		announcementDateKey,
		announcementDescriptionKey,
		announcementHeaderKey,
		announcementLinkKey,
		announcementLinkLocation
	)
		local data = {
			announcementButtonKey = announcementButtonKey,
			announcementDateKey = announcementDateKey,
			announcementDescriptionKey = announcementDescriptionKey,
			announcementHeaderKey = announcementHeaderKey,
			announcementLinkKey = announcementLinkKey,
			announcementLinkLocation = announcementLinkLocation,
			clientId = getClientId(),
			platformId = getPlatformId(),
			studioSid = getStudioSessionId(),
			userId = getUserId(),
		}
		AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "AnnouncementViewed", data)
	end

	function Analytics.AnnouncementLinkClicked(
		announcementButtonKey,
		announcementDateKey,
		announcementDescriptionKey,
		announcementHeaderKey,
		announcementLinkKey,
		announcementLinkLocation
	)
		local data = {
			announcementButtonKey = announcementButtonKey,
			announcementDateKey = announcementDateKey,
			announcementDescriptionKey = announcementDescriptionKey,
			announcementHeaderKey = announcementHeaderKey,
			announcementLinkKey = announcementLinkKey,
			announcementLinkLocation = announcementLinkLocation,
			clientId = getClientId(),
			platformId = getPlatformId(),
			studioSid = getStudioSessionId(),
			userId = getUserId(),
		}
		AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "AnnouncementLinkClicked", data)
	end

	function Analytics.AnnouncementClosed(
		announcementButtonKey,
		announcementDateKey,
		announcementDescriptionKey,
		announcementHeaderKey,
		announcementLinkKey,
		announcementLinkLocation,
		durationBeforeClosed
	)
		local data = {
			announcementButtonKey = announcementButtonKey,
			announcementDateKey = announcementDateKey,
			announcementDescriptionKey = announcementDescriptionKey,
			announcementHeaderKey = announcementHeaderKey,
			announcementLinkKey = announcementLinkKey,
			announcementLinkLocation = announcementLinkLocation,
			durationBeforeClosed = durationBeforeClosed,
			clientId = getClientId(),
			platformId = getPlatformId(),
			studioSid = getStudioSessionId(),
			userId = getUserId(),
		}
		AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "AnnouncementClosed", data)
	end

	function Analytics.AnnouncementAcknowledged(
		announcementButtonKey,
		announcementDateKey,
		announcementDescriptionKey,
		announcementHeaderKey,
		announcementLinkKey,
		announcementLinkLocation,
		durationBeforeClosed
	)
		local data = {
			announcementButtonKey = announcementButtonKey,
			announcementDateKey = announcementDateKey,
			announcementDescriptionKey = announcementDescriptionKey,
			announcementHeaderKey = announcementHeaderKey,
			announcementLinkKey = announcementLinkKey,
			announcementLinkLocation = announcementLinkLocation,
			durationBeforeClosed = durationBeforeClosed,
			clientId = getClientId(),
			platformId = getPlatformId(),
			studioSid = getStudioSessionId(),
			userId = getUserId(),
		}
		AnalyticsSenders.sendEventImmediately("studio", "Marketplace", "AnnouncementAcknowledged", data)
	end
end

return Analytics
