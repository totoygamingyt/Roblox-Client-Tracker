local Plugin = script.Parent.Parent.Parent.Parent
local Framework = require(Plugin.Packages.Framework)
local Util = Framework.Util
local Action = Util.Action

local Models = Plugin.Src.Models
local VariableRow = require(Models.Watch.VariableRow)
local StepStateBundle = require(Plugin.Src.Models.StepStateBundle)

export type Path = string

export type Props = {
	stepStateBundle: StepStateBundle.StepStateBundle,
	tokenizedList: { Path },
	newVarsMapping: { [Path]: VariableRow.VariableRow },
}

return Action(script.Name, function(stepStateBundle: StepStateBundle.StepStateBundle, newVars: { VariableRow.VariableRow }): Props
		local tokenizedList = {}
		local newVarsMapping = {}

		for index, variableRow in ipairs(newVars) do
			table.insert(tokenizedList, variableRow.pathColumn)
			newVarsMapping[variableRow.pathColumn] = variableRow
		end

		return {
			stepStateBundle = stepStateBundle,
			tokenizedList = tokenizedList,
			newVarsMapping = newVarsMapping,
		}
	end
)
