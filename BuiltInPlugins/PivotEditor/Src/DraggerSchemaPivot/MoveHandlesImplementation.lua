local Plugin = script.Parent.Parent.Parent

local DraggerFramework = Plugin.Packages.DraggerFramework

local Roact = require(Plugin.Packages.Roact)

local getSelectableWithCache = require(Plugin.Packages.DraggerSchemaCore.getSelectableWithCache)

local setWorldPivot = require(Plugin.Src.Utility.setWorldPivot)
local computeSnapPointsForInstance = require(Plugin.Src.Utility.computeSnapPointsForInstance)
local SnapPoints = require(Plugin.Src.Components.SnapPoints)
local DraggedPivot = require(DraggerFramework.Components.DraggedPivot)
local classifyInstancePivot = require(Plugin.Src.Utility.classifyInstancePivot)

local MoveHandlesImplementation = {}
MoveHandlesImplementation.__index = MoveHandlesImplementation

function MoveHandlesImplementation.new(draggerContext, analyticsName)
	return setmetatable({
		_draggerContext = draggerContext,
		_analyticsName = analyticsName,
	}, MoveHandlesImplementation)
end

function MoveHandlesImplementation:_selectedIsActive()
	if self._draggerContext:shouldShowActiveInstanceHighlight() then
		return self._selection[#self._selection] == self._primaryObject
	else
		return false
	end
end

function MoveHandlesImplementation:_setCurrentSnap(object: Instance?)
	self._snapPoints = computeSnapPointsForInstance(object)
	self._snapPointsAreFor = object
end

function MoveHandlesImplementation:beginDrag(selection, initialSelectionInfo)
	self._selection = selection
	self._initialPivot = initialSelectionInfo:getBoundingBox()

	-- Note: _primaryObject may be nil in the case where we delete an object in
	-- the middle of dragging a handle.
	self._primaryObject = initialSelectionInfo:getPrimaryObject()
	self:_setCurrentSnap(self._primaryObject)
end

-- Get the first selectable associated any of the candidateParts
-- A loop is required because this may be non-trivial in the case where some of
-- the parts have Locked = true.
local function findSelectable(candidateParts: {BasePart}): PVInstance?
	for _, part in ipairs(candidateParts) do
		local candidateSelectable = getSelectableWithCache(part, false, {})
		if candidateSelectable then
			return candidateSelectable
		end
	end
	return nil
end

function MoveHandlesImplementation:_findNewSnapTargetImpl(smallTestPart: BasePart)
	local hitParts = smallTestPart:GetTouchingParts()

	-- Prefer "sticking to" the current snap target over choosing a new one.
	for _, part in ipairs(hitParts) do
		if part:IsDescendantOf(self._snapPointsAreFor) then
			return
		end
	end
	
	-- Not colliding with anything in the current snap target, find a new one.
	local newCandidate = findSelectable(hitParts)
	if newCandidate then
		self:_setCurrentSnap(newCandidate)
	end
end

function MoveHandlesImplementation:_findNewSnapTargetViaCollision(pivot)
	-- TODO: This code should use WorldRoot:GetPartsInPart() once that
	-- method is implemented and ships instead of GetTouchingParts() which
	-- requires us to temporarily parent the part to the workspace. Vs
	-- GetPartsInPart will not require that.

	-- 0.01 is a magic value as close to zero as makes sense. 0.05 is the min
	-- physical part size at the time of writing, but that may change, and 0.01
	-- is small enough that building at any reasonable scale you won't get
	-- artifacts where you notice the non-zero-ness of the value.
	local temporaryPartForRegionQuery = Instance.new("Part")
	temporaryPartForRegionQuery.Size = Vector3.new(0.01, 0.01, 0.01)
	temporaryPartForRegionQuery.Position = pivot.Position

	-- Disable archivable so that the ChangeHistoryService won't notice the
	-- test part as a spurious changed item.
	temporaryPartForRegionQuery.Archivable = false

	-- Stick the test part under Terrain to minimize the chance of it
	-- interfearing with some event listener on stuff in the workspace, and
	-- to prevent it messing with the scroll state of the Explorer pane.
	temporaryPartForRegionQuery.Parent = workspace.Terrain

	self:_findNewSnapTargetImpl(temporaryPartForRegionQuery)

	-- Clean up the region query part
	temporaryPartForRegionQuery:Destroy()
end

function MoveHandlesImplementation:updateDrag(globalTransform)
	if self._primaryObject then
		local newPivot = globalTransform * self._initialPivot
		setWorldPivot(self._primaryObject, newPivot)
		self:_findNewSnapTargetViaCollision(newPivot)
	end
	return globalTransform
end

function MoveHandlesImplementation:endDrag()
	if self._primaryObject then
		self._draggerContext:getAnalytics():sendEvent("setPivot", {
			gridSize = self._draggerContext:getGridSize(),
			rotateIncrement = self._draggerContext:getRotateIncrement(),
			toolName = self._analyticsName,
			handleId = "Move",
			pivotType = classifyInstancePivot(self._primaryObject),
		})
	end
end

function MoveHandlesImplementation:getSnapPoints()
	if self._draggerContext:shouldSnapPivotToGeometry() then
		return self._snapPoints
	else
		return nil
	end
end

function MoveHandlesImplementation:render(globalTransform)
	local currentPivot = globalTransform * self._initialPivot
	local contents = {
		DraggedPivot = Roact.createElement(DraggedPivot, {
			DraggerContext = self._draggerContext,
			CFrame = currentPivot,
			IsActive = self:_selectedIsActive(),
		}),
	}
	-- not _snapPoints will be the case when we drag into a Tool or Constraint.
	if self._draggerContext:shouldSnapPivotToGeometry() then
		contents.SnapPoints = Roact.createElement(SnapPoints, {
			Focus = currentPivot.Position,
			SnapPoints = self._snapPoints,
			DraggerContext = self._draggerContext,
		})
	end
	return Roact.createFragment(contents)
end

return MoveHandlesImplementation