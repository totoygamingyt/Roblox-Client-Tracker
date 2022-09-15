local NetworkingVirtualEvents = script:FindFirstAncestor("NetworkingVirtualEvents")

local constants = require(NetworkingVirtualEvents.constants)

return function(roduxNetworking)
	local DeleteVirtualEvent = roduxNetworking.POST(script, function(requestBuilder, eventId: number)
		return requestBuilder(constants.API_URL):path("v1"):path("virtual-events"):id(eventId)
	end)

	return DeleteVirtualEvent
end
