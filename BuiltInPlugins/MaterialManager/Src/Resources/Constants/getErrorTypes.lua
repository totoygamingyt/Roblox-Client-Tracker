local Plugin = script.Parent.Parent.Parent.Parent
local _Types = require(Plugin.Src.Types)

export type ErrorType = string

local ErrorTypes: _Types.Map<string, ErrorType> = {
	FailedUrl = "FailedUrl",
	FailedToSelectFile = "FailedToSelectFile",
	FailedToImportMap = "FailedToImportMap",
	FailedToUploadFromFileMap = "FailedToUploadFromFileMap",
	MissingMaterial = "MissingMaterial",
	None = "None",
}

return function(): _Types.Map<string, ErrorType>
	return ErrorTypes
end
