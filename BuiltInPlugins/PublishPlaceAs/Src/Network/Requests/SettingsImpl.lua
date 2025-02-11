--[[
	Interface for changing ingame settings.

	Flow:
		SettingsImpl can be provided via a SettingsImplProvider, then
		used as an Interface by the SaveChanges and LoadAllSettings thunks
		to save and load settings. Other implementations, such as
		SettingsImpl_mock, can be provided to allow testing.
]]
local StudioPublishService = game:GetService("StudioPublishService")

local Plugin = script.Parent.Parent.Parent.Parent

local PostContactEmail = require(Plugin.Src.Thunks.PostContactEmail)

local KeyProvider = require(Plugin.Src.Util.KeyProvider)
local optInLocationsKey = KeyProvider.getOptInLocationsKeyName()
local shouldShowDevPublishLocations = require(Plugin.Src.Util.PublishPlaceAsUtilities).shouldShowDevPublishLocations

local UNIVERSEACTIVATE_ACCEPTED_KEYS = {
	isActive = true,
}

local CONFIGURATION_ACCEPTED_KEYS = {
	description = true,
	genre = true,
	name = true,
	playableDevices = true,
	isFriendsOnly = true,
}

if shouldShowDevPublishLocations() then
	CONFIGURATION_ACCEPTED_KEYS.OptInLocations = true
end

local function universeActivateAcceptsValue(key)
	return UNIVERSEACTIVATE_ACCEPTED_KEYS[key] ~= nil
end

local function configurationAcceptsValue(key)
	return CONFIGURATION_ACCEPTED_KEYS[key] ~= nil
end

local function parseErrorMessages(response, message)
	-- TODO: jbousellam - 8/20/2021 - Once we get updated error messages from the backend,
	-- this first message may be redundant, so we can consider removing it later.
	local error = message .. " HTTP " .. response.responseCode
	warn(error)
	for _, value in pairs(response.responseBody.errors) do
		warn(value.userFacingMessage)
	end
end

--[[
	Used to save the chosen state of all game settings by saving to web
	endpoints or setting properties in the datamodel.
]]

local function saveAll(state, localization, apiImpl, email, isPublish)
	local configuration = {}
	local universeActivate = {}

	for setting, value in pairs(state) do
		-- Add name, genre, game description, and playable devices
		if configurationAcceptsValue(setting) then
			configuration[setting] = value
		-- Set if the game is public or private
		elseif universeActivateAcceptsValue(setting) then
			universeActivate[setting] = value
		end
	end

	game:GetService("StudioPublishService"):SetTeamCreateOnPublishInfo(state.teamCreateEnabled, configuration.name)

	StudioPublishService:setUploadNames(configuration.name, configuration.name)
	StudioPublishService:publishAs(0, 0, state.creatorId, isPublish, nil)

	local success, gameId
	success, gameId = StudioPublishService.GamePublishFinished:wait()

	-- Failure handled in ScreenCreateNewGame
	if not success then
		return
	end

	if configuration.playableDevices then
		local toTable = {}
		for key, value in pairs(configuration.playableDevices) do
			if value then
				table.insert(toTable, key)
			end
		end
		configuration.playableDevices = toTable
	end

	if shouldShowDevPublishLocations() and email ~= nil then
		local responseCode = PostContactEmail(apiImpl, email, gameId)
		if responseCode == 200 then
			assert(configuration.OptInLocations)
			local optInTable = {}
			local optOutTable = {}
			for key, value in pairs(configuration.OptInLocations) do
				if value then
					table.insert(optInTable, key)
				else
					table.insert(optOutTable, key)
				end
			end
			configuration.optInRegions = optInTable
			configuration.optOutRegions = optOutTable
		else
			warn(localization:getText(optInLocationsKey, "EmailSubmitFailure"))
		end
		configuration.OptInLocations = nil
	end

	apiImpl.Develop.V2.Universes.configuration(gameId, configuration):makeRequest()
	:andThen(function()
		StudioPublishService:SetUniverseDisplayName(configuration.name)
		StudioPublishService:RefreshDocumentDisplayName()
		StudioPublishService:EmitPlacePublishedSignal()
	end, function(response)
		parseErrorMessages(response, localization:getText("Error","SetConfiguration"))
	end)

	if universeActivate.isActive then
		apiImpl.Develop.V1.Universes.activate(gameId):makeRequest()
		:catch(function(response)
			parseErrorMessages(response, localization:getText("Error","ActivatingUniverse"))
		end)
	else
		apiImpl.Develop.V1.Universes.deactivate(gameId):makeRequest()
		:catch(function(response)
			parseErrorMessages(response, localization:getText("Error","DeactivatingUniverse"))
		end)
	end
end

return {
	saveAll = saveAll,
}
