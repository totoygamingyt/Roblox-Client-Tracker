--[[
	Publish page for Basic Info settings.
		- Game name and description
		- Game privacy settings (who is allowed to play the game)
		- Playable Devices (which devices can run this game)
		- Genre
		- Thumbnails (Screenshots and Video)
		- Game Icon

	Settings:
		string Name - The game name
		bool IsActive - Whether the game is public or private
		bool IsFriendsOnly - Whether the game is open to everyone or only friends/group members
		string Group - The name of the group that owns this game, if one does
		string Description - The game description
		string Genre - The genre of this game
		table Devices - A table of which devices are playable
		table Thumbnails - A table of this game's thumbnails
		list Order - The order in which this game's thumbnails display
		string GameIcon - The rbxassetid url of the game's icon, or "None" if no icon exists.

	Errors:
		name: "Empty", "TooLong"
		description: "TooLong"
		devices: "NoDevices"
]]
local MAX_NAME_LENGTH = 50
local MAX_DESCRIPTION_LENGTH = 1000
local TEAM_CREATE_ENABLED = "teamCreateEnabled"

local FFlagCOLLAB734FixPublishPlaceAsDropdownContrastIssue = game:DefineFastFlag("COLLAB734FixPublishPlaceAsDropdownContrastIssue", false);
local FIntLuobuDevPublishAnalyticsHundredthsPercentage = game:GetFastInt("LuobuDevPublishAnalyticsHundredthsPercentage")
local FStringTeamCreateLearnMoreLink = game:GetFastString("TeamCreateLink")

local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local Cryo = require(Plugin.Packages.Cryo)
local Framework = require(Plugin.Packages.Framework)

local SharedFlags = Framework.SharedFlags
local FFlagRemoveUILibraryRoundTextBox = SharedFlags.getFFlagRemoveUILibraryRoundTextBox()
local FFlagRemoveUILibraryTitledFrame = SharedFlags.getFFlagRemoveUILibraryTitledFrame()

local UILibrary = if FFlagRemoveUILibraryTitledFrame and FFlagRemoveUILibraryRoundTextBox then nil else require(Plugin.Packages.UILibrary)

local RoundTextBox
if not FFlagRemoveUILibraryRoundTextBox then
	RoundTextBox = UILibrary.Component.RoundTextBox
end

local Framework = require(Plugin.Packages.Framework)
local UI = Framework.UI

local Button = UI.Button
local HoverArea = UI.HoverArea
local Image = UI.Decoration.Image
local LinkText = UI.LinkText
local SelectInput = UI.SelectInput
local Separator = Framework.UI.Separator
local StyledDialog = Framework.StudioUI.StyledDialog
local TextLabel = UI.Decoration.TextLabel
local TextInput2 = UI.TextInput2
local TextWithInlineLink = UI.TextWithInlineLink
local Tooltip = UI.Tooltip
local TitledFrame = if FFlagRemoveUILibraryTitledFrame then UI.TitledFrame else UILibrary.Component.TitledFrame

local TeachingCallout = require(Plugin.Src.Components.TeachingCallout)

local Header = require(Plugin.Src.Components.Header)
local PlatformSelect = require(Plugin.Src.Components.PlatformSelect)
local CheckBoxSet = require(Plugin.Src.Components.CheckBoxSet)
local ToggleButtonWithTitle = require(Plugin.Src.Components.ToggleButtonWithTitle)

local GetPlayerAcceptances = require(Plugin.Src.Thunks.GetPlayerAcceptances)

local AddChange = require(Plugin.Src.Actions.AddChange)
local AddErrors = require(Plugin.Src.Actions.AddErrors)
local Constants = require(Plugin.Src.Resources.Constants)

local createMenuPage = require(Plugin.Src.Components.createMenuPage)

local GuiService = game:GetService("GuiService")

