--!nonstrict

local InspectAndBuyFolder = script.Parent.Parent
local Thunk = require(InspectAndBuyFolder.Thunk)
local GetProductInfo = require(InspectAndBuyFolder.Thunks.GetProductInfo)
local AssetInfo = require(InspectAndBuyFolder.Models.AssetInfo)
local SetAssets = require(InspectAndBuyFolder.Actions.SetAssets)
local SetEquippedAssets = require(InspectAndBuyFolder.Actions.SetEquippedAssets)
local Constants = require(InspectAndBuyFolder.Constants)

local requiredServices = {}

local function getAssetIds(humanoidDescription)
	local assets = {}

	for assetTypeId, name in pairs(Constants.HumanoidDescriptionIdToName) do
		if Constants.AssetTypeIdToAccessoryTypeEnum[assetTypeId] == nil then
			local assetIds = humanoidDescription[name] or ""
			for _, id in pairs(string.split(assetIds)) do
				if tonumber(id) and id ~= "0" then
					table.insert(assets, AssetInfo.fromHumanoidDescription(id))
				end
			end
		end
	end

	local accessories = humanoidDescription:GetAccessories(--[[includeRigidAccessories =]] true)
	for _, accessory in pairs(accessories) do
		assets[#assets + 1] = AssetInfo.fromHumanoidDescription(accessory.AssetId)
	end

	local emotes = humanoidDescription:GetEmotes()

	for _, emote in pairs(emotes) do
		for _, assetId in pairs(emote) do
			assets[#assets + 1] = AssetInfo.fromHumanoidDescription(assetId)
		end
	end

	return assets
end

--[[
	Given a humanoid description object, parse through the ids and get
	each assets information.
]]
local function GetAssetsFromHumanoidDescription(humanoidDescription, isForLocalPlayer)
	return Thunk.new(script.Name, requiredServices, function(store, services)
		local assets = getAssetIds(humanoidDescription)
		if not isForLocalPlayer then
			for _, asset in ipairs(assets) do
				coroutine.wrap(function()
					store:dispatch(GetProductInfo(asset.assetId))
				end)()
			end
			store:dispatch(SetAssets(assets))
		else
			store:dispatch(SetEquippedAssets(assets))
		end
	end)
end

return GetAssetsFromHumanoidDescription
