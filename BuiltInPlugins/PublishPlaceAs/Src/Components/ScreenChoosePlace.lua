--[[
	Allow the user to go back to picking a universe
	Allow the user to select a place to overwrite
]]
local FFlagPlacePublishManagementUI2 = game:GetFastFlag("PlacePublishManagementUI2")
local FFlagEnablePlacePublishManagementInTeamCreate = game:GetFastFlag("EnablePlacePublishManagementInTeamCreate")

local StudioPublishService = game:GetService("StudioPublishService")

local Plugin = script.Parent.Parent.Parent

local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local UILibrary = require(Plugin.Packages.UILibrary)

local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local SharedFlags = Framework.SharedFlags
local FFlagRemoveUILibraryButton = SharedFlags.getFFlagRemoveUILibraryButton()
local FFlagRemoveUILibraryLoadingIndicator = SharedFlags.getFFlagRemoveUILibraryLoadingIndicator()

local Constants = require(Plugin.Src.Resources.Constants)

local UI = Framework.UI
local Button = if FFlagRemoveUILibraryButton then UI.Button else UILibrary.Component.RoundTextButton
local InfiniteScrollingFrame = UILibrary.Component.InfiniteScrollingFrame
local LoadingIndicator = if FFlagRemoveUILibraryLoadingIndicator then UI.LoadingIndicator else UILibrary.Component.LoadingIndicator
local SearchBar = Framework.StudioUI.SearchBar
local Separator = UI.Separator

local SetIsPublishing = require(Plugin.Src.Actions.SetIsPublishing)
local SetScreen = require(Plugin.Src.Actions.SetScreen)
local SetPlaceInfo = require(Plugin.Src.Actions.SetPlaceInfo)
local SetPublishInfo = require(Plugin.Src.Actions.SetPublishInfo)
local LoadExistingPlaces = require(Plugin.Src.Thunks.LoadExistingPlaces)

local Footer = require(Plugin.Src.Components.Footer)
local TilePlace = require(Plugin.Src.Components.TilePlace)

local shouldShowDevPublishLocations = require(Plugin.Src.Util.PublishPlaceAsUtilities).shouldShowDevPublishLocations
local getIsOptInChina = require(Plugin.Src.Util.PublishPlaceAsUtilities).getIsOptInChina
local isTeamCreateEnabled = require(Plugin.Src.Util.PublishPlaceAsUtilities).isTeamCreateEnabled

local ScreenChoosePlace = Roact.PureComponent:extend("ScreenChoosePlace")

function shouldShowNextPublishManagemnt(optInRegions, isPublish)
	if not FFlagPlacePublishManagementUI2 or not isPublish then
		return false
	end

	if not FFlagEnablePlacePublishManagementInTeamCreate and isTeamCreateEnabled() then
		return false
	end

	-- global game
	if not shouldShowDevPublishLocations() then
		return true
	end

	-- china optin game
	if getIsOptInChina(optInRegions) == true then
		return true
	end

	-- china game but non-optin
	return false
end

function ScreenChoosePlace:init()
	self.state = {
		selectedPlace = nil,
		searchTerm = "",
	}

	self.finishedConnection = nil

	self.layoutRef = Roact.createRef()

	self.OnSearchRequested = function(searchTerm)
		self:setState({
			searchTerm = searchTerm
		})
	end
end

function ScreenChoosePlace:didMount()
	self.finishedConnection = StudioPublishService.GamePublishFinished:connect(function(success)

		if self.state.selectedPlace == nil then
			return
		end

		if success then
			self.props.OpenPublishSuccessfulPage(self.state.selectedPlace, self.props.ParentGame)
		else
			self.props.OpenPublishFailPage(self.state.selectedPlace, self.props.ParentGame)
		end
	end)
end

function ScreenChoosePlace:willUnmount()
	--Places shares the same address as the running table in the thunk. So we can clear it by
	--removing all elements in places
	for key, _ in pairs(self.props.Places) do self.props.Places[key] = nil end
	if self.finishedConnection then
		self.finishedConnection:disconnect()
	end
end

