--!strict
local Plugin = script:FindFirstAncestor("Toolbox")

local Packages = Plugin.Packages
local Framework = require(Packages.Framework)
local Dash = Framework.Dash
local LuauPolyfill = require(Packages.LuauPolyfill)
local Set = LuauPolyfill.Set
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array

local AssetQuotaTypes = require(Plugin.Core.Types.AssetQuotaTypes)
local AssetSubTypes = require(Plugin.Core.Types.AssetSubTypes)
local HomeTypes = require(Plugin.Core.Types.HomeTypes)
local Category = require(Plugin.Core.Types.Category)
local Url = require(Plugin.Libs.Http.Url)

local wrapStrictTable = require(Plugin.Core.Util.wrapStrictTable)
local getPlaceId = require(Plugin.Core.Util.getPlaceId)

local FFlagToolboxEnableAssetConfigPhoneVerification = game:GetFastFlag("ToolboxEnableAssetConfigPhoneVerification")
local FIntCanManageLuaRolloutPercentage = game:DefineFastInt("CanManageLuaRolloutPercentage", 0)
local FFlagInfiniteScrollerForVersions2 = game:getFastFlag("InfiniteScrollerForVersions2")
local FFlagToolboxUseQueryForCategories2 = game:GetFastFlag("ToolboxUseQueryForCategories2")
local FFlagToolboxUseGetVote = game:GetFastFlag("ToolboxUseGetVote")
local FFlagStudioPluginsUseBedev2Endpoint = game:GetFastFlag("StudioPluginsUseBedev2Endpoint")
local FFlagToolboxSwitchVerifiedEndpoint = require(Plugin.Core.Util.getFFlagToolboxSwitchVerifiedEndpoint)
local FFlagToolboxAssetConfigurationVerifiedPrice = game:GetFastFlag("ToolboxAssetConfigurationVerifiedPrice")

local Urls = {}

local GET_ASSETS = Url.BASE_URL .. "IDE/Toolbox/Items?"
local GET_ASSETS_DEVELOPER = Url.DEVELOP_URL .. "v1/toolbox/items?"
local GET_ASSETS_CREATIONS = Url.ITEM_CONFIGURATION_URL .. "v1/creations/get-assets?"
local GET_ASSETS_CREATION_DETAILS = Url.ITEM_CONFIGURATION_URL .. "v1/creations/get-asset-details"
local GET_USER = Url.API_URL .. "users/%d"
local GET_GROUP = Url.GROUP_URL .. "v0/groups/%d"
local GET_METADATA = Url.ITEM_CONFIGURATION_URL .. "v1/metadata"
local GET_UPLOAD_CATALOG_ITEM = Url.PUBLISH_URL .. "v1/assets/upload"
local POST_UPLOAD_ASSET_THUMBNAIL = Url.PUBLISH_URL .. "v1/assets/%d/thumbnail"
local GET_CONFIG_CATALOG_ITEM = Url.DEVELOP_URL .. "v1/assets/%d"
local GET_CONFIGURE_SALES = Url.ITEM_CONFIGURATION_URL .. "v1/assets/%d/release"
local GET_UPDATE_SALES = Url.ITEM_CONFIGURATION_URL .. "v1/assets/%d/update-price"
local Get_THUMBNAIL_STATUS = Url.THUMBNAIL_URL .. "v1/assets?"

local POST_VOTE = Url.BASE_URL .. "voting/vote"
local INSERT_ASSET = Url.BASE_URL .. "IDE/Toolbox/InsertAsset?"
local GET_MANAGEABLE_GROUPS = Url.DEVELOP_URL .. "v1/user/groups/canmanage"

local GET_PLUGIN_INFO = Url.APIS_URL .. "studio-plugin-api/v1/plugins?"
local DEPRECATED_GET_PLUGIN_INFO = Url.DEVELOP_URL .. "v1/plugins?"

