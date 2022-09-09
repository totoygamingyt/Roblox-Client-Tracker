local Page = script.Parent.Parent
local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local Framework = require(Plugin.Packages.Framework)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Cryo = require(Plugin.Packages.Cryo)

local UI = Framework.UI
local Pane = UI.Pane

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local PermissionsConstants = require(Page.Util.PermissionsConstants)
local LOADING = require(Page.Keys.loadingInProgress)
local PLAY_KEY = PermissionsConstants.PlayKey
local EDIT_KEY = PermissionsConstants.EditKey

local UserHeadshotThumbnail = require(Plugin.Src.Components.AutoThumbnails.UserHeadshotThumbnail)
local GroupIconThumbnail = require(Plugin.Src.Components.AutoThumbnails.GroupIconThumbnail)
local Searchbar = require(Page.Components.SearchBar)

local GetUserCollaborators = require(Page.Selectors.GetUserCollaborators)
local GetGroupCollaborators = require(Page.Selectors.GetGroupCollaborators)
local AddUserCollaborator = require(Page.Thunks.AddUserCollaborator)
local AddGroupCollaborator = require(Page.Thunks.AddGroupCollaborator)
local SearchCollaborators = require(Page.Thunks.SearchCollaborators)

local IsGroupGame = require(Page.Selectors.IsGroupGame)

local PERMISSIONS_ID = "Permissions"

local CollaboratorSearchWidget = Roact.PureComponent:extend("CollaboratorSearchWidget")

function CollaboratorSearchWidget:isLoading()
	local props = self.props
	local searchData = props.SearchData

	local cachedSearchResults = searchData.CachedSearchResults
	local searchTerm = searchData.SearchText

	return searchData.LocalUserGroups == LOADING
		or searchData.LocalUserFriends == LOADING
		or cachedSearchResults[searchTerm] == LOADING
		or (cachedSearchResults[searchTerm] == nil and searchTerm ~= "")
end

function CollaboratorSearchWidget:isFriend(userId)
	local props = self.props
	local ownerType = props.ownerType
	local ownerFriends = props.ownerFriends
	-- For group games the ownerType will be Enum.CreatorType.Group. So isFriend will always return false for group games.
	if ownerType == Enum.CreatorType.User then
		-- Linear search here should be fine since friends are capped so it shouldn't take too long to go through all of them.
		for _,friendId in ipairs(ownerFriends) do
			if friendId == userId then
				return true
			end
		end
	end

	return false
end

function CollaboratorSearchWidget:getMatches()
	local props = self.props

	local searchData = props.SearchData
	local userCollaborators = props.UserCollaborators
	local groupCollaborators = props.GroupCollaborators

	local cachedSearchResults = searchData.CachedSearchResults
	local searchTerm = searchData.SearchText

	local userCollaboratorLookup = {}
	for _,userId in ipairs(userCollaborators) do
		userCollaboratorLookup[userId] = true
	end
	local function userAlreadyCollaborator(userId)
		return userCollaboratorLookup[userId] ~= nil
	end

	local groupCollaboratorLookup = {}
	for _,groupId in ipairs(groupCollaborators) do
		groupCollaboratorLookup[groupId] = true
	end
	local function groupAlreadyCollaborator(groupId)
		return groupCollaboratorLookup[groupId] ~= nil
	end

	local matches = { Users = {}, Groups = {} }
	if cachedSearchResults[searchTerm] and cachedSearchResults[searchTerm] ~= LOADING then
		local rawUserMatches = cachedSearchResults[searchTerm][PermissionsConstants.UserSubjectKey]
		local rawGroupMatches = cachedSearchResults[searchTerm][PermissionsConstants.GroupSubjectKey]

		local userMatches = {}
		for _,v in pairs(rawUserMatches) do
			local subjectId = v[PermissionsConstants.SubjectIdKey]
			if not userAlreadyCollaborator(subjectId) then
				table.insert(userMatches, v)
			end
		end

		local groupMatches = {}
		for _,v in pairs(rawGroupMatches) do
			local groupId = v[PermissionsConstants.GroupIdKey]
			if not groupAlreadyCollaborator(groupId) then
				table.insert(groupMatches, v)
			end
		end

		matches.Users = userMatches
		matches.Groups = groupMatches
	end
	return matches
end

