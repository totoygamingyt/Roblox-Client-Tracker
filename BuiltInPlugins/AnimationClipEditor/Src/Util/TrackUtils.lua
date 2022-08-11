--[[
	Utility functions for dope sheet tracks to use to help
	create Keyframe components and place them onscreen.
]]

local Plugin = script.Parent.Parent.Parent
local Cryo = require(Plugin.Packages.Cryo)
local KeyframeUtils = require(Plugin.Src.Util.KeyframeUtils)
local PathUtils = require(Plugin.Src.Util.PathUtils)

local Constants = require(Plugin.Src.Util.Constants)
local CurveUtils = require(Plugin.Src.Util.CurveUtils)
local isEmpty = require(Plugin.Src.Util.isEmpty)
local Templates = require(Plugin.Src.Util.Templates)
local Types = require(Plugin.Src.Types)

local GetFFlagFacialAnimationSupport = require(Plugin.LuaFlags.GetFFlagFacialAnimationSupport)
local GetFFlagFacsUiChanges = require(Plugin.LuaFlags.GetFFlagFacsUiChanges)
local GetFFlagCurveEditor = require(Plugin.LuaFlags.GetFFlagCurveEditor)

local TrackUtils = {}

local function removeNegativeZero(val)
	if val == 0 then
		return math.abs(val)
	else
		return val
	end
end

-- Performs a visiting function on each component track (i.e. Position and Rotation
-- tracks of a CFrame track). func is called with the track, the path to that
-- track (as an array of track names), and a flag telling if it's a leaf track.
-- If leavesOnly is true, then func is only called for tracks that don't have components
function TrackUtils.traverseTracks(trackName, track, func, leavesOnly)
	assert(func ~= nil, "func must not be nil")

	local function traverse(track, trackName, path)
		if track ~= nil then
			if trackName then
				path = Cryo.List.join(path, {trackName})
			end

			local isLeaf = track.Components == nil or isEmpty(track.Components)

			if isLeaf or not leavesOnly then
				func(track, trackName, path, isLeaf)
			end

			if track.Components ~= nil then
				for componentName, componentTrack in pairs(track.Components) do
					traverse(componentTrack, componentName, path)
				end
			end
		end
	end

	traverse(track, trackName, {})
end

-- Performs a visiting function on each keyframe between the range
-- startTick and endTick, inclusive. For each keyframe within the range,
-- visitFunc provides the tick and the keyframe at that tick.
function TrackUtils.traverseKeyframeRange(keyframes, startTick, endTick, func)
	local first, first2 = KeyframeUtils.findNearestKeyframes(keyframes, startTick)
	local last = KeyframeUtils.findNearestKeyframes(keyframes, endTick)
	local firstIndex = first2 and first2 or first
	local lastIndex = last

	for keyIndex = firstIndex, lastIndex do
		local tck = keyframes[keyIndex]
		if tck >= startTick and tck <= endTick then
			func(tck, keyframes[keyIndex])
		end
	end
end

-- Gets the next keyframe of the animation (for navigation)
function TrackUtils.getNextKeyframe(tracks, playhead)
	local minFrame = nil
	for trackName, track in pairs(tracks) do
		TrackUtils.traverseTracks(nil, track, function(track)
			local keyframes = track.Keyframes
			local exactIndex, _, nextIndex = KeyframeUtils.findNearestKeyframesProperly(keyframes, playhead+1)
			nextIndex = exactIndex or nextIndex
			local nextFrame = nextIndex and keyframes[nextIndex] or nil
			if nextFrame then
				minFrame = minFrame and math.min(minFrame, nextFrame) or nextFrame
			end
		end, true)
	end
	return minFrame or playhead
end

-- Gets the previous keyframe of the animation (for navigation)
function TrackUtils.getPreviousKeyframe(tracks, playhead)
	local maxFrame = nil
	for trackName, track in pairs(tracks) do
		TrackUtils.traverseTracks(nil, track, function(track)
			local keyframes = track.Keyframes
			local exactIndex, prevIndex = KeyframeUtils.findNearestKeyframesProperly(keyframes, playhead-1)
			prevIndex = exactIndex or prevIndex
			local prevFrame = prevIndex and keyframes[prevIndex] or nil
			if prevFrame and prevFrame < playhead then
				maxFrame = maxFrame and math.max(maxFrame, prevFrame) or prevFrame
			end
		end, true)
	end
	return maxFrame or playhead
end

