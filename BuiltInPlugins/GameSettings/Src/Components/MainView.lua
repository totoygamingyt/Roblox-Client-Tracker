--[[
	The top level container of the Game Settings window.
	Contains the menu bar, the footer, and the currently selected page.

	Props:
		int Selected = The index of the currently selected menu entry
		function SelectionChanged = A callback when the selected entry is changed
]]

local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Cryo = require(Plugin.Packages.Cryo)
local DEPRECATED_Constants = require(Plugin.Src.Util.DEPRECATED_Constants)

local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local FrameworkUI = Framework.UI
local Util = Framework.Util

local Button = FrameworkUI.Button
local Container = FrameworkUI.Container
local HoverArea = FrameworkUI.HoverArea

local FitTextLabel = Util.FitFrame.FitTextLabel

local MenuBar = require(Plugin.Src.Components.MenuBar)
local Separator = require(Plugin.Src.Components.Separator)
local Footer = require(Plugin.Src.Components.Footer)
local PageManifest = require(Plugin.Pages.PageManifest)
local Analytics = require(Plugin.Src.Util.Analytics)

local TextService = game:GetService("TextService")

local MainView = Roact.PureComponent:extend("MainView")
local StudioPublishService = game:GetService("StudioPublishService")

function MainView:init()
	local selectedPage

	-- if FirstSelectedId is specified, find page with matching LocalizationId
	-- otherwise, find first valid page
	local firstSelectedId = self.props.FirstSelectedId
	if firstSelectedId and firstSelectedId ~= "" then
		-- Find page with matching LocalizationId
		for i, pageComponent in ipairs(PageManifest) do
			if pageComponent and pageComponent.LocalizationId == firstSelectedId then
				selectedPage = i
				break
			end
		end
		assert(selectedPage, "There are no pages in PageManifest with LocalizationId \"" .. firstSelectedId .. "\"")
	else
		-- Entries may be false due to flagging instead of a valid page component, so skip them
		local firstValidPage = nil
		for i, pageComponent in ipairs(PageManifest) do
			if pageComponent then
				firstValidPage = i
				break
			end
		end
		assert(firstValidPage, "There are no valid pages in PageManifest")
		selectedPage = firstValidPage
	end

	self.state = {
		Selected = selectedPage,
		PageContentOffset = 0,
	}
end

function MainView:pageSelected(index)
	local oldTabId = PageManifest[self.state.Selected].LocalizationId
	local newTabId = PageManifest[index].LocalizationId
	Analytics.onTabChangeEvent(oldTabId, newTabId)

	self:setState({
		Selected = index,
	})
end

function MainView:render()
	local props = self.props
	local Selected = self.state.Selected
	local theme = props.Stylizer
	local localization = props.Localization

	local isPublishedGame = props.GameId ~= 0
	local pageLoadStates = props.PageLoadStates

	local children = {}
	local menuEntries = {}
	if isPublishedGame then
		for i,pageComponent in ipairs(PageManifest) do
			if pageComponent then
				local loadState = pageLoadStates[pageComponent.LocalizationId]
				menuEntries[i] = pageComponent.LocalizationId
				children[tostring(pageComponent)] = (i == Selected or loadState ~= nil) and Roact.createElement("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Visible = i == Selected,
				}, {
					PageContents = Roact.createElement(pageComponent),
				})
			end
		end
	end

	local publishText = localization:getText("General", "PublishText")
    local buttonText = localization:getText("General", "ButtonPublish")
	publishText = localization:getText("General", "SaveText")
	buttonText = localization:getText("General", "ButtonSaveToRoblox")
	local buttonTextExtents = TextService:GetTextSize(buttonText, theme.fontStyle.Normal.TextSize,
		theme.fontStyle.Normal.Font, Vector2.new(math.huge, math.huge))

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = theme.backgroundColor,
	}, (not isPublishedGame) and {
		UseText = Roact.createElement(FitTextLabel, Cryo.Dictionary.join(theme.fontStyle.Normal, {
            Position = UDim2.new(0.5, 0, 0, theme.mainView.publishText.offset),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = publishText,

			BackgroundTransparency = 1,

			width = theme.mainView.publishText.width,
        })),

        PublishButton = Roact.createElement(Button, {
            Style = "GameSettingsPrimaryButton",

            Text = buttonText,
            Size = UDim2.new(0, buttonTextExtents.X + theme.mainView.publishButton.paddingX,
                0, buttonTextExtents.Y + theme.mainView.publishButton.paddingY),
            Position = UDim2.new(0.5, 0, 0, theme.mainView.publishButton.offset),
            AnchorPoint = Vector2.new(0.5, 0.5),

            OnClick = function()
                StudioPublishService:ShowSaveOrPublishPlaceToRoblox(false, false, Enum.StudioCloseMode.None)
                self.props.OnClose(false)
            end,
        }, {
            Roact.createElement(HoverArea, {Cursor = "PointingHand"}),
        }),
	} or {
		Padding = Roact.createElement("UIPadding", {
			PaddingTop = UDim.new(0, 5),
		}),

		Layout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		CenterContent = Roact.createElement(Container, {
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 1, -theme.footer.height),
		}, {
			Layout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			MenuBar = Roact.createElement(MenuBar, {
				LayoutOrder = 1,
				Entries = menuEntries,
				Selected = Selected,
				SelectionChanged = function(index)
					self:pageSelected(index)
				end,
			}),

			Separator = Roact.createElement(Separator, {
				LayoutOrder = 2,
				Size = UDim2.new(0, 3, 1, 0),
				Position = UDim2.new(0, DEPRECATED_Constants.MENU_BAR_WIDTH, 0, 0),
			}),

			PageContent = Roact.createElement("Frame", {
				LayoutOrder = 3,
				Size = UDim2.new(1, -self.state.PageContentOffset, 1, 0),
				BackgroundTransparency = 1,

				[Roact.Change.AbsolutePosition] = function(rbx)
					local parent = rbx.Parent
					if not parent then return end

					local relativePosition = rbx.AbsolutePosition - parent.AbsolutePosition
					self:setState({ PageContentOffset = relativePosition.X })
				end,
			}, children)
		}),

		FooterContent = Roact.createElement(Container, {
			Size = UDim2.new(1, 0, 0, theme.footer.height),
			LayoutOrder = 2,
		}, {
			Footer = Roact.createElement(Footer, {
				OnClose = function(didSave, savePromise)
					self.props.OnClose(didSave, savePromise)
				end,
			})
		}),
	})
end

MainView = withContext({
	Localization = ContextServices.Localization,
	Stylizer = ContextServices.Stylizer,
})(MainView)

MainView = RoactRodux.connect(
	function(state, props)
		return {
			GameId = state.Metadata.gameId,
			PageLoadStates = state.PageLoadState,
		}
	end
)(MainView)

return MainView
