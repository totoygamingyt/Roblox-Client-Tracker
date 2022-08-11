local FFlagToolboxEnableAnnouncementsDialog = game:GetFastFlag("ToolboxEnableAnnouncementsDialog")

local Plugin = script.Parent.Parent.Parent

local DebugFlags = require(Plugin.Core.Util.DebugFlags)

local Category = require(Plugin.Core.Types.Category)
local Sort = require(Plugin.Core.Types.Sort)

local Settings = {}
Settings.__index = Settings

local disableMarketplaceAndRecents = require(Plugin.Core.Util.ToolboxUtilities).disableMarketplaceAndRecents
local showRobloxCreatedAssets = require(Plugin.Core.Util.ToolboxUtilities).showRobloxCreatedAssets

-- Built in plugins share the same namespace for settings, so mark this as from the toolbox
local SETTING_PREFIX = "Toolbox_"
local SELECTED_CATEGORY_NAME_KEY = SETTING_PREFIX .. "SelectedCategoryName"
local SELECTED_SEARCH_TERM_KEY = SETTING_PREFIX .. "SelectedSearchTerm"
local SELECTED_SORT_INDEX_KEY = SETTING_PREFIX .. "SelectedSortIndex"
local SHOW_SCRIPT_WARNING_KEY = SETTING_PREFIX .. "ShowScriptWarning"
local LAST_ANNOUNCEMENT_VIEWED_KEY = SETTING_PREFIX .. "LastAnnouncementViewedKey"

function Settings.new(plugin)
	local self = {
		_plugin = plugin,
	}

	setmetatable(self, Settings)

	return self
end

function Settings:_getSetting(setting, default)
	if not self._plugin then
		return default
	end

	local value = self._plugin:GetSetting(setting)

	if DebugFlags.shouldLogSettings() then
		print(
			('Settings:_getSetting(setting="%s", default=%s) got value = %s'):format(
				tostring(setting),
				type(default) == "string" and '"' .. tostring(default) .. '"' or tostring(default),
				type(value) == "string" and '"' .. tostring(value) .. '"' or tostring(value)
			)
		)
	end

	if not value then
		value = default
	end
	return value
end

function Settings:_setSetting(setting, value)
	if not self._plugin then
		return
	end

	if DebugFlags.shouldLogSettings() then
		print(
			('Settings:_setSetting(setting="%s", value=%s)'):format(
				tostring(setting),
				type(value) == "string" and '"' .. tostring(value) .. '"' or tostring(value)
			)
		)
	end

	self._plugin:SetSetting(setting, value)
end

function Settings:getSelectedCategoryName()
	return self:_getSetting(SELECTED_CATEGORY_NAME_KEY, Category.DEFAULT.name)
end

function Settings:setSelectedCategoryName(categoryName)
	return self:_setSetting(SELECTED_CATEGORY_NAME_KEY, categoryName)
end

function Settings:getSelectedSearchTerm()
	return self:_getSetting(SELECTED_SEARCH_TERM_KEY, "")
end

function Settings:setSelectedSearchTerm(searchTerm)
	return self:_setSetting(SELECTED_SEARCH_TERM_KEY, searchTerm)
end

function Settings:getSelectedSortIndex()
	return self:_getSetting(SELECTED_SORT_INDEX_KEY, 1)
end

function Settings:setSelectedSortIndex(index)
	return self:_setSetting(SELECTED_SORT_INDEX_KEY, index)
end

function Settings:getShowScriptWarning()
	return self:_getSetting(SHOW_SCRIPT_WARNING_KEY, "true") == "true"
end

function Settings:setShowScriptWarning(value)
	return self:_setSetting(SHOW_SCRIPT_WARNING_KEY, tostring(value))
end

if FFlagToolboxEnableAnnouncementsDialog then
	function Settings:getLastAnnouncementViewedKey()
		return self:_getSetting(LAST_ANNOUNCEMENT_VIEWED_KEY, "")
	end

	function Settings:setLastAnnouncementViewedKey(value)
		return self:_setSetting(LAST_ANNOUNCEMENT_VIEWED_KEY, tostring(value))
	end
end

function Settings:updateFromPageInfo(pageInfo)
	if DebugFlags.shouldLogSettings() then
		print("Settings:updateFromPageInfo()")
	end

	self:setSelectedCategoryName(pageInfo.categoryName)
	self:setSelectedSearchTerm(pageInfo.searchTerm)
	self:setSelectedSortIndex(pageInfo.sortIndex)
end

function Settings:loadInitialSettings()
	if DebugFlags.shouldLogSettings() then
		print("Settings:loadInitialSettings()")
	end

	local initSettings = {}
	if disableMarketplaceAndRecents() then
		-- We don't allow Marketplace or Recents for Luobu. We can't risk the loaded setting defaulting to Marketplace.
		initSettings.categoryName = Category.DEFAULT.name
	else
		initSettings.categoryName = self:getSelectedCategoryName()

		if not Category.getCategoryByName(initSettings.categoryName) then
			initSettings.categoryName = Category.DEFAULT.name
		end
	end

	if showRobloxCreatedAssets() then
		-- Override default settings to only show Roblox created assets for Luobu
		initSettings.tab = Category.MARKETPLACE_KEY
		initSettings.categoryName = Category.DEFAULT.name
		initSettings.creator = Category.CREATOR_ROBLOX
	end

	initSettings.searchTerm = self:getSelectedSearchTerm()
	initSettings.sortIndex = self:getSelectedSortIndex()

	if game:FindFirstChild("DefaultToolboxSearch") then
		initSettings.searchTerm = game.DefaultToolboxSearch.Value
		-- Also set the initial category to free models and relevant sort
		initSettings.categoryName = Category.DEFAULT.name
		initSettings.sortIndex = Sort.getDefaultSortForCategory(initSettings.categoryName)
	end

	if not Sort.canSort(initSettings.searchTerm, initSettings.categoryName) then
		initSettings.sortIndex = Sort.getDefaultSortForCategory(initSettings.categoryName)
	end

	return initSettings
end

return Settings
