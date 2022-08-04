 -- Remove with FFlagDeprecateMaterialController

local Plugin = script.Parent.Parent.Parent
local _Types = require(Plugin.Src.Types)
local Framework = require(Plugin.Packages.Framework)

local ContextItem = Framework.ContextServices.ContextItem

local FrameworkUtil = Framework.Util
local Signal = FrameworkUtil.Signal

local Util = Plugin.Src.Util
local damerauLevenshteinDistance = require(Util.DamerauLevenshteinDistance)
local containsPath = require(Util.ContainsPath)

local Constants = Plugin.Src.Resources.Constants
local getMaterialPath = require(Constants.getMaterialPath)
local getMaterialType = require(Constants.getMaterialType)
local getMaterialName = require(Constants.getMaterialName)
local getSupportedMaterials = require(Constants.getSupportedMaterials)

local supportedMaterials = getSupportedMaterials()

export type Category = {
	Builtin: boolean,
	Categories: _Types.Map<string, Category>,
	CategoryNames: _Types.Array<string>,
	Materials: _Types.Array<_Types.Material>,
}

local function recurseMaterials(category: Category, materialList: _Types.Array<_Types.Material>, filter: ((material: _Types.Material) -> boolean)?)
	-- Optimized to make sure we don't need to check for filter's existence every iteration
	if filter then
		for _, material in ipairs(category.Materials) do
			if filter(material) then
				table.insert(materialList, material)
			end
		end
	else
		for _, material in ipairs(category.Materials) do
			table.insert(materialList, material)
		end
	end

	for _, categoryName in ipairs(category.CategoryNames) do
		recurseMaterials(category.Categories[categoryName], materialList, filter)
	end
end

local MaterialController = ContextItem:extend("MaterialController")

function MaterialController.new(materialServiceWrapper: any)
	local self = setmetatable({
		_categoryChangedSignal = Signal.new(),
		_materialAddedSignal = Signal.new(),
		_materialRemovedSignal = Signal.new(),
		_materialChangedSignal = Signal.new(),
		_materialNameChangedSignal = Signal.new(),
		_materialStatusChangedSignal = Signal.new(),
		_overrideChangedSignal = Signal.new(),
		_materialChangedListeners = {},

		_rootCategory = {
			Categories = {},
			CategoryNames = {},
			Materials = {},
		},
		_materialPaths = {},
		_materialWrappers = {},
		_materialStatuses = {},
		_materialServiceWrapper = materialServiceWrapper,
		_nameToEnum = {},
	}, MaterialController)

	self._materialServiceAdded = self._materialServiceWrapper:asInstance().DescendantAdded:Connect(function(instance)
		if instance:IsA("MaterialVariant") then
			self:addMaterial(instance.BaseMaterial, instance, getMaterialPath(instance.BaseMaterial))
		end
	end)

	self._materialServiceRemoved = self._materialServiceWrapper:asInstance().DescendantRemoving:Connect(function(instance)
		if instance:IsA("MaterialVariant") then
			self:removeMaterial(instance)
		end
	end)

	self._materialServiceChanged = self._materialServiceWrapper:asInstance().Changed:Connect(function(property)
		if self._nameToEnum[property] then
			self._overrideChangedSignal:Fire(self._nameToEnum[property])
		end
	end)

	for material, _ in pairs(supportedMaterials) do
		self:addMaterial(material, nil, getMaterialPath(material))
	end

	for _, descendant in ipairs(self._materialServiceWrapper:asInstance():GetDescendants()) do
		if descendant:IsA("MaterialVariant") then
			self:addMaterial(descendant.BaseMaterial, descendant, getMaterialPath(descendant.BaseMaterial))
		end
	end

	for materialEnum, _ in ipairs(supportedMaterials) do
		local materialName = getMaterialName(materialEnum) .. "Name"
		self._nameToEnum[materialName] = materialEnum
	end

	return self
end

function MaterialController:destroy()
	self._materialServiceAdded:Disconnect()
	self._materialServiceRemoved:Disconnect()
	self._materialServiceChanged:Disconnect()

	for materialIndex, materialListeners in ipairs(self._materialChangedListeners) do
		self._materialChangedListeners[materialIndex]:Disconnect()
		self._materialChangedListeners[materialIndex] = nil
	end
end

function MaterialController:getMaterialWrapper(material : Enum.Material, materialVariant : MaterialVariant?) : _Types.Material
	return {
		Material = material,
		MaterialPath = getMaterialPath(material),
		MaterialType = getMaterialType(material),
		MaterialVariant = materialVariant,
	}
end

function MaterialController:getRootCategory() : Category
	return self._rootCategory
end

function MaterialController:addCategory(path: _Types.Path, builtin: boolean): Category?
	return self:findCategory(path, builtin, true)
end

function MaterialController:findCategory(path: _Types.Path, builtin: boolean?, add: boolean?): Category?
	assert(#path > 0 or not add, "Can't add root category")

	local category: Category = self._rootCategory
	local changed = false
	for _, directory in ipairs(path) do
		if category.Categories[directory] then
			category = category.Categories[directory]
		elseif add then
			changed = true

			category.Categories[directory] = {
				Builtin = builtin,
				Categories = {},
				CategoryNames = {},
				Materials = {},
			}
			table.insert(category.CategoryNames, directory)
			table.sort(category.CategoryNames)

			category = category.Categories[directory]
		else
			return nil
		end
	end

	if changed then
		self._categoryChangedSignal:Fire(path)
	end

	return category
end

function MaterialController:removeCategory(path: _Types.Path)
	-- TODO

	assert(false, "MaterialController does not currently support removing categories")
end

function MaterialController:moveCategory(source: _Types.Path, target: _Types.Path)
	-- TODO

	assert(false, "MaterialController does not currently support moving categories")
end

function MaterialController:getCategoriesChangedSignal(): RBXScriptSignal
	return self._categoryChangedSignal
end

function MaterialController:getOverrideStatus(materialType : Enum.Material) : Enum.PropertyStatus
	return self._materialServiceWrapper:asService():GetOverrideStatus(materialType)
end

function MaterialController:addMaterial(material : Enum.Material, materialVariant : MaterialVariant, moving : boolean)
	local path = getMaterialPath(material)
	local materialWrapper = self:getMaterialWrapper(material, materialVariant)
	local category = self:addCategory(path, not materialWrapper.MaterialVariant)
	assert(category, "Category to which a Material is added should exist, or be created")
	table.insert(category.Materials, materialWrapper)

	if materialVariant then
		self._materialPaths[materialVariant] = path
		self._materialWrappers[materialVariant] = materialWrapper
		-- If the way to categorize is changed, make it happen here
		assert(not self._materialChangedListeners[materialVariant], "Already connected to material changed")

		self._materialChangedListeners[materialVariant] = materialVariant.Changed:Connect(function(property)
			if property == "ColorMap" or property == "MetalnessMap" or property == "NormalMap" or property == "RoughnessMap" then
				self._materialChangedSignal:Fire(materialVariant)
			elseif property == "StudsPerTile" then
				self._materialChangedSignal:Fire(materialVariant)
			elseif property == "MaterialPattern" then
				self._materialChangedSignal:Fire(materialVariant)
			elseif property == "BaseMaterial" then
				self:moveMaterial(materialVariant)
				self._materialChangedSignal:Fire(materialVariant)
			elseif property == "Name" then
				self._materialChangedSignal:Fire(materialVariant)
				self._materialNameChangedSignal:Fire(materialVariant)
			end
		end)
	else
		self._materialPaths[material] = path
		self._materialWrappers[material] = materialWrapper
	end

	self._materialAddedSignal:Fire(path, materialVariant, moving)
end

-- Built-in Materials will never be removed so there is not point in adding support for them here
function MaterialController:removeMaterial(material : MaterialVariant, moving : boolean)
	local path = self._materialPaths[material]
	assert(path, "Cannot remove material that does not exist")
	local category = self:findCategory(path)
	assert(category, "Cannot remove material from category that does not exist")

	for index, materialInfo in ipairs(category.Materials) do
		if materialInfo.MaterialVariant == material then
			table.remove(category.Materials, index)
			break
		end
	end

	self._materialPaths[material] = nil
	self._materialWrappers[material] = nil

	if self._materialChangedListeners[material] then
		self._materialChangedListeners[material]:Disconnect()
		self._materialChangedListeners[material] = nil
	end

	self._materialRemovedSignal:Fire(path, material, moving)
end

function MaterialController:moveMaterial(material: MaterialVariant)
	assert(self._materialPaths[material], "Tried to move material that wasn't registered.")

	self:removeMaterial(material, true)
	self:addMaterial(material.BaseMaterial, material, true)
end

function MaterialController:getMaterial(material: MaterialVariant)
	return self._materialWrappers[material]
end

function MaterialController:getMaterials(path: _Types.Path, search: string?): _Types.Array<_Types.Material>
	local category = self:findCategory(path)
	assert(category, "Tried to get materials for path which does not exist")

	local materials = {}

	if not search or search == "" then
		recurseMaterials(category, materials)
	else
		local tolerance = 0
		search = string.lower(search)


		local function searchFilter(material)
			local name
			if material.MaterialVariant then
				name = string.lower(material.MaterialVariant.Name)
			else
				name = string.lower(getMaterialName(material.Material))
			end
			local findName = string.find(name, search) or damerauLevenshteinDistance(name, search) == tolerance
			return findName and (#path == 0 or containsPath(path, getMaterialPath(material.Material)))
		end

		recurseMaterials(category, materials, searchFilter)

		if #materials == 0 then
			tolerance = 1
			recurseMaterials(category, materials, searchFilter)
		end
	end

	return materials
end

function MaterialController:getVariants(baseMaterial: Enum.Material)
	local category = self:findCategory({})
	assert(category, "Tried to get materials for path which does not exist")

	local materials = {}
	recurseMaterials(category, materials, function(material)
		return material.MaterialVariant and material.MaterialVariant.BaseMaterial == baseMaterial
	end)

	return materials
end

function MaterialController:ifMaterialNameExists(name: string, baseMaterial: Enum.Material): boolean
	local category = self:findCategory({})
	assert(category, "Tried to get materials for path which does not exist")

	local materials = {}
	recurseMaterials(category, materials, function(material)
		return material.MaterialVariant and material.MaterialVariant.Name == name and material.Material == baseMaterial
	end)

	return #materials ~= 0
end

function MaterialController:getUses2022Materials(): boolean
	return self._materialServiceWrapper:asService().Use2022Materials
end

function MaterialController:getMaterialOverrideChangedSignal(material : Enum.Material)
	return self._materialServiceWrapper:asService():GetMaterialOverrideChanged(material)
end

function MaterialController:getBuiltInMaterialsChangedSignal(material : Enum.Material)
	return self._materialServiceWrapper:asInstance():GetPropertyChangedSignal("Use2022Materials")
end

function MaterialController:getMaterialOverride(material : Enum.Material) : string
	if supportedMaterials[material] then
		return self._materialServiceWrapper:asService():GetBaseMaterialOverride(material)
	else
		return ""
	end
end

function MaterialController:setMaterialOverride(material : Enum.Material, materialVariant : string?)
	self._materialServiceWrapper:asService():SetBaseMaterialOverride(material, materialVariant or "")
end

function MaterialController:getMaterialOverrides(material: Enum.Material): (_Types.Array<_Types.Material>, number)
	local currentOverride = self:getMaterialOverride(material)

	local materialIndex = -1
	local materials = {}
	local materialNames = {}

	local options = self:getVariants(material)
	table.insert(options, {
		MaterialVariant = {
			Name = getMaterialName(material)
		}
	})
	table.sort(options, function(a, b) return a.MaterialVariant.Name:upper() < b.MaterialVariant.Name:upper() end)

	for index, variant in ipairs(options) do
		local name = variant.MaterialVariant.Name
		if materialNames[name] then
			continue
		end

		table.insert(materials, name)
		materialNames[name] = true

		if name == currentOverride then
			materialIndex = index
		end
	end

	table.sort(materials)

	if currentOverride == "" then
		return materials, 0
	end

	return materials, materialIndex
end

function MaterialController:getMaterialVariant(material : Enum.Material, name : string) : MaterialVariant
	return self._materialServiceWrapper:asService():GetMaterialVariant(material, name)
end

function MaterialController:getMaterialAddedSignal(): RBXScriptSignal
	return self._materialAddedSignal
end

function MaterialController:getMaterialRemovedSignal(): RBXScriptSignal
	return self._materialRemovedSignal
end

function MaterialController:getMaterialChangedSignal(): RBXScriptSignal
	return self._materialChangedSignal
end

function MaterialController:getMaterialNameChangedSignal(): RBXScriptSignal
	return self._materialNameChangedSignal
end

function MaterialController:getOverrideChangedSignal(): RBXScriptSignal
	return self._overrideChangedSignal
end

function MaterialController:getOverrideStatusChangedSignal() : RBXScriptSignal
	return self._materialServiceWrapper:asService().OverrideStatusChanged
end

return MaterialController
