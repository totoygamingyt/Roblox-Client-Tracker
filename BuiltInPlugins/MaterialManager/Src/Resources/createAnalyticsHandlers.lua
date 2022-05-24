local Plugin = script.Parent.Parent.Parent

local Cryo = require(Plugin.Packages.Cryo)

local DebugFlags = require(Plugin.Src.Util.DebugFlags)

local HttpService = game:GetService("HttpService")

-- New Plugin Setup: Change this to the analytics context name for your plugin
local pluginAnalyticsContext = "MaterialManager"

return function(analyticsService)
	local function _sendEvent(eventName, additionalArgs)
		additionalArgs = additionalArgs or {}

		local args = Cryo.Dictionary.join({
			studioSid = analyticsService:GetSessionId(),
			clientId = analyticsService:GetClientId(),
			placeId = game.PlaceId,
		}, additionalArgs)

		if DebugFlags.LogAnalytics() then
			print(("%s SendEvent eventName=%s args=%s"):format(
				pluginAnalyticsContext, tostring(eventName), HttpService:JSONEncode(args)))
		end

		analyticsService:SendEventDeferred("studio", pluginAnalyticsContext, eventName, args)
	end

	local function _reportInfluxSeries(eventName, additionalArgs, throttlingPercent)
		additionalArgs = additionalArgs or {}

		if DebugFlags.LogAnalytics() then
			print(("%s SendEvent eventName=%s args=%s throttlingPercent=%s"):format(
				pluginAnalyticsContext, tostring(eventName), HttpService:JSONEncode(additionalArgs), tostring(throttlingPercent)))
		end

		analyticsService:ReportInfluxSeries(eventName, additionalArgs, throttlingPercent)
	end

	local function _reportCounter(counterName, count)
		count = count or 1
		if DebugFlags.LogAnalytics() then
			print(("%s ReportCounter counterName=%s count=%s"):format(
				pluginAnalyticsContext, tostring(counterName), tostring(count)))
		end
		analyticsService:ReportCounter(counterName, count)
	end

	return {
		newMaterialVariantCounter = function()
			_reportCounter("NewMaterialVariant")
		end,

		newMaterialVariant = function(additionalArgs, throttlingPercent)
			_reportInfluxSeries("BaseMaterialForVariant", additionalArgs, throttlingPercent)
		end,
	}
end
