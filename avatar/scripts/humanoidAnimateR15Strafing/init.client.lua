local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local pose = "Standing"

local userNoUpdateOnLoopSuccess, userNoUpdateOnLoopValue = pcall(function() return UserSettings():IsUserFeatureEnabled("UserNoUpdateOnLoop") end)
local userNoUpdateOnLoop = userNoUpdateOnLoopSuccess and userNoUpdateOnLoopValue

local userEmoteToRunThresholdChange do
	local success, value = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserEmoteToRunThresholdChange")
	end)
	userEmoteToRunThresholdChange = success and value
end

local userPlayEmoteByIdAnimTrackReturn do
	local success, value = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserPlayEmoteByIdAnimTrackReturn2")
	end)
	userPlayEmoteByIdAnimTrackReturn = success and value
end

local AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
local HumanoidHipHeight = 2

local cachedRunningSpeed = 0 -- The most recent speed passed to onRunning().  Tiny variations from cachedRunningSpeed will not cause animation updates.
local cachedLocalDirection = {x=0.0, y=0.0} -- unit 2D object space direction of motion
local smallButNotZero = 0.0001 -- We want weights to be small but not so small the animation stops
local strafingDisabled = nil
local runBlendtime = 0.1
local rootPart

local function strafeMode()
	local result = not strafingDisabled and not Humanoid.AutoRotate
	return result
end

local EMOTE_TRANSITION_TIME = 0.1

local currentAnim = ""
local currentAnimInstance = nil
local currentAnimTrack = nil
local currentAnimKeyframeHandler = nil
local currentAnimSpeed = 1.0

local runAnimTrack = nil
local runAnimKeyframeHandler = nil

local PreloadedAnims = {}

