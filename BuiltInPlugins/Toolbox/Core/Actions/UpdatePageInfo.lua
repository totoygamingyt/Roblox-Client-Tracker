local Plugin = script.Parent.Parent.Parent

local Packages = Plugin.Packages
local Util = require(Packages.Framework).Util
local Action = Util.Action

local DebugFlags = require(Plugin.Core.Util.DebugFlags)

return Action(script.Name, function(changes, settings)
	if DebugFlags.shouldDebugWarnings() then
		-- We check type(changes.creator) == "table" because it can be set to Cryo.None,
		-- which passes a truthiness or ~= nil check
		if
			changes
			and type(changes.creator) == "table"
			and changes.creator.Id ~= nil
			and changes.creator.Type == nil
		then
			warn("Setting PageInfo.creator without a type")
		end
	end

	return {
		changes = changes,
		settings = settings,
	}
end)
