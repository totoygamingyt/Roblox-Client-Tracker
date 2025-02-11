local Plugin = script.Parent.Parent.Parent.Parent

local PermissionsConstants = require(Plugin.Core.Components.AssetConfiguration.Permissions.PermissionsConstants)

local WebConstants = require(Plugin.Core.Util.Permissions.Constants)
local webKeys = WebConstants.webKeys
local webValues = WebConstants.webValues

local KeyConverter = {}

local DebugFlags = require(Plugin.Core.Util.DebugFlags)
local FFlagLimitGroupRoleSetPermissionsInGui = game:GetFastFlag("LimitGroupRoleSetPermissionsInGui")

function KeyConverter.getInternalSubjectType(webKey)
	if webKey == webKeys.UserSubject then
		return PermissionsConstants.UserSubjectKey
	elseif webKey == webKeys.RoleSubject then
		return PermissionsConstants.RoleSubjectKey
	elseif webKey == webKeys.GroupSubject then
		return PermissionsConstants.GroupSubjectKey
	else
		-- not supported
		error("Could not determine subject type")
	end
end

function KeyConverter.getInternalAction(webKey)
	if webKey == webKeys.GrantAssetPermissionsAction then
		return PermissionsConstants.OwnKey
	elseif webKey == webKeys.UseAction then
		return PermissionsConstants.UseViewKey
	elseif webKey == webKeys.EditAction then
		return PermissionsConstants.EditKey
	elseif webKey == webKeys.UseViewAction then
		return PermissionsConstants.UseViewKey
	elseif webKey == webKeys.RevokedAction then
		return PermissionsConstants.NoAccessKey
	elseif webKey == nil then
		return PermissionsConstants.NoAccessKey
	else
		-- not supported
		error("Unsupported Action: " .. tostring(webKey))
	end
end

if FFlagLimitGroupRoleSetPermissionsInGui then
	function KeyConverter.getPermissionLevel(webValue)
		if webValue == webValues.AccountPermissionLevel then
			return PermissionsConstants.AccountPermissionLevel
		elseif webValue == webValues.UniversePermissionLevel then
			return PermissionsConstants.UniversePermissionLevel
		elseif webValue == webValues.AssetPermissionLevel then
			return PermissionsConstants.AssetPermissionLevel
		else
			-- not supported
			error("Unsupported PermissionLevel: " .. tostring(webValue))
		end
	end

	function KeyConverter.getPermissionSource(webValue)
		if webValue == webValues.AssetPermissionSource then
			return PermissionsConstants.AssetPermissionSource
		elseif webValue == webValues.GroupPermissionSource then
			return PermissionsConstants.GroupPermissionSource
		else
			-- not supported
			error("Unsupported PermissionSource: " .. tostring(webValue))
		end
	end
end

function KeyConverter.getWebSubjectType(internalSubjectType)
	if internalSubjectType == PermissionsConstants.UserSubjectKey then
		return webKeys.UserSubject
	elseif internalSubjectType == PermissionsConstants.GroupSubjectKey then
		return webKeys.GroupSubject
	elseif internalSubjectType == PermissionsConstants.RoleSubjectKey then
		return webKeys.RoleSubject
	else
		-- not supported
		error("Invalid SubjectType: " .. tostring(internalSubjectType))
	end
end

function KeyConverter.getWebAction(internalAction)
	if internalAction == PermissionsConstants.UseViewKey then
		return webKeys.UseViewAction
	elseif internalAction == PermissionsConstants.EditKey then
		return webKeys.EditAction
	elseif internalAction == PermissionsConstants.NoAccessKey then
		return webKeys.RevokedAction
	elseif internalAction == PermissionsConstants.RevokedKey then
		return webKeys.RevokedAction
	else
		-- not supported
		error("Invalid Action: " .. tostring(internalAction))
	end
end

function KeyConverter.getAssetPermissionAction(webAction)
	if webAction == webKeys.UseViewAction then
		return webKeys.UseAction
	elseif webAction == webKeys.OwnAction then
		return webKeys.EditAction
	else
		return webAction
	end
end

function KeyConverter.getAssetPermissionSubjectType(internalSubjectType)
	if internalSubjectType == webKeys.RoleSubject then
		return webKeys.GroupRolesetSubject
	else
		return internalSubjectType
	end
end

--For PostCheckActions reponse parsing,
--status can be 1 of these values : "HasPermission","NoPermission","AssetNotFound","UnknownError"
function KeyConverter.resolveActionPermission(webKey, status, assetId)
	if status == webKeys.UnknownError then
		if DebugFlags.shouldDebugWarnings() then
			warn(
				string.format(
					"Ignoring %s for assetId: %s, webKey: %s",
					tostring(status),
					tostring(assetId),
					tostring(webKey)
				)
			)
		end
		return PermissionsConstants.NoneKey
	elseif status == webKeys.HasPermission then
		return KeyConverter.getInternalAction(webKey)
	elseif status == webKeys.NoPermission then
		return PermissionsConstants.NoAccessKey
	elseif status == webKeys.AssetNotFound then
		error("Permissions Error: " .. tostring(status) .. ", assetId: " .. tostring(assetId))
	else
		-- "status == Unknown Error"
		error("Permissions Error: " .. tostring(status) .. ", assetId: " .. tostring(assetId))
	end
end

return KeyConverter
