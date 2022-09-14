export type Config = {
	roduxNetworking: any,
}

export type VirtualEventSchema = {
	id: string,
	title: string,
	description: string,
	eventTime: {
		startUtc: string,
		endUtc: string,
	},
	host: {
		hostTypeId: string, -- "user" | "group"
		hostTargetId: number,
	},
	universeId: number,
	status: string, -- "activated" | "cancelled" | "unpublished"
	createdUtc: string,
	updatedUtc: string,
}

return {}
