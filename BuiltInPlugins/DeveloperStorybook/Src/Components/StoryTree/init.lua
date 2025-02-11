--[[
	Display a list of available targets
]]
local main = script.Parent.Parent.Parent
local Roact = require(main.Packages.Roact)
local RoactRodux = require(main.Packages.RoactRodux)

local Framework = require(main.Packages.Framework)
local SharedFlags = Framework.SharedFlags
local FFlagDevFrameworkList = SharedFlags.getFFlagDevFrameworkList()

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local UI = Framework.UI
local Container = UI.Container
local TreeView = UI.TreeView

local Actions = main.Src.Actions
local SelectStory = require(Actions.SelectStory)
local ToggleStory = require(Actions.ToggleStory)

local StoryTreeRow = if FFlagDevFrameworkList then nil else require(main.Src.Components.StoryTree.StoryTreeRow)

local Thunks = main.Src.Thunks
local GetStories = require(Thunks.GetStories)

local StoryTree = Roact.PureComponent:extend("StoryTree")

local function getChildren(item)
	return item:GetChildren()
end

local function getItemKey(item, index: number)
	return item.Name .. "#" .. tostring(index)
end

function StoryTree:init()
	if not FFlagDevFrameworkList then
		self.toggleRow = function(row)
			local newExpansion = {
				[row.item] = not self.props.Expansion[row.item]
			}
			self.props.toggleStory(newExpansion)
		end
		self.selectRow = function(row)
			self.props.selectStory(row.item)
		end
		self.renderRow = function(row)
			local props = self.props
			local style = props.Stylizer
			local isSelected = props.Selection[row.item]
			local isExpanded = props.Expansion[row.item]
			return Roact.createElement(StoryTreeRow, {
				row = row,
				style = style,
				isSelected = isSelected,
				isExpanded = isExpanded,
				onToggled = self.toggleRow,
				onSelected = self.selectRow
			})
		end
	end
	self.onSelectionChange = function(selection)
		for story, _ in pairs(selection) do
			self.props.selectStory(story)
			-- Only select first story
			return
		end
	end

	self.onExpansionChange = function(expansion)
		self.props.toggleStory(expansion)
	end
end

function StoryTree:didMount()
	self.props.getStories()
end

function StoryTree:render()
	local props = self.props
	return Roact.createElement(Container, {},
	{
		Tree = Roact.createElement(TreeView, {
			RowProps = {
				GetContents = function(item)
					return item.Name, {
						Size = UDim2.fromOffset(16, 16),
						Image = ("rbxasset://textures/DeveloperStorybook/%s.png"):format(item.Icon)
					}
				end,
			},
			LayoutOrder = props.LayoutOrder,
			RootItems = props.Stories,
			GetChildren = getChildren,
			GetItemKey = getItemKey,
			OnSelectionChange = if FFlagDevFrameworkList then self.onSelectionChange else nil,
			OnExpansionChange = if FFlagDevFrameworkList then self.onExpansionChange else nil,
			RenderRow = if FFlagDevFrameworkList then nil else self.renderRow,
			Selection = if FFlagDevFrameworkList then props.Selection else nil,
			Size = UDim2.fromScale(1, 1),
			Expansion = props.Expansion,
			Style = "BorderBox",
		})
	})
end

StoryTree = withContext({
	Stylizer = ContextServices.Stylizer,
})(StoryTree)

return RoactRodux.connect(
	function(state, props)
		return {
			Stories = #state.Stories.searchFilter > 0 and state.Stories.searchStories or state.Stories.stories,
			Selection = state.Stories.selectedStory and {[state.Stories.selectedStory] = true} or {},
			Expansion = #state.Stories.searchFilter > 0 and state.Stories.expandedSearchStories or state.Stories.expandedStories
		}
	end,
	function(dispatch)
		return {
			selectStory = function(story)
				dispatch(SelectStory(story))
			end,
			toggleStory = function(change)
				dispatch(ToggleStory(change))
			end,
			getStories = function()
				dispatch(GetStories())
			end,
		}
	end
)(StoryTree)
