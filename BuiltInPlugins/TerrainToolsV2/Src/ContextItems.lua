local Plugin = script.Parent.Parent

local Framework = require(Plugin.Packages.Framework)

local ContextItem = Framework.ContextServices.ContextItem

local TerrainInterfaces = script.Parent.TerrainInterfaces

return {
	-- Because we're still partially using UI Library Theme implementation
	-- we need to wrap it in Dev Framework context items
	UILibraryTheme = ContextItem:createSimple("UILibraryTheme", {
		getValues = function(theme)
			return theme.values
		end,
		getChangedSignal = function(theme)
			return theme.valuesChanged
		end,
		destroy = function(theme)
			theme:destroy()
		end,
	}),

	-- Also wrap terrain as it is a C++ Instance
	Terrain = ContextItem:createSimple("Terrain"),

	PluginActivationController = require(script.Parent.Util.PluginActivationController),
	PluginActionsController = require(script.Parent.Util.PluginActionsController),

	TerrainGeneration = require(TerrainInterfaces.TerrainGenerationInstance),
	TerrainImporter = require(TerrainInterfaces.TerrainImporterInstance),
	SeaLevel = require(TerrainInterfaces.TerrainSeaLevel),

	ImageLoader = require(script.Parent.Util.ImageLoader),
	CalloutController =  require(script.Parent.Util.CalloutController),
}