local animTable = {}
local animNames = { 
	idle = 	{
		{ id = "http://www.roblox.com/asset/?id=507766666", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=507766951", weight = 1 },
		{ id = "http://www.roblox.com/asset/?id=507766388", weight = 9 }
	},
	walk = 	{
		{ id = "http://www.roblox.com/asset/?id=507777826", weight = 10 }
	},
	run = 	{
		{ id = "http://www.roblox.com/asset/?id=507767714", weight = 10 }
	},

	swim = 	{
		{ id = "http://www.roblox.com/asset/?id=507784897", weight = 10 }
	},
	swimidle = 	{
		{ id = "http://www.roblox.com/asset/?id=507785072", weight = 10 }
	},
	jump = 	{
		{ id = "http://www.roblox.com/asset/?id=507765000", weight = 10 }
	},
	fall = 	{
		{ id = "http://www.roblox.com/asset/?id=507767968", weight = 10 }
	},
	climb = {
		{ id = "http://www.roblox.com/asset/?id=507765644", weight = 10 }
	},
	sit = 	{
		{ id = "http://www.roblox.com/asset/?id=2506281703", weight = 10 }
	},
	toolnone = {
		{ id = "http://www.roblox.com/asset/?id=507768375", weight = 10 }
	},
	toolslash = {
		{ id = "http://www.roblox.com/asset/?id=522635514", weight = 10 }
	},
	toollunge = {
		{ id = "http://www.roblox.com/asset/?id=522638767", weight = 10 }
	},
	wave = {
		{ id = "http://www.roblox.com/asset/?id=507770239", weight = 10 }
	},
	point = {
		{ id = "http://www.roblox.com/asset/?id=507770453", weight = 10 }
	},
	dance = {
		{ id = "http://www.roblox.com/asset/?id=507771019", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507771955", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507772104", weight = 10 }
	},
	dance2 = {
		{ id = "http://www.roblox.com/asset/?id=507776043", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507776720", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507776879", weight = 10 }
	},
	dance3 = {
		{ id = "http://www.roblox.com/asset/?id=507777268", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507777451", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507777623", weight = 10 }
	},
	laugh = {
		{ id = "http://www.roblox.com/asset/?id=507770818", weight = 10 }
	},
	cheer = {
		{ id = "http://www.roblox.com/asset/?id=507770677", weight = 10 }
	},
}

local locomotionMap = {}

-- Existance in this list signifies that it is an emote, the value indicates if it is a looping emote
local emoteNames = { wave = false, point = false, dance = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

math.randomseed(tick())

function findExistingAnimationInSet(set, anim)
	if set == nil or anim == nil then
		return 0
	end

	for idx = 1, set.count, 1 do
		if set[idx].anim.AnimationId == anim.AnimationId then
			return idx
		end
	end

	return 0
end

function configureAnimationSet(name, fileList)
	if (animTable[name] ~= nil) then
		for _, connection in pairs(animTable[name].connections) do
			connection:disconnect()
		end
	end
	animTable[name] = {}
	animTable[name].count = 0
	animTable[name].totalWeight = 0
	animTable[name].connections = {}

	local allowCustomAnimations = true

	local success, msg = pcall(function() allowCustomAnimations = game:GetService("StarterPlayer").AllowCustomAnimations end)
	if not success then
		allowCustomAnimations = true
	end

	-- check for config values
	local config = script:FindFirstChild(name)
	if (allowCustomAnimations and config ~= nil) then
		table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
		table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))
		
		local idx = 0

		for _, childPart in pairs(config:GetChildren()) do
			if (childPart:IsA("Animation")) then
				local newWeight = 1
				local weightObject = childPart:FindFirstChild("Weight")
				if (weightObject ~= nil) then
					newWeight = weightObject.Value
				end
				animTable[name].count = animTable[name].count + 1
				idx = animTable[name].count
				animTable[name][idx] = {}
				animTable[name][idx].anim = childPart
				animTable[name][idx].weight = newWeight
				animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
				table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
				table.insert(animTable[name].connections, childPart.ChildAdded:connect(function(property) configureAnimationSet(name, fileList) end))
				table.insert(animTable[name].connections, childPart.ChildRemoved:connect(function(property) configureAnimationSet(name, fileList) end))
				local lv = childPart:GetAttribute("LinearVelocity")
				if lv then
					locomotionMap[name] = {lv={x=lv.x, y=lv.y}, speed = math.sqrt(lv.x * lv.x + lv.y * lv.y)}
				elseif name == "run" or name == "walk" then
					-- If you don't have a linear velocity with your run or walk, you can't blend/strafe
					locomotionMap[name] = {}
					warn("Strafe blending disabled. No linear velocity information for "..'"'.."walk"..'"'.." and "..'"'.."run"..'"'..".")
					strafingDisabled = true
				end
			end
		end
	end

	-- fallback to defaults
	if (animTable[name].count <= 0) then
		for idx, anim in pairs(fileList) do
			animTable[name][idx] = {}
			animTable[name][idx].anim = Instance.new("Animation")
			animTable[name][idx].anim.Name = name
			animTable[name][idx].anim.AnimationId = anim.id
			animTable[name][idx].weight = anim.weight
			animTable[name].count = animTable[name].count + 1
			animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
		end
	end

	-- preload anims
	for i, animType in pairs(animTable) do
		for idx = 1, animType.count, 1 do
			if PreloadedAnims[animType[idx].anim.AnimationId] == nil then
				Humanoid:LoadAnimation(animType[idx].anim)
				PreloadedAnims[animType[idx].anim.AnimationId] = true
			end
		end
	end
end

------------------------------------------------------------------------------------------------------------

