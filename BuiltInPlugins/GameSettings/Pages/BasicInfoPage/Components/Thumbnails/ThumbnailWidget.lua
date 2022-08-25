--[[
	Represents the Thumbnails widget in Basic Info.
	Consists of a list of tips as well as the ThumbnailSet.
	Handles the logic for dragging and reordering thumbnails.

	This component should only be created as part of a ThumbnailController.
	If just making a list of thumbnails to preview, use a ThumbnailSet.

	Props:
		bool Enabled = Whether this component is enabled.

		table Thumbnails = A list of thumbnails to display.
			{id1 = {thumbnail1}, id2 = {thumbnail2}, ..., idn = {thumbnailn}}

		list Order = The order that the given Thumbnails will be displayed.
			{id1, id2, id3, ..., idn}

		int LayoutOrder = The order in which this widget should display in its parent.
		function ThumbnailAction = A callback for when the user interacts with a Thumbnail.
			Called when a thumbnail's button is pressed, when the user wants to add a new
			thumbnail, or when the user has finished dragging a thumbnail.
			These actions are handled by the ThumbnailController above this component.
]]
local FFlagGameSettingsRemoveFitContent = game:GetFastFlag("GameSettingsRemoveFitContent")

local Page = script.Parent.Parent.Parent
local Plugin = script.Parent.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local Cryo = require(Plugin.Packages.Cryo)
local UILibrary = require(Plugin.Packages.UILibrary)
local Framework = require(Plugin.Packages.Framework)

local SharedFlags = Framework.SharedFlags
local FFlagRemoveUILibraryBulletPoint = SharedFlags.getFFlagRemoveUILibraryBulletPoint()

local UI = Framework.UI
local BulletList = UI.BulletList
local Pane = UI.Pane

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local DEPRECATED_Constants = require(Plugin.Src.Util.DEPRECATED_Constants)

local ThumbnailSet = require(Page.Components.Thumbnails.ThumbnailSet)
local DragGhostThumbnail = require(Page.Components.Thumbnails.DragGhostThumbnail)

local BulletPoint
if not FFlagRemoveUILibraryBulletPoint then
    BulletPoint = UILibrary.Component.BulletPoint
end

local FitToContent

