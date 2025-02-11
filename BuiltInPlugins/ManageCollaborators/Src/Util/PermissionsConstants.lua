--[[
	Constants used by components/network requests to handle permissions
--]]

local Plugin = script.Parent.Parent.Parent
local Cryo = require(Plugin.Packages.Cryo)

local function createKey(keyName)
	local key = newproxy(true)

	getmetatable(key).__tostring = function()
		return "Symbol("..keyName..")"
	end

	return key
end

--[[
	Keys used in internal data structures. The tables don't contain any data, and are just
	unique identifiers used in lieu of Lua's lack of enums. By using these, we can easily
	tell what the meaning of keys are. {subjectId=_} doesn't communicate where it's coming
	from, its scope, what files we need to use it in, etc, whereas {[SubjectIdKey] = _} is
	less arbitrary
--]]
local uniqueIdentifiers = {
	-- Used in internal data structure for permissions
	NoAccessKey = createKey("NoAccessPermission"),
	PlayKey = createKey("PlayPermission"),
	EditKey = createKey("EditPermission"),
	NoEditMustBeFriendKey = createKey("NoEditMustBeFriendPermission"),
	NoUserEditGroupGameKey = createKey("NoUserEditGroupGamePermission"),
	AdminKey = createKey("AdminPermission"),
	OwnerKey = createKey("OwnerPermission"),
	MultipleKey = createKey("MultiplePermission"),

	UserSubjectKey = createKey("UserSubjectType"),
	GroupSubjectKey = createKey("GroupSubjectType"),
	RoleSubjectKey = createKey("RoleSubjectType"),

	ActionKey = createKey("Action"),
	SubjectIdKey = createKey("SubjectId"),
	SubjectNameKey = createKey("SubjectName"),
	SubjectTypeKey = createKey("SubjectType"),
	SubjectRankKey = createKey("SubjectRank"),
	GroupIdKey = createKey("GroupId"),
	GroupNameKey = createKey("GroupName"),
	GroupMemberCountKey = createKey("GroupMemberCountKey"),

	IsFriendKey = createKey("IsFriend"),
}

local miscConstants = {
	DEPRECATED_MaxSearchResultsPerSubjectType = 3,
	MaxSearchResultsPerSubjectTypeUsers = 3,
	MaxSearchResultsPerSubjectTypeGroups = 2,
}

return Cryo.Dictionary.join(
	uniqueIdentifiers,
	miscConstants
)