function ScreenChoosePlace:render()
	local props = self.props
	local theme = props.Stylizer
	local localization = props.Localization

	local onClose = props.OnClose
	local isPublish = FFlagPlacePublishManagementUI2 and props.IsPublish or nil

	local nextPageCursor = props.NextPageCursor
	local places = props.Places

	local parentGame = props.ParentGame
	local isPublishing = props.IsPublishing

	local dispatchLoadExistingPlaces = props.DispatchLoadExistingPlaces
	local dispatchSetIsPublishing = props.dispatchSetIsPublishing
	local openChooseGamePage = props.OpenChooseGamePage
	local OpenPublishManagement =  FFlagPlacePublishManagementUI2 and props.OpenPublishManagement or nil

	local newPlaceSelected = false
	if self.state.selectedPlace ~= nil then
		newPlaceSelected = self.state.selectedPlace.placeId == 0
	end

	local gameText = parentGame and parentGame.name or ""
	local headerText = localization:getText("ScreenHeader", "ChoosePlace", { gameText })
	local untitledGameText = localization:getText("General", "UntitledGame")

	local components = {
		Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 0),
			[Roact.Ref] = self.layoutRef,
		}),
	}

	if props.PlacesQueryState == Constants.QUERY_STATE.QUERY_STATE_SUCCESS then
		for _, place in pairs(places) do
			if string.find(place.name:lower(), self.state.searchTerm:lower()) then
				local createdTile = Roact.createElement(TilePlace, {
					Name = place.name,
					Id = place.placeId,
					LayoutOrder = #components + 1,
					Selected = self.state.selectedPlace and self.state.selectedPlace.placeId == place.placeId,
					LastItem = false,
					OnActivated = function()
						self:setState({
							selectedPlace = place
						})
					end,
				})
				components[#components + 1] = createdTile
			end
		end

		components[0] = Roact.createElement(TilePlace, {
			Name = localization:getText("Button", "AddNewPlaceToGame"),
			LayoutOrder = 1,
			Selected = newPlaceSelected,
			OnActivated = function()
				self:setState({
					selectedPlace = {
						placeId = 0,
						name = untitledGameText
					}
				})
			end,
		})
	end

	local showNextPublishManagemnt = FFlagPlacePublishManagementUI2 and shouldShowNextPublishManagemnt(props.OptInRegions, isPublish) and not newPlaceSelected
	local footerMainButtonName = newPlaceSelected and "Create" or (showNextPublishManagemnt and "Next" or "Overwrite")

	local TILE_HEIGHT = 80

	-- TODO: (smallick) 2020/07/27
	-- Replace this with layoutRef
	-- Manually calculating CanvasHeight for now
	local canvasSize = 200
	canvasSize = components and math.ceil(#components * TILE_HEIGHT) or 200

	-- Force atleast 7 rows to show up to force scroll to appear. Further search results can be taken care of by InfiniteScrollingFrame
	-- nextPageFunc
	if canvasSize < 7 * TILE_HEIGHT then
		if nextPageCursor then
			dispatchLoadExistingPlaces(parentGame, nextPageCursor)
		end
	end

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = theme.backgroundColor,
		BorderSizePixel = 0,
	}, {
		Back = Roact.createElement("ImageButton", {
			Image = theme.icons.backArrow,
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 30, 0, 10),
			Style = 0,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			[Roact.Event.Activated] = function()
				openChooseGamePage()
			end,
		}),

		Sep1 = Roact.createElement(Separator, {
			Position = UDim2.new(0.5, 0, 0, 50),
		}),

		Header = Roact.createElement("TextLabel", {
			Text = headerText,
			Position = UDim2.new(0, 30, 0, 80),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 20,
			BackgroundTransparency = 1,
			Font = theme.header.font,
			TextColor3 = theme.textColor,
		}),

		SearchBar = Roact.createElement("Frame", {
			Position = UDim2.new(0.7, 4, 0, 62),
			Size = UDim2.new(0, theme.DROPDOWN_WIDTH + 20, 0, theme.DROPDOWN_HEIGHT),
			BackgroundTransparency = 1,
		}, {
			Roact.createElement(SearchBar, {
				Size = UDim2.new(0.7, 0, 1, 0),
				ShowSearchIcon = true,
				ShowSearchButton = false,
				IncrementalTextSearch = true,
				OnSearchRequested = self.OnSearchRequested,
			}),
		}),

		MainContentsSuccess = (props.PlacesQueryState == Constants.QUERY_STATE.QUERY_STATE_SUCCESS)
			and Roact.createElement(InfiniteScrollingFrame, {
				Size = UDim2.new(1, 0, 0.5, theme.FOOTER_HEIGHT * 2),
				Position = UDim2.new(0, 0, 0, 100),
				BackgroundTransparency = 1,
				-- TODO: replace manual calculation with self.layoutRef
				-- LayoutRef = self.layoutRef,
				CanvasHeight = canvasSize,
				NextPageRequestDistance = 100,
				NextPageFunc = function()
					if nextPageCursor then
						dispatchLoadExistingPlaces(parentGame, nextPageCursor)
					end
				end,
			}, components),
		MainContentsQuerying = (props.PlacesQueryState == Constants.QUERY_STATE.QUERY_STATE_QUERYING)
			and Roact.createElement("Frame", {
				Position = UDim2.new(0, 30, 0, 115),
				Size = UDim2.new(0.95, 0, 0.7, 0),
				BackgroundColor3 = theme.backgroundColor,
			}, {
				Roact.createElement(LoadingIndicator, {
					Position = UDim2.new(0.5, -100, 0, 115),
					Size = UDim2.new(0, 200, 0, 50),
				})
			}),

		MainContentsFailed = (props.PlacesQueryState == Constants.QUERY_STATE.QUERY_STATE_FAILED)
			and Roact.createElement("Frame", {
				Position = UDim2.new(0, 30, 0, 115),
				Size = UDim2.new(0.95, 0, 0.7, 0),
				BackgroundColor3 = theme.backgroundColor,
			},
				{
					Roact.createElement("TextLabel", {
						Text = localization:getText("General", "FetchFailed"),
						Position = UDim2.new(0.5, 0, 0, 50),
						TextSize = 24,
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextColor3 = theme.failText.text,
						Font = theme.failText.font,
					}),
					Roact.createElement(Button, if FFlagRemoveUILibraryButton then {
						AnchorPoint = Vector2.new(0.5, 0.5),
						OnClick = function()
							dispatchLoadExistingPlaces(parentGame)
						end,
						Position = UDim2.new(0.5, 0, 0, 100),
						Size = UDim2.new(0, 150, 0, 75),
						Style = "Round",
						Text = localization:getText("Button", "Retry"),
					} else {
						Position = UDim2.new(0.5, 0, 0, 100),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Style = theme.defaultButton,
						Size = UDim2.new(0, 150, 0, 75),
						Active = true,
						Name = localization:getText("Button", "Retry"),
						TextSize = Constants.TEXT_SIZE,
						OnClicked = function()
							dispatchLoadExistingPlaces(parentGame)
						end
					})
				}
			),

		Footer = Roact.createElement(Footer, {
			MainButton = {
				Name = footerMainButtonName,
				Active = parentGame and self.state.selectedPlace ~= nil and not isPublishing,
				OnActivated = function()
					-- groupId is unused
					game:GetService("StudioPublishService"):SetTeamCreateOnPublishInfo(false, "")
					if FFlagPlacePublishManagementUI2 and showNextPublishManagemnt then
						-- open place publish screen
						OpenPublishManagement(self.state.selectedPlace, self.props.ParentGame)
					else
						-- groupId is unused
						if self.state.selectedPlace.placeId == 0 then
							-- 0 indicates uploading to a new slot
							StudioPublishService:setUploadNames("New Place", parentGame.name)
						else
							StudioPublishService:setUploadNames(self.state.selectedPlace.name, parentGame.name)
						end
						StudioPublishService:publishAs(parentGame.universeId, self.state.selectedPlace.placeId, 0, props.IsPublish, nil)
						dispatchSetIsPublishing(true)
					end
				end,
			},
			OnClose = onClose,
			NextScreen = nil,
		}),
	})