if not FFlagGameSettingsRemoveFitContent then
	local createFitToContent = UILibrary.Component.createFitToContent
	FitToContent = createFitToContent("Frame", "UIListLayout", {
		Padding = UDim.new(0, 15),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local getSocialMediaReferencesAllowed = require(Plugin.Src.Util.GameSettingsUtilities).getSocialMediaReferencesAllowed

local ThumbnailWidget = Roact.PureComponent:extend("ThumbnailWidget")

function ThumbnailWidget:init()
	self.frameRef = Roact.createRef()
	self.state = {
		dragId = nil,
		dragIndex = nil,
		oldIndex = nil,
	}

	self.heightChanged = function(newheight)
		local frame = self.frameRef.current
		frame.Size = UDim2.new(1, 0, 0, newheight + DEPRECATED_Constants.FRAME_PADDING
			+ DEPRECATED_Constants.ELEMENT_PADDING + DEPRECATED_Constants.HEADER_HEIGHT + DEPRECATED_Constants.ELEMENT_PADDING)
	end

	self.startDragging = function(dragInfo)
		self:setState({
			dragId = dragInfo.thumbnailId,
			dragIndex = dragInfo.index,
			oldIndex = dragInfo.index or nil,
		})
	end

	self.dragMove = function(dragInfo)
		self:setState({
			dragIndex = dragInfo.index,
		})
	end

	self.stopDragging = function()
		if self.state.dragId ~= nil and self.state.dragIndex ~= nil then
			local props = self.props
			props.Mouse:__resetCursor()

			if self.state.dragIndex == self.state.oldIndex then
				self:setState({
					dragId = Roact.None,
					dragIndex = Roact.None,
					oldIndex = Roact.None,
				})
			else
				self.props.ThumbnailAction("MoveTo", {
					thumbnailId = self.state.dragId,
					index = self.state.dragIndex,
				})
			end
		end
	end
end

function ThumbnailWidget:didUpdate(nextProps)
	-- When the user stops dragging, the Order prop will change, and
	-- the lastState will still hold a dragId and dragIndex. Set those values
	-- back to nil here so that the thumbnails render in the right order.
	if nextProps.Order ~= self.props.Order then
		self:setState({
			dragId = Roact.None,
			dragIndex = Roact.None,
			oldIndex = Roact.None,
		})
	end
end

function ThumbnailWidget:render()
	local props = self.props
	local theme = props.Stylizer
	local localization = props.Localization

	local active = self.props.Enabled

	local thumbnails = self.props.Thumbnails or {}
	local order = self.props.Order or {}
	local numThumbnails = #order or 0
	local errorMessage = self.props.ErrorMessage

	local dragId = self.state.dragId
	local dragIndex = self.state.dragIndex
	local dragging = dragId ~= nil

	local dragThumbnails
	local dragOrder
	if dragging then
		dragThumbnails = Cryo.Dictionary.join(thumbnails, {
			[dragId] = {
				id = "DragDestination",
			},
		})
		dragOrder = Cryo.List.removeValue(order, dragId)
		table.insert(dragOrder, dragIndex, dragId)
	end

	local dragImageId = nil
	if thumbnails[dragId] then
		if thumbnails[dragId].imageId then
			dragImageId = "rbxassetid://" .. thumbnails[dragId].imageId
		elseif thumbnails[dragId].tempId then
			dragImageId = thumbnails[dragId].tempId
		end
	end

	local countTextColor
	if errorMessage or numThumbnails > DEPRECATED_Constants.MAX_THUMBNAILS then
		countTextColor = DEPRECATED_Constants.ERROR_COLOR
	else
		countTextColor = theme.thumbnail.count
	end
	
	local notes
	
	if FFlagRemoveUILibraryBulletPoint then
        notes = Roact.createElement(BulletList, {
            TextTruncate = Enum.TextTruncate.AtEnd,
            Items = {
				if getSocialMediaReferencesAllowed() then localization:getText("General", "ThumbnailsLimit", {
					maxThumbnails = DEPRECATED_Constants.MAX_THUMBNAILS,
				})
				else localization:getText("General", "ThumbnailsLimitLuobu", {
					maxThumbnails = DEPRECATED_Constants.MAX_THUMBNAILS,
				}),
				localization:getText("General", "ThumbnailsHint", {
					fileTypes = table.concat(DEPRECATED_Constants.IMAGE_TYPES, ", "),
				}),
				localization:getText("General", "ThumbnailsModeration"),
			}
        })
    else
		notes = Roact.createElement("Frame", {
			LayoutOrder = 1,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 72),
			Position = UDim2.new(0, 0, 0, 0),
		}, {
			Layout = Roact.createElement("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			LimitHint = Roact.createElement(BulletPoint, {
				LayoutOrder = 1,
				Text = getSocialMediaReferencesAllowed() and localization:getText("General", "ThumbnailsLimit", {
					maxThumbnails = DEPRECATED_Constants.MAX_THUMBNAILS,
				})
				or localization:getText("General", "ThumbnailsLimitLuobu", {
					maxThumbnails = DEPRECATED_Constants.MAX_THUMBNAILS,
				}),
			}),
			FileHint = Roact.createElement(BulletPoint, {
				LayoutOrder = 2,
				Text = localization:getText("General", "ThumbnailsHint", {
					fileTypes = table.concat(DEPRECATED_Constants.IMAGE_TYPES, ", "),
				}),
			}),
			ModerationHint = Roact.createElement(BulletPoint, {
				LayoutOrder = 3,
				Text = localization:getText("General", "ThumbnailsModeration"),
			}),
		})
	end

	local children = {
		-- Placed in a folder to prevent this component from being part
		-- of the LayoutOrder. This component is a drag area that is the size
		-- of the entire component.
		DragFolder = Roact.createElement("Folder", {}, {
			DragGhost = Roact.createElement(DragGhostThumbnail, {
				Enabled = active and dragging,
				Image = dragImageId,
				StopDragging = self.stopDragging,
			}),
		}),

		Title = Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.Normal, {
			LayoutOrder = 0,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 16),

			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = localization:getText("General", "TitleThumbnails"),
		})),

		Notes = notes,

		Thumbnails = Roact.createElement(ThumbnailSet, {
			LayoutOrder = 2,
			Thumbnails = dragging and dragThumbnails or thumbnails,
			Order = dragging and dragOrder or order,
			HoverBarsEnabled = not dragging,
			Enabled = active,
			Position = UDim2.new(0, 0, 0, 96),

			SetHeight = self.heightChanged,

			StartDragging = self.startDragging,
			DragMove = self.dragMove,

			ButtonPressed = self.props.ThumbnailAction,
			AddNew = function()
				self.props.ThumbnailAction("AddNew")
			end,

			UpdateAltText = function(info)
				self.props.ThumbnailAction("UpdateAltText", info)
			end,
			AltTextError = self.props.AltTextError,
		}),

		-- Placed in a folder to prevent this component from being part
		-- of the LayoutOrder and receiving padding above and below
		CountFolder = Roact.createElement("Folder", {}, {
			Count = Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.Smaller, {
				Visible = active,
				Size = UDim2.new(1, 0, 0, 20),
				Position = UDim2.new(0, 0, 1, DEPRECATED_Constants.ELEMENT_PADDING),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = 1,
				TextColor3 = countTextColor,
				Text = errorMessage
					or numThumbnails > 0 and (numThumbnails .. "/" .. DEPRECATED_Constants.MAX_THUMBNAILS)
					or localization:getText("General", "ThumbnailsCount", {maxThumbnails = DEPRECATED_Constants.MAX_THUMBNAILS}),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
			})),
		}),
	}

	if FFlagGameSettingsRemoveFitContent then
		return Roact.createElement(Pane, {
			LayoutOrder = self.props.LayoutOrder or 1,
			Layout = Enum.FillDirection.Vertical,
			AutomaticSize = Enum.AutomaticSize.XY,
			Spacing = UDim.new(0, 15),
		}, children)
	else
		return Roact.createElement(FitToContent, {
			LayoutOrder = self.props.LayoutOrder or 1,
			BackgroundTransparency = 1,
		}, children)
	end
end

ThumbnailWidget = withContext({
	Stylizer = ContextServices.Stylizer,
	Localization = ContextServices.Localization,
	Mouse = ContextServices.Mouse,
})(ThumbnailWidget)

return ThumbnailWidget
