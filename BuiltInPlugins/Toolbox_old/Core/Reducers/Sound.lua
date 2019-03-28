local Plugin = script.Parent.Parent.Parent

local Libs = Plugin.Libs
local Cryo = require(Libs.Cryo)
local Rodux = require(Libs.Rodux)

local DebugFlags = require(Plugin.Core.Util.DebugFlags)
local Immutable = require(Plugin.Core.Util.Immutable)

local PlayPreviewSound = require(Plugin.Core.Actions.PlayPreviewSound)
local PausePreviewSound = require(Plugin.Core.Actions.PausePreviewSound)
local StopPreviewSound = require(Plugin.Core.Actions.StopPreviewSound)
local ResumePreviewSound = require(Plugin.Core.Actions.ResumePreviewSound)
local StopAllSounds = require(Plugin.Core.Actions.StopAllSounds)

return Rodux.createReducer({
	currentSoundId = 0,
	isPlaying = false,
}, {
	[PlayPreviewSound.name] = function(state, action)
		if state.currentSoundId == action.currentSoundId and DebugFlags.shouldDebugWarnings() then
			warn("Trying to play the same sound instead of resuming it. Current SoundId : ", action.currentSoundId)
		end

		return Cryo.Dictionary.join(state, {
			currentSoundId = action.currentSoundId,
			isPlaying = true
		})
	end,

	[PausePreviewSound.name] = function(state, action)
		if not state.isPlaying and DebugFlags.shouldDebugWarnings() then
			warn(("Trying to pause a sound that is not playing! Current SoundId : %d"):format(state.currentSoundId))
		end

		return Cryo.Dictionary.join(state, {
			isPlaying = false
		})
	end,

	[StopPreviewSound.name] = function(state, action)
		if not state.isPlaying and DebugFlags.shouldDebugWarnings() then
			warn(("Trying to stop a sound that is not playing! Current SoundId : %d"):format(state.currentSoundId))
		end

		return Cryo.Dictionary.join(state, {
			currentSoundId = 0,
			isPlaying = false
		})
	end,

	[ResumePreviewSound.name] = function(state, action)
		if state.isPlaying and DebugFlags.shouldDebugWarnings() then
			warn(("Trying to resume a sound which is playing! Current SoundId : %d"):format(state.currentSoundId))
		end

		return Cryo.Dictionary.join(state, {
			isPlaying = true
		})
	end,

	[StopAllSounds.name] = function(state, action)
		return Cryo.Dictionary.join(state, {
			currentSoundId = 0,
			isPlaying = false
		})
	end,
})