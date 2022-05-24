local Plugin = script.Parent.Parent.Parent.Parent

local getFFlagDisableAvatarAnchoredSetting = require(Plugin.Src.Flags.getFFlagDisableAvatarAnchoredSetting)

local AssetImportService = game:GetService("AssetImportService")

local getFFlagAssetImporterFixPivotAndInsertLocations = require(Plugin.Src.Flags.getFFlagAssetImporterFixPivotAndInsertLocations)

local function hideIfAvatar()
	return AssetImportService:IsAvatar() and getFFlagDisableAvatarAnchoredSetting()
end

local function hideIfNotAvatar()
	return not AssetImportService:IsAvatar()
end

local function hideIfNotInsertToWorkspace(rootSettings)
	if getFFlagAssetImporterFixPivotAndInsertLocations() then
		return not rootSettings.InsertInWorkspace
	else
		return true
	end
end

return {
	{
		Section = "FileGeneral",
		Properties = {
			{Name = "ImportName", Editable = true},
			{Name = "ImportAsModelAsset", Editable = true},
			{Name = "InsertInWorkspace", Editable = true},
			{Name = "InsertWithScenePosition", Editable = true, ShouldHide = hideIfNotInsertToWorkspace},
			{Name = "Anchored", Editable = true, ShouldHide = hideIfAvatar},
		},
	},
	{
		Section = "AvatarGeneral",
		Properties = {
			{Name = "RigType", Editable = true, ShouldHide = hideIfNotAvatar},
		},
	},
	{
		Section = "FileTransform",
		Properties = {
			{Name = "WorldForward", Editable = true, Dependencies = {"WorldUp"}},
			{Name = "WorldUp", Editable = true, Dependencies = {"WorldForward"}},
		},
	},
	{
		Section = "FileGeometry",
		Properties = {
			{Name = "ScaleUnit", Editable = true},
			{Name = "FileDimensions", Editable = false, Dependencies = {"ScaleUnit"}},
			{Name = "PolygonCount", Editable = false},
			{Name = "MergeMeshes", Editable = true},
			{Name = "InvertNegativeFaces", Editable = true},
		},
	},
}
