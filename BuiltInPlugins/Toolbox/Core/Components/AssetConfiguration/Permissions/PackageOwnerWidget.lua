--[[
	An item that displays game owner access permissions and can be interacted with to change them
	if the owner is a group. User owners and group owner roles can never be changed.

	Necessary Properties:
	OwnerName = string, Name of collaborator. Displayed in primary label
	OwnerThumbnail = string, Icon to display in item (e.g. user headshot, group logo, etc)
	Enabled = bool, Whether the component is enabled or not
	OwnerId = num, used for getting the thumbnail and passing to CollaboratorItem
	OwnerType = Enum.CreatorType.*, used for determining if this is a Group-Owned or User-Owned Package.
	GroupMetadata = table, used to populate information about rolesets and what permissions they have.
	Permissions = table, contains the information about the current shared permissions of the package.
	PermissionsChanged = function, callback for when a user's role has been changed.
]]
local Plugin = script.Parent.Parent.Parent.Parent.Parent

local Packages = Plugin.Packages
local Roact = require(Packages.Roact)
local Framework = require(Packages.Framework)

local Util = Plugin.Core.Util
local Urls = require(Util.Urls)
local Constants = require(Util.Constants)
local ContextHelper = require(Util.ContextHelper)
local AssetConfigConstants = require(Util.AssetConfigConstants)

local withLocalization = ContextHelper.withLocalization
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local PermissionsDirectory = Plugin.Core.Components.AssetConfiguration.Permissions
local PermissionsConstants = require(PermissionsDirectory.PermissionsConstants)
local CollaboratorItem = require(PermissionsDirectory.CollaboratorItem)
local GroupCollaboratorItem = require(PermissionsDirectory.GroupCollaboratorItem)

local FrameworkUtil = require(Packages.Framework).Util
local deepJoin = FrameworkUtil.deepJoin

local function getGroupOwnerPermissions(props, localized)
	if not props.CanManage then return {} end

	local permissions = {
		{Key = PermissionsConstants.EditKey, Display = localized.PackagePermissions.ActionDropdown.EditLabel, Description = localized.PackagePermissions.ActionDropdown.EditDescription},
	}

	return permissions
end

local function getUserOwnerPermissions()
	return {} -- Owner can never be changed
end

local PackageOwnerWidget = Roact.PureComponent:extend("PackageOwnerWidget")

function PackageOwnerWidget:init()
	self.rolePermissionChanged = function(roleId, newPermission)
		local props = self.props

		local newPermissions = deepJoin(props.Permissions, {
			[PermissionsConstants.RoleSubjectKey] = {
				[roleId] = {
					[PermissionsConstants.ActionKey] = newPermission,
				}
			}
		})

		props.PermissionsChanged(newPermissions)
	end
end

function PackageOwnerWidget:render()
	return withLocalization(function(_, localized)
		return self:renderContent(nil, localized)
	end)
end

function PackageOwnerWidget:renderContent(theme, localized)
	local props = self.props
	theme = props.Stylizer

	local collaboratorItem
	if props.OwnerType == Enum.CreatorType.User then
		collaboratorItem = Roact.createElement(CollaboratorItem, {
			LayoutOrder = 1,
			Removable = false,

			SubjectType = Enum.CreatorType.User,

			CollaboratorName = props.OwnerName,
			CollaboratorId = props.OwnerId,
			CollaboratorIcon = Urls.constructRBXThumbUrl(AssetConfigConstants.rbxThumbTypes["AvatarHeadShot"], props.OwnerId,
				AssetConfigConstants.rbxThumbSizes.AvatarHeadshotImageSize),
			UseMask = true,

			Action =  localized.PackagePermissions.ActionDropdown.OwnerLabel,
			Enabled = props.Enabled,

			Items = getUserOwnerPermissions(),
			RolePermissionChanged = nil, -- Owner permissions can't be changed
		})
	else
		collaboratorItem = Roact.createElement(GroupCollaboratorItem, {
			LayoutOrder = 1,
			Removable = false,

			GroupData = props.GroupMetadata,
			Enabled = props.Enabled,

			Items = getGroupOwnerPermissions(props, localized),

			RolePermissionChanged = self.rolePermissionChanged,

			Permissions = props.Permissions,
		})
	end

	return Roact.createElement("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder or 0,
		Size = UDim2.new(1, 0, 0, 0),
	}, {
		UIListLayout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		Title = Roact.createElement("TextLabel", {
			Font = Constants.FONT,
			TextSize = Constants.FONT_SIZE_TITLE,
			TextColor3 = theme.assetConfig.packagePermissions.subTextColor,
			LayoutOrder = 0,
			Text = localized.PackagePermissions.Title.PackageCreator,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			-- Accounting for the CollaboratorItem under it.
			Size = UDim2.new(1, 50, 0, 50),
		}),

		Owner = collaboratorItem,
	})
end

PackageOwnerWidget = withContext({
	Stylizer = ContextServices.Stylizer,
})(PackageOwnerWidget)

return PackageOwnerWidget