-- Gets the summary keyframes between startTick and endTick for tracks.
-- selectedKeyframes and previewing are optional parameters.
-- selectedKeyframes is used to find which summary keyframes are selected, and
-- previewing is used to determine if the user is currently moving keyframes.
function TrackUtils.getSummaryKeyframes(tracks, startTick, endTick, selectedKeyframes, previewing)
	local foundTicks = {}
	local selectedTicks = {}
	for trackName, track in pairs(tracks) do
		local instance = track.Instance
		-- Sometimes, tracks is passed as an array of tracks without a name
		local name = track.Name or trackName

		TrackUtils.traverseTracks(name, track, function(track, _, path)
			local keyframes = track.Keyframes

			local selectedTrack = selectedKeyframes and selectedKeyframes[instance] or nil
			for _, part in ipairs(path) do
				selectedTrack = selectedTrack and (selectedTrack.Components and selectedTrack.Components[part] or selectedTrack[part])
					or nil
			end

			local selection = selectedTrack and selectedTrack.Selection or {}
			if keyframes and not isEmpty(keyframes) then
				TrackUtils.traverseKeyframeRange(keyframes, startTick, endTick, function(tck)

					foundTicks[tck] = true
					if selection[tck] then
						selectedTicks[tck] = true
					end
				end)
			end
		end, true)
	end

	local ticks = Cryo.Dictionary.keys(foundTicks)
	return ticks, selectedTicks
end

function TrackUtils.getScaledKeyframePosition(tck, startTick, endTick, width)
	return math.floor((tck - startTick) * width / (endTick - startTick))
end

function TrackUtils.getKeyframeFromPosition(position, startTick, endTick, trackLeft, trackWidth)
	local timelineScale = trackWidth / (endTick - startTick)
	local xposInTimeline = position.X - trackLeft
	local tck = startTick + xposInTimeline / timelineScale
	return KeyframeUtils.getNearestTick(tck)
end

function TrackUtils.countVisibleKeyframes(keyframes, startTick, endTick)
	local startIndex, endIndex = TrackUtils.getKeyframesExtents(keyframes, startTick, endTick)
	if startIndex == endIndex then
		local hasKeyframe = KeyframeUtils.findKeyframe(keyframes, startTick)
			or KeyframeUtils.findKeyframe(keyframes, endTick)
		return hasKeyframe ~= nil and 1 or 0
	else
		return endIndex - startIndex + 1
	end
end

function TrackUtils.getKeyframesExtents(keyframes, startTick, endTick)
	local first, second = KeyframeUtils.findNearestKeyframes(keyframes, startTick)
	local startIndex, endIndex
	if second ~= nil then
		startIndex = second
	else
		startIndex = first
	end
	endIndex = KeyframeUtils.findNearestKeyframes(keyframes, endTick)

	if startIndex and endIndex and keyframes[startIndex] >= startTick and keyframes[endIndex] >= startTick then
		return startIndex, endIndex
	end
end

-- Returns the expanded size of a track based on its type.
function TrackUtils.getExpandedSize(track)
	if track.Components then
		-- If the track has components, rely on them
		local function recGetExpandedSize(track)
			local total = 1
			if track.Expanded then
				for _, component in pairs(track.Components) do
					total = total + recGetExpandedSize(component)
				end
			end
			return total
		end

		return recGetExpandedSize(track)
	else
		local trackType = track.Type
		if trackType == Constants.TRACK_TYPES.CFrame then
			return 3
		else
			return 2
		end
	end
end

function TrackUtils.getDefaultValue(track)
	if track and track.Type then
		return KeyframeUtils.getDefaultValue(track.Type)
	end
end

-- Given a track name and a list of trackEntries, find the
-- type of the corresponding track
function TrackUtils.getTrackTypeFromName(trackName, tracks)
	for _, track in pairs(tracks) do
		if track.Name == trackName then
			return track.Type
		end
	end
end

-- Given a full path and a list of trackEntries, find the
-- type of the corresponding component
function TrackUtils.getComponentTypeFromPath(path, tracks)
	for _, track in pairs(tracks) do
		if track.Name == path[1] then
			local relPath = PathUtils.getRelativePath(path)
			local currentComponent = track
			for _, pathPart in ipairs(relPath) do
				if currentComponent.Components and currentComponent.Components[pathPart] then
					currentComponent = currentComponent.Components[pathPart]
				end
			end
			return currentComponent.Type
		end
	end
end

function TrackUtils.getEulerAnglesOrder(track: Types.Track?): (Enum.RotationOrder?)
	if track == nil then
		return nil
	end

	if track.Type == Constants.TRACK_TYPES.CFrame then
		if not track.Components then
			return nil
		end

		return TrackUtils.getEulerAnglesOrder(
			track.Components[Constants.PROPERTY_KEYS.Rotation])
	end

	if track.Type == Constants.TRACK_TYPES.EulerAngles then
		return track.EulerAnglesOrder
	end

	return nil
end

-- Given a track, return the type of rotation used (if relevant)
function TrackUtils.getRotationType(track)
	local rotationTrack = track.Components and track.Components[Constants.PROPERTY_KEYS.Rotation]
	return rotationTrack and rotationTrack.Type or nil
end

-- Given a track name and a list of trackEntries, find the
-- type of rotation used by the track
function TrackUtils.getRotationTypeFromName(trackName, tracks)
	for _, track in pairs(tracks) do
		if track.Name == trackName then
			return TrackUtils.getRotationType(track)
		end
	end
end

-- Given a vertical position yPos in the dope sheet, finds which track
-- is at that position.
function TrackUtils.getTrackFromPosition(tracks, topTrackIndex, yPos)
	local trackIndex = math.max(0, topTrackIndex - 1)
	yPos = yPos - Constants.SUMMARY_TRACK_HEIGHT
	local numTracks = #tracks

	for index, track in ipairs(tracks) do
		if index >= topTrackIndex then
			if yPos <= 0 then
				break
			end

			trackIndex = trackIndex + 1

			if track.Expanded then
				yPos = yPos - Constants.TRACK_HEIGHT * TrackUtils.getExpandedSize(track)
			else
				yPos = yPos - Constants.TRACK_HEIGHT
			end
		end
	end

	-- If yPos is still positive after passing all tracks, it is off
	-- the bottom of the dope sheet.
	if yPos / Constants.TRACK_HEIGHT > 0 then
		return numTracks + 1
	elseif trackIndex == topTrackIndex - 1 then
		-- Summary track
		return 0
	else
		return math.max(0, trackIndex)
	end
end

-- Given a vertical position yPos in the dope sheet, finds which track
-- is at that position. Returns the track index, the path, and the track
-- type
function TrackUtils.getTrackInfoFromPosition(tracks, topTrackIndex, yPos)
	if yPos < Constants.SUMMARY_TRACK_HEIGHT then
		return 0, {}, nil, nil
	end

	yPos = yPos - Constants.SUMMARY_TRACK_HEIGHT

	local function recurse(track, y, path)
		if y < Constants.SUMMARY_TRACK_HEIGHT then
			return path, y, track.Type, TrackUtils.getRotationType(track)
		end

		y = y - Constants.SUMMARY_TRACK_HEIGHT
		if track.Expanded then
			for _, componentName in ipairs(Constants.COMPONENT_TRACK_TYPES[track.Type]._Order) do
				local resPath, trackType
				if track.Components[componentName] then
					resPath, y, trackType = recurse(track.Components[componentName], y, Cryo.List.join(path, {componentName}))
					if resPath then
						return resPath, y, trackType, nil
					end
				end
			end
		end
		return nil, y, nil, nil
	end

	local trackIndex = math.max(0, topTrackIndex - 1)
	local trackType, rotationType

	for index, track in ipairs(tracks) do
		if index >= topTrackIndex then
			local relPath
			relPath, yPos, trackType, rotationType = recurse(track, yPos, {track.Name})
			trackIndex = trackIndex + 1

			if relPath then
				return trackIndex, relPath, trackType, rotationType
			end
		end
	end

	return #tracks + 1, {}, nil, nil
end

function TrackUtils.getTrackIndex(tracks, trackName)
	for index, track in ipairs(tracks) do
		if trackName == track.Name then
			return index
		end
	end
end

function TrackUtils.getTrackYPosition(tracks, topTrackIndex, trackIndex)
	local yPos = Constants.SUMMARY_TRACK_HEIGHT

	local index = topTrackIndex
	while index < trackIndex do
		local currentTrack = tracks[index]
		if currentTrack.Expanded then
			yPos = yPos + Constants.TRACK_HEIGHT * TrackUtils.getExpandedSize(currentTrack)
		else
			yPos = yPos + Constants.TRACK_HEIGHT
		end
		index = index + 1
	end

	return yPos
end

function TrackUtils.getCurrentValue(
	track: Types.Track,
	tck: number,
	animationData: Types.AnimationData,
	defaultEulerAnglesOrder: Enum.RotationOrder)
	: (CFrame | Vector3 | number)?

	local name = track.Name
	local instance = track.Instance

	if animationData == nil then
		return TrackUtils.getDefaultValue(track)
	end

	local currentTrack = animationData.Instances[instance].Tracks[name]
	if currentTrack then
		return KeyframeUtils.getValue(currentTrack, tck, defaultEulerAnglesOrder)
	else
		return TrackUtils.getDefaultValue(track)
	end
end

-- Return the value of the track identified by path, at the specified tick. If the track is not
-- found, return the default value based on trackType
function TrackUtils.getCurrentValueForPath(
	path: PathUtils.Path,
	instance: string,
	tck: number,
	animationData: any,
	trackType: string,
	defaultEulerAnglesOrder: Enum.RotationOrder)
	: ()

	local currentTrack = animationData.Instances[instance]

	-- Follow the path, through Tracks for the first part, or through Components for the next parts
	for index, name in ipairs(path) do
		currentTrack = (index == 1 and currentTrack.Tracks or currentTrack.Components)[name]
		if not currentTrack then
			return KeyframeUtils.getDefaultValue(trackType)
		end
	end

	return KeyframeUtils.getValue(currentTrack, tck, defaultEulerAnglesOrder)
end

function TrackUtils.getItemsForProperty(track, value, name, defaultEAO)
	local trackType = track.Type
	local eulerAnglesOrder = track.EulerAnglesOrder or defaultEAO
	local properties = Constants.PROPERTY_KEYS
	local items

	local function makeVectorItems(x, y, z, componentType)
		return {
			{ Name = Constants.PROPERTY_KEYS.X, Key = "X", Value = x, Type = componentType },
			{ Name = Constants.PROPERTY_KEYS.Y, Key = "Y", Value = y, Type = componentType },
			{ Name = Constants.PROPERTY_KEYS.Z, Key = "Z", Value = z, Type = componentType },
		}
	end

	if trackType == Constants.TRACK_TYPES.CFrame then
		-- This is only used for animations that have not been promoted to channels
		-- This is also the only reason we need to pass down a default EAO, as curve tracks
		-- will have that information embedded.
		local position = value.Position
		local xRot, yRot, zRot
		if GetFFlagCurveEditor() then
			xRot, yRot, zRot = value:ToEulerAngles(eulerAnglesOrder)
		else
			xRot, yRot, zRot = value:ToEulerAnglesXYZ()
		end
		xRot = removeNegativeZero(math.deg(xRot))
		yRot = removeNegativeZero(math.deg(yRot))
		zRot = removeNegativeZero(math.deg(zRot))
		items = {
			Position = makeVectorItems(position.X, position.Y, position.Z, Constants.TRACK_TYPES.Number),
			Rotation = makeVectorItems(xRot, yRot, zRot, Constants.TRACK_TYPES.Angle),
		}
	elseif trackType == Constants.TRACK_TYPES.Position then
		items = makeVectorItems(value.X, value.Y, value.Z, Constants.TRACK_TYPES.Number)
	elseif trackType == Constants.TRACK_TYPES.EulerAngles then
		items = makeVectorItems(removeNegativeZero(math.deg(value.X)),
			removeNegativeZero(math.deg(value.Y)),
			removeNegativeZero(math.deg(value.Z)),
			Constants.TRACK_TYPES.Angle)
	elseif trackType == Constants.TRACK_TYPES.Quaternion then
		local xRot, yRot, zRot
		if GetFFlagCurveEditor() then
			xRot, yRot, zRot = value:ToEulerAngles(eulerAnglesOrder)
		else
			xRot, yRot, zRot = value:ToEulerAnglesXYZ()
		end
		items = makeVectorItems(removeNegativeZero(math.deg(xRot)),
			removeNegativeZero(math.deg(yRot)),
			removeNegativeZero(math.deg(zRot)),
			Constants.TRACK_TYPES.Angle)
	elseif trackType == Constants.TRACK_TYPES.Facs then
		if GetFFlagFacsUiChanges() then
			value = math.clamp(value, 0, 1)
		end
		items = {
			{
				Name = "V",
				Key = "Value",
				Value = value,
				Type = Constants.TRACK_TYPES.Facs,
			},
		}
	elseif trackType == Constants.TRACK_TYPES.Angle then
		items = {
			{
				Name = name,
				Key = name,
				Value = removeNegativeZero(math.deg(value)),
				Type = Constants.TRACK_TYPES.Angle,
			},
		}
	else
		items = {
			{
				Name = name,
				Key = name,
				Value = value,
				Type = Constants.TRACK_TYPES.Number,
			},
		}
	end

	return items
end

function TrackUtils.getPropertyForItems(track, items, defaultEAO)
	local trackType = track.Type
	local value
	local eulerAnglesOrder = track.EulerAnglesOrder or defaultEAO

	if trackType == Constants.TRACK_TYPES.CFrame then
		local position = items.Position
		local rotation = items.Rotation
		local xRot = math.rad(rotation[1].Value)
		local yRot = math.rad(rotation[2].Value)
		local zRot = math.rad(rotation[3].Value)
		value = CFrame.new(position[1].Value, position[2].Value, position[3].Value)
			* CFrame.fromEulerAngles(xRot, yRot, zRot, eulerAnglesOrder)
	elseif trackType == Constants.TRACK_TYPES.Position then
		value = Vector3.new(items[1].Value, items[2].Value, items[3].Value)
	elseif trackType == Constants.TRACK_TYPES.EulerAngles then
		value = Vector3.new(math.rad(items[1].Value), math.rad(items[2].Value), math.rad(items[3].Value))
	elseif trackType == Constants.TRACK_TYPES.Quaternion then
		value = CFrame.fromEulerAngles(math.rad(items[1].Value), math.rad(items[2].Value), math.rad(items[3].Value), eulerAnglesOrder)
	elseif trackType == Constants.TRACK_TYPES.Number then
		value = items[1].Value
	elseif trackType == Constants.TRACK_TYPES.Angle then
		value = math.rad(items[1].Value)
	elseif trackType == Constants.TRACK_TYPES.Facs then
		value = items[1].Value
		if GetFFlagFacsUiChanges() then
			value = math.clamp(value, 0, 1)
		end
	end

	return value
end

function TrackUtils.getZoomRange(animationData, scroll, zoom, editingLength)
	local range = {}
	local startTick = animationData.Metadata.StartTick
	local endTick = math.max(animationData.Metadata.EndTick, editingLength)

	local length = endTick - startTick
	local lengthWithPadding = length * Constants.LENGTH_PADDING
	lengthWithPadding = math.min(lengthWithPadding, Constants.MAX_ANIMATION_LENGTH)

	local zoomedLength = lengthWithPadding * (1 - zoom)
	zoomedLength = math.max(zoomedLength, 1)

	range.Start = startTick + (lengthWithPadding - zoomedLength) * scroll
	range.End = range.Start + zoomedLength

	return range
end

function TrackUtils.adjustCurves(track)
	if not track.Keyframes then
		return
	end

	-- Make a copy, because we're possibly going to add new keyframes (cubic/bounce/elastic interpolation)
	local keyframesCopy = Cryo.List.join({}, track.Keyframes)

	for index, tck in pairs(keyframesCopy) do
		local data = track.Data[tck]
		local easingStyle = data.EasingStyle
		local easingDirection = data.EasingDirection

		if index < #keyframesCopy then
			local nextTick = keyframesCopy[index+1]
			local nextData = track.Data[nextTick]

			local newKeyframes = CurveUtils.generateCurve(track.Type, easingStyle, easingDirection, tck, data, nextTick, nextData)
			if newKeyframes and not isEmpty(newKeyframes) then
				track.Keyframes = Cryo.List.join(track.Keyframes, Cryo.Dictionary.keys(newKeyframes))
				track.Data = Cryo.Dictionary.join(track.Data, newKeyframes)
			end
		else
			data.EasingStyle = nil
			data.EasingDirection = nil
			data.InterpolationMode = Constants.POSE_EASING_STYLE_TO_KEY_INTERPOLATION[easingStyle]
		end
	end

	table.sort(track.Keyframes)
	track.IsCurveTrack = true
end

function TrackUtils.splitTrackComponents(track, rotationType, eulerAnglesOrder)
	if track.Type == Constants.TRACK_TYPES.CFrame then
		-- Creates the components hierarchy for a track
		local function createTrackComponents(_track)
			local componentTypes = Constants.COMPONENT_TRACK_TYPES[_track.Type]

			if componentTypes then
				-- If there are children, create them and their descendants
				_track.Components = {}
				for _, componentName in pairs(componentTypes._Order) do
					local componentType = componentTypes[componentName]
					if componentName == Constants.PROPERTY_KEYS.Rotation and rotationType then
						componentType = rotationType
					end

					_track.Components[componentName] = Templates.track(componentType)
					if GetFFlagCurveEditor() and componentName == Constants.PROPERTY_KEYS.Rotation
							and componentType == Constants.TRACK_TYPES.EulerAngles then
						_track.Components[componentName].EulerAnglesOrder = eulerAnglesOrder
					end
					createTrackComponents(_track.Components[componentName])
				end
			else
				-- We can already duplicate the keyframes from the top track and prepare the data array
				_track.Keyframes = track.Keyframes and Cryo.List.join({}, track.Keyframes) or {}
				_track.Data = {}
			end
		end

		createTrackComponents(track)

		for _, tck in pairs(track.Keyframes or {}) do
			local cFrame = track.Data[tck].Value

			if rotationType == Constants.TRACK_TYPES.Quaternion then
				local position = cFrame.Position
				local quaternion = cFrame - cFrame.Position

				local positionTrack = track.Components.Position
				local rotationTrack = track.Components.Rotation

				for _, componentName in ipairs(Constants.COMPONENT_TRACK_TYPES[Constants.TRACK_TYPES.Position]._Order) do
					positionTrack.Components[componentName].Data[tck] = Cryo.Dictionary.join(track.Data[tck], { Value = position[componentName] })
				end

				rotationTrack.Data[tck] = Cryo.Dictionary.join(track.Data[tck], { Value = quaternion })
			else
				-- Decompose the CFrame into two Vectors so they can both be accessed by .X, .Y, .Z
				local position = cFrame.Position
				local rotation
				if GetFFlagCurveEditor() then
					rotation = Vector3.new(cFrame:ToEulerAngles(eulerAnglesOrder))
				else
					rotation = Vector3.new(cFrame:ToEulerAnglesXYZ())
				end

				for componentName, componentTrack in pairs(track.Components) do
					local values = componentName == Constants.PROPERTY_KEYS.Position and position or rotation

					for grandchildName, grandchild in pairs(componentTrack.Components) do
						grandchild.Data[tck] = Cryo.Dictionary.join(track.Data[tck], {
							Value = values[grandchildName]
						})
					end
					componentTrack.Keyframes = nil
					componentTrack.Data = nil
				end
			end
		end

		-- Adjust tangents, add intermediate nodes (bouncing/elastic), etc
		for _, componentTrack in pairs(track.Components) do
			TrackUtils.adjustCurves(componentTrack)
			for _, grandchild in pairs(componentTrack.Components or {}) do
				TrackUtils.adjustCurves(grandchild)
			end
		end

		-- Delete top track data
		track.Keyframes = nil
		track.Data = nil
	elseif track.Type == Constants.TRACK_TYPES.Facs then
		track.Keyframes = track.Keyframes or {}
		track.Data = track.Data or {}
		TrackUtils.adjustCurves(track)
	end
end

function TrackUtils.createTrackListEntryComponents(
	track: Track,
	instanceName: string,
	rotationType: string,
	eulerAnglesOrder: string)
	: ()

	local componentTypes = Constants.COMPONENT_TRACK_TYPES[track.Type]
	track.Instance = instanceName

	if componentTypes then
		-- If there are children, create them and their descendants
		track.Components = {}
		for _, componentName in ipairs(componentTypes._Order) do
			local componentType = componentTypes[componentName]

			if not GetFFlagCurveEditor() then
				if componentName == Constants.PROPERTY_KEYS.Rotation then
					componentType = rotationType
				end

				track.Components[componentName] = Templates.trackListEntry(componentType)
				track.Components[componentName].Name = componentName
			else
				local newTrack

				if componentName == Constants.PROPERTY_KEYS.Rotation then
					newTrack = Templates.trackListEntry(rotationType)
					if rotationType == Constants.TRACK_TYPES.EulerAngles then
						newTrack.EulerAnglesOrder = eulerAnglesOrder
					end
				else
					newTrack = Templates.trackListEntry(componentType)
				end
				newTrack.Name = componentName
				track.Components[componentName] = newTrack
			end

			TrackUtils.createTrackListEntryComponents(
				track.Components[componentName],
				instanceName,
				rotationType,
				eulerAnglesOrder)
		end
	end
end

-- For each tick between startTick and endTick, return a table that contains:
-- Count: The number of component leaves that are defined
-- Complete: Whether all expected components are defined
-- EasingStyle: The easing style shared by all components, or nil if there's a mismatch

function TrackUtils.getComponentsInfo(track: any, startTick: number, endTick: number?)
	endTick = endTick or startTick

	local info = {}
	local expectedComponents = 0
	TrackUtils.traverseTracks(nil, track, function()
		expectedComponents = expectedComponents + 1
	end, true)

	TrackUtils.traverseTracks(nil, track, function(track)
		if track.Data then
			for tck, data in pairs(track.Data) do
				if tck >= startTick and tck <= endTick then
					if info[tck] then
						info[tck].Count = info[tck].Count + 1
						info[tck].Complete = info[tck].Count == expectedComponents
						if info[tck].EasingStyle ~= data.EasingStyle then
							info[tck].EasingStyle = nil
						end
						if info[tck].InterpolationMode ~= data.InterpolationMode then
							info[tck].InterpolationMode = nil
						end
					else
						info[tck] = {
							Count = 1,
							Complete = expectedComponents == 1,
							EasingStyle = data.EasingStyle,
							InterpolationMode = data.InterpolationMode
						}
					end
				end
			end
		end
	end, true)
	return info
end

-- Follows the elements of trackPath to reach a specific track in the trackEntries hierarchies
function TrackUtils.findTrackEntry(trackEntries, trackPath)
	if not (trackEntries and trackPath) then
		return nil
	end

	local currentTrack
	for _, trackEntry in ipairs(trackEntries) do
		if trackEntry.Name == trackPath[1] then
			currentTrack = trackEntry
			break
		end
	end

	if not currentTrack then
		return nil
	end

	for index, pathPart in ipairs(trackPath) do
		if index > 1 then
			currentTrack = currentTrack.Components[pathPart]
			if not currentTrack then
				return nil
			end
		end
	end

	return currentTrack
end

-- Traverse all components of the provided trackType, calling func with
-- the relative path of each leaf (to the initial track type)
-- TODO: We can get rid of rotationType if we decide to have two different CFrame types,
-- such as EulerCFrame and QuaternionCFrame, for the top level track.
function TrackUtils.traverseComponents(trackType, func, rotationType)
	local function recurse(_trackType, relPath)

		local compTypes = Constants.COMPONENT_TRACK_TYPES[_trackType]
		if compTypes then
			for _, compName in ipairs(compTypes._Order) do
				local compType = compTypes[compName]
				if compName == Constants.PROPERTY_KEYS.Rotation then
					compType = rotationType
				end
				recurse(compType, Cryo.List.join(relPath, {compName}))
			end
		else
			func(_trackType, relPath)
		end
	end

	recurse(trackType, {})
end

-- Takes a trackType and a value, and calls the func callback for each leaf component.
-- func is called with the leaf relative path (to the initial track type), and the value.
-- This relies on paths only, tracks don't have to exist.
-- rotationType determines if we want to follow the Quaternion hierarchy, or the Euler angles hierarchy.
function TrackUtils.traverseValue(trackType, value, func, rotationType, eulerAnglesOrder)
	local function recurse(_trackType, relPath, _value)
		if _trackType == Constants.TRACK_TYPES.CFrame then
			local position = _value.Position
			recurse(Constants.TRACK_TYPES.Position, Cryo.List.join(relPath, {Constants.PROPERTY_KEYS.Position}), position)

			local rotation
			if rotationType == Constants.TRACK_TYPES.Quaternion then
				rotation = _value - position
			else
				if GetFFlagCurveEditor() then
					rotation = Vector3.new(_value:ToEulerAngles(eulerAnglesOrder))
				else
					rotation = Vector3.new(_value:ToEulerAnglesXYZ())
				end
			end
			recurse(rotationType, Cryo.List.join(relPath, {Constants.PROPERTY_KEYS.Rotation}), rotation)
		elseif _trackType == Constants.TRACK_TYPES.Position then
			recurse(Constants.TRACK_TYPES.Number, Cryo.List.join(relPath, {Constants.PROPERTY_KEYS.X}), _value.X)
			recurse(Constants.TRACK_TYPES.Number, Cryo.List.join(relPath, {Constants.PROPERTY_KEYS.Y}), _value.Y)
			recurse(Constants.TRACK_TYPES.Number, Cryo.List.join(relPath, {Constants.PROPERTY_KEYS.Z}), _value.Z)
		elseif _trackType == Constants.TRACK_TYPES.EulerAngles then
			recurse(Constants.TRACK_TYPES.Angle, Cryo.List.join(relPath, {Constants.PROPERTY_KEYS.X}), _value.X)
			recurse(Constants.TRACK_TYPES.Angle, Cryo.List.join(relPath, {Constants.PROPERTY_KEYS.Y}), _value.Y)
			recurse(Constants.TRACK_TYPES.Angle, Cryo.List.join(relPath, {Constants.PROPERTY_KEYS.Z}), _value.Z)
		else
			func(_trackType, relPath, _value)
		end
	end

	recurse(trackType, {}, value)
end

-- Returns the previous keyframe. If exactMatch is set, and there is an existing keyframe at that tick,
-- that keyframe is returned
function TrackUtils.findPreviousKeyframe(track, tck, exactMatch: boolean?)
	local exactIndex, prevIndex, _ = KeyframeUtils.findNearestKeyframesProperly(track.Keyframes, tck)
	if exactMatch then
		prevIndex = prevIndex or exactIndex
	end
	local prevTick = prevIndex and track.Keyframes[prevIndex] or nil
	return prevTick and track.Data[prevTick] or nil
end

function TrackUtils.convertTrackToEulerAngles(track: Track, eulerAnglesOrder: Enum.RotationOrder): ()
	-- This abstracts the euler angles order.
	local toAngles: {[Enum.RotationOrder]: (Vector3) -> (number, number, number)} = {
		[Enum.RotationOrder.XYZ] = function(v) return v.Z, v.Y, v.X end,
		[Enum.RotationOrder.XZY] = function(v) return v.Y, v.Z, v.X end,
		[Enum.RotationOrder.YXZ] = function(v) return v.Z, v.X, v.Y end,
		[Enum.RotationOrder.YZX] = function(v) return v.X, v.Z, v.Y end,
		[Enum.RotationOrder.ZXY] = function(v) return v.Y, v.X, v.Z end,
		[Enum.RotationOrder.ZYX] = function(v) return v.X, v.Y, v.Z end,
	}

	local fromAngles: {[Enum.RotationOrder]: (number, number, number) -> (Vector3)} = {
		[Enum.RotationOrder.XYZ] = function(a, b, c) return Vector3.new(c, b, a) end,
		[Enum.RotationOrder.XZY] = function(a, b, c) return Vector3.new(c, a, b) end,
		[Enum.RotationOrder.YXZ] = function(a, b, c) return Vector3.new(b, c, a) end,
		[Enum.RotationOrder.YZX] = function(a, b, c) return Vector3.new(a, c, b) end,
		[Enum.RotationOrder.ZXY] = function(a, b, c) return Vector3.new(b, a, c) end,
		[Enum.RotationOrder.ZYX] = function(a, b, c) return Vector3.new(a, b, c) end,
	}

	-- Given a set of three previous angles and a new CFrame, find the Euler
	-- decomposition that best fits the previous angles.
	local function findClosestAngles(prevAngles: Vector3, value:CFrame): Vector3
		local angles = Vector3.new(value:ToEulerAngles(eulerAnglesOrder))

		if not prevAngles then
			return angles
		end

		local alpha, beta, gamma = toAngles[eulerAnglesOrder](angles)
		local prevAlpha, prevBeta, prevGamma = toAngles[eulerAnglesOrder](prevAngles)

		-- From now on, beta is always the second angle that is applied. It is also
		-- the one that is calculated by an asin, and therefore the only one that
		-- can accept a "mirrored" solution beta2 = PI - beta + 2kPI, on top of the
		-- generic beta + 2kPI solution.
		-- Alpha and gamma can only accept the generic solutions
		-- [alpha|gamma] + 2kPI. However, if beta is mirrored, then alpha and gamma
		-- must also be shifted by PI radians.
		local alpha2 = alpha + math.pi
		local beta2 = math.pi - beta
		local gamma2 = gamma + math.pi

		-- Since each angle accepts a generic solution a+2kPI,
		-- let's start by moving each angle within PI radians of the previous angle.
		local function reduceFullCircles(last: number, now: number): (number)
			local nCircles = math.floor((last - now) / (math.pi * 2) + 0.5)
			return now + nCircles * math.pi * 2
		end
		alpha = reduceFullCircles(prevAlpha, alpha)
		alpha2 = reduceFullCircles(prevAlpha, alpha2)
		beta = reduceFullCircles(prevBeta, beta)
		beta2 = reduceFullCircles(prevBeta, beta2)
		gamma = reduceFullCircles(prevGamma, gamma)
		gamma2 = reduceFullCircles(prevGamma, gamma2)

		local dist = ((prevAlpha-alpha) * (prevAlpha-alpha))
			+ ((prevBeta-beta) * (prevBeta-beta))
			+ ((prevGamma-gamma) * (prevGamma-gamma))

		local dist2 = ((prevAlpha-alpha2) * (prevAlpha-alpha2))
			+ ((prevBeta-beta2) * (prevBeta-beta2))
			+ ((prevGamma-gamma2) * (prevGamma-gamma2))

		-- Pick the best option
		if dist <= dist2 then
			return fromAngles[eulerAnglesOrder](alpha, beta, gamma)
		else
			return fromAngles[eulerAnglesOrder](alpha2, beta2, gamma2)
		end
	end

	local componentNames = Constants.COMPONENT_TRACK_TYPES[Constants.TRACK_TYPES.EulerAngles]._Order

	-- First pass. Create components and copy the ticks.
	track.Components = {}
	track.EulerAnglesOrder = eulerAnglesOrder
	for _, componentName in ipairs(componentNames) do
		local componentType = Constants.COMPONENT_TRACK_TYPES[Constants.TRACK_TYPES.EulerAngles][componentName]
		local componentTrack = Templates.track(componentType)

		componentTrack.Keyframes = Cryo.List.join(track.Keyframes)
		componentTrack.Data = {}
		componentTrack.IsCurveTrack = true
		track.Components[componentName] = componentTrack
	end

	-- Find the Euler Angles and create the keyframes in the 3
	-- components
	local angles = nil
	for _, tck in ipairs(track.Keyframes) do
		local keyframe = track.Data[tck]
		angles = findClosestAngles(angles, keyframe.Value)

		for _, componentName in ipairs(componentNames) do
			local newKeyframe = Templates.keyframe()
			newKeyframe.Value = angles[componentName]
			newKeyframe.InterpolationMode = track.Data[tck].InterpolationMode
			track.Components[componentName].Data[tck] = newKeyframe
		end
	end

	-- Calculate the slopes
	for _, componentName in ipairs(componentNames) do
		local componentTrack = track.Components[componentName]

		for index, tck in ipairs(track.Keyframes) do
			local prevTick = track.Keyframes[index-1]
			local nextTick = track.Keyframes[index+1]
			local parentKeyframe = track.Data[tck]

			local keyframe = componentTrack.Data[tck]

			-- Adjust the slopes by multiplying them by the value difference
			-- with the previous (left) or the next (right) key. For quaternion
			-- rotations, the slope is calculated to go from 0 to 1. For Euler
			-- angles, we need to adjust them to go from vl to v (left) or v to
			-- vr (right)
			if parentKeyframe.LeftSlope ~= nil and prevTick then
				local prevValue = componentTrack.Data[prevTick].Value
				local delta = angles[componentName] - prevValue
				keyframe.LeftSlope = parentKeyframe.LeftSlope * delta
			else
				keyframe.LeftSlope = nil
			end
			if parentKeyframe.RightSlope ~= nil and nextTick then
				local nextValue = componentTrack.Data[nextTick].Value
				local delta = nextValue - angles[componentName]
				keyframe.RightSlope = parentKeyframe.RightSlope * delta
			else
				keyframe.RightSlope = nil
			end
		end
	end

	-- Delete data from the parent
	track.Keyframes = nil
	track.Data = nil
	track.Type = Constants.TRACK_TYPES.EulerAngles
end

function TrackUtils.countKeyframes(track: Types.Track): (number)
	local numKeyframes = 0
	TrackUtils.traverseTracks(nil, track, function(componentTrack: Types.Track): ()
		if componentTrack.Keyframes then
			numKeyframes += #componentTrack.Keyframes
		end
	end, true)

	return numKeyframes
end

return TrackUtils