function configureAnimationSetOld(name, fileList)
	if (animTable[name] ~= nil) then
		for _, connection in pairs(animTable[name].connections) do
			connection:disconnect()
		end
	end
	animTable[name] = {}
	animTable[name].count = 0
	animTable[name].totalWeight = 0
	animTable[name].connections = {}

	local allowCustomAnimations = true

	local success, msg = pcall(function() allowCustomAnimations = game:GetService("StarterPlayer").AllowCustomAnimations end)
	if not success then
		allowCustomAnimations = true
	end

	-- check for config values
	local config = script:FindFirstChild(name)
	if (allowCustomAnimations and config ~= nil) then
		table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
		table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))
		local idx = 1
		for _, childPart in pairs(config:GetChildren()) do
			if (childPart:IsA("Animation")) then
				table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
				animTable[name][idx] = {}
				animTable[name][idx].anim = childPart
				local weightObject = childPart:FindFirstChild("Weight")
				if (weightObject == nil) then
					animTable[name][idx].weight = 1
				else
					animTable[name][idx].weight = weightObject.Value
				end
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
				idx = idx + 1
			end
		end
	end

	-- fallback to defaults
	if (animTable[name].count <= 0) then
		for idx, anim in pairs(fileList) do
			animTable[name][idx] = {}
			animTable[name][idx].anim = Instance.new("Animation")
			animTable[name][idx].anim.Name = name
			animTable[name][idx].anim.AnimationId = anim.id
			animTable[name][idx].weight = anim.weight
			animTable[name].count = animTable[name].count + 1
			animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
		end
	end

	-- preload anims
	for i, animType in pairs(animTable) do
		for idx = 1, animType.count, 1 do
			Humanoid:LoadAnimation(animType[idx].anim)
		end
	end
end

-- Setup animation objects
function scriptChildModified(child)
	local fileList = animNames[child.Name]
	if (fileList ~= nil) then
		configureAnimationSet(child.Name, fileList)
	else
		if child:isA("StringValue") then
			animNames[child.Name] = {}
			configureAnimationSet(child.Name, animNames[child.Name])
		end
	end	
end

script.ChildAdded:connect(scriptChildModified)
script.ChildRemoved:connect(scriptChildModified)

-- Clear any existing animation tracks
-- Fixes issue with characters that are moved in and out of the Workspace accumulating tracks
local animator = if Humanoid then Humanoid:FindFirstChildOfClass("Animator") else nil
if animator then
	local animTracks = animator:GetPlayingAnimationTracks()
	for i,track in ipairs(animTracks) do
		track:Stop(0)
		track:Destroy()
	end
end

for name, fileList in pairs(animNames) do
	configureAnimationSet(name, fileList)
end
for child in script:GetChildren() do
	if child.isA("StringValue") and not animNames[child.name] then
		animNames[child.Name] = {}
		configureAnimationSet(child.Name, animNames[child.Name])
	end
end

-- ANIMATION

-- declarations
local toolAnim = "None"
local toolAnimTime = 0

local jumpAnimTime = 0
local jumpAnimDuration = 0.31

local toolTransitionTime = 0.1
local fallTransitionTime = 0.2

local currentlyPlayingEmote = false

-- functions

function stopAllAnimations()
	local oldAnim = currentAnim

	-- return to idle if finishing an emote
	if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
		oldAnim = "idle"
	end

	if currentlyPlayingEmote then
		oldAnim = "idle"
		currentlyPlayingEmote = false
	end

	currentAnim = ""
	currentAnimInstance = nil
	if (currentAnimKeyframeHandler ~= nil) then
		currentAnimKeyframeHandler:disconnect()
	end

	if (currentAnimTrack ~= nil) then
		currentAnimTrack:Stop()
		currentAnimTrack:Destroy()
		currentAnimTrack = nil
	end

	for _,v in pairs(locomotionMap) do
		if v.track then
			v.track:Stop()
			v.track:Destroy()
			v.track = nil
		end
	end
	if not strafeMode() then

		if (runAnimKeyframeHandler ~= nil) then
			runAnimKeyframeHandler:disconnect()
		end

	end

	return oldAnim
end

function getHeightScale()
	if Humanoid then
		if not Humanoid.AutomaticScalingEnabled then
			return 1
		end

		local scale = Humanoid.HipHeight / HumanoidHipHeight
		if AnimationSpeedDampeningObject == nil then
			AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
		end
		if AnimationSpeedDampeningObject ~= nil then
			scale = 1 + (Humanoid.HipHeight - HumanoidHipHeight) * AnimationSpeedDampeningObject.Value / HumanoidHipHeight
		end
		return scale
	end
	return 1
end


local function signedAngle(a, b)
	return -math.atan2(a.x * b.y - a.y * b.x, a.x * b.x + a.y * b.y)
end

local angleWeight = 2.0
local function get2DWeight(px, p1, p2, sx, s1, s2)
	local avgLength = 0.5 * (s1 + s2)

	local p_1 = {x = (sx - s1)/avgLength, y = (angleWeight * signedAngle(p1, px))}
	local p12 = {x = (s2 - s1)/avgLength, y = (angleWeight * signedAngle(p1, p2))}	
	local denom = smallButNotZero + (p12.x*p12.x + p12.y*p12.y)
	local numer = p_1.x * p12.x + p_1.y * p12.y
	local r = math.clamp(1.0 - numer/denom, 0.0, 1.0)
	return r
end

local function blend2D(targetVelo, targetSpeed)
	local h = {}
	local sum = 0.0
	for n,v1 in pairs(locomotionMap) do
		if targetVelo.x * v1.lv.x < 0.0 or targetVelo.y * v1.lv.y < 0 then
			-- Require same quadrant as target
			h[n] = 0.0
			continue
		end
		h[n] = math.huge
		for j,v2 in pairs(locomotionMap) do
			if targetVelo.x * v2.lv.x < 0.0 or targetVelo.y * v2.lv.y < 0 then
				-- Require same quadrant as target
				continue
			end
			h[n] = math.min(h[n], get2DWeight(targetVelo, v1.lv, v2.lv, targetSpeed, v1.speed, v2.speed))
		end
		sum += h[n]
	end

	--truncates below 10% contribution
	local sum2 = 0.0
	local weightedVeloX = 0
	local weightedVeloY = 0
	for n,v in pairs(locomotionMap) do

		if (h[n] / sum > 0.1) then
			sum2 += h[n]
			weightedVeloX += h[n] * v.lv.x
			weightedVeloY += h[n] * v.lv.y
		else
			h[n] = 0.0
		end
	end
	local animSpeed
	local weightedSpeedSquared = weightedVeloX * weightedVeloX + weightedVeloY * weightedVeloY
	if weightedSpeedSquared > smallButNotZero then
		animSpeed = math.sqrt(targetSpeed * targetSpeed / weightedSpeedSquared)
	else
		animSpeed = 0
	end

	animSpeed = animSpeed / getHeightScale()
	local groupTimePosition = 0
	for n,v in pairs(locomotionMap) do
		if v.track.IsPlaying then
			groupTimePosition = v.track.TimePosition
			break
		end
	end
	for n,v in pairs(locomotionMap) do
		-- if not loco
		if h[n] > 0.0 then
			if not v.track.IsPlaying then 
				v.track:Play(runBlendtime)
				v.track.TimePosition = groupTimePosition
			end

			local weight = math.max(smallButNotZero, h[n] / sum2)
			v.track:AdjustWeight(weight, runBlendtime)
			v.track:AdjustSpeed(animSpeed)
		else
			v.track:Stop(runBlendtime)
		end
	end

end

local function getWalkDirection()
	local walkToPoint = Humanoid.WalkToPoint
	local walkToPart = Humanoid.WalkToPart
	if Humanoid.MoveDirection ~= Vector3.zero then
		return Humanoid.MoveDirection
	elseif walkToPart or walkToPoint ~= Vector3.zero then
		local destination
		if walkToPart then
			destination = walkToPart.CFrame:PointToWorldSpace(walkToPoint)
		else
			destination = walkToPoint
		end
		local moveVector = destination - Humanoid.RootPart.CFrame.Position
		moveVector = Vector3.new(moveVector.x, 0.0, moveVector.z)
		local mag = moveVector.Magnitude
		if mag > 0.01 then
			moveVector /= mag
		else
			moveVector = Vector3.zero
		end
		return moveVector
	else
		return Humanoid.MoveDirection
	end
end

local function onVelocityChanged(speed)
	if not strafeMode() then
		return
	end
	if not speed then
		-- If speed wasn't passed in, assume it hasn't changed
		speed = cachedRunningSpeed
	end
	cachedRunningSpeed = speed
	local moveDirection = getWalkDirection()
	if not rootPart then
		rootPart = Humanoid.RootPart
		rootPart:GetPropertyChangedSignal("Rotation"):Connect(onVelocityChanged)
	end
	local cframe = rootPart.CFrame
	if math.abs(cframe.UpVector.Y) < smallButNotZero or pose ~= "Running" or speed <0.001 then
		-- We are horizontal!  Do something  (turn off locomotion)
		for n,v in pairs(locomotionMap) do
			if v.track then
				v.track:AdjustWeight(smallButNotZero, runBlendtime)
				cachedRunningSpeed = 0
			end
		end
		return
	end
	local lookat = cframe.LookVector
	local direction = Vector3.new(lookat.X, 0.0, lookat.Z)
	direction = direction / direction.Magnitude --sensible upVector means this is non-zero.
	local ly = moveDirection:Dot(direction)
	local lx = direction.X*moveDirection.Z - direction.Z*moveDirection.X
	local tempDir = {x=lx, y=ly} -- root space moveDirection
	local delta = {x=tempDir.x-cachedLocalDirection.x, y=tempDir.y-cachedLocalDirection.y}
	if delta.x*delta.x + delta.y*delta.y > 0.001 or math.abs(speed - cachedRunningSpeed) > 0.01 then
		cachedLocalDirection = tempDir
		blend2D(cachedLocalDirection, cachedRunningSpeed)
		cachedRunningSpeed = speed
	end 

end

local function onRootPartChanged()
	if rootPart then
		rootPart:GetPropertyChangedSignal("Rotation"):Disconnect(onVelocityChanged)
	end
	rootPart = Humanoid.RootPart
	rootPart:GetPropertyChangedSignal("Rotation"):Connect(onVelocityChanged)
end

local function rootMotionCompensation(speed)
	local speedScaled = speed * 1.25
	local heightScale = getHeightScale()
	local runSpeed = speedScaled / heightScale
	return runSpeed
end

local function setRunSpeed(speed)
	local normalizedWalkSpeed = 0.5 -- established empirically using current `913402848` walk animation
	local normalizedRunSpeed  = 1
	local runSpeed = rootMotionCompensation(speed)
	local walkAnimationWeight = smallButNotZero
	local runAnimationWeight = smallButNotZero
	local walkAnimationTimewarp = runSpeed/normalizedWalkSpeed
	local runAnimationTimerwarp = runSpeed/normalizedRunSpeed

	if runSpeed <= normalizedWalkSpeed then
		walkAnimationWeight = 1
	elseif runSpeed < normalizedRunSpeed then
		local fadeInRun = (runSpeed - normalizedWalkSpeed)/(normalizedRunSpeed - normalizedWalkSpeed)
		walkAnimationWeight = 1 - fadeInRun
		runAnimationWeight  = fadeInRun
		walkAnimationTimewarp = 1
		runAnimationTimerwarp = 1
	else
		runAnimationWeight = 1
	end
	currentAnimTrack:AdjustWeight(walkAnimationWeight)
	runAnimTrack:AdjustWeight(runAnimationWeight)
	currentAnimTrack:AdjustSpeed(walkAnimationTimewarp)
	runAnimTrack:AdjustSpeed(runAnimationTimerwarp)
end

function setAnimationSpeed(speed)
	if currentAnim == "walk" then
		if not strafeMode() then
			setRunSpeed(speed)
		end
	else
		if speed ~= currentAnimSpeed then
			currentAnimSpeed = speed
			currentAnimTrack:AdjustSpeed(currentAnimSpeed)
		end
	end
end

function keyFrameReachedFunc(frameName)
	if (frameName == "End") then
		if currentAnim == "walk" then
			if strafeMode() then
				for n,v in pairs(locomotionMap) do
					local track = v.track
				 	if not userNoUpdateOnLoop or track.Looped ~= true then
				 		track.timePosition = 0.0
					end
				 end
			else
				if userNoUpdateOnLoop == true then
					if runAnimTrack.Looped ~= true then
						runAnimTrack.TimePosition = 0.0
					end
					if currentAnimTrack.Looped ~= true then
						currentAnimTrack.TimePosition = 0.0
					end
				else
					runAnimTrack.TimePosition = 0.0
					currentAnimTrack.TimePosition = 0.0
				end
			end
		else
			local repeatAnim = currentAnim
			-- return to idle if finishing an emote
			if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
				repeatAnim = "idle"
			end

			if currentlyPlayingEmote then
				if currentAnimTrack.Looped then
					-- Allow the emote to loop
					return
				end
				
				repeatAnim = "idle"
				currentlyPlayingEmote = false
			end

			local animSpeed = currentAnimSpeed
			playAnimation(repeatAnim, 0.15, Humanoid)
			setAnimationSpeed(animSpeed)
		end
	end
end

function rollAnimation(animName)
	local roll = math.random(1, animTable[animName].totalWeight)
	local origRoll = roll
	local idx = 1
	while (roll > animTable[animName][idx].weight) do
		roll = roll - animTable[animName][idx].weight
		idx = idx + 1
	end
	return idx
end

local maxVeloX, minVeloX, maxVeloY, minVeloY

local function destroyRunAnimations()
	for _,v in pairs(locomotionMap) do
		if v.track then
			v.track:Stop()
			v.track:Destroy()
			v.track = nil
		end
	end
end

local function resetVelocityBounds(velo)
	minVeloX = 0
	maxVeloX = 0
	minVeloY = 0
	maxVeloY = 0
end

local function updateVelocityBounds(velo)
	if velo then 
		if velo.x > maxVeloX then maxVeloX = velo.x end
		if velo.y > maxVeloY then maxVeloY = velo.y end
		if velo.x < minVeloX then minVeloX = velo.x end
		if velo.y < minVeloY then minVeloY = velo.y end
	end
end

local function checkVelocityBounds(velo)
	if not strafingDisabled and (maxVeloX == 0 or minVeloX == 0 or maxVeloY == 0 or minVeloY == 0) then
		warn("Strafe blending disabled.  Not all quandrants of motion represented.")
		strafingDisabled = true
	end
end

local function setupWalkAnimation(anim, animName, transitionTime, humanoid)
	resetVelocityBounds()
	-- check to see if we need to blend a walk/run animation
	for n,v in pairs(locomotionMap) do
		v.track = humanoid:LoadAnimation(animTable[n][1].anim)
		v.track.Priority = Enum.AnimationPriority.Core
		updateVelocityBounds(v.lv)
	end
	checkVelocityBounds()
	currentAnimTrack = locomotionMap["walk"].track
	runAnimTrack = locomotionMap["run"].track
	if strafeMode() then
		onVelocityChanged()
	else
		currentAnimTrack:Play(0.2)
		currentAnimTrack:AdjustWeight(smallButNotZero)
		runAnimTrack:Play(0.2)
		runAnimTrack:AdjustWeight(smallButNotZero)
		if (runAnimKeyframeHandler ~= nil) then
			runAnimKeyframeHandler:disconnect()
		end

		runAnimKeyframeHandler = runAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)

	end
end

local function switchToAnim(anim, animName, transitionTime, humanoid)
	-- switch animation		
	if (anim ~= currentAnimInstance) then

		if (currentAnimTrack ~= nil) then
			currentAnimTrack:Stop(transitionTime)
			currentAnimTrack:Destroy()
		end
		if (currentAnimKeyframeHandler ~= nil) then
			currentAnimKeyframeHandler:disconnect()
		end

		destroyRunAnimations()

		if userNoUpdateOnLoop == true then
			runAnimTrack = nil
		end

		currentAnimSpeed = 1.0

		currentAnim = animName
		currentAnimInstance = anim	

		if animName == "walk" then
			setupWalkAnimation(anim, animName, transitionTime, humanoid)
		else
			-- load it to the humanoid; get AnimationTrack
			currentAnimTrack = humanoid:LoadAnimation(anim)
			currentAnimTrack.Priority = Enum.AnimationPriority.Core
 
			currentAnimTrack:Play(transitionTime)		
		end

		-- set up keyframe name triggers
		currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)

	end
end

function playAnimation(animName, transitionTime, humanoid)
	local idx = rollAnimation(animName)
	local anim = animTable[animName][idx].anim

	switchToAnim(anim, animName, transitionTime, humanoid)
	currentlyPlayingEmote = false
end