local shouldShowDevPublishLocations = require(Plugin.Src.Util.PublishPlaceAsUtilities).shouldShowDevPublishLocations
local getOptInLocationsRequirementsLink = require(Plugin.Src.Util.PublishPlaceAsUtilities).getOptInLocationsRequirementsLink
local sendAnalyticsToKibana = require(Plugin.Src.Util.PublishPlaceAsUtilities).sendAnalyticsToKibana
local getPlayerAppDownloadLink = require(Plugin.Src.Util.PublishPlaceAsUtilities).getPlayerAppDownloadLink
local calculateTextSize = require(Plugin.Src.Util.PublishPlaceAsUtilities).calculateTextSize
local KeyProvider = require(Plugin.Src.Util.KeyProvider)
local optInLocationsKey = KeyProvider.getOptInLocationsKeyName()
local chinaKey = KeyProvider.getChinaKeyName()
local seriesNameKey = KeyProvider.getLuobuStudioDevPublishKeyName()
local checkboxToggleKey = KeyProvider.getCheckboxToggleKeyName()
local selectedKey = KeyProvider.getSelectedKeyName()
local termsOfUseDialogKey = KeyProvider.getTermsOfUseDialogKeyName()
local buttonClickedKey = KeyProvider.getButtonClickedKeyName()

local LayoutOrderIterator = Framework.Util.LayoutOrderIterator

local function PaddedTextLabel(props)
	return Roact.createElement(TextLabel, {
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.new(1, 0, 0, props.Height),
		Style = props.Style,
		Text = props.Text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
	},	{
		-- This padding ensures the text is not lined up right along the edge of the TextLabel
		Padding = Roact.createElement("UIPadding", {
			PaddingTop = UDim.new(0, props.Padding),
			PaddingLeft = UDim.new(0, props.Padding),
		}),
	})
end

