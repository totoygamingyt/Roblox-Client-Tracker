local config = require(script.config)
local types = require(script.types)

export type VirtualEventSchema = types.VirtualEventSchema

return {
	config = config,
}
