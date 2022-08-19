local Plugin = script.Parent.Parent.Parent

local Packages = Plugin.Packages
local Cryo = require(Packages.Cryo)
local Rodux = require(Packages.Rodux)

local Util = Plugin.Core.Util
local PagedRequestCursor = require(Util.PagedRequestCursor)
local LOADING_IN_BACKGROUND = require(Util.Keys).LoadingInProgress

local Actions = Plugin.Core.Actions
local SetAssetId = require(Actions.SetAssetId)
local SetUploadAssetType = require(Actions.SetUploadAssetType)
local ExtendVersionHistoryData = require(Actions.ExtendVersionHistoryData)
local SetVersionHistoryData = require(Actions.SetVersionHistoryData)
local SetAssetConfigData = require(Actions.SetAssetConfigData)
local SetCurrentScreen = require(Actions.SetCurrentScreen)
local SetScreenConfig = require(Actions.SetScreenConfig)
local AddChange = require(Actions.AddChange)
local ClearChange = require(Actions.ClearChange)
local SetAssetGroupData = require(Actions.SetAssetGroupData)
local UploadResult = require(Actions.UploadResult)
local ValidateAnimationResult = require(Actions.ValidateAnimationResult)
local NetworkError = require(Actions.NetworkError)
local SetAssetConfigTab = require(Actions.SetAssetConfigTab)
local SetOverrideAssets = require(Actions.SetOverrideAssets)
local SetAssetConfigManageableGroups = require(Actions.SetAssetConfigManageableGroups)
local SetIsVerifiedCreator = require(Actions.SetIsVerifiedCreator)
local SetLoadingPage = require(Actions.SetLoadingPage)
local UpdateOverrideAssetData = require(Actions.UpdateOverrideAssetData)
local SetCurrentPage = require(Actions.SetCurrentPage)
local SetOverrideCursor = require(Actions.SetOverrideCursor)
local SetAssetConfigThumbnailStatus = require(Actions.SetAssetConfigThumbnailStatus)
local SetGroupMetadata = require(Actions.SetGroupMetadata)
local SetOwnerUsername = require(Actions.SetOwnerUsername)
local CollaboratorSearchActions = require(Actions.CollaboratorSearchActions)
local SetCollaborators = require(Actions.SetCollaborators)
local SetIsPackage = require(Actions.SetIsPackage)
local UpdateAssetConfigData = require(Actions.UpdateAssetConfigData)
local UpdateAssetConfigStore = require(Actions.UpdateAssetConfigStore)
local SetGroupRoleInfo = require(Actions.SetGroupRoleInfo)
local SetPackagePermission = require(Actions.SetPackagePermission)
local SetTagSuggestions = require(Actions.SetTagSuggestions)
local SetFieldError = require(Actions.SetFieldError)
local SetUploadFee = require(Actions.SetUploadFee)
local SetAssetConfigAssetTypeAgents = require(Actions.SetAssetConfigAssetTypeAgents)
local SetDescendantPermissions = require(Actions.SetDescendantPermissions)
local SetPublishingRequirements = require(Actions.SetPublishingRequirements)

local FFlagInfiniteScrollerForVersions2 = game:getFastFlag("InfiniteScrollerForVersions2")
local FFlagToolboxEnableAssetConfigPhoneVerification = game:GetFastFlag("ToolboxEnableAssetConfigPhoneVerification")
local FFlagToolboxSwitchVerifiedEndpoint = require(Plugin.Core.Util.getFFlagToolboxSwitchVerifiedEndpoint)