end

ScreenChoosePlace = withContext({
	Stylizer = ContextServices.Stylizer,
	Localization = ContextServices.Localization,
})(ScreenChoosePlace)

local function mapStateToProps(state, props)
	local placeInfo = state.ExistingGame.placeInfo
	local selectedGame = state.ExistingGame.selectedGame
	local gameConfiguration = state.ExistingGame.gameConfiguration
	return {
		NextPageCursor = placeInfo.nextPageCursor,
		Places = placeInfo.places,
		ParentGame = selectedGame,
		IsPublishing = state.PublishedPlace.isPublishing,
		PlacesQueryState = placeInfo.queryState,
		OptInRegions = FFlagPlacePublishManagementUI2 and gameConfiguration.optInRegions or nil,
	}
end

local function useDispatchForProps(dispatch)
	return {
		DispatchLoadExistingPlaces = function(parentGame, cursor)
			dispatch(LoadExistingPlaces(parentGame, cursor))
		end,
		dispatchSetIsPublishing = function(isPublishing)
			dispatch(SetIsPublishing(isPublishing))
		end,
		OpenChooseGamePage = function()
			dispatch(SetPlaceInfo({ places = {} }))
			dispatch(SetScreen(Constants.SCREENS.CHOOSE_GAME))
		end,
		OpenPublishSuccessfulPage = function(place, game)
			dispatch(SetPublishInfo({ id = game.universeId, name = place.name, parentGameName = game.name, }))
			dispatch(SetScreen(Constants.SCREENS.PUBLISH_SUCCESSFUL))
		end,
		OpenPublishFailPage = function(place, game)
			dispatch(SetPublishInfo({ id = place.placeId, name = place.name, parentGameName = game.name, parentGameId = game.universeId, failed = true }))
			dispatch(SetScreen(Constants.SCREENS.PUBLISH_FAIL))
		end,
		ClearPlaces = function()
			dispatch(SetPlaceInfo({ places = {} }))
		end,
		OpenPublishManagement = function(place, universe)
			dispatch(SetPlaceInfo({ places = {place}, parentGame = universe }))
			dispatch(SetScreen(Constants.SCREENS.PUBLISH_MANAGEMENT))
		end,
	}
end

return RoactRodux.connect(mapStateToProps, useDispatchForProps)(ScreenChoosePlace)