function CollaboratorSearchWidget:getResults()
	local props = self.props

	local searchData = props.SearchData

	local localization = props.Localization

	local isGroupGame = props.IsGroupGame

	local searchTerm = searchData.SearchText

	if searchTerm == "" then
		return {}
	end

	local matches = self:getMatches()

	local results = {}

	-- If there are less than max groups, we can display more users. If there are less than max users, we can display more groups
	local maxUserResultsAfterAdjustment = PermissionsConstants.MaxSearchResultsPerSubjectTypeUsers
	local maxGroupResultsAfterAdjustment = PermissionsConstants.MaxSearchResultsPerSubjectTypeGroups

	local usersRemaining = PermissionsConstants.MaxSearchResultsPerSubjectTypeUsers - #matches.Users
	local groupsRemaining = PermissionsConstants.MaxSearchResultsPerSubjectTypeGroups - #matches.Groups
	if groupsRemaining > 0 then
		maxUserResultsAfterAdjustment = groupsRemaining > 0 and PermissionsConstants.MaxSearchResultsPerSubjectTypeUsers + groupsRemaining
	end
	if usersRemaining > 0 then
		maxGroupResultsAfterAdjustment = usersRemaining > 0 and PermissionsConstants.MaxSearchResultsPerSubjectTypeGroups + usersRemaining
	end

	if #matches.Users > 0  then
		local userResults = {}

		for _, user in pairs(matches.Users) do
			if #userResults + 1 > maxUserResultsAfterAdjustment then break end

			table.insert(userResults, {
				Icon = Roact.createElement(UserHeadshotThumbnail, {
					Id = user[PermissionsConstants.SubjectIdKey],
					Size = UDim2.new(1, 0, 1, 0),
				}),
				Name = user[PermissionsConstants.SubjectNameKey],
				Key = {
					Type = PermissionsConstants.UserSubjectKey,
					Id = user[PermissionsConstants.SubjectIdKey],
					Name = user[PermissionsConstants.SubjectNameKey]
				},
			})
		end

		userResults.LayoutOrder = 0

		results[localization:getText(PERMISSIONS_ID, "UsersCollaboratorType")] = userResults
	end

	if #matches.Groups > 0 and not isGroupGame then

		local groupResults = {}

		for _, group in pairs(matches.Groups) do
			if #groupResults + 1 > maxGroupResultsAfterAdjustment then break end
			table.insert(groupResults, {
				Icon = Roact.createElement(GroupIconThumbnail, {
					Id = group[PermissionsConstants.GroupIdKey],
					Size = UDim2.new(1, 0, 1, 0),
				}),
				Name = group[PermissionsConstants.GroupNameKey],
				Key = {
					Type = PermissionsConstants.GroupSubjectKey,
					Id = group[PermissionsConstants.GroupIdKey],
					Name = group[PermissionsConstants.GroupNameKey]
				},
			})
		end

		groupResults.LayoutOrder = 0

		results[localization:getText(PERMISSIONS_ID, "GroupsCollaboratorType")] = groupResults
	end

	return results
end

function CollaboratorSearchWidget:render()
	local props = self.props

	local layoutOrder = props.LayoutOrder
	local writable = props.Writable

	local userCollaborators = props.UserCollaborators
	local addUserCollaborator = props.AddUserCollaborator
	local addGroupCollaborator = props.AddGroupCollaborator
	local searchCollaborators = props.SearchCollaborators

	local theme = props.Stylizer
	local localization = props.Localization

	local results = self:getResults()
	local isLoading = self:isLoading()

	local numCollaborators = #userCollaborators
	local maxCollaborators = game:GetFastInt("MaxAccessPermissionsCollaborators")
	local tooManyCollaborators = numCollaborators >= maxCollaborators

	local tooManyCollaboratorsText = localization:getText(PERMISSIONS_ID, "CollaboratorSearchbarTooManyText1",{
		maxNumCollaborators = maxCollaborators,
	})

	local children = {
		Title = Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.Subtitle, {
			AutomaticSize = Enum.AutomaticSize.XY,
			LayoutOrder = 0,

			Text = localization:getText("General", "TitleCollaborators"),
			TextXAlignment = Enum.TextXAlignment.Left,

			BackgroundTransparency = 1,
		})),

		Searchbar = Roact.createElement(Searchbar, {
			LayoutOrder = 1,
			Enabled = writable and not tooManyCollaborators,

			HeaderHeight = 25,
			ItemHeight = 50,

			ErrorText = tooManyCollaborators and tooManyCollaboratorsText or nil,
			DefaultText = localization:getText(PERMISSIONS_ID, "CollaboratorSearchbarDefaultText"),
			NoResultsText = localization:getText(PERMISSIONS_ID, "CollaboratorSearchbarNoResultsText"),
			LoadingMore = isLoading,

			onSearchRequested = function(text)
				searchCollaborators(text, true)
			end,
			onTextChanged = function(text)
				searchCollaborators(text, false)
			end,
			OnItemClicked = function(key)
				-- More info on adding collaborators and access level: https://confluence.rbx.com/pages/viewpage.action?spaceKey=CD&title=Place+Permissions+inside+Studio
				if key.Type == PermissionsConstants.UserSubjectKey then
					if self:isFriend(key.Id) then
						addUserCollaborator(key.Id, key.Name, EDIT_KEY)
					else
						addUserCollaborator(key.Id, key.Name, PLAY_KEY)
					end
				elseif key.Type == PermissionsConstants.GroupSubjectKey then
					addGroupCollaborator(key.Id, PLAY_KEY)
				else
					assert(false)
				end
			end,

			Results = results,
		}),
	}

	return Roact.createElement(Pane, {
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.Y,
		Layout = Enum.FillDirection.Vertical,
		LayoutOrder = layoutOrder,
		Spacing = UDim.new(0, 32),
	}, children)
end

CollaboratorSearchWidget = withContext({
	Stylizer = ContextServices.Stylizer,
	Localization = ContextServices.Localization,
	Mouse = ContextServices.Mouse,
})(CollaboratorSearchWidget)

CollaboratorSearchWidget = RoactRodux.connect(
	function(state, props)
		return {
			IsGroupGame = IsGroupGame(state),
			UserCollaborators = GetUserCollaborators(state),
			GroupCollaborators = GetGroupCollaborators(state),
			SearchData = state.CollaboratorSearch,
			ownerType = state.GameOwnerMetadata.creatorType,
			ownerFriends = state.GameOwnerMetadata.creatorFriends,
		}
	end,
	function(dispatch)
		return {
			AddUserCollaborator = function(...)
				dispatch(AddUserCollaborator(...))
			end,
			AddGroupCollaborator = function(...)
				dispatch(AddGroupCollaborator(...))
			end,
			SearchCollaborators = function(...)
				dispatch(SearchCollaborators(...))
			end,
		}
	end
)(CollaboratorSearchWidget)

return CollaboratorSearchWidget