return Rodux.createReducer({
	-- Empty table means publish new asset
	-- Otherwise we are editing existing asset.
	assetConfigData = {},
	assetGroupData = {},

	versionHistory = nil,

	-- We will use this table to track changes within assetConfig.
	-- This should be global to the assetConfig, that's why it's in the store.
	-- It's each component's duty to tell the store if a element has changed or not.
	changed = {},

	assetId = nil,
	thumbnailStatus = nil,
	instances = nil,
	sourceInstances = nil, -- original Instances used for swapping during Package Publish
	screenFlowType = nil, -- AssetConfigConstants.FLOW_TYPE.*
	assetTypeEnum = nil, -- Enum.AssetType.*
	currentScreen = nil, --AssetConfigConstants.SCREENS.*
	screenConfigs = { -- one entry per screen
		--[[
		[AssetConfigConstants.SCREENS.*] = {
		},
		--]]
	},
	allowedAssetTypesForRelease = {},
	allowedAssetTypesForUpload = {},

	currentTab = nil,

	resultsArray = {},

	manageableGroups = {},
	assetTypeAgents = {},

	isVerifiedCreator = true,

	networkError = nil,
	networkErrorAction = nil,

	-- This is a table that will hold every network request.
	-- However, not all network requests will be treated equally. Some will require us to break currrent
	-- asset config session, some of those will only require us to show user what happened.
	networkTable = {},

	-- For overrideAsset
	fetchedAll = false,
	loadingPage = 0,
	currentPage = 1,

	-- For fetching my models and plugins to override only
	overrideCursor = PagedRequestCursor.createDefaultCursor(),

	-- For Package Permissions
	groupMetadata = {},
	localUserFriends = nil,
	cachedSearchResults = {},
	searchText = "",
	success = false,
	collaborators = {},
	isPackageAsset = false,
	packagePermissions = {},

	-- For Model Publish
	descendantPermissions = {},

	iconFile = nil, -- Will be used in preview and upload result

	-- catalog tags
	tagSuggestions = {},
	latestTagSuggestionTime = 0,
	latestTagSearchQuery = "",

	publishingRequirements = if FFlagToolboxEnableAssetConfigPhoneVerification then {} else nil,
}, {

	[UpdateAssetConfigStore.name] = function(state, action)
		return Cryo.Dictionary.join(state, action.storeData)
	end,

	[SetAssetId.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			assetId = action.assetId,
		})
	end,

	[SetUploadAssetType.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			assetTypeEnum = action.assetTypeEnum,
		})
	end,

	[SetCurrentScreen.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			currentScreen = action.currentScreen,
		})
	end,

	[SetScreenConfig.name] = function(state, action)
		local newSubScreenConfig = Cryo.Dictionary.join(state.screenConfigs[action.screen], {
			[action.variable] = action.value,
		})

		local newScreenConfigs = Cryo.Dictionary.join(state.screenConfigs, {
			[action.screen] = newSubScreenConfig,
		})

		return Cryo.Dictionary.join(state, {
			screenConfigs = newScreenConfigs,
		})
	end,

	[ExtendVersionHistoryData.name] = function(state, action)
		assert(FFlagInfiniteScrollerForVersions2)
		-- The new version history consists of the old version history's *data*
		-- pre-pended to the new version history's data, but preserving the
		-- new history's other metadata.
		return Cryo.Dictionary.join(state, {
			versionHistory = {
				nextPageCursor = action.versionHistory.nextPageCursor,
				data = Cryo.List.join(state.versionHistory.data, action.versionHistory.data),
			}
		})
	end,

	[SetVersionHistoryData.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			versionHistory = action.versionHistory,
		})
	end,

	[SetAssetConfigData.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			assetConfigData = action.assetConfigData,
		})
	end,

	[UpdateAssetConfigData.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			assetConfigData = Cryo.Dictionary.join(state.assetConfigData or {}, action.assetConfigData),
		})
	end,

	[AddChange.name] = function(state, action)
		local setting = action.setting
		local value = action.value

		return Cryo.Dictionary.join(state, {
			changed = Cryo.Dictionary.join(state.changed or {}, {
				[setting] = value,
			}),
		})
	end,

	[ClearChange.name] = function(state, action)
		local setting = action.setting

		return Cryo.Dictionary.join(state, {
			changed = Cryo.Dictionary.join(state.changed or {}, {
				[setting] = Cryo.None,
			}),
		})
	end,

	[SetAssetGroupData.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			assetGroupData = action.assetGroupData,
		})
	end,

	[NetworkError.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			networkError = action.response,
			networkErrorAction = action.networkErrorAction,
		})
	end,

	[UploadResult.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			uploadSucceeded = action.uploadSucceeded,
		})
	end,

	[ValidateAnimationResult.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			validateAnimationSucceeded = action.validateAnimationSucceeded,
		})
	end,

	[SetAssetConfigTab.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			currentTab = action.tabItem,
		})
	end,

	[SetOverrideAssets.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			resultsArray = action.resultsArray,
			fetchedAll = Cryo.None,
		})
	end,

	[UpdateOverrideAssetData.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			resultsArray = Cryo.List.join(state.resultsArray, action.resultsArray),
			fetchedAll = action.fetchedAll,
		})
	end,

	[SetAssetConfigManageableGroups.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			manageableGroups = action.manageableGroups,
		})
	end,

	[SetIsVerifiedCreator.name] = if not FFlagToolboxSwitchVerifiedEndpoint then function(state, action)
		return Cryo.Dictionary.join(state, {
			isVerifiedCreator = action.isVerifiedCreator,
		})
	end else nil,

	[SetLoadingPage.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			loadingPage = action.loadingPage,
		})
	end,

	[SetCurrentPage.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			currentPage = action.currentPage,
		})
	end,

	[SetOverrideCursor.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			overrideCursor = action.overrideCursor,
		})
	end,

	[SetAssetConfigThumbnailStatus.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			thumbnailStatus = action.thumbnailStatus,
		})
	end,

	[SetGroupMetadata.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			[action.groupMetadata.Id] = {
				name = action.groupMetadata.Name,
				groupMetadata = action.groupMetadata,
			},
		})
	end,

	[SetOwnerUsername.name] = function(state, action)
		if Enum.CreatorType[state.assetConfigData.Creator.type] ~= Enum.CreatorType.User then
			return state
		end

		return Cryo.Dictionary.join(state, {
			assetConfigData = Cryo.Dictionary.join(state.assetConfigData, {
				Creator = Cryo.Dictionary.join(state.assetConfigData.Creator, {
					username = action.ownerUsername,
				}),
			}),
		})
	end,

	[CollaboratorSearchActions.LoadedLocalUserFriends.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			localUserFriends = action.success and action.friends or {},
		})
	end,

	[CollaboratorSearchActions.LoadedLocalUserGroups.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			localUserGroups = action.success and action.groups or {},
		})
	end,

	[CollaboratorSearchActions.LoadedWebResults.name] = function(state, action)
		if not state.cachedSearchResults then
			state = Cryo.Dictionary.join(state, {
				cachedSearchResults = {},
			})
		end
		return Cryo.Dictionary.join(state, {
			cachedSearchResults = Cryo.Dictionary.join(state.cachedSearchResults, {
				[action.key] = action.success and action.results or {},
			}),
		})
	end,

	[CollaboratorSearchActions.LoadingWebResults.name] = function(state, action)
		if not state.cachedSearchResults then
			state = Cryo.Dictionary.join(state, {
				cachedSearchResults = {},
			})
		end
		return Cryo.Dictionary.join(state, {
			cachedSearchResults = Cryo.Dictionary.join(state.cachedSearchResults, {
				[action.searchTerm] = LOADING_IN_BACKGROUND,
			}),
		})
	end,

	[CollaboratorSearchActions.LoadingLocalUserFriends.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			localUserFriends = LOADING_IN_BACKGROUND,
		})
	end,

	[CollaboratorSearchActions.LoadingLocalUserGroups.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			localUserGroups = LOADING_IN_BACKGROUND,
		})
	end,

	[CollaboratorSearchActions.SearchTextChanged.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			searchText = action.text,
		})
	end,

	[SetCollaborators.name] = function(state, action)
		if state.originalCollaborators then
			return Cryo.Dictionary.join(state, {
				collaborators = action.collaborators,
			})
		else
			return Cryo.Dictionary.join(state, {
				originalCollaborators = action.collaborators,
				collaborators = action.collaborators,
			})
		end
	end,

	[SetIsPackage.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			isPackageAsset = action.isPackageAsset,
		})
	end,

	[SetGroupRoleInfo.name] = function(state, action)
		if Enum.CreatorType[state.assetConfigData.Creator.type] ~= Enum.CreatorType.Group then
			return state
		end

		local groupId = state.assetConfigData.Creator.targetId
		for i, role in pairs(action.groupRoleInfo) do
			for j, roleset in pairs(state[groupId].groupMetadata.Roles) do
				if role.name == roleset.Name then
					local newRoleset = Cryo.Dictionary.join(roleset, {
						Id = role.id,
					})
					state[groupId].groupMetadata.Roles[j] = newRoleset
				end
			end
		end
		return state
	end,

	[SetPackagePermission.name] = function(state, action)
		if not state.packagePermissions then
			state.packagePermissions = {}
		end

		state.packagePermissions = Cryo.Dictionary.join(state.packagePermissions, action.packagePermissions)

		return state
	end,

	[SetTagSuggestions.name] = function(state, action)
		if action.sentTime < (state.latestTagSuggestionTime or 0) then
			return state
		end

		return Cryo.Dictionary.join(state, {
			tagSuggestions = action.suggestions,
			latestTagSuggestionTime = action.sentTime,
			latestTagSearchQuery = action.prefix,
		})
	end,

	[SetFieldError.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			tabErrors = Cryo.Dictionary.join(state.tabErrors or {}, {
				[action.tabName] = Cryo.Dictionary.join(state.tabErrors and state.tabErrors[action.tabName] or {}, {
					[action.fieldName] = action.hasError,
				}),
			}),
		})
	end,

	[SetUploadFee.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			isUploadFeeEnabled = action.isUploadFeeEnabled,
			uploadFee = action.uploadFee,
			canAffordUploadFee = action.canAffordUploadFee,
		})
	end,

	[SetAssetConfigAssetTypeAgents.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			assetTypeAgents = action.assetTypeAgents,
		})
	end,

	[SetDescendantPermissions.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			descendantPermissions = action.permission,
		})
	end,

	[SetPublishingRequirements.name] = if FFlagToolboxEnableAssetConfigPhoneVerification then function(state, action)
		return Cryo.Dictionary.join(state, {
			publishingRequirements = action.publishingRequirements,
		})
	end else nil,
})