local ASSET_ID_STRING = "rbxassetid://%d"
local ASSET_ID_PATH = "asset/?"
local ASSET_ID = Url.BASE_URL .. ASSET_ID_PATH
local ASSET_GAME_ASSET_ID = Url.GAME_ASSET_URL .. ASSET_ID_PATH

local ASSET_THUMBNAIL = Url.GAME_ASSET_URL .. "asset-thumbnail/image?"

local RBXTHUMB_BASE_URL = "rbxthumb://type=%s&id=%d&w=%d&h=%d"

local USER_SEARCH = Url.BASE_URL .. "search/users/results?"
local USER_THUMBNAIL = Url.BASE_URL .. "headshot-thumbnail/image?"

local CATALOG_V1_BASE = Url.CATALOG_URL .. "v1%s"
local FAVORITE_COUNT_BASE = "/favorites/assets/%d/count"
local GET_FAVORITED_BASE = "/favorites/users/%d/assets/%d/favorite"
local POST_FAVORITED_BASE = "/favorites/users/%d/assets/%d/favorite"
local DELETE_FAVORITE_BASE = "/favorites/users/%d/assets/%d/favorite"

local GET_VERSION_HISTORY_BASE = Url.DEVELOP_URL .. "v1/assets/%s/saved-versions"
local GET_VERSION_HISTORY_PAGE_BASE = Url.DEVELOP_URL .. "v1/assets/%s/saved-versions?cursor=%s"
local POST_REVERT_HISTORY_BASE = Url.DEVELOP_URL .. "v1/assets/%s/revert-version?"
local GET_ASSET_CONFIG = Url.DEVELOP_URL .. "v1/assets?"
local GET_ASSET_GROUP = Url.DEVELOP_URL .. "/v1/groups/%s"

local POST_UPLOAD_ANIMATION_BASE = Url.BASE_URL .. "ide/publish/uploadnewanimation?"
local POST_OVERWRITE_ANIMATION_BASE = Url.BASE_URL .. "ide/publish/uploadexistinganimation?"
local VALIDATE_ANIMATION_BASE = Url.BASE_URL .. "/studio/animations/validateId?"

local PATCH_ASSET_BASE = Url.DEVELOP_URL .. "v1/assets/%s?"
local POST_UPLOAD_ASSET_BASE = Url.DATA_URL .. "Data/Upload.ashx?"

local GET_MY_GROUPS = Url.GROUP_URL .. "v2/users/%%20%%20%s/groups/roles"
local GET_IS_VERIFIED_CREATOR = Url.DEVELOP_URL .. "v1/user/is-verified-creator"
local GET_GROUP_ROLE_INFO = Url.GROUP_URL .. "v1/groups/%s/roles"

local GET_USER_FRIENDS_URL = Url.FRIENDS_URL .. "v1/users/%d/friends"
local ROBUX_PURCHASE_URL = Url.BASE_URL .. "upgrades/robux"
local ROBUX_BALANCE_URL = Url.ECONOMY_URL .. "v1/users/%d/currency"

local CAN_MANAGE_ASSET_URL = Url.API_URL .. "users/%d/canmanage/%d"
local CAN_MANAGE_ASSET_DEVELOP_URL = Url.DEVELOP_URL .. "v1/user/%d/canmanage/%d"
local ASSET_PURCHASE_URLV2 = Url.ECONOMY_URL .. "/v2/user-products/%d/purchase"

-- Package Permissions URLs
local POST_PACKAGE_METADATA = Url.APIS_URL .. "packages-api/v1/packages/assets/versions/metadata/get"

-- Asset Permissions URLs
local ASSET_PERMISSIONS = Url.APIS_URL .. "asset-permissions-api/v1/assets/%s/permissions"
local ASSET_CHECK_PERMISSIONS = Url.APIS_URL .. "asset-permissions-api/v1/assets/check-actions"

local GET_TAGS_PREFIX_SEARCH = Url.ITEM_CONFIGURATION_URL .. "v1/tags/prefix-search?"
local GET_ITEM_TAGS_METADATA = Url.ITEM_CONFIGURATION_URL .. "v1/item-tags/metadata"
local GET_ITEM_TAGS = Url.ITEM_CONFIGURATION_URL .. "v1/item-tags?"
local ADD_ASSET_TAG = Url.ITEM_CONFIGURATION_URL .. "v1/item-tags"
local DELETE_ITEM_TAG = Url.ITEM_CONFIGURATION_URL .. "v1/item-tags/%s"

local TOOLBOX_SERVICE_URL = Url.APIS_URL .. "toolbox-service/v1"
local GET_TOOLBOX_ITEMS = Url.APIS_URL .. "toolbox-service/v1/%s?"
local GET_ITEM_DETAILS = Url.APIS_URL .. "toolbox-service/v1/items/details?"

local GET_VOTE = FFlagToolboxUseGetVote and TOOLBOX_SERVICE_URL .. "/voting/vote?"

local AVATAR_ASSETS_GET_UPLOAD_FEE = Url.ITEM_CONFIGURATION_URL .. "v1/avatar-assets/%s/get-upload-fee"
local AVATAR_ASSETS_UPLOAD = Url.ITEM_CONFIGURATION_URL .. "v1/avatar-assets/%s/upload"
local ASSET_TYPE_AGENTS = Url.ITEM_CONFIGURATION_URL .. "v1/asset-types/%s/agents?"

local AUTOCOMPLETE = Url.APIS_URL .. "autocomplete-studio/v2/suggest?"

local PUBLISHING_REQUIREMENTS_URL = Url.APIS_URL .. "marketplace-publishing-requirements-api/v1/requirements?"

local DEFAULT_ASSET_SIZE = 100
local DEFAULT_SEARCH_ROWS = 3

function Urls.constructGetItemDetails(assetIds)
	-- assetIds : array<number>
	return GET_ITEM_DETAILS .. Url.makeQueryString({
		assetIds = table.concat(assetIds, ","),
	})
end

function Urls.constructGetAssetsUrl(category, searchTerm, pageSize, page, sortType, groupId, creatorId)
	return GET_ASSETS
		.. Url.makeQueryString({
			category = category,
			keyword = searchTerm,
			num = pageSize,
			page = page,
			sort = sortType,
			groupId = groupId,
			creatorId = creatorId,
		})
end

local MIGRATED_ASSET_TYPES = Set.new({ Category.MUSIC.name, Category.SOUND_EFFECTS.name, Category.UNKNOWN_AUDIO.name })
function Urls.usesMarketplaceRoute(category: string): boolean
	return MIGRATED_ASSET_TYPES:has(category)
end

function Urls.constructGetToolboxItemsUrl(args: {
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
	useCreatorWhitelist: boolean?,
	tags: { string }?,
})
	local categoryName = args.categoryName
	local ownerId = args.ownerId
	local query = Object.assign(
		{},
		Dash.omit(args, { "categoryName", "sectionName", "ownerId", "tags" }),
		{ tags = if args.tags then Array.join(args.tags, ",") else nil },
		{ placeId = if args.sectionName then getPlaceId() else nil }
	)

	local categoryData = Category.getCategoryByName(categoryName)

	if not categoryData then
		error(string.format("Could not find categoryData for %s", categoryName))
	end

	local targetUrl
	if args.sectionName then
		local apiName = Category.ToolboxAssetTypeToEngine[categoryData.assetType].Value
		targetUrl = string.format("%s/home/%s/section/%s/assets", TOOLBOX_SERVICE_URL, apiName, args.sectionName)
	elseif Urls.usesMarketplaceRoute(categoryData.name) then
		targetUrl = string.format("%s/marketplace/%d", TOOLBOX_SERVICE_URL, categoryData.assetType)
	else
		local apiName = Category.API_NAMES[categoryName]
		local isCreationsTab = Category.getTabForCategoryName(categoryData.name) == Category.CREATIONS

		if not apiName then
			error(string.format("Could not find API_NAME for %s", categoryName))
		end

		if categoryData.ownershipType == Category.OwnershipType.MY then
			targetUrl = string.format("%s/inventory/user/%d/%s", TOOLBOX_SERVICE_URL, ownerId :: number, apiName)
		elseif categoryData.ownershipType == Category.OwnershipType.GROUP then
			if isCreationsTab then
				targetUrl = string.format("%s/creations/group/%d/%s", TOOLBOX_SERVICE_URL, ownerId :: number, apiName)
			else
				targetUrl = string.format("%s/inventory/group/%d/%s", TOOLBOX_SERVICE_URL, ownerId :: number, apiName)
			end
		elseif categoryData.ownershipType == Category.OwnershipType.RECENT then
			targetUrl = string.format("%s/recent/user/%d/%s", TOOLBOX_SERVICE_URL, ownerId :: number, apiName)
		else
			targetUrl = string.format("%s/%s", TOOLBOX_SERVICE_URL, apiName)
		end
	end
	-- Add values in queryParams to the query, and override the ones in the query if necessary, since queryParams will be the source of truth going forward
	if FFlagToolboxUseQueryForCategories2 and query.queryParams ~= nil then
		for key, val in pairs(query.queryParams) do
			query[key] = val
		end
	end
	local urlQueryParams = if FFlagToolboxUseQueryForCategories2
		then Url.makeQueryString(query, false, true)
		else Url.makeQueryString(query)
	if #urlQueryParams > 0 then
		targetUrl = targetUrl .. "?" .. urlQueryParams
	end
	return targetUrl
end

-- category, string, neccesary parameter.
-- keyword, string, used for searching.
-- sort, string, default to relevence.
-- creatorId, number, user id or group id.
-- num, number, how many asset per page.
-- page, number, which page are we requesting.
-- groupId, number, used to fetch group asset.
-- creatorType, number, unused, maybe will be put in use one day.
function Urls.getDevelopAssetUrl(category, keyword, sort, creatorId, num, page, groupId, creatorType)
	return GET_ASSETS_DEVELOPER
		.. Url.makeQueryString({
			category = category,
			keyword = keyword,
			num = num,
			page = page,
			sort = sort,
			groupId = groupId,
			creatorType = creatorType,
			creatorId = creatorId,
		})
end

function Urls.constructGetAssetGroupCreationsUrl(assetType, limit, cursor, isPackageExcluded, groupId)
	return string.format("%s/creations/group/%d/%s?", TOOLBOX_SERVICE_URL, groupId, assetType)
		.. Url.makeQueryString({
			limit = limit,
			cursor = cursor,
		})
end

function Urls.constructGetAssetCreationsUrl(assetType, limit, cursor, isPackageExcluded, groupId)
	return GET_ASSETS_CREATIONS
		.. Url.makeQueryString({
			assetType = assetType,
			isArchived = false,
			limit = limit,
			cursor = cursor,
			groupId = groupId,
		})
end

function Urls.constructGetAssetCreationDetailsUrl()
	return GET_ASSETS_CREATION_DETAILS
end

function Urls.constructGetCreatorInfoUrl(creatorId, creatorType)
	assert(type(creatorId) == "number")

	if creatorType == Enum.CreatorType.Group.Value then
		return GET_GROUP:format(creatorId)
	elseif creatorType == Enum.CreatorType.User.Value then
		return GET_USER:format(creatorId)
	else
		error(("Unknown creatorType '%s'"):format(creatorType))
	end
end

function Urls.constructGetMetaDataUrl()
	return GET_METADATA
end

function Urls.constructUploadCatalogItemUrl()
	return GET_UPLOAD_CATALOG_ITEM
end

function Urls.constructUploadAssetThumbnailUrl(assetId)
	return POST_UPLOAD_ASSET_THUMBNAIL:format(assetId)
end

function Urls.contuctGetThumbnailStatusUrl(assetIds)
	return Get_THUMBNAIL_STATUS
		.. Url.makeQueryString({
			assetIds = assetIds,
			format = "Png", -- Even you can't choos other option, you still need this.
			size = "150x150", -- Again, not optional here.
		})
end

function Urls.constructConfigureSalesUrl(assetId)
	return GET_CONFIGURE_SALES:format(assetId)
end

function Urls.constructUpdateSalesUrl(assetId)
	return GET_UPDATE_SALES:format(assetId)
end

function Urls.constructConfigureCatalogItemUrl(assetId)
	return GET_CONFIG_CATALOG_ITEM:format(assetId)
end

function Urls.constructGetVoteUrl(assetId, assetType)
	return GET_VOTE .. Url.makeQueryString({
		assetId = assetId,
		assetType = assetType,
	})
end

function Urls.constructPostVoteUrl()
	return POST_VOTE
end

function Urls.constructInsertAssetUrl(assetId)
	return string.format("%s/insert/asset/%d", TOOLBOX_SERVICE_URL, assetId)
end

function Urls.constructGetPluginInfoUrl(assetId)
	if FFlagStudioPluginsUseBedev2Endpoint then
		return GET_PLUGIN_INFO .. Url.makeQueryString({
			pluginIds = assetId,
		})
	else
		return DEPRECATED_GET_PLUGIN_INFO .. Url.makeQueryString({
			pluginIds = assetId,
		})
	end
end

function Urls.constructGetManageableGroupsUrl()
	return GET_MANAGEABLE_GROUPS
end

function Urls.constructAssetIdString(assetId)
	return ASSET_ID_STRING:format(assetId)
end

function Urls.constructAssetIdUrl(assetId)
	return ASSET_ID .. Url.makeQueryString({
		id = assetId,
	})
end

function Urls.constructAssetSavedVersionPageString(assetId, pageCursor)
	assert(FFlagInfiniteScrollerForVersions2)
	return (GET_VERSION_HISTORY_PAGE_BASE):format(assetId, pageCursor)
end

function Urls.constructAssetSavedVersionString(assetId)
	return (GET_VERSION_HISTORY_BASE):format(assetId)
end

function Urls.constructRevertAssetVersionString(assetId, versionNumber)
	return (POST_REVERT_HISTORY_BASE):format(assetId) .. Url.makeQueryString({
		assetVersionNumber = versionNumber,
	})
end

function Urls.constructAssetConfigDataUrl(assetId)
	return GET_ASSET_CONFIG .. Url.makeQueryString({
		assetIds = assetId,
	})
end

function Urls.constructAssetGameAssetIdUrl(assetId, assetTypeId, isPackage, assetName)
	return ASSET_GAME_ASSET_ID
		.. Url.makeQueryString({
			id = assetId,
			assetName = assetName,
		})
		.. "#"
		.. Url.makeQueryString({
			assetTypeId = assetTypeId,
			isPackage = isPackage,
		})
end

function Urls.constructAssetThumbnailUrl(assetId: number, width: number, height: number): string
	return RBXTHUMB_BASE_URL:format("Asset", tonumber(assetId) or 0, width, height)
end

function Urls.constructRBXThumbUrl(type, assetId, size)
	return RBXTHUMB_BASE_URL:format(type, tonumber(assetId) or 0, size, size)
end

function Urls.constructUserSearchUrl(searchTerm, numResults)
	return USER_SEARCH
		.. Url.makeQueryString({
			keyword = searchTerm,
			maxRows = numResults or DEFAULT_SEARCH_ROWS,
		})
end

function Urls.constructUserThumbnailUrl(userId: number, width: number?): string
	-- The URL only accepts certain sizes for thumbnails. This includes 50, 75, 100, 150, 250, 420 etc.
	width = width or DEFAULT_ASSET_SIZE

	return USER_THUMBNAIL
		.. Url.makeQueryString({
			userId = userId,
			width = width,
			height = width,
			format = "png",
		})
end

function Urls.constructFavoriteCountsUrl(assetId)
	return CATALOG_V1_BASE:format(FAVORITE_COUNT_BASE:format(assetId))
end

function Urls.constructGetFavoritedUrl(userId, assetId)
	return CATALOG_V1_BASE:format(GET_FAVORITED_BASE:format(userId, assetId))
end

function Urls.constructPostFavoriteUrl(userId, assetId)
	return CATALOG_V1_BASE:format(POST_FAVORITED_BASE:format(userId, assetId))
end

function Urls.constructDeleteFavoriteUrl(userId, assetId)
	return CATALOG_V1_BASE:format(DELETE_FAVORITE_BASE:format(userId, assetId))
end

function Urls.constructPatchAssetUrl(assetId)
	return (PATCH_ASSET_BASE):format(assetId)
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
function Urls.constructPostUploadAssetUrl(
	assetid,
	type,
	name,
	description,
	genreTypeId,
	ispublic,
	allowComments,
	groupId
)
	return POST_UPLOAD_ASSET_BASE
		.. Url.makeQueryString({
			assetid = assetid,
			type = tostring(type),
			name = tostring(name),
			description = tostring(description),
			genreTypeId = genreTypeId,
			ispublic = ispublic and "True" or "False",
			allowComments = allowComments and "True" or "False",
			groupId = groupId or "",
		})
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
function Urls.constructPostUploadAnimationUrl(type, name, description, groupId)
	return POST_UPLOAD_ANIMATION_BASE
		.. Url.makeQueryString({
			assetTypeName = tostring(type),
			name = tostring(name),
			description = tostring(description),
			AllID = tostring(1),
			ispublic = "False",
			allowComments = "True",
			isGamesAsset = "False",
			groupId = groupId or "",
		})
end

function Urls.constructValidateAnimationUrl(assetid)
	return VALIDATE_ANIMATION_BASE .. Url.makeQueryString({
		animationId = assetid,
	})
end

function Urls.constructPostOverwriteAnimationUrl(assetid)
	return POST_OVERWRITE_ANIMATION_BASE .. Url.makeQueryString({
		assetID = assetid,
	})
end

function Urls.constructOverrideAssetsUrl(assetid, type)
	return POST_UPLOAD_ASSET_BASE .. Url.makeQueryString({
		assetid = assetid,
		type = type,
	})
end

function Urls.constructGetMyGroupUrl(userId)
	return (GET_MY_GROUPS):format(tostring(userId))
end

if not FFlagToolboxSwitchVerifiedEndpoint then
	function Urls.constructIsVerifiedCreatorUrl()
		return GET_IS_VERIFIED_CREATOR
	end
end

function Urls.constructGetUserFriendsUrl(userId)
	return GET_USER_FRIENDS_URL:format(userId)
end

function Urls.constructAssetPermissionsUrl(assetId)
	return ASSET_PERMISSIONS:format(assetId)
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
function Urls.constructAssetCheckPermissionsUrl()
	return ASSET_CHECK_PERMISSIONS
end

function Urls.getRobuxPurchaseUrl()
	return ROBUX_PURCHASE_URL
end

function Urls.constructPostPackageMetadata()
	return POST_PACKAGE_METADATA
end

function Urls.constructGetRobuxBalanceUrl(userId)
	return ROBUX_BALANCE_URL:format(userId)
end

-- TODO DEVTOOLS-4290: Only used in AssetConfiguration
function Urls.constructGetGroupRoleInfoUrl(groupId)
	return GET_GROUP_ROLE_INFO:format(groupId)
end

function Urls.constructCanManageAssetUrl(assetId: number, userId: number)
	if (userId % 100) + 1 <= FIntCanManageLuaRolloutPercentage then
		return CAN_MANAGE_ASSET_DEVELOP_URL:format(userId, assetId)
	else
		return CAN_MANAGE_ASSET_URL:format(userId, assetId)
	end
end

function Urls.constructAssetPurchaseUrl(productId)
	return ASSET_PURCHASE_URLV2:format(productId)
end

function Urls.constructGetTagsPrefixSearchUrl(prefix, numberOfResults)
	return GET_TAGS_PREFIX_SEARCH .. Url.makeQueryString({
		prefix = prefix,
		numberOfResults = numberOfResults,
	})
end

function Urls.constructGetTagsMetadataUrl()
	return GET_ITEM_TAGS_METADATA
end

function Urls.constructGetAssetItemTagsUrl(assetId)
	return GET_ITEM_TAGS .. Url.makeQueryString({
		itemIds = string.format("AssetId:%d", assetId),
	})
end

function Urls.constructAddAssetTagUrl()
	return ADD_ASSET_TAG
end

function Urls.constructDeleteAssetItemTagUrl(itemTagId)
	return DELETE_ITEM_TAG:format(itemTagId)
end

function Urls.constructUploadCatalogItemFormatUrl(assetId, type, name, description, isPublic, format)
	return POST_UPLOAD_ASSET_BASE
		.. Url.makeQueryString({
			assetid = assetId,
			type = tostring(type),
			name = tostring(name),
			description = tostring(description),
			isPublic = isPublic and "True" or "False",
			format = format,
		})
end

function Urls.constructAvatarAssetsGetUploadFeeUrl(assetType)
	return AVATAR_ASSETS_GET_UPLOAD_FEE:format(assetType.Name)
end

function Urls.constructAvatarAssetsUploadUrl(assetType)
	return AVATAR_ASSETS_UPLOAD:format(assetType.Name)
end

function Urls.constructAssetTypeAgentsUrl(assetType)
	return ASSET_TYPE_AGENTS:format(assetType.Name)
		.. Url.makeQueryString({
			["requestModel.actionType"] = "Upload",
			["requestModel.agentType"] = "Group",
		})
end

function Urls.constructToolboxAutocompleteUrl(categoryName, searchTerm, numberOfResults)
	local url = AUTOCOMPLETE
		.. Url.makeQueryString({
			cat = categoryName,
			limit = numberOfResults,
			prefix = searchTerm,
		})
	return url
end

function Urls.constructGetHomeConfigurationUrl(assetType: Enum.AssetType, locale: string?)
	return string.format("%s/home/%s/configuration?", TOOLBOX_SERVICE_URL, assetType.Name)
		.. Url.makeQueryString({
			locale = locale,
			placeId = getPlaceId(),
		})
end

if FFlagToolboxEnableAssetConfigPhoneVerification or FFlagToolboxAssetConfigurationVerifiedPrice then
	function Urls.constructPublishingRequirementsUrl(
		assetId: number,
		assetType: Enum.AssetType?,
		assetSubType: AssetSubTypes.AssetSubType?,
		marketplaceType: string?
	)
		return PUBLISHING_REQUIREMENTS_URL
			.. Url.makeQueryString({
				assetId = assetId,
				assetType = if assetType then assetType.Name else nil,
				assetSubTypes = assetSubType, -- TODO: make this an array of subtypes: https://jira.rbx.com/browse/STM-2186
				marketplaceType = marketplaceType,
			})
	end
end

function Urls.getCreatorMarketplaceQuotas(
	assetType: Enum.AssetType,
	resourceType: AssetQuotaTypes.AssetQuotaResourceType
)
	return string.format(
		"%s/v1/asset-quotas?%s",
		Url.PUBLISH_URL,
		Url.makeQueryString({
			assetType = assetType.Name,
			resourceType = resourceType,
		})
	)
end

return wrapStrictTable(Urls) :: typeof(Urls)
