local CorePackages = game:GetService("CorePackages")

local Roact = require(CorePackages.Roact)
local t = require(CorePackages.Packages.t)

local Components = script.Parent.Parent
local Connection = Components.Connection
local LayoutValues = require(Connection.LayoutValues)
local WithLayoutValues = LayoutValues.WithLayoutValues

local FFlagUpdateLeaderboardIconPriority = game:GetFastFlag("UpdateLeaderboardIconPriority")

local PlayerIcon = Roact.Component:extend("PlayerIcon")

PlayerIcon.validateProps = t.strictInterface({
	player = t.instanceIsA("Player"),
	layoutOrder = t.integer,

	playerIconInfo = t.strictInterface({
		isPlaceOwner = t.boolean,
		avatarIcon = t.optional(t.string),
		specialGroupIcon = t.optional(t.string),
	}),

	playerRelationship = t.strictInterface({
		isBlocked = t.boolean,
		friendStatus = t.enum(Enum.FriendStatus),
		isFollowing = t.boolean,
		isFollower = t.boolean,
	})
})

local function getSocialIconImage(layoutValues, relationship)
	local friendIcon = layoutValues.FriendIcons[relationship.friendStatus]

	if relationship.isBlocked then
		return layoutValues.BlockedIcon
	elseif friendIcon then
		return friendIcon
	elseif relationship.isFollowing and not FFlagUpdateLeaderboardIconPriority then
		return layoutValues.FollowingIcon
	end

	return nil
end

local function getIconImage(layoutValues, player, iconInfo, relationship)
	local membershipIcon = layoutValues.MembershipIcons[player.MembershipType]
	local socialIcon = getSocialIconImage(layoutValues, relationship)
	if FFlagUpdateLeaderboardIconPriority then
		if socialIcon then
			return socialIcon
		elseif iconInfo.isPlaceOwner then
			return layoutValues.PlaceOwnerIcon
		elseif layoutValues.CustomPlayerIcons[player.UserId] then
			return layoutValues.CustomPlayerIcons[player.UserId]
		elseif iconInfo.specialGroupIcon then
			return iconInfo.specialGroupIcon
		elseif relationship.isFollowing then
			return layoutValues.FollowingIcon
		elseif membershipIcon then
			-- TODO: Replace this with single premium icon check if that is the future.
			return membershipIcon
		end
	else
		if layoutValues.CustomPlayerIcons[player.UserId] then
			return layoutValues.CustomPlayerIcons[player.UserId]
		elseif iconInfo.isPlaceOwner then
			return layoutValues.PlaceOwnerIcon
		elseif iconInfo.specialGroupIcon then
			return iconInfo.specialGroupIcon
		elseif socialIcon then
			return socialIcon
		elseif membershipIcon then
			-- TODO: Replace this with single premium icon check if that is the future.
			return membershipIcon
		end
	end
	return ""
end

function PlayerIcon:render()
	return WithLayoutValues(function(layoutValues)
		local avatarIcon = self.props.playerIconInfo.avatarIcon
		if avatarIcon == nil then
			avatarIcon = layoutValues.DefaultThumbnail
		end
		if layoutValues.IsTenFoot then
			return Roact.createElement("ImageLabel", {
				LayoutOrder = self.props.layoutOrder,
				Size = layoutValues.PlayerIconBackgroundSize,
				BackgroundTransparency = 1,
				Image = layoutValues.PlayerBackgroundImage,
			}, {
				Roact.createElement("ImageLabel", {
					Size = layoutValues.PlayerIconSize,
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = avatarIcon,
					BorderSizePixel = 0,
				})
			})
		else
			return Roact.createElement("ImageLabel", {
				LayoutOrder = self.props.layoutOrder,
				Size = layoutValues.PlayerIconSize,
				BackgroundTransparency = 1,
				Image = getIconImage(
					layoutValues,
					self.props.player,
					self.props.playerIconInfo,
					self.props.playerRelationship
				),
				BorderSizePixel = 0,
			})
		end
	end)
end

return PlayerIcon