function playEmote(emoteAnim, transitionTime, humanoid)
	switchToAnim(emoteAnim, emoteAnim.Name, transitionTime, humanoid)
	currentlyPlayingEmote = true
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

local toolAnimName = ""
local toolAnimTrack = nil
local toolAnimInstance = nil
local currentToolAnimKeyframeHandler = nil

function toolKeyFrameReachedFunc(frameName)
	if (frameName == "End") then
		playToolAnimation(toolAnimName, 0.0, Humanoid)
	end
end


function playToolAnimation(animName, transitionTime, humanoid, priority)
		local idx = rollAnimation(animName)
		local anim = animTable[animName][idx].anim

		if (toolAnimInstance ~= anim) then

			if (toolAnimTrack ~= nil) then
				toolAnimTrack:Stop()
				toolAnimTrack:Destroy()
				transitionTime = 0
			end

			-- load it to the humanoid; get AnimationTrack
			toolAnimTrack = humanoid:LoadAnimation(anim)
			if priority then
				toolAnimTrack.Priority = priority
			end

			-- play the animation
			toolAnimTrack:Play(transitionTime)
			toolAnimName = animName
			toolAnimInstance = anim

			currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
		end
end

function stopToolAnimations()
	local oldAnim = toolAnimName

	if (currentToolAnimKeyframeHandler ~= nil) then
		currentToolAnimKeyframeHandler:disconnect()
	end

	toolAnimName = ""
	toolAnimInstance = nil
	if (toolAnimTrack ~= nil) then
		toolAnimTrack:Stop()
		toolAnimTrack:Destroy()
		toolAnimTrack = nil
	end

	return oldAnim
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- STATE CHANGE HANDLERS

function onRunning(speed)
	local movedDuringEmote =
		userEmoteToRunThresholdChange and currentlyPlayingEmote and Humanoid.MoveDirection == Vector3.new(0, 0, 0)
	local speedThreshold = movedDuringEmote and Humanoid.WalkSpeed or 0.75
	if speed > speedThreshold then
		local scale = 16.0
		playAnimation("walk", 0.2, Humanoid)
		setAnimationSpeed(speed / scale)
		pose = "Running"
	else
		if emoteNames[currentAnim] == nil and not currentlyPlayingEmote then
			playAnimation("idle", 0.2, Humanoid)
			pose = "Standing"
		end
	end
	if strafeMode() then
		onVelocityChanged(speed)
	end
end

function onDied()
	pose = "Dead"
end

function onJumping()
	playAnimation("jump", 0.1, Humanoid)
	jumpAnimTime = jumpAnimDuration
	pose = "Jumping"
end

function onClimbing(speed)
	local scale = 5.0
	playAnimation("climb", 0.1, Humanoid)
	setAnimationSpeed(speed / scale)
	pose = "Climbing"
end

function onGettingUp()
	pose = "GettingUp"
end

function onFreeFall()
	if (jumpAnimTime <= 0) then
		playAnimation("fall", fallTransitionTime, Humanoid)
	end
	pose = "FreeFall"
end

function onFallingDown()
	pose = "FallingDown"
end

function onSeated()
	pose = "Seated"
end

function onPlatformStanding()
	pose = "PlatformStanding"
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

function onSwimming(speed)
	if speed > 1.00 then
		local scale = 10.0
		playAnimation("swim", 0.4, Humanoid)
		setAnimationSpeed(speed / scale)
		pose = "Swimming"
	else
		playAnimation("swimidle", 0.4, Humanoid)
		pose = "Standing"
	end
end

function animateTool()
	if (toolAnim == "None") then
		playToolAnimation("toolnone", toolTransitionTime, Humanoid, Enum.AnimationPriority.Idle)
		return
	end

	if (toolAnim == "Slash") then
		playToolAnimation("toolslash", 0, Humanoid, Enum.AnimationPriority.Action)
		return
	end

	if (toolAnim == "Lunge") then
		playToolAnimation("toollunge", 0, Humanoid, Enum.AnimationPriority.Action)
		return
	end
end

function getToolAnim(tool)
	for _, c in ipairs(tool:GetChildren()) do
		if c.Name == "toolanim" and c.className == "StringValue" then
			return c
		end
	end
	return nil
end

local lastTick = 0

function stepAnimate(currentTime)
	local amplitude = 1
	local frequency = 1
  	local deltaTime = currentTime - lastTick
  	lastTick = currentTime

	local climbFudge = 0
	local setAngles = false

  	if (jumpAnimTime > 0) then
  		jumpAnimTime = jumpAnimTime - deltaTime
  	end

	if (pose == "FreeFall" and jumpAnimTime <= 0) then
		playAnimation("fall", fallTransitionTime, Humanoid)
	elseif (pose == "Seated") then
		playAnimation("sit", 0.5, Humanoid)
		return
	elseif (pose == "Running") then
		playAnimation("walk", 0.2, Humanoid)
	elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
		stopAllAnimations()
		amplitude = 0.1
		frequency = 1
		setAngles = true
	end

	-- Tool Animation handling
	local tool = Character:FindFirstChildOfClass("Tool")
	if tool and tool:FindFirstChild("Handle") then
		local animStringValueObject = getToolAnim(tool)

		if animStringValueObject then
			toolAnim = animStringValueObject.Value
			-- message recieved, delete StringValue
			animStringValueObject.Parent = nil
			toolAnimTime = currentTime + .3
		end

		if currentTime > toolAnimTime then
			toolAnimTime = 0
			toolAnim = "None"
		end

		animateTool()
	else
		stopToolAnimations()
		toolAnim = "None"
		toolAnimInstance = nil
		toolAnimTime = 0
	end
end


local function onAutoRotate()
	-- reset running
	onRunning(cachedRunningSpeed)
end

-- connect events
Humanoid.Died:connect(onDied)
Humanoid.Running:connect(onRunning)
Humanoid.Jumping:connect(onJumping)
Humanoid.Climbing:connect(onClimbing)
Humanoid.GettingUp:connect(onGettingUp)
Humanoid.FreeFalling:connect(onFreeFall)
Humanoid.FallingDown:connect(onFallingDown)
Humanoid.Seated:connect(onSeated)
Humanoid.PlatformStanding:connect(onPlatformStanding)
Humanoid.Swimming:connect(onSwimming)

Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(onVelocityChanged)
Humanoid:GetPropertyChangedSignal("RootPart"):Connect(onRootPartChanged)
Humanoid:GetPropertyChangedSignal("AutoRotate"):Connect(onAutoRotate)
Humanoid:GetPropertyChangedSignal("WalkToPoint"):Connect(onVelocityChanged)
Humanoid:GetPropertyChangedSignal("WalkToPart"):Connect(onVelocityChanged)

-- setup emote chat hook
game:GetService("Players").LocalPlayer.Chatted:connect(function(msg)
	local emote = ""
	if (string.sub(msg, 1, 3) == "/e ") then
		emote = string.sub(msg, 4)
	elseif (string.sub(msg, 1, 7) == "/emote ") then
		emote = string.sub(msg, 8)
	end

	if (pose == "Standing" and emoteNames[emote] ~= nil) then
		playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)
	end
end)

-- emote bindable hook
script:WaitForChild("PlayEmote").OnInvoke = function(emote)
	-- Only play emotes when idling
	if pose ~= "Standing" then
		return
	end

	if emoteNames[emote] ~= nil then
		-- Default emotes
		playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)

		if userPlayEmoteByIdAnimTrackReturn then
			return true, currentAnimTrack
		else
			return true
		end
	elseif typeof(emote) == "Instance" and emote:IsA("Animation") then
		-- Non-default emotes
		playEmote(emote, EMOTE_TRANSITION_TIME, Humanoid)

		if userPlayEmoteByIdAnimTrackReturn then
			return true, currentAnimTrack
		else
			return true
		end
	end

	-- Return false to indicate that the emote could not be played
	return false
end

if Character.Parent ~= nil then
	-- initialize to idle
	playAnimation("idle", 0.1, Humanoid)
	pose = "Standing"
end

-- loop to handle timed state transitions and tool animations
while Character.Parent ~= nil do
	local _, currentGameTime = wait(0.1)
	stepAnimate(currentGameTime)
end
