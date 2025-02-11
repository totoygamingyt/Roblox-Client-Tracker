--[[
	Updates selected assets if keys have changed.
]]
local Plugin = script.Parent.Parent.Parent
local Framework = require(Plugin.Packages.Framework)

local Dash = Framework.Dash
local shallowEqual = Dash.shallowEqual

local SetSelectedAssets = require(Plugin.Src.Actions.SetSelectedAssets)

return function(selectedAssets)
	return function(store)
		local state = store:getState()
		local prevSelectedAssets = state.AssetManagerReducer.selectedAssets

		if not shallowEqual(selectedAssets, prevSelectedAssets) then
			store:dispatch(SetSelectedAssets(selectedAssets))
		end
	end
end
