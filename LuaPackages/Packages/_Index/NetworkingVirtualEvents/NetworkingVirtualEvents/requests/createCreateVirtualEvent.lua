local NetworkingVirtualEvents = script:FindFirstAncestor("NetworkingVirtualEvents")

local constants = require(NetworkingVirtualEvents.constants)

return function(roduxNetworking)
	type Payload = {
		title: string,
		description: string,
		eventTime: {
			startTime: DateTime,
			endTime: DateTime,
		},
		universeId: number,
	}

	local CreateVirtualEvent = roduxNetworking.POST(script, function(requestBuilder, payload: Payload)
		return requestBuilder(constants.API_URL):path("v1"):path("virtual-events"):path("create"):body({
			title = payload.title,
			description = payload.description,
			eventTime = {
				-- ToIsoDate converts our start/end times into the format
				-- "2020-01-02T10:30:45Z" which is required by the backend
				startTime = payload.eventTime.startTime:ToIsoDate(),
				endTime = payload.eventTime.endTime:ToIsoDate(),
			},
			universeId = payload.universeId,
		})
	end)

	return CreateVirtualEvent
end