local groupsLoaded = false
--Uses props to display current settings values
local function displayContents(parent)
	local props = parent.props

	local theme = props.Stylizer
	local localization = props.Localization
	local description = props.Description
	local descriptionChanged = props.DescriptionChanged
	local descriptionError = props.DescriptionError
	local devices = props.Devices
	local devicesChanged = props.DevicesChanged
	local devicesError = props.DevicesError
	local genre = props.Genre
	local genreChanged = props.GenreChanged
	local name = props.Name
	local nameChanged = props.NameChanged
	local nameError = props.NameError
	local creatorId = props.CreatorId
	local groups = props.Groups
	local creatorChanged = props.CreatorChanged
	local optInLocations = props.OptInLocations
	local optInLocationsChanged = props.OptInLocationsChanged
	local playerAcceptance = props.PlayerAcceptance

	local selectedGenreIndex
	local selectGenre
	local genreItems

	local selectedCreatorIndex
	local selectCreator
	local creatorItems
	-- remove DEPRECATED variables with FFlagCOLLAB734FixPublishPlaceAsDropdownContrastIssue
	local DEPRECATED_genres

	local DEPRECATED_dropdownItems
	local DEPRECATED_creatorItem

	if FFlagCOLLAB734FixPublishPlaceAsDropdownContrastIssue then
		local genreItemsMetadata = Cryo.List.map(Constants.GENRE_IDS, function(name)
			return { Key = name, Text = localization:getText("Genre", name) }
		end)

		selectedGenreIndex = 1

		selectGenre = function(_, index)
			local selectedGenreKey = genreItemsMetadata[index].Key
			genreChanged(selectedGenreKey)
		end

		genreItems = {}
		for index, genreMetadata in pairs(genreItemsMetadata) do
			table.insert(genreItems, genreMetadata.Text)
			if genre == genreMetadata.Key then
				selectedGenreIndex = index
			end
		end

		local creatorItemsMetadata = { { Key = 0, Type = Constants.SUBJECT_TYPE.USER, Text = localization:getText("GroupDropdown", "Me") } }
		selectedCreatorIndex = 1

		selectCreator = function(_, index)
			local selectedCreatorKey = creatorItemsMetadata[index].Key
			creatorChanged(selectedCreatorKey)
		end

		if groups and next(groups) ~= nil then
			for _, group in pairs(groups) do
				table.insert(creatorItemsMetadata, { Key = group.groupId, Type = Constants.SUBJECT_TYPE.GROUP, Text = group.name })
			end
			if not groupsLoaded then
				groupsLoaded = true
				for _, itemMetadata in ipairs(creatorItemsMetadata) do
					if game.CreatorId == itemMetadata.Key and game.CreatorType == Enum.CreatorType.Group then
						creatorChanged(itemMetadata.Key)
					end
				end
			end
		end

		creatorItems = {}
		for index, itemMetadata in ipairs(creatorItemsMetadata) do
			table.insert(creatorItems, itemMetadata.Text)
			if creatorId == itemMetadata.Key then
				selectedCreatorIndex = index
			end
		end
	else
		DEPRECATED_genres = Cryo.List.map(Constants.GENRE_IDS, function(name)
			return {Key = name, Text = localization:getText("Genre", name)}
		end)

		DEPRECATED_dropdownItems = { { Type = Constants.SUBJECT_TYPE.USER, Key = 0, Text = localization:getText("GroupDropdown", "Me"), }, }

		DEPRECATED_creatorItem = DEPRECATED_dropdownItems[1]

		if groups and next(groups) ~= nil then
			for _, group in pairs(groups) do
				table.insert(DEPRECATED_dropdownItems, { Type = Constants.SUBJECT_TYPE.GROUP, Key = group.groupId, Text = group.name, })
			end
			if not groupsLoaded then
				groupsLoaded = true
				for _, item in ipairs(DEPRECATED_dropdownItems) do
					if game.CreatorId == item.Key and game.CreatorType == Enum.CreatorType.Group then
						creatorChanged(item.Key)
					end
				end
			end
		end

		for _, item in ipairs(DEPRECATED_dropdownItems) do
			if creatorId == item.Key then
				DEPRECATED_creatorItem = item
			end
		end
	end

	local nameLength = utf8.len(name)
	local descriptionLength = utf8.len(description)

	local layoutOrder = LayoutOrderIterator.new()

	-- Question: Is there a way for me to get the size and font type automagically from the LinkText Style "Body"?
	local hyperLinkTextSize = calculateTextSize(localization:getText(optInLocationsKey, "RequirementsLinkText"), 14, "SourceSans")
	
	local displayResult = {
		Header = Roact.createElement(Header, {
			Title = localization:getText("MenuItem", "BasicInfo"),
			LayoutOrder = layoutOrder:getNextOrder(),
		}),

		Name = Roact.createElement(TitledFrame, if FFlagRemoveUILibraryTitledFrame then {
			LayoutOrder = layoutOrder:getNextOrder(),
			Title = localization:getText("PageTitle", "Name"),
		} else {
			Title = localization:getText("PageTitle", "Name"),
			MaxHeight = 60,
			LayoutOrder = layoutOrder:getNextOrder(),
			TextSize = Constants.TEXT_SIZE,
		}, {
			TextBox = (if FFlagRemoveUILibraryRoundTextBox then
				Roact.createElement(TextInput2,  {
					ErrorText = nameError and localization:getText("Error", nameError, { tostring(nameLength), tostring(MAX_NAME_LENGTH) }),
					MaxLength = MAX_NAME_LENGTH,
					OnTextChanged = nameChanged,
					Text = name,
				})
			else
				Roact.createElement(RoundTextBox, {
					Active = true,
					ErrorMessage = nameError and localization:getText("Error", nameError, { tostring(nameLength), tostring(MAX_NAME_LENGTH) }),
					MaxLength = MAX_NAME_LENGTH,
					Text = name,
					TextSize = Constants.TEXT_SIZE,
					SetText = nameChanged,
				})
			),
		}),

		Description = Roact.createElement(TitledFrame, if FFlagRemoveUILibraryTitledFrame then {
			LayoutOrder = layoutOrder:getNextOrder(),
			Title = localization:getText("PageTitle", "Description"),
		} else {
			Title = localization:getText("PageTitle", "Description"),
			MaxHeight = theme.descriptionBox.maxHeight,
			LayoutOrder = layoutOrder:getNextOrder(),
			TextSize = Constants.TEXT_SIZE,
		}, {
			TextBox = (if FFlagRemoveUILibraryRoundTextBox then
				Roact.createElement(TextInput2, {
					ErrorText = descriptionError and localization:getText("Error", descriptionError, { tostring(descriptionLength), tostring(MAX_DESCRIPTION_LENGTH) }),
					Height = theme.descriptionBox.textBoxHeight,
					MaxLength = MAX_DESCRIPTION_LENGTH,
					MultiLine = true,
					OnTextChanged = descriptionChanged,
					Text = description,
				})
			else
				Roact.createElement(RoundTextBox, {
					Active = true,
					Height = theme.descriptionBox.textBoxHeight,
					Multiline = true,
					MaxLength = MAX_DESCRIPTION_LENGTH,
					Text = description,
					TextSize = Constants.TEXT_SIZE,
					SetText = descriptionChanged,
					ErrorMessage = descriptionError and localization:getText("Error", descriptionError, { tostring(descriptionLength), tostring(MAX_DESCRIPTION_LENGTH) }),
				})
			),
		}),

		Separator1 = Roact.createElement(Separator, {
			LayoutOrder = layoutOrder:getNextOrder(),
		}),

		Creator = Roact.createElement(TitledFrame, if FFlagRemoveUILibraryTitledFrame then {
			LayoutOrder = layoutOrder:getNextOrder(),
			Title = localization:getText("PageTitle", "Creator"),
		} else {
			Title = localization:getText("PageTitle", "Creator"),
			MaxHeight = 38,
			TextSize = Constants.TEXT_SIZE,
			ZIndex = 2,
			LayoutOrder = layoutOrder:getNextOrder(),
		}, {
			Selector = Roact.createElement(SelectInput, if FFlagCOLLAB734FixPublishPlaceAsDropdownContrastIssue then {
				Items = creatorItems,
				SelectedIndex = selectedCreatorIndex,
				OnItemActivated = selectCreator,
				Width = theme.selectInput.width.creator,
			} else {
				Items = DEPRECATED_dropdownItems,
				OnItemActivated = function(item)
					creatorChanged(item.Key)
				end,
				OnRenderItem = function(item, index, activated)
					local mainText = item.Text

					return Roact.createElement(Button, {
						OnClick = activated,
						LayoutOrder = index,
						Size = UDim2.new(1, 0, 0, theme.selectInput.button.height),
					}, {
						UILayout = Roact.createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Vertical,
							Padding = UDim.new(0, 0),
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Top,
						}),

						MainTextLabel = Roact.createElement(PaddedTextLabel, {
							Height = theme.selectInput.fontStyle.Normal.TextSize,
							LayoutOrder = 0,
							Padding = theme.selectInput.padding,
							Style = "Normal",
							Text = mainText,
						}),
					})
				end,
				PlaceholderText = DEPRECATED_creatorItem.Text,
				Width = theme.selectInput.width.creator,
			}),
		}),

		Separator2 = Roact.createElement(Separator, {
			LayoutOrder = layoutOrder:getNextOrder(),
		}),

		Genre = Roact.createElement(TitledFrame, if FFlagRemoveUILibraryTitledFrame then {
			LayoutOrder = layoutOrder:getNextOrder(),
			Title = localization:getText("PageTitle", "Genre"),
		} else {
			Title = localization:getText("PageTitle", "Genre"),
			MaxHeight = 38,
			TextSize = Constants.TEXT_SIZE,
			ZIndex = 2,
			LayoutOrder = layoutOrder:getNextOrder(),
		}, {
			Selector = Roact.createElement(SelectInput, if FFlagCOLLAB734FixPublishPlaceAsDropdownContrastIssue then {
				Items = genreItems,
				SelectedIndex = selectedGenreIndex,
				OnItemActivated = selectGenre,
				Width = theme.selectInput.width.genre,
			} else {
				Items = DEPRECATED_genres,
				OnItemActivated = function(item)
					genreChanged(item.Key)
				end,
				OnRenderItem = function(item, index, activated)
					local mainText = item.Text

					return Roact.createElement(Button, {
						OnClick = activated,
						LayoutOrder = index,
						Size = UDim2.new(1, 0, 0, theme.selectInput.button.height),
					}, {
						UILayout = Roact.createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Vertical,
							Padding = UDim.new(0, 0),
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Top,
						}),

						MainTextLabel = Roact.createElement(PaddedTextLabel, {
							Height = theme.selectInput.fontStyle.Normal.TextSize,
							LayoutOrder = 0,
							Padding = theme.selectInput.padding,
							Style = "Normal",
							Text = mainText,
						}),
					})
				end,
				PlaceholderText = localization:getText("Genre", genre),
				Width = theme.selectInput.width.genre,
			}),
		}),

		Separator4 = Roact.createElement(Separator, {
			LayoutOrder = layoutOrder:getNextOrder(),
		}),

		Devices = Roact.createElement(PlatformSelect, {
			LayoutOrder = layoutOrder:getNextOrder(),
			Devices = devices,
			DevicesError = devicesError,
			DeviceSelected = function(id, selected)
				local newDevices = Cryo.Dictionary.join(devices, {
					[id] = selected,
				})
				devicesChanged(newDevices)
			end,
		}),

		Separator3 = Roact.createElement(Separator, {
			LayoutOrder = layoutOrder:getNextOrder(),
		}),

		EnableTeamCreate = Roact.createElement(ToggleButtonWithTitle, {
			Title = localization:getText("TeamCreate", "Title"),
			LayoutOrder = layoutOrder:getNextOrder(),
			Disabled = false,
			Selected = props.TeamCreateEnabled,
			LinkProps = {
				Text = localization:getText("TeamCreate", "LinkDescription"),
				LinkText = localization:getText("TeamCreate", "LinkText"),
				OnLinkClicked = function()
					GuiService:OpenBrowserWindow(FStringTeamCreateLearnMoreLink)
				end,
			},
			OnClick = function()
				props.TeamCreateEnabledChanged(not props.TeamCreateEnabled)
			end,
		}, {
			TeachingCallout = Roact.createElement(TeachingCallout, {
				DefinitionId = "PublishPlaceAsTeamCreateToggleCallout",
				LocationId = "TeamCreateToggle", }),
			}),
	}

	if props.IsPublish then
		if shouldShowDevPublishLocations() then
			displayResult.Separator5 = Roact.createElement(Separator, {
				LayoutOrder = layoutOrder:getNextOrder(),
			})

			displayResult.OptInLocations = Roact.createElement(CheckBoxSet, {
				Title = localization:getText(optInLocationsKey, "TitleOptInLocations"),
				LayoutOrder = layoutOrder:getNextOrder(),
				MaxHeight = theme.optInLocations.height,
				Boxes = {{
					Id = chinaKey,
					Title = localization:getText(optInLocationsKey, chinaKey),
					Selected = optInLocations and optInLocations.China or false,
					LinkTextFrame = Roact.createElement("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(0, theme.requirementsLink.length, 0, theme.requirementsLink.height),
						Position = UDim2.new(0, 0, 0, theme.requirementsLink.paddingY),
					}, {
						LinkTextLabel = Roact.createElement(TextLabel, {
							Position = UDim2.new(0, hyperLinkTextSize.X, 0, 0),
							Size = UDim2.new(1, -hyperLinkTextSize.X, 1, 0),
							Style = "Body",
							Text = localization:getText(optInLocationsKey, "ChinaRequirements"),
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Top,
						}),

						LinkText = Roact.createElement(LinkText, {
							OnClick = function()
								local url = getOptInLocationsRequirementsLink(chinaKey)
								GuiService:OpenBrowserWindow(url)
							end,
							Size = UDim2.new(0, hyperLinkTextSize.X, 0, hyperLinkTextSize.Y),
							Style = "Body",
							Text = localization:getText(optInLocationsKey, "RequirementsLinkText"),
						}),
					}),
				}},
				Enabled = optInLocations ~= nil,
				EntryClicked = function(box)
					if not playerAcceptance then
						parent:setState({
							showDialog = true,
						})
					else
						local newLocations = Cryo.Dictionary.join(optInLocations, {
							[box.Id] = (box.Selected) and Cryo.None or not box.Selected,
						})
						local points = {
							[optInLocationsKey] = box.Id,
							[selectedKey] = not box.Selected,
						}
						sendAnalyticsToKibana(seriesNameKey, FIntLuobuDevPublishAnalyticsHundredthsPercentage, checkboxToggleKey, points)
						optInLocationsChanged(newLocations)
					end
				end,
				Tooltip = Roact.createElement(Image, {
					Size = UDim2.fromOffset(theme.tooltipIcon.size, theme.tooltipIcon.size),
					Position = UDim2.new(0, 0, 0, theme.tooltipIcon.paddingY),
					Style = "TooltipStyle",
					StyleModifier = parent.state.StyleModifier,
				}, {
					Roact.createElement(Tooltip, {
						Text = localization:getText(optInLocationsKey, "Tooltip"),
					}),
					Roact.createElement(HoverArea, {
						Cursor = "PointingHand",
						MouseEnter = parent.onMouseEnter,
						MouseLeave = parent.onMouseLeave,
					}),
				}),
			})

			displayResult.Dialog = Roact.createElement(StyledDialog, {
				Enabled = parent.state.showDialog,
				Modal = true,
				Title = "",
				MinContentSize = Vector2.new(theme.dialog.minSize.width, theme.dialog.minSize.height),
				Buttons = {
					{ Key = "OK", Text = localization:getText("General", "ReplyOK") }
				},
				OnButtonPressed = function()
					parent:setState({
						showDialog = false,
					})
					local points = {
						[buttonClickedKey] = "OK",
					}
					sendAnalyticsToKibana(seriesNameKey, FIntLuobuDevPublishAnalyticsHundredthsPercentage, termsOfUseDialogKey, points)
				end,
				OnClose = function()
					parent:setState({
						showDialog = false
					})
					local points = {
						[buttonClickedKey] = "Close",
					}
					sendAnalyticsToKibana(seriesNameKey, FIntLuobuDevPublishAnalyticsHundredthsPercentage, termsOfUseDialogKey, points)
				end,
				ButtonHorizontalAlignment = Enum.HorizontalAlignment.Center,
			}, {
				Layout = Roact.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				Header = Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.Title, {
					Position = UDim2.new(0.5, 0, 0, 45),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.new(1, 0, 0, 60),
					BackgroundTransparency = 1,
					Text = localization:getText("General", "TermsDialogHeader"),
					TextWrapped = true,
				})),

				Body = Roact.createElement(TextWithInlineLink, {
					OnLinkClicked = function()
						local url = getPlayerAppDownloadLink("China")
						GuiService:OpenBrowserWindow(url)
					end,
					Text = localization:getText("General", "TermsDialogBody"),
					LinkText = localization:getText("General", "TermsDialogBodyLink"),
					LinkPlaceholder = "[link]",
					MaxWidth = theme.textWithInlineLink.maxWidth,
					TextProps = Cryo.Dictionary.join(theme.fontStyle.Normal,{
						BackgroundTransparency = 1,
					}),
				})
			})
		end
	end

	return displayResult
