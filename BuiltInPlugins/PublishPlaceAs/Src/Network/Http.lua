local HttpRbxApiService = game:GetService("HttpRbxApiService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")

local Plugin = script.Parent.Parent.Parent
local Promise = require(Plugin.Packages.Framework).Util.Promise

local BAD_REQUEST = 400

local BASE_URL = ContentProvider.BaseUrl
if BASE_URL:find("https://www.") == 1 then
	BASE_URL = BASE_URL:sub(13)
elseif BASE_URL:find("http://www.") == 1 then
	BASE_URL = BASE_URL:sub(12)
end

local function applyParamsToUrl(requestInfo)
	local params = requestInfo.Params
	requestInfo.Params = nil -- HttpRbxApiService doesn't know what this is, so remove it before we give it requestInfo

	if params then
		local paramList = {}

		for paramName,paramValue in pairs(params) do
			local paramPair = HttpService:UrlEncode(paramName).."="..HttpService:UrlEncode(paramValue)
			table.insert(paramList, paramPair)
		end

		requestInfo.Url = requestInfo.Url .. "?" .. table.concat(paramList, "&")
	end
end

local Http = {}

function Http.BuildRobloxUrl(front, back, ...)
	return "https://" .. front .. "." .. BASE_URL .. (string.format(back, ...) or "")
end

function Http.Request(requestInfo)
	applyParamsToUrl(requestInfo)

	return Promise.new(function(resolve, reject)
		-- Prevent yielding
		spawn(function()
			local ok, result = pcall(HttpRbxApiService.RequestAsync,
				HttpRbxApiService, requestInfo)
			if ok then
				resolve(result)
			else
				reject(result)
			end
		end)
	end)
end

function Http.RequestInternal(requestInfo)
	applyParamsToUrl(requestInfo)

	return Promise.new(function(resolve, reject)
		-- Prevent yielding
		spawn(function()
			HttpService:RequestInternal(requestInfo):Start(function(success, response)
				if success then
					if response.StatusCode >= BAD_REQUEST then
						reject("HTTP error: "..tostring(response.StatusCode))
					else
						resolve(response.Body)
					end
				else
					reject("HTTP error: "..tostring(response.HttpError))
				end
			end)
		end)
	end)
end

return Http
