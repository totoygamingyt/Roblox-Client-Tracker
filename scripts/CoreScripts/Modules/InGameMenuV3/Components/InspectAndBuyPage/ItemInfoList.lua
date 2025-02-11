--[[
	UI to display relevant information for the selected asset/bundle
	This includes the following information:
	creator name, asset type (or "bundle" if not an asset), and item genre
]]
local CorePackages = game:GetService("CorePackages")

local Roact = require(CorePackages.Roact)
local t = require(CorePackages.Packages.t)

local InGameMenu = script.Parent.Parent.Parent
local ItemInfoRow = require(InGameMenu.Components.InspectAndBuyPage.ItemInfoRow)
local Constants = require(InGameMenu.InspectAndBuyConstants)

local UIBlox = require(CorePackages.UIBlox)
local withStyle = UIBlox.Style.withStyle
local withLocalization = require(InGameMenu.Localization.withLocalization)

local ROW_HEIGHT = 53

local ItemInfoList = Roact.PureComponent:extend("ItemInfoList")

ItemInfoList.validateProps = t.strictInterface({
	creatorText = t.optional(t.string),

	genreText = t.optional(t.string),
	showAllDividers = t.optional(t.boolean),
	itemType = t.optional(t.string),
	itemSubType = t.optional(t.string),

	LayoutOrder = t.optional(t.integer),
})

ItemInfoList.defaultProps = {
	LayoutOrder = 0,
	creatorText = "",
	genreText = "",
	showAllDividers = false,
}

type ItemInfo = {
	infoName: string,
	infoData: string,
}

function ItemInfoList:makeItemInfoListData(localizedCategoryType)
	local creatorText = self.props.creatorText
	local genreText = self.props.genreText

	local itemInfoListData: {ItemInfo} = {}
	--TODO: LOCALIZE
	table.insert(itemInfoListData, {
		infoName = "Creator",
		infoData = creatorText,
	})
	table.insert(itemInfoListData, {
		infoName = "Type",
		infoData = localizedCategoryType or "",
	})
	table.insert(itemInfoListData, {
		infoName = "Genre",
		infoData = genreText,
	})

	return itemInfoListData
end

function ItemInfoList:renderWithProviders(stylePalette, localized)
	local itemType = self.props.itemType

	--TODO: LOCALIZE
	local categoryType
	if itemType == Enum.AvatarItemType.Asset and self.props.itemSubType then
		local category = Constants.AssetTypeIdToCategory[self.props.itemSubType]
		if not category then
			-- fallback if no category given
			categoryType = "Unknown"
		else
			categoryType = category .. " | " .. self.props.itemSubType
		end
	elseif itemType == Enum.AvatarItemType.Bundle then
		categoryType = "Bundle"
	end

	local itemInfoListData = self:makeItemInfoListData(categoryType)

	local theme = stylePalette.Theme
	local layoutOrder = self.props.LayoutOrder
	local showAllDividers = self.props.showAllDividers
	local listContents = {}

	listContents["Layout"] = Roact.createElement("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})

	local rowCount = 0
	for i, item in ipairs(itemInfoListData) do
		rowCount = rowCount + 1
		local hasDivider = showAllDividers or (i < #itemInfoListData)

		listContents["InfoRow" .. i] = Roact.createElement(ItemInfoRow, {
			infoName = item.infoName,
			infoData = item.infoData,
			LayoutOrder = rowCount,
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		})
		if hasDivider then
			rowCount = rowCount + 1
			listContents["Divider" .. i] = Roact.createElement("Frame", {
				BackgroundColor3 = theme.Divider.Color,
				BackgroundTransparency = theme.Divider.Transparency,
				BorderSizePixel = 0,
				LayoutOrder = rowCount,
				Size = UDim2.new(1, 0, 0, 1),
			})
		end
	end

	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		LayoutOrder = layoutOrder,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
	}, listContents :: any)
end

function ItemInfoList:render()
	return withLocalization({
	})(function(localized)
		return withStyle(function(stylePalette)
			return self:renderWithProviders(stylePalette, localized)
		end)
	end)
end

return ItemInfoList