end

--Loads settings values into props by key
local function loadValuesToProps(getValue, state)
	-- Set in settings reducer.
	local errors = state.NewGameSettings.errors
	local groupInfo = state.GroupsHavePermission.groupInfo

	return {
		NameError = errors.name,
		DescriptionError = errors.description,
		DevicesError = errors.playableDevices,
		IsCurrentlyActive = state.NewGameSettings.current.isActive,
		Groups = groupInfo.groups,

		Name = getValue("name"),
		Description = getValue("description"),
		Genre = getValue("genre"),
		Devices = getValue("playableDevices") or {},
		RootPlaceId = getValue("rootPlaceId"),
		IsActive = getValue("isActive"),
		IsFriendsOnly = getValue("isFriendsOnly"),
		CreatorId = getValue("creatorId"),
		OptInLocations = shouldShowDevPublishLocations() and getValue(optInLocationsKey) or {},
		PlayerAcceptance = state.Policy.PlayerAcceptance,
		TeamCreateEnabled = getValue(TEAM_CREATE_ENABLED),
	}
end

--Implements dispatch functions for when the user changes values
local function dispatchForProps(setValue, dispatch)
	return {
		CreatorChanged = setValue("creatorId"),

		GenreChanged = setValue("genre"),

		NameChanged = function(text)
			dispatch(AddChange("name", text))
			local nameLength = utf8.len(text)
			local whitespaceTrimmedString, _ = string.gsub(text, " ", "")
			if nameLength == 0 or string.len(whitespaceTrimmedString) == 0 then
				dispatch(AddErrors({name = "NameEmpty"}))
			elseif nameLength > MAX_NAME_LENGTH then
				dispatch(AddErrors({name = "NameTooLong"}))
			end
		end,

		DescriptionChanged = function(text)
			dispatch(AddChange("description", text))
			local descriptionLength = utf8.len(text)
			if descriptionLength > MAX_DESCRIPTION_LENGTH then
				dispatch(AddErrors({description = "DescriptionTooLong"}))
			end
		end,

		DevicesChanged = function(devices)
			dispatch(AddChange("playableDevices", devices))
			for _, value in pairs(devices) do
				if value then
					return
				end
			end
			dispatch(AddErrors({playableDevices = "NoDevices"}))
		end,

		OptInLocationsChanged = function(locations)
			if shouldShowDevPublishLocations() then
				dispatch(AddChange(optInLocationsKey, locations))
			end
		end,

		IsFriendsOnlyChanged = setValue("isFriendsOnly"),
		IsActiveChanged = setValue("isActive"),

		GetPlayerAcceptances = function(apiImpl)
			if not shouldShowDevPublishLocations() then
				return
			end

			dispatch(GetPlayerAcceptances(apiImpl))
		end,

		TeamCreateEnabledChanged = function(enabled)
			dispatch(AddChange(TEAM_CREATE_ENABLED, enabled))
		end,
	}
end

local basePage = createMenuPage(loadValuesToProps, dispatchForProps)

local function BasicInfo(props)
	return Roact.createElement(basePage, {
		Content = displayContents,
		AddLayout = true,
		IsPublish = props.IsPublish,
	})
end

return BasicInfo
