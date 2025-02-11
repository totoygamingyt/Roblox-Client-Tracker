--!nonstrict
local CorePackages = game:GetService("CorePackages")
local HttpRbxApiService = game:GetService("HttpRbxApiService")

local httpRequest = require(CorePackages.AppTempCommon.Temp.httpRequest)
local Url = require(CorePackages.AppTempCommon.LuaApp.Http.Url)

local httpImpl = httpRequest(HttpRbxApiService)

return function(outfitId)
	local url = string.format("%s/v1/outfits/%s/details", Url.AVATAR_URL, tostring(outfitId))
	return httpImpl(url, "GET"):andThen(function(result)
		local data = result.responseBody

		return data.name
	end)
end
