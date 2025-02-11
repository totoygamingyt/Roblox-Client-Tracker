return function(plugin, pluginLoaderContext)
	if not plugin then
		return
	end

	-- Fast flags
	local FFlagDebugBuiltInPluginModalsNotBlocking = game:GetFastFlag("DebugBuiltInPluginModalsNotBlocking")
	local FFlagDeveloperSubscriptionsEnabled = game:GetFastFlag("DeveloperSubscriptionsEnabled")
	local FFlagGameSettingsRoactInspector = game:DefineFastFlag("GameSettingsRoactInspector", false)

	--Turn this on when debugging the store and actions
	local LOG_STORE_STATE_AND_EVENTS = false

	local RunService = game:GetService("RunService")

	local Plugin = script.Parent.Parent
	local Roact = require(Plugin.Packages.Roact)
	local Rodux = require(Plugin.Packages.Rodux)
	local Cryo = require(Plugin.Packages.Cryo)

	local Framework = require(Plugin.Packages.Framework)
	local ContextServices = Framework.ContextServices
	local FrameworkUtil = Framework.Util
	local Promise = FrameworkUtil.Promise

	local MainView = require(Plugin.Src.Components.MainView)
	local SimpleDialog = require(Plugin.Src.Components.Dialog.SimpleDialog)
	local MainReducer = require(Plugin.Src.Reducers.MainReducer)
	local ExternalServicesWrapper = require(Plugin.Src.Components.ExternalServicesWrapper)
	local MakeTheme = require(Plugin.Src.Util.MakeTheme)
	local Networking = require(Plugin.Src.ContextServices.Networking)
	local WorldRootPhysics = require(Plugin.Pages.WorldPage.ContextServices.WorldRootPhysics)
	local GameInfoController = require(Plugin.Src.Controllers.GameInfoController)
	local GameMetadataController = require(Plugin.Src.Controllers.GameMetadataController)
	local GroupMetadataController = require(Plugin.Src.Controllers.GroupMetadataController)
	local GamePermissionsController = require(Plugin.Pages.PermissionsPage.Controllers.GamePermissionsController)
	local GameOptionsController = require(Plugin.Pages.OptionsPage.Controllers.GameOptionsController)
	local MonetizationController = require(Plugin.Pages.MonetizationPage.Controllers.MonetizationController)
	local DevSubsController = require(Plugin.Pages.MonetizationPage.Controllers.DevSubsController)
	local PlacesController = require(Plugin.Pages.PlacesPage.Controllers.PlacesController)
	local PolicyInfoController = require(Plugin.Src.Controllers.PolicyInfoController)
	local SecurityController = require(Plugin.Pages.SecurityPage.Controllers.SecurityController)
	local SocialController = require(Plugin.Pages.PermissionsPage.Controllers.SocialController)
	local UniverseAvatarController = require(Plugin.Pages.AvatarPage.Controllers.UniverseAvatarController)
	local LocalizationPageController = require(Plugin.Pages.LocalizationPage.Controllers.LocalizationPageController)

	local CurrentStatus = require(Plugin.Src.Util.CurrentStatus)

	local ResetStore = require(Plugin.Src.Actions.ResetStore)
	local SetCurrentStatus = require(Plugin.Src.Actions.SetCurrentStatus)
	local DiscardChanges = require(Plugin.Src.Actions.DiscardChanges)
	local SetGameId = require(Plugin.Src.Actions.SetGameId)
	local SetGame = require(Plugin.Src.Actions.SetGame)

	local isEmpty = require(Plugin.Src.Util.isEmpty)
	local Analytics = require(Plugin.Src.Util.Analytics)

	local gameSettingsHandle
	local pluginGui
	local openedTimestamp
	local inspector

	local worldRootPhysics = WorldRootPhysics.new()

	local thunkContextItems = {}

	local networking = Networking.new()
	local gameInfoController = GameInfoController.new(networking:get())
	local gameMetadataController = GameMetadataController.new(networking:get())
	local groupMetadataController = GroupMetadataController.new(networking:get())
	local gamePermissionsController = GamePermissionsController.new(networking:get())
	local monetizationController = MonetizationController.new(networking:get())
	local devSubsController = FFlagDeveloperSubscriptionsEnabled and DevSubsController.new(networking:get()) or nil
	local gameOptionsController = GameOptionsController.new(networking:get())
	local universePermissionsController = SecurityController.new(networking:get())
	local socialController = SocialController.new(networking:get())
	local universeAvatarController = UniverseAvatarController.new(networking:get())
	local placesController = PlacesController.new(networking:get())
	local localizationPageController = LocalizationPageController.new(networking:get())
	local policyInfoController = PolicyInfoController.new(networking:get())

	thunkContextItems.networking = networking:get()
	thunkContextItems.worldRootPhysicsController = worldRootPhysics:get()
	thunkContextItems.gameInfoController = gameInfoController
	thunkContextItems.gameMetadataController = gameMetadataController
	thunkContextItems.groupMetadataController = groupMetadataController
	thunkContextItems.gamePermissionsController = gamePermissionsController
	thunkContextItems.gameOptionsController = gameOptionsController
	thunkContextItems.monetizationController = monetizationController
	thunkContextItems.devSubsController = devSubsController
	thunkContextItems.universePermissionsController = universePermissionsController
	thunkContextItems.socialController = socialController
	thunkContextItems.universeAvatarController = universeAvatarController
	thunkContextItems.placesController = placesController
	thunkContextItems.localizationPageController = localizationPageController
	thunkContextItems.policyInfoController = policyInfoController

	local thunkWithArgsMiddleware = FrameworkUtil.ThunkWithArgsMiddleware(thunkContextItems)
	local middlewares = { thunkWithArgsMiddleware }

	if LOG_STORE_STATE_AND_EVENTS then
		table.insert(middlewares, Rodux.loggerMiddleware)
	end

	local settingsStore = Rodux.Store.new(MainReducer, nil, middlewares)
	local lastObservedStatus = CurrentStatus.Open

	local SourceStrings = Plugin.Src.Resources.SourceStrings
	local LocalizedStrings = Plugin.Src.Resources.LocalizedStrings

	local localization = ContextServices.Localization.new({
		pluginName = Plugin.Name,
		stringResourceTable = SourceStrings,
		translationResourceTable = LocalizedStrings,
	})

	-- Make sure that the main window elements cannot be interacted with
	-- when a second dialog is open over the Game Settings widget
	local function setMainWidgetInteractable(interactable)
		if pluginGui then
			for _, instance in pairs(pluginGui:GetDescendants()) do
				if instance:IsA("GuiObject") then
					instance.Active = interactable
				end
			end
		end
	end

	local function showDialog(type, props)
		return Promise.new(function(resolve, reject)
			spawn(function()
				setMainWidgetInteractable(false)
				local dialogHandle
				local CancelDialogBody
				local size = props.Size or Vector2.new(473, 197)
				local dialog
				dialog = plugin:CreateQWidgetPluginGui(props.Title, {
					Size = size,
					Modal = not FFlagDebugBuiltInPluginModalsNotBlocking,
				})
				dialog.Enabled = true
				dialog.Title = props.Title
				local dialogContents = Roact.createElement(ExternalServicesWrapper, {
					theme = MakeTheme(),
					mouse = plugin:GetMouse(),
					localization = localization,
					pluginGui = pluginGui,
					plugin = plugin,
				}, {
					Content = Roact.createElement(
						type,
						Cryo.Dictionary.join(props, {
							OnResult = function(result)
								Roact.unmount(dialogHandle)
								dialog:Destroy()
								setMainWidgetInteractable(true)
								resolve(result)
							end,
						})
					),
				})

				dialog:BindToClose(function()
					Roact.unmount(dialogHandle)
					dialog:Destroy()
					setMainWidgetInteractable(true)
					resolve(false)
				end)

				dialogHandle = Roact.mount(dialogContents, dialog)
			end)
		end)
	end

	local function closeAnalytics(userPressedSave)
		if openedTimestamp then
			local timeOpen = tick() - openedTimestamp
			openedTimestamp = nil
			Analytics.onCloseEvent(userPressedSave and "Save" or "Cancel", timeOpen)
		end
	end

	--Closes and unmounts the Game Settings popup window
	local function closeGameSettings(userPressedSave)
		local state = settingsStore:getState()
		local currentStatus = state.Status

		local function close()
			--Exit game settings and delete all changes without saving
			settingsStore:dispatch(DiscardChanges())
			settingsStore:dispatch(SetCurrentStatus(CurrentStatus.Closed))
			pluginGui.Enabled = false
			Roact.unmount(gameSettingsHandle)

			if FFlagGameSettingsRoactInspector and inspector then
				inspector:destroy()
			end

			closeAnalytics(userPressedSave)
		end

		if currentStatus == CurrentStatus.Working and not userPressedSave then
			close()
			return
		end

		if currentStatus ~= CurrentStatus.Closed then
			if currentStatus == CurrentStatus.Error and userPressedSave then
				settingsStore:dispatch(SetCurrentStatus(CurrentStatus.Open))
			else
				local changed = state.Settings.Changed
				local hasUnsavedChanges = changed and not isEmpty(changed)
				if hasUnsavedChanges and not userPressedSave then
					--Prompt if the user actually wanted to save using a Modal
					local dialogProps
					dialogProps = {
						Size = Vector2.new(343, 145),
						Title = localization:getText("General", "CancelDialogHeader"),
						Header = localization:getText("General", "CancelDialogBody"),
						Buttons = {
							localization:getText("General", "ReplyNo"),
							localization:getText("General", "ReplyYes"),
						},
					}
					showDialog(SimpleDialog, dialogProps):andThen(function(didDiscardAllChanges)
						if didDiscardAllChanges then
							close()
						else
							--Return to game settings window without modifying state,
							--giving the user another chance to modify or save.
							settingsStore:dispatch(SetCurrentStatus(CurrentStatus.Open))
							if not pluginGui.Enabled then
								pluginGui.Enabled = true
							end
						end
					end)
				else
					settingsStore:dispatch(SetCurrentStatus(CurrentStatus.Closed))
					pluginGui.Enabled = false
					Roact.unmount(gameSettingsHandle)

					if FFlagGameSettingsRoactInspector and inspector then
						inspector:destroy()
					end

					closeAnalytics(userPressedSave)
				end
			end
		end
	end

	local function makePluginGui()
		local pluginId = Plugin.Name
		local size = Vector2.new(960, 600)
		pluginGui = plugin:CreateQWidgetPluginGui(pluginId, {
			Size = size,
			MinSize = size,
			Resizable = true,
			Modal = not FFlagDebugBuiltInPluginModalsNotBlocking,
			InitialEnabled = false,
		})
		pluginGui.Name = Plugin.Name
		pluginGui.Title = localization:getText("General", "PluginName")
		pluginGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		pluginGui:BindToClose(function()
			closeGameSettings(false)
		end)
	end

	--Initializes and populates the Game Settings popup window
	local function openGameSettings(gameId, dataModel, firstSelectedId)
		if settingsStore then
			local state = settingsStore:getState()
			local currentStatus = state.Status
			if currentStatus ~= CurrentStatus.Closed then
				return
			end
		end

		local servicesProvider = Roact.createElement(ExternalServicesWrapper, {
			store = settingsStore,
			showDialog = showDialog,
			theme = MakeTheme(),
			mouse = plugin:GetMouse(),
			localization = localization,
			pluginGui = pluginGui,
			plugin = plugin,
			worldRootPhysics = worldRootPhysics,
		}, {
			mainView = Roact.createElement(MainView, {
				OnClose = closeGameSettings,
				FirstSelectedId = firstSelectedId,
			}),
		})

		settingsStore:dispatch(ResetStore())
		settingsStore:dispatch(SetGameId(gameId))
		settingsStore:dispatch(SetGame(dataModel))

		settingsStore:dispatch(SetCurrentStatus(CurrentStatus.Open))

		gameSettingsHandle = Roact.mount(servicesProvider, pluginGui)
		pluginGui.Enabled = true

		if FFlagGameSettingsRoactInspector then
			if game:GetService("StudioService"):HasInternalPermission() then
				inspector = Framework.DeveloperTools.forPlugin("Game Settings", plugin)
				inspector:addRoactTree("Roact tree", gameSettingsHandle, Roact)
			end
		end

		Analytics.onOpenEvent(plugin:GetStudioUserId(), gameId)
		openedTimestamp = tick()
	end

	--Binds a toolbar button to the Game Settings window
	local function main()
		plugin.Name = Plugin.Name

		local settingsButton = pluginLoaderContext.mainButton

		-- Don't want to be able to open game settings while the game is running
		-- it is for edit mode only!
		if RunService:IsEdit() then
			makePluginGui()
			settingsButton.ClickableWhenViewportHidden = true
			settingsButton.Enabled = true

			pluginLoaderContext.mainButtonClickedSignal:Connect(function()
				openGameSettings(game.GameId, game)
			end)
			settingsStore.changed:connect(function(state)
				if state.Status ~= lastObservedStatus then
					settingsButton:SetActive(state.Status ~= CurrentStatus.Closed)
					setMainWidgetInteractable(state.Status ~= CurrentStatus.Working)
					lastObservedStatus = state.Status
				end
			end)

			-- hook into event for opening game settings
			pluginLoaderContext.signals["StudioService.OnOpenGameSettings"]:Connect(function(pageIdentifier)
				openGameSettings(game.GameId, game, pageIdentifier)
			end)
		else
			settingsButton.Enabled = false
		end
	end

	main()
end
