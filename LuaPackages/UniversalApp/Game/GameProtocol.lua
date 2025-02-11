local CorePackages = game:GetService("CorePackages")
local MessageBus = require(CorePackages.UniversalApp.MessageBus)
local t = require(CorePackages.Packages.t)
local Cryo = require(CorePackages.Cryo)

local Types = require(script.Parent.GameProtocolTypes)

type LaunchParams = Types.LaunchParams
export type GameProtocol = Types.GameProtocol

export type GameProtocolModule = GameProtocol & {
	new: () -> GameProtocol,
	default: GameProtocol
}

local NAME = "Game"

local optionalParams = t.strictInterface({
	placeId = t.optional(t.number),
	userId = t.optional(t.number),
	accessCode = t.optional(t.string),
	gameInstanceId = t.optional(t.string),
	linkCode = t.optional(t.string),
	referralPage = t.optional(t.string)
})

local function checkRequiredParams(props)
	return props.placeId or props.userId
end 

local GameProtocol: GameProtocolModule = {
	GAME_LAUNCH_DESCRIPTOR = {
		mid = MessageBus.getMessageId(NAME, "launch"),
		validateParams = t.intersection(optionalParams, checkRequiredParams)
	}
} :: GameProtocolModule

(GameProtocol :: any).__index = GameProtocol

function GameProtocol.new(): GameProtocol
	local self = setmetatable({
		subscriber = MessageBus.Subscriber.new(),
	}, GameProtocol)
	return (self :: any) :: GameProtocol
end

function GameProtocol:launchGame(params: LaunchParams): ()
	if type(params.placeId) == "string" then
		params.placeId = tonumber(params.placeId)
	end
	if type(params.userId) == "string" then
		params.userId = tonumber(params.userId)
	end
	MessageBus.publish(self.GAME_LAUNCH_DESCRIPTOR, params)
end

GameProtocol.default = GameProtocol.new()

return GameProtocol
