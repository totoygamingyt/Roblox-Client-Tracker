--[[
	Controls which Tool is shown in the tool frame
	Handles all the bindings between the ui and the tool functionality
]]
local Plugin = script.Parent.Parent.Parent

local Framework = require(Plugin.Packages.Framework)
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local ContextItems = require(Plugin.Src.ContextItems)

local Tools = script.Parent.Tools
local Add = require(Tools.Add)
local Clear = require(Tools.Clear)
local Erode = require(Tools.Erode)
local Fill = require(Tools.Fill)
local Flatten = require(Tools.Flatten)
local Generate = require(Tools.Generate)
local Grow = require(Tools.Grow)
local ImportLocal = require(Tools.ImportLocal)
local Paint = require(Tools.Paint)
local Region = require(Tools.Region)
local SeaLevel = require(Tools.SeaLevel)
local Replace = require(Tools.Replace)
local Smooth = require(Tools.Smooth)
local Subtract = require(Tools.Subtract)

local Actions = Plugin.Src.Actions
local ChangeTool = require(Actions.ChangeTool)

local Functions = Plugin.Src.Components.Functions
local TerrainRegionEditor = require(Functions.TerrainRegionEditor)

local TerrainEnums = require(Plugin.Src.Util.TerrainEnums)
local ToolId = TerrainEnums.ToolId

local toolToScript = {
	[ToolId.Select] = TerrainRegionEditor,
	[ToolId.Move] = TerrainRegionEditor,
	[ToolId.Resize] = TerrainRegionEditor,
	[ToolId.Rotate] = TerrainRegionEditor,
	[ToolId.Copy] = TerrainRegionEditor,
	[ToolId.Paste] = TerrainRegionEditor,
	[ToolId.Delete] = TerrainRegionEditor,
	[ToolId.Fill] = TerrainRegionEditor,
}

local toolComponent = {
	[ToolId.Generate] = Generate,
	[ToolId.ImportLocal] = ImportLocal,
	[ToolId.Clear] = Clear,

	[ToolId.Select] = Region,
	[ToolId.Move] = Region,
	[ToolId.Resize] = Region,
	[ToolId.Rotate] = Region,
	[ToolId.Copy] = Region,
	[ToolId.Paste] = Region,
	[ToolId.Delete] = Region,
	[ToolId.Fill] = Fill,

	[ToolId.Add] = Add,
	[ToolId.Subtract] = Subtract,

	[ToolId.Grow] = Grow,
	[ToolId.Erode] = Erode,
	[ToolId.Smooth] = Smooth,
	[ToolId.Flatten] = Flatten,

	[ToolId.SeaLevel] = SeaLevel,
	[ToolId.Replace] = Replace,
	[ToolId.Paint] = Paint,
}

local function ToggleTool(toolName, mouse)
	-- TODO: As other terrain interface modules get refactored
	-- Remove this function and move the logic elsewhere
	local currentToolScript = toolToScript[toolName]
	if currentToolScript ~= TerrainRegionEditor then
		TerrainRegionEditor.Close()
	end

	if toolName and toolName ~= ToolId.None and currentToolScript then
		coroutine.wrap(function()
			currentToolScript.Init(toolName, mouse)
		end)()
	end
end

local ToolRenderer = Roact.PureComponent:extend(script.Name)

function ToolRenderer:init()
	self.scrollingRef = Roact.createRef()
	self.layoutRef = Roact.createRef()

	self.onContentSizeChanged = function()
		local scrollingFrame = self.scrollingRef.current
		local layout = self.layoutRef.current

		if scrollingFrame and layout then
			scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
		end
	end
end

function ToolRenderer:willUnmount()
	local currentToolScript = toolToScript[self.props.currentTool]
	if currentToolScript == TerrainRegionEditor then
		TerrainRegionEditor.Close()
	end
end

function ToolRenderer:willUpdate(nextProps, nextState)
	ToggleTool(nextProps.currentTool, self.props.Mouse:get())
end

function ToolRenderer:didUpdate(previousProps, previousState)
	-- we use this to enable the use of these buttons as
	-- buttons and not as tools for the regions tools
	if self.props.currentTool == ToolId.Delete or
		self.props.currentTool == ToolId.Paste or
		self.props.currentTool == ToolId.Copy then
		self.props.dispatchChangeTool(previousProps.currentTool)
	end
end

function ToolRenderer:render()
	local theme = self.props.Theme:get()

	local currentTool = self.props.currentTool
	local layoutOrder = self.props.LayoutOrder
	local roactElement = toolComponent[currentTool]

	-- the ToolRenderer is the last element in the the list of
	-- elements in the layout, so we pass it the previous
	-- elements' aggregate size so this element fills the remaining
	-- space. This can probably removed when we get better
	-- layout size management.
	local upperContentYSize = self.props.UpperContentYSize or 0

	local toolRenderTheme = theme.toolRenderTheme
	return Roact.createElement("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -upperContentYSize),
		CanvasSize = UDim2.new(),
		BackgroundTransparency = 1,
		LayoutOrder = layoutOrder,

		TopImage = toolRenderTheme.scrollTopImage,
		MidImage = toolRenderTheme.scrollMidImage,
		BottomImage = toolRenderTheme.scrollBotImage,
		VerticalScrollBarInset = toolRenderTheme.verticalScrollBarInset,
		BorderSizePixel = 0,

		[Roact.Ref] = self.scrollingRef,
	},{
		UIListLayout = Roact.createElement("UIListLayout", {
			[Roact.Ref] = self.layoutRef,
			[Roact.Change.AbsoluteContentSize] = self.onContentSizeChanged,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Tool = roactElement and Roact.createElement(roactElement),
	})
end


ToolRenderer = withContext({
	Theme = ContextItems.UILibraryTheme,
	Mouse = ContextServices.Mouse,
})(ToolRenderer)



local function mapStateToProps(state, props)
	return {
		currentTool = state.Tools.currentTool,
	}
end

local function mapDispatchToProps(dispatch)
	return {
		dispatchChangeTool = function(tool)
			dispatch(ChangeTool(tool))
		end
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(ToolRenderer)
