local RobloxPluginGuiService = game:GetService("RobloxPluginGuiService")

local Plugin = script.Parent.Parent.Parent

local Packages = Plugin.Packages
local Promise = require(Packages.Framework).Util.Promise

local function SerializeInstances(instances, studioAssetService)
	return Promise.new(function(resolve, reject)
		task.spawn(function()
			local tempFolder = Instance.new("Folder")
			tempFolder.Name = "TemporaryInstances"
			tempFolder.Parent = RobloxPluginGuiService
			for _, instance in pairs(instances) do
				instance.Parent = tempFolder
			end

			local success, result = pcall(function()
				return studioAssetService:SerializeInstances(instances)
			end)

			-- parent instances back to nil so they can be GC'd later if needed
			for _, instance in pairs(instances) do
				instance.Parent = nil
			end
			tempFolder:Destroy()

			if success then
				resolve(result)
			else
				reject("SerializeInstances failed: " .. tostring(result))
			end
		end)
	end)
end

return SerializeInstances
