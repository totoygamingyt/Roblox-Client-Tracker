--[[
	NetworkInterface

	Provides an interface between real Networking implementation and Mock one for production and test
]]
--

local Plugin = script.Parent.Parent.Parent
local Networking = require(Plugin.Libs.Http.Networking)
local Packages = Plugin.Packages
local Framework = require(Packages.Framework)
local Dash = Framework.Dash
local Promise = Framework.Util.Promise

local DebugFlags = require(Plugin.Core.Util.DebugFlags)
local PageInfoHelper = require(Plugin.Core.Util.PageInfoHelper)
local Urls = require(Plugin.Core.Util.Urls)
local Constants = require(Plugin.Core.Util.Constants)

local AssetQuotaTypes = require(Plugin.Core.Types.AssetQuotaTypes)
local AssetSubType = require(Plugin.Core.Types.AssetSubType)
local HomeTypes = require(Plugin.Core.Types.HomeTypes)
local Category = require(Plugin.Core.Types.Category)

local ToolboxUtilities = require(Plugin.Core.Util.ToolboxUtilities)

local FFlagToolboxSwitchVerifiedEndpoint = require(Plugin.Core.Util.getFFlagToolboxSwitchVerifiedEndpoint)
local FFlagToolboxEnableAssetConfigPhoneVerification = game:GetFastFlag("ToolboxEnableAssetConfigPhoneVerification")
local FIntToolboxGrantUniverseAudioPermissionsTimeoutInMS = game:GetFastInt(
	"ToolboxGrantUniverseAudioPermissionsTimeoutInMS"
)

local NetworkInterface = {}
NetworkInterface.__index = NetworkInterface

local FFlagInfiniteScrollerForVersions2 = game:getFastFlag("InfiniteScrollerForVersions2")

function NetworkInterface.new()
	local networkImp = {
		_networkImp = Networking.new(),
	}
	setmetatable(networkImp, NetworkInterface)

	return networkImp
end

local function printUrl(method, httpMethod, url, payload)
	if DebugFlags.shouldDebugUrls() then
		print(("NetworkInterface:%s()"):format(method))
		print(("\t%s %s"):format(httpMethod:upper() or "method=nil", url or "url=nil"))
		if payload then
			print(("\t%s"):format(tostring(payload)))
		end
	end
end

local function sendRequestAndRetry(requestFunc, retryData)
	retryData = retryData or {
		attempts = 0,
		time = 0,
		maxRetries = 5,
	}
	retryData.attempts = retryData.attempts + 1
	return requestFunc():catch(function(result)
		local responseCode = result["responseCode"]
		local is4xx = responseCode >= 400 and responseCode <= 499
		-- Don't retry on bad request (4xx)

		if retryData.attempts >= retryData.maxRetries or is4xx then
			-- Eventually give up
			return Promise.reject(result)
		end

		local timeToWait = 2 ^ (retryData.attempts - 1)
		wait(timeToWait)

		return sendRequestAndRetry(requestFunc, retryData)
	end)
end

function NetworkInterface:jsonEncode(data)
	return self._networkImp:jsonEncode(data)
end

function NetworkInterface:getAssets(pageInfo)
	local requestInfo = PageInfoHelper.getRequestInfo(pageInfo)

	local targetUrl = Urls.constructGetAssetsUrl(
		requestInfo.category,
		requestInfo.searchTerm,
		Constants.GET_ITEMS_PAGE_SIZE,
		requestInfo.targetPage,
		requestInfo.sortType,
		requestInfo.groupId,
		requestInfo.creatorId
	)

	return sendRequestAndRetry(function()
		printUrl("getAssets", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getToolboxItems(
	args: {
		categoryName: string,
		sectionName: string?,
		sortType: string?,
		keyword: string?,
		queryParams: HomeTypes.SubcategoryQueryParams?,
		cursor: string?,
		limit: number?,
		ownerId: number?,
		creatorType: string?,
		creatorTargetId: number?,
		minDuration: number?,
		maxDuration: number?,
		includeOnlyVerifiedCreators: boolean?,
		tags: { string }?,
		searchSource: string?,
	}
)
	local categoryName = args.categoryName

	local useCreatorWhitelist = nil

	if categoryName == Category.WHITELISTED_PLUGINS.name then
		useCreatorWhitelist = ToolboxUtilities.getShouldUsePluginCreatorWhitelist()
	end

	local targetUrl = Urls.constructGetToolboxItemsUrl(Dash.join(args, { useCreatorWhitelist = useCreatorWhitelist }))

	return sendRequestAndRetry(function()
		printUrl("getToolboxItems", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getItemDetailsAssetIds(assetIds)
	local targetUrl = Urls.constructGetItemDetails(assetIds)

	return sendRequestAndRetry(function()
		printUrl("getItemDetails", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getItemDetails(data)
	-- data = [ {"id":<long>, "itemType":"Asset"}, ... ]
	local assetIds = {}
	for _, assetInfo in ipairs(data) do
		table.insert(assetIds, assetInfo.id)
	end

	return self:getItemDetailsAssetIds(assetIds)
end

-- For now, only whitelistplugin uses this endpoint to fetch data.
function NetworkInterface:getDevelopAsset(pageInfo)
	local requestInfo = PageInfoHelper.getRequestInfo(pageInfo)

	local targetUrl = Urls.getDevelopAssetUrl(
		requestInfo.category,
		requestInfo.searchTerm,
		requestInfo.sortType,
		requestInfo.creatorId,
		Constants.GET_ITEMS_PAGE_SIZE,
		requestInfo.targetPage,
		requestInfo.groupId,
		requestInfo.creatorType
	)

	return sendRequestAndRetry(function()
		printUrl("getDevelopAsset", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

-- assetTypeOverride, used to override the assetType for requesting data. So, we don't need to deal with
-- categories and index.
function NetworkInterface:getAssetCreations(pageInfo, cursor, assetTypeOverride, groupIdOverride)
	local assetTypeName = assetTypeOverride
	local groupId = groupIdOverride
	if pageInfo then
		assetTypeName = PageInfoHelper.getBackendNameForPageInfoCategory(pageInfo)

		local categoryIsGroup = Category.categoryIsGroupAsset(pageInfo.categoryName)

		groupId = categoryIsGroup and PageInfoHelper.getGroupIdForPageInfo(pageInfo) or nil
	end

	local targetUrl = Urls.constructGetAssetCreationsUrl(
		assetTypeName,
		Constants.GET_ASSET_CREATIONS_PAGE_SIZE_LIMIT,
		cursor,
		nil,
		groupId
	)

	return sendRequestAndRetry(function()
		printUrl("getAssetCreations", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getAssetGroupCreations(pageInfo, cursor, assetTypeOverride, groupIdOverride)
	local assetTypeName = assetTypeOverride
	local groupId = groupIdOverride
	if pageInfo then
		assetTypeName = PageInfoHelper.getBackendNameForPageInfoCategory(pageInfo)

		local categoryIsGroup = Category.categoryIsGroupAsset(pageInfo.categoryName)

		groupId = categoryIsGroup and PageInfoHelper.getGroupIdForPageInfo(pageInfo) or nil
	end

	local targetUrl = Urls.constructGetAssetGroupCreationsUrl(
		assetTypeName,
		Constants.GET_ASSET_CREATIONS_PAGE_SIZE_LIMIT,
		cursor,
		nil,
		groupId
	)

	return sendRequestAndRetry(function()
		printUrl("getAssetGroupCreations", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getGroupAnimations(cursor, groupId)
	local targetUrl = Urls.constructGetAssetCreationsUrl(
		"Animation",
		Constants.GET_ASSET_CREATIONS_PAGE_SIZE_LIMIT,
		cursor,
		nil,
		groupId
	)

	return sendRequestAndRetry(function()
		printUrl("getGroupAnimations", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getAssetCreationDetails(assetIds)
	if DebugFlags.shouldDebugWarnings() and assetIds and #assetIds > Constants.GET_ASSET_CREATIONS_DETAILS_LIMIT then
		warn(
			("getAssetCreationDetails() does not support requests for more than %d assets at one time"):format(
				#assetIds
			)
		)
	end

	local targetUrl = Urls.constructGetAssetCreationDetailsUrl()

	return sendRequestAndRetry(function()
		printUrl("getAssetCreationDetails", "POST", targetUrl)
		local payload = self._networkImp:jsonEncode({ assetIds = assetIds })
		return self._networkImp:httpPostJson(targetUrl, payload)
	end)
end

function NetworkInterface:getCreatorInfo(creatorId, creatorType)
	local targetUrl = Urls.constructGetCreatorInfoUrl(creatorId, creatorType)

	return sendRequestAndRetry(function()
		printUrl("getCreatorInfo", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getMetaData()
	local targetUrl = Urls.constructGetMetaDataUrl()

	return sendRequestAndRetry(function()
		printUrl("getAccountInfo", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getVote(assetId, assetType)
	local targetUrl = Urls.constructGetVoteUrl(assetId, assetType)

	return sendRequestAndRetry(function()
		printUrl("getVote", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:postVote(assetId, bool)
	local targetUrl = Urls.constructPostVoteUrl()

	local payload = self._networkImp:jsonEncode({
		assetId = assetId,
		vote = bool,
	})

	return sendRequestAndRetry(function()
		printUrl("postVote", "POST", targetUrl, payload)
		return self._networkImp:httpPostJson(targetUrl, payload)
	end)
end

function NetworkInterface:configureSales(assetId, saleStatus, price)
	local targetUrl = Urls.constructConfigureSalesUrl(assetId)

	local payload = self._networkImp:jsonEncode({
		price = price,
		saleStatus = saleStatus,
	})

	return sendRequestAndRetry(function()
		printUrl("configureSales", "POST", targetUrl, payload)
		return self._networkImp:httpPostJson(targetUrl, payload)
	end)
end

function NetworkInterface:updateSales(assetId, price)
	local targetUrl = Urls.constructUpdateSalesUrl(assetId)

	local payload = self._networkImp:jsonEncode({
		price = price,
	})

	return sendRequestAndRetry(function()
		printUrl("updateSales", "POST", targetUrl, payload)
		return self._networkImp:httpPostJson(targetUrl, payload)
	end)
end

function NetworkInterface:postUnvote(assetId)
	local targetUrl = Urls.constructPostVoteUrl()

	local payload = self._networkImp:jsonEncode({
		assetId = assetId,
	})

	return sendRequestAndRetry(function()
		printUrl("postUnvote", "POST", targetUrl, payload)
		return self._networkImp:httpPostJson(targetUrl, payload)
	end)
end

function NetworkInterface:postInsertAsset(assetId)
	local targetUrl = Urls.constructInsertAssetUrl(assetId)
	local payload = {}

	return sendRequestAndRetry(function()
		printUrl("postInsertAsset", "POST", targetUrl, payload)
		return self._networkImp:httpPost(targetUrl, payload)
	end)
end

function NetworkInterface:getManageableGroups()
	local targetUrl = Urls.constructGetManageableGroupsUrl()

	return sendRequestAndRetry(function()
		printUrl("getManageableGroups", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getUsers(searchTerm, numResults)
	local targetUrl = Urls.constructUserSearchUrl(searchTerm, numResults)
	printUrl("getUsers", "GET", targetUrl)
	return self._networkImp:httpGetJson(targetUrl)
end

function NetworkInterface:getFavoriteCounts(assetId)
	local targetUrl = Urls.constructFavoriteCountsUrl(assetId)

	printUrl("getFavorites", "GET", targetUrl)
	return self._networkImp:httpGet(targetUrl)
end

function NetworkInterface:getFavorited(userId, assetId)
	local targetUrl = Urls.constructGetFavoritedUrl(userId, assetId)

	printUrl("getFavorited", "GET", targetUrl)
	return self._networkImp:httpGet(targetUrl)
end

-- TODO DEVTOOLS-4290: Needs to be shared
function NetworkInterface:getAssetConfigData(assetId)
	local targetUrl = Urls.constructAssetConfigDataUrl(assetId)

	printUrl("getAssetConfigData", "GET", targetUrl)
	return self._networkImp:httpGet(targetUrl)
end

-- cursor must be the valid page cursor value returned by previous
-- invocations of this function or getVersionHistory() for the given assetId.
-- cursor must not be nil.
function NetworkInterface:getVersionHistoryPage(assetId, cursor)
	assert(FFlagInfiniteScrollerForVersions2)
	assert(cursor ~= nil)
	local targetUrl = Urls.constructAssetSavedVersionPageString(assetId, cursor)

	printUrl("getVersionsHistoryNextPage", "GET", targetUrl)
	return self._networkImp:httpGet(targetUrl)
end

function NetworkInterface:getVersionsHistory(assetId)
	local targetUrl = Urls.constructAssetSavedVersionString(assetId)

	printUrl("getVersionsHistory", "GET", targetUrl)
	return self._networkImp:httpGet(targetUrl)
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
function NetworkInterface:postRevertVersion(assetId, versionNumber)
	local targetUrl = Urls.constructRevertAssetVersionString(assetId, versionNumber)

	printUrl("postRevertVersion", "POST", targetUrl)
	return self._networkImp:httpPostJson(targetUrl, {})
end

function NetworkInterface:postFavorite(userId, assetId)
	local targetUrl = Urls.constructPostFavoriteUrl(userId, assetId)

	local payload = self._networkImp:jsonEncode({
		userId = userId,
		assetId = assetId,
	})

	printUrl("postFavorite", "POST", targetUrl, payload)
	return self._networkImp:httpPostJson(targetUrl, payload)
end

function NetworkInterface:deleteFavorite(userId, assetId)
	local targetUrl = Urls.constructDeleteFavoriteUrl(userId, assetId)

	printUrl("deleteFavorite", "DELETE", targetUrl)
	return self._networkImp:httpDelete(targetUrl)
end

function NetworkInterface:uploadCatalogItem(formBodyData, boundary)
	local targetUrl = Urls.constructUploadCatalogItemUrl()

	local requestInfo = {
		Url = targetUrl,
		Method = "POST",
		Body = formBodyData,
		CachePolicy = Enum.HttpCachePolicy.None,
		Headers = {
			["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
		},
	}

	printUrl("uploadCatalogItem", "POST FORM-DATA", targetUrl, formBodyData)
	return self._networkImp:requestInternal(requestInfo):catch(function(err)
		return Promise.reject(err)
	end)
end

function NetworkInterface:uploadCatalogItemFormat(assetId, type, name, description, isPublic, format, instanceData)
	local targetUrl = Urls.constructUploadCatalogItemFormatUrl(assetId, type, name, description, isPublic, format)

	return sendRequestAndRetry(function()
		printUrl("uploadCatalogItemFormat", "POST", targetUrl, instanceData)
		return self._networkImp:httpPost(targetUrl, instanceData)
	end)
end

--multipart/form-data for uploading images to Roblox endpoints
--Moderation occurs on the web
local FORM_DATA = "--%s\r\n"
	.. "Content-Type: image/%s\r\n"
	.. 'Content-Disposition: form-data; filename="%s"; name="request.files"\r\n'
	.. "\r\n"
	.. "%s\r\n"
	.. "--%s--\r\n"

function NetworkInterface:uploadAssetThumbnail(assetId, iconFile)
	local targetUrl = Urls.constructUploadAssetThumbnailUrl(assetId)

	local contents = iconFile:GetBinaryContents()
	local name = string.lower(iconFile.Name)
	local index = string.find(name, ".", 1, true)
	local extension = string.sub(name, index + 1)
	--DEVTOOLS-3170
	-- HttpService:GenerateGuid(false)
	-- Lookinto why HttpService won't work here.
	local key = "UUDD-LRLR-BABA"
	local form = string.format(FORM_DATA, key, extension, name, contents, key)

	local requestInfo = {
		Url = targetUrl,
		Method = "POST",
		Body = form,
		CachePolicy = Enum.HttpCachePolicy.None,
		Headers = {
			["Content-Type"] = "multipart/form-data; boundary=" .. tostring(key),
		},
	}

	printUrl("uploadAssetThumbnail", "POST FORM-DATA", targetUrl, form)
	return self._networkImp:requestInternal(requestInfo):catch(function(err)
		return Promise.reject(err)
	end)
end

function NetworkInterface:getThumbnailStatus(assetId)
	local targetUrl = Urls.contuctGetThumbnailStatusUrl({ assetId })

	printUrl("getThumbnailStatus", "GET", targetUrl)
	return self._networkImp:httpGetJson(targetUrl)
end

function NetworkInterface:configureCatalogItem(assetId, patchDataTable)
	local targetUrl = Urls.constructConfigureCatalogItemUrl(assetId)

	local patchPayload = self._networkImp:jsonEncode(patchDataTable)

	local requestInfo = {
		Url = targetUrl,
		Method = "PATCH",
		Body = patchPayload,
		CachePolicy = Enum.HttpCachePolicy.None,
		Headers = {
			["Content-Type"] = "application/json",
		},
	}

	-- TODO: replace this with Networking:httpPatch
	printUrl("configureCatalogItem", "PATCH", targetUrl, patchPayload)
	return self._networkImp:requestInternal(requestInfo):catch(function(err)
		return Promise.reject(err)
	end)
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
--[[
	assetId (number, must)
	name (string, optional): Name of the asset ,
	description (string, optional): Description of the asset ,
	genres (Array[string], optional): List of genres of the asset ,
	enableComments (boolean, optional): Indicates comments enabled. ,
	isCopyingAllowed (boolean, optional): Indicates if copying is allowed. ,
	locale (string, optional),
	localName (string, optional),
	localDescription (string, optional)
]]
function NetworkInterface:patchAsset(
	assetId,
	name,
	description,
	genres,
	enableComments,
	isCopyingAllowed,
	locale,
	localName,
	localDescription
)
	local targetUrl = Urls.constructPatchAssetUrl(assetId)

	local payload = self._networkImp:jsonEncode({
		name = name,
		description = description,
		genres = genres,
		enableComments = enableComments,
		isCopyingAllowed = isCopyingAllowed,
		locale = locale,
		localName = localName,
		localDescription = localDescription,
	})

	printUrl("patchAsset", "PATCH", targetUrl, payload)
	return self._networkImp:httpPatch(targetUrl, payload)
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
-- assetId, number, defualt to 0 for new asset.
-- type, string, the asset type of the asset.
-- name, string, need to be url encoded.
-- name, string, need to be url encoded.
-- description, string, need to be url encoded.
-- genreTypeId, Id, for genre.
-- ispublic, bool
-- allowComments, bool
-- groupId, number, default to nil
-- instanceData, serialised instance, used in post body
function NetworkInterface:postUploadAsset(
	assetid,
	type,
	name,
	description,
	genreTypeId,
	ispublic,
	allowComments,
	groupId,
	instanceData
)
	local targetUrl = Urls.constructPostUploadAssetUrl(
		assetid,
		type,
		name,
		description,
		genreTypeId,
		ispublic,
		allowComments,
		groupId
	)

	printUrl("postUploadAsset", "POST", targetUrl, instanceData)
	return self._networkImp:httpPost(targetUrl, instanceData)
end

function NetworkInterface:postOverrideAsset(assetid, type, instanceData)
	local targetUrl = Urls.constructOverrideAssetsUrl(assetid, type)

	printUrl("postOverrideAsset", "POST", targetUrl)
	return self._networkImp:httpPost(targetUrl, instanceData)
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
function NetworkInterface:validateAnimation(assetid)
	local targetUrl = Urls.constructValidateAnimationUrl(assetid)
	local requestInfo = {
		Url = targetUrl,
		Method = "GET",
		CachePolicy = Enum.HttpCachePolicy.None,
		Headers = {
			["Content-Type"] = "application/json",
		},
	}

	printUrl("validateAnimation", "GET", targetUrl)
	return self._networkImp:requestInternal(requestInfo):catch(function(err)
		return Promise.reject(err)
	end)
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
function NetworkInterface:postUploadAnimation(assetid, name, description, groupId, instanceData)
	local targetUrl = Urls.constructPostUploadAnimationUrl("Animation", name, description, groupId)

	local requestInfo = {
		Url = targetUrl,
		Method = "POST",
		Body = instanceData,
		CachePolicy = Enum.HttpCachePolicy.None,
		Headers = {
			["Content-Type"] = "application/octet-stream",
		},
	}

	printUrl("uploadAnimation", "POST", targetUrl, instanceData)
	return self._networkImp:requestInternal(requestInfo):catch(function(err)
		return Promise.reject(err)
	end)
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
function NetworkInterface:postOverrideAnimation(assetid, instanceData)
	local targetUrl = Urls.constructPostOverwriteAnimationUrl(assetid)

	local requestInfo = {
		Url = targetUrl,
		Method = "POST",
		Body = instanceData,
		CachePolicy = Enum.HttpCachePolicy.None,
		Headers = {
			["Content-Type"] = "application/octet-stream",
		},
	}

	printUrl("uploadAnimation", "POST", targetUrl, instanceData)
	return self._networkImp:requestInternal(requestInfo):catch(function(err)
		return Promise.reject(err)
	end)
end

if not FFlagToolboxSwitchVerifiedEndpoint then
	-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
	function NetworkInterface:getIsVerifiedCreator()

		local targetUrl = Urls.constructIsVerifiedCreatorUrl()

		printUrl("getIsVerifiedCreator", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end
end

-- Extend this function if using an array.
function NetworkInterface:getPluginInfo(assetId)
	local targetUrl = Urls.constructGetPluginInfoUrl(assetId)

	printUrl("getPluginInfo", "GET", targetUrl)
	return self._networkImp:httpGetJson(targetUrl)
end

function NetworkInterface:getLocalUserFriends(userId)
	local targetUrl = Urls.constructGetUserFriendsUrl(userId)

	printUrl("getUserFriends", "GET", userId)
	return self._networkImp:httpGet(targetUrl)
end

function NetworkInterface:postForPackageMetadata(assetid)
	local targetUrl = Urls.constructPostPackageMetadata()

	local payload = '[{ "assetId" : ' .. assetid .. ', "assetVersionNumber" : 1 }]'
	return self._networkImp:httpPostJson(targetUrl, payload)
end

function NetworkInterface:getRobuxBalance(userId)
	local targetUrl = Urls.constructGetRobuxBalanceUrl(userId)

	printUrl("getRobuxBalance", "GET", targetUrl)
	return self._networkImp:httpGetJson(targetUrl)
end

function NetworkInterface:getCanManageAsset(assetId, userId)
	local targetUrl = Urls.constructCanManageAssetUrl(assetId, userId)

	printUrl("getCanManageAsset", "GET", targetUrl)
	return self._networkImp:httpGetJson(targetUrl)
end

function NetworkInterface:purchaseAsset(productId, info)
	local infoJson = self:jsonEncode(info)
	local targetUrl = Urls.constructAssetPurchaseUrl(productId)

	printUrl("purchaseAsset", "GET", targetUrl)
	return self._networkImp:httpPostJson(targetUrl, infoJson)
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
function NetworkInterface:getGroupRoleInfo(groupId)
	local targetUrl = Urls.constructGetGroupRoleInfoUrl(groupId)

	printUrl("getGroupRoleInfo", "GET", groupId)
	return self._networkImp:httpGet(targetUrl)
end

function NetworkInterface:grantAssetPermissions(assetId, permissions)
	local targetUrl = Urls.constructAssetPermissionsUrl(assetId)
	local putPayload = self._networkImp:jsonEncode(permissions)

	printUrl("grantAssetPermissions", "PATCH", targetUrl, putPayload)
	return self._networkImp:httpPatch(targetUrl, putPayload)
end

function NetworkInterface:grantAssetPermissionWithTimeout(assetId, payload)
	local targetUrl = Urls.constructAssetPermissionsUrl(assetId)

	local requestBody = self._networkImp:jsonEncode(payload)

	local options = {
		Url = targetUrl,
		Method = "PATCH",
		Body = requestBody,
		Headers = {
			["Content-Type"] = "application/json",
		},
		Timeout = FIntToolboxGrantUniverseAudioPermissionsTimeoutInMS,
	}

	return self._networkImp:requestInternalRaw(options)
end

function NetworkInterface:revokeAssetPermissions(assetId, permissions)
	local targetUrl = Urls.constructAssetPermissionsUrl(assetId)
	local putPayload = self._networkImp:jsonEncode(permissions)

	printUrl("revokeAssetPermissions", "DELETE", targetUrl, putPayload)
	return self._networkImp:httpDeleteWithPayload(targetUrl, putPayload)
end

function NetworkInterface:getAssetPermissions(assetId)
	local targetUrl = Urls.constructAssetPermissionsUrl(assetId)

	printUrl("getAssetPermissions", "GET", targetUrl)
	return self._networkImp:httpGetJson(targetUrl)
end

function NetworkInterface:postAssetCheckPermissions(actions, assetIds)
	local targetUrl = Urls.constructAssetCheckPermissionsUrl()

	return sendRequestAndRetry(function()
		local payload = self._networkImp:jsonEncode({ actions = actions, assetIds = assetIds })
		printUrl("postAssetCheckPermissions", "POST", targetUrl)
		return self._networkImp:httpPostJson(targetUrl, payload)
	end)
end

function NetworkInterface:tagsPrefixSearch(prefix, numberOfResults)
	local targetUrl = Urls.constructGetTagsPrefixSearchUrl(prefix, numberOfResults)

	return sendRequestAndRetry(function()
		printUrl("tagsPrefixSearch", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getTagsMetadata()
	local targetUrl = Urls.constructGetTagsMetadataUrl()

	return sendRequestAndRetry(function()
		printUrl("getTagsMetadata", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getAssetItemTags(assetId)
	local targetUrl = Urls.constructGetAssetItemTagsUrl(assetId)

	return sendRequestAndRetry(function()
		printUrl("getAssetItemTags", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:addAssetTag(assetId, tagId)
	local targetUrl = Urls.constructAddAssetTagUrl()

	local payload = self._networkImp:jsonEncode({
		itemId = string.format("AssetId:%d", assetId),
		tagId = tagId,
	})

	return sendRequestAndRetry(function()
		printUrl("addAssetTag", "POST", targetUrl, payload)
		return self._networkImp:httpPost(targetUrl, payload)
	end)
end

function NetworkInterface:deleteAssetItemTag(itemTagId)
	local targetUrl = Urls.constructDeleteAssetItemTagUrl(itemTagId)

	return sendRequestAndRetry(function()
		printUrl("deleteAssetItemTag", "DELETE", targetUrl)
		return self._networkImp:httpDelete(targetUrl)
	end)
end

function NetworkInterface:avatarAssetsGetUploadFee(assetType, formBodyData, boundary)
	local targetUrl = Urls.constructAvatarAssetsGetUploadFeeUrl(assetType)

	local requestInfo = {
		Url = targetUrl,
		Method = "POST",
		Body = formBodyData,
		CachePolicy = Enum.HttpCachePolicy.None,
		Headers = {
			["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
		},
	}

	printUrl("avatarAssetsGetUploadFee", "POST FORM-DATA", targetUrl, formBodyData)
	return self._networkImp:requestInternalRaw(requestInfo):catch(function(err)
		return Promise.reject(err)
	end)
end

function NetworkInterface:avatarAssetsUpload(assetType, formBodyData, boundary)
	local targetUrl = Urls.constructAvatarAssetsUploadUrl(assetType)

	local requestInfo = {
		Url = targetUrl,
		Method = "POST",
		Body = formBodyData,
		CachePolicy = Enum.HttpCachePolicy.None,
		Headers = {
			["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
		},
	}

	printUrl("avatarAssetsUpload", "POST FORM-DATA", targetUrl, formBodyData)
	return self._networkImp:requestInternalRaw(requestInfo):catch(function(err)
		return Promise.reject(err)
	end)
end

function NetworkInterface:getAssetTypeAgents(assetType)
	local targetUrl = Urls.constructAssetTypeAgentsUrl(assetType)

	return sendRequestAndRetry(function()
		printUrl("getAssetTypeAgents", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end)
end

function NetworkInterface:getAutocompleteResults(categoryName, searchTerm, numberOfResults)
	local targetUrl = Urls.constructToolboxAutocompleteUrl(categoryName, searchTerm, numberOfResults)
	printUrl("getAutocompleteResults", "GET", targetUrl)
	return self._networkImp:httpGetJson(targetUrl)
end

function NetworkInterface:getHomeConfiguration(assetType: Enum.AssetType, locale: string?)
	local targetUrl = Urls.constructGetHomeConfigurationUrl(assetType, locale)
	printUrl("getHomeConfiguration", "GET", targetUrl)
	return self._networkImp:httpGetJson(targetUrl)
end

function NetworkInterface:getCreatorMarketplaceQuotas(
	assetType: Enum.AssetType,
	resourceType: AssetQuotaTypes.AssetQuotaResourceType
)
	local targetUrl = Urls.getCreatorMarketplaceQuotas(assetType, resourceType)
	printUrl("getCreatorMarketplaceQuotas", "GET", targetUrl)
	return self._networkImp:httpGetJson(targetUrl)
end

if FFlagToolboxEnableAssetConfigPhoneVerification then
	function NetworkInterface:getPublishingRequirements(
		assetId: number,
		assetType: Enum.AssetType?,
		assetSubType: AssetSubType.AssetSubType?
	)
		local marketplaceType = "Creator"
		local targetUrl = Urls.constructPublishingRequirementsUrl(assetId, assetType, assetSubType, marketplaceType)
		printUrl("getPublishingRequirements", "GET", targetUrl)
		return self._networkImp:httpGetJson(targetUrl)
	end
end

export type NetworkInterface = typeof(NetworkInterface)

return NetworkInterface
