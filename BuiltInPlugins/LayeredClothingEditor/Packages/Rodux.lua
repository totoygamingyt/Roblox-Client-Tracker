--[[
	Package link auto-generated by manage_libraries and Rotriever
]]
local FFlagLayeredClothingEditorDeduplicatePackages = game:GetFastFlag("LayeredClothingEditorDeduplicatePackages")
if FFlagLayeredClothingEditorDeduplicatePackages then
	local PackageIndex = script.Parent._Index
	local Package = require(PackageIndex["roblox_rodux"]["rodux"])
	return Package
else
	local PackageIndex = script.Parent._IndexOld
	return require(PackageIndex["roblox_rodux"]["rodux"])
end

