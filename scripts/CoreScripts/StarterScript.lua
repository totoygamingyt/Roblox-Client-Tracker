--!nonstrict
-- Creates all neccessary scripts for the gui on initial load, everything except build tools
-- Created by Ben T. 10/29/10
-- Please note that these are loaded in a specific order to diminish errors/perceived load time by user

local CorePackages = game:GetService("CorePackages")
local ScriptContext = game:GetService("ScriptContext")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VRService = game:GetService("VRService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RobloxGui = game:GetService("CoreGui"):WaitForChild("RobloxGui")
local CoreGuiModules = RobloxGui:WaitForChild("Modules")

local loadErrorHandlerFromEngine = game:GetEngineFeature("LoadErrorHandlerFromEngine")

local initify = require(CorePackages.initify)

-- Initifying CorePackages.Packages is required for the error reporter to work.
initify(CorePackages.Packages)

-- Load the error reporter as early as possible, even before we finish requiring,
-- so that it can report any errors that come after this point.
ScriptContext:AddCoreScriptLocal("CoreScripts/CoreScriptErrorReporter", RobloxGui)

local Roact = require(CorePackages.Roact)
local PolicyService = require(CoreGuiModules:WaitForChild("Common"):WaitForChild("PolicyService"))

-- remove this when removing FFlagConnectErrorHandlerInLoadingScript
local FFlagConnectionScriptEnabled = settings():GetFFlag("ConnectionScriptEnabled")
local FFlagLuaInviteModalEnabled = settings():GetFFlag("LuaInviteModalEnabledV384")
local FFlagVirtualCursorEnabled = game:GetEngineFeature("VirtualCursorEnabled")
local FFlagVRAvatarGestures = game:DefineFastFlag("VRAvatarGestures", false)

local FFlagUseRoactGlobalConfigInCoreScripts = require(RobloxGui.Modules.Flags.FFlagUseRoactGlobalConfigInCoreScripts)
local FFlagConnectErrorHandlerInLoadingScript = require(RobloxGui.Modules.Flags.FFlagConnectErrorHandlerInLoadingScript)

local GetFFlagScreenTime = require(CorePackages.Regulations.ScreenTime.GetFFlagScreenTime)

local GetFFlagScreenshotHudApi = require(RobloxGui.Modules.Flags.GetFFlagScreenshotHudApi)

local GetFFlagEnableVoiceDefaultChannel = require(RobloxGui.Modules.Flags.GetFFlagEnableVoiceDefaultChannel)

local GetFFlagStartScreenTimeUsingGuacEnabled
	= require(CorePackages.Regulations.ScreenTime.GetFFlagStartScreenTimeUsingGuacEnabled)

local GetFFlagEnableIXPInGame = require(CoreGuiModules.Common.Flags.GetFFlagEnableIXPInGame)

local GetFFlagShareInviteLinkContextMenuV1ABTestEnabled = require(RobloxGui.Modules.Settings.Flags.GetFFlagShareInviteLinkContextMenuV1ABTestEnabled)
local ShareInviteLinkABTestManager = require(RobloxGui.Modules.Settings.ShareInviteLinkABTestManager)
local IsExperienceMenuABTestEnabled = require(CoreGuiModules.InGameMenuV3.IsExperienceMenuABTestEnabled)
local ExperienceMenuABTestManager = require(CoreGuiModules.InGameMenuV3.ExperienceMenuABTestManager)
local GetFFlagEnableNewInviteMenuIXP = require(CoreGuiModules.Flags.GetFFlagEnableNewInviteMenuIXP)
local NewInviteMenuExperimentManager = require(CoreGuiModules.Settings.Pages.ShareGame.NewInviteMenuExperimentManager)

local GetCoreScriptsLayers = require(CoreGuiModules.Experiment.GetCoreScriptsLayers)

local FFlagEnableLuobuWarningToast = require(RobloxGui.Modules.Flags.FFlagEnableLuobuWarningToast)

local GetFFlagRtMessaging = require(RobloxGui.Modules.Flags.GetFFlagRtMessaging)

local GetFFlagEnableKeyboardUINavigation = require(RobloxGui.Modules.Flags.GetFFlagEnableKeyboardUINavigation)

game:DefineFastFlag("MoodsEmoteFix3", false)
game:DefineFastFlag("SelfieViewFeature", false)

-- The Rotriever index, as well as the in-game menu code itself, relies on
-- the init.lua convention, so we have to run initify over the module.
-- We do this explicitly because the LocalPlayer hasn't been created at this
-- point, so we can't check enrollment status.
initify(CoreGuiModules.InGameMenu)
initify(CoreGuiModules.InGameMenuV3)
initify(CoreGuiModules.TrustAndSafety)

local RoactGamepad = require(CorePackages.Packages.RoactGamepad)
local FFlagRoactGamepadFixDelayedRefFocusLost = require(CorePackages.AppTempCommon.Flags.FFlagRoactGamepadFixDelayedRefFocusLost)
RoactGamepad.Config.TempFixDelayedRefFocusLost = FFlagRoactGamepadFixDelayedRefFocusLost

local UIBlox = require(CorePackages.UIBlox)
local uiBloxConfig = require(CoreGuiModules.UIBloxInGameConfig)
UIBlox.init(uiBloxConfig)

local localPlayer = Players.LocalPlayer
while not localPlayer do
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	localPlayer = Players.LocalPlayer
end

-- Since prop validation can be expensive in certain scenarios, you can enable
-- this flag locally to validate props to Roact components.
if FFlagUseRoactGlobalConfigInCoreScripts and RunService:IsStudio() then
	Roact.setGlobalConfig({
		propValidation = true,
		elementTracing = true,
	})
end

local InGameMenuDependencies = require(CorePackages.InGameMenuDependencies)
local InGameMenuUIBlox = InGameMenuDependencies.UIBlox
if InGameMenuUIBlox ~= UIBlox then
	InGameMenuUIBlox.init(uiBloxConfig)
end

local soundFolder = Instance.new("Folder")
soundFolder.Name = "Sounds"
soundFolder.Parent = RobloxGui

-- This can be useful in cases where a flag configuration issue causes requiring a CoreScript to fail
local function safeRequire(moduleScript)
	local success, ret = pcall(require, moduleScript)
	if success then
		return ret
	else
		warn("Failure to Start CoreScript module " .. moduleScript.Name .. ".\n" .. ret)
	end
end

if not FFlagConnectErrorHandlerInLoadingScript and not loadErrorHandlerFromEngine then
	if FFlagConnectionScriptEnabled and not GuiService:IsTenFootInterface() then
		ScriptContext:AddCoreScriptLocal("Connection", RobloxGui)
	end
end

-- In-game notifications script
ScriptContext:AddCoreScriptLocal("CoreScripts/NotificationScript2", RobloxGui)

-- TopBar
initify(CoreGuiModules.TopBar)
coroutine.wrap(safeRequire)(CoreGuiModules.TopBar)

if game:GetEngineFeature("LuobuModerationStatus") then
	coroutine.wrap(function()
		initify(CoreGuiModules.Watermark)
		safeRequire(CoreGuiModules.Watermark)
	end)()
end

-- MainBotChatScript (the Lua part of Dialogs)
ScriptContext:AddCoreScriptLocal("CoreScripts/MainBotChatScript2", RobloxGui)

if game:GetEngineFeature("ProximityPrompts") then
	ScriptContext:AddCoreScriptLocal("CoreScripts/ProximityPrompt", RobloxGui)
end

coroutine.wrap(function() -- this is the first place we call, which can yield so wrap in coroutine
	if GetFFlagStartScreenTimeUsingGuacEnabled() then
		ScriptContext:AddCoreScriptLocal("CoreScripts/ScreenTimeInGame", RobloxGui)
	else
		if PolicyService:IsSubjectToChinaPolicies() then
			ScriptContext:AddCoreScriptLocal("CoreScripts/AntiAddictionPrompt", RobloxGui)
			if GetFFlagScreenTime() then
				ScriptContext:AddCoreScriptLocal("CoreScripts/ScreenTimeInGame", RobloxGui)
			end
		end
	end
end)()

if FFlagEnableLuobuWarningToast then
	coroutine.wrap(function()
		if PolicyService:IsSubjectToChinaPolicies() then
			if not game:IsLoaded() then
				game.Loaded:Wait()
			end
			initify(CoreGuiModules.LuobuWarningToast)
			safeRequire(CoreGuiModules.LuobuWarningToast)
		end
	end)()
end

-- Performance Stats Management
ScriptContext:AddCoreScriptLocal("CoreScripts/PerformanceStatsManagerScript", RobloxGui)

-- Default Alternate Death Ragdoll (China only for now)
ScriptContext:AddCoreScriptLocal("CoreScripts/PlayerRagdoll", RobloxGui)

-- Chat script
coroutine.wrap(safeRequire)(RobloxGui.Modules.ChatSelector)
coroutine.wrap(safeRequire)(RobloxGui.Modules.PlayerList.PlayerListManager)

local UserRoactBubbleChatBeta do
	local success, value = pcall(function()
		return UserSettings():IsUserFeatureEnabled("UserRoactBubbleChatBeta")
	end)
	UserRoactBubbleChatBeta = success and value
end

if game:GetEngineFeature("EnableBubbleChatFromChatService") or UserRoactBubbleChatBeta then
	ScriptContext:AddCoreScriptLocal("CoreScripts/PlayerBillboards", RobloxGui)
end

-- Purchase Prompt Script
coroutine.wrap(function()
	initify(CoreGuiModules.PurchasePrompt)
	local PurchasePrompt = safeRequire(CoreGuiModules.PurchasePrompt)

	if PurchasePrompt then
		PurchasePrompt.mountPurchasePrompt()
	end
end)()

-- Prompt Block Player Script
ScriptContext:AddCoreScriptLocal("CoreScripts/BlockPlayerPrompt", RobloxGui)
ScriptContext:AddCoreScriptLocal("CoreScripts/FriendPlayerPrompt", RobloxGui)

-- Avatar Context Menu
ScriptContext:AddCoreScriptLocal("CoreScripts/AvatarContextMenu", RobloxGui)

-- Backpack!
coroutine.wrap(safeRequire)(RobloxGui.Modules.BackpackScript)

-- Keyboard Navigation :)
if GetFFlagEnableKeyboardUINavigation() then
	coroutine.wrap(safeRequire)(RobloxGui.Modules.KeyboardUINavigation)
end

-- Emotes Menu
coroutine.wrap(safeRequire)(RobloxGui.Modules.EmotesMenu.EmotesMenuMaster)

initify(CoreGuiModules.AvatarEditorPrompts)
coroutine.wrap(safeRequire)(CoreGuiModules.AvatarEditorPrompts)

-- GamepadVirtualCursor
if FFlagVirtualCursorEnabled then
	coroutine.wrap(safeRequire)(RobloxGui.Modules.VirtualCursor.VirtualCursorMain)
end

ScriptContext:AddCoreScriptLocal("CoreScripts/VehicleHud", RobloxGui)

if FFlagLuaInviteModalEnabled then
	ScriptContext:AddCoreScriptLocal("CoreScripts/InviteToGamePrompt", RobloxGui)
end

if UserInputService.TouchEnabled then -- touch devices don't use same control frame
	-- only used for touch device button generation
	ScriptContext:AddCoreScriptLocal("CoreScripts/ContextActionTouch", RobloxGui)

	RobloxGui:WaitForChild("ControlFrame")
	RobloxGui.ControlFrame:WaitForChild("BottomLeftControl")
	RobloxGui.ControlFrame.BottomLeftControl.Visible = false
end

ScriptContext:AddCoreScriptLocal("CoreScripts/InspectAndBuy", RobloxGui)

coroutine.wrap(function()
	if not VRService.VREnabled then
		VRService:GetPropertyChangedSignal("VREnabled"):Wait()
	end
	safeRequire(RobloxGui.Modules.VR.VirtualKeyboard)
	safeRequire(RobloxGui.Modules.VR.UserGui)
end)()

ScriptContext:AddCoreScriptLocal("CoreScripts/NetworkPause", RobloxGui)

if GetFFlagScreenshotHudApi() and not PolicyService:IsSubjectToChinaPolicies() then
	ScriptContext:AddCoreScriptLocal("CoreScripts/ScreenshotHud", RobloxGui)
end

if game:GetEngineFeature("VoiceChatSupported") and GetFFlagEnableVoiceDefaultChannel() then
	ScriptContext:AddCoreScriptLocal("CoreScripts/VoiceDefaultChannel", RobloxGui)
end

if GetFFlagEnableIXPInGame() then
	coroutine.wrap(function()
		local IXPServiceWrapper = require(CoreGuiModules.Common.IXPServiceWrapper)
		IXPServiceWrapper:InitializeAsync(localPlayer.UserId, GetCoreScriptsLayers())
		if IsExperienceMenuABTestEnabled() then
			ExperienceMenuABTestManager.default:initialize()
		end

		if GetFFlagShareInviteLinkContextMenuV1ABTestEnabled() then
			ShareInviteLinkABTestManager.default:initialize()
		end

		if GetFFlagEnableNewInviteMenuIXP() then
			NewInviteMenuExperimentManager.default:initialize()
		end
	end)()
end

ScriptContext:AddCoreScriptLocal("CoreScripts/ExperienceChatMain", RobloxGui)

ScriptContext:AddCoreScriptLocal("CoreScripts/ChatEmoteUsage", script.Parent)

if GetFFlagRtMessaging() then
	game:GetService("RtMessagingService")
end

if game:GetEngineFeature("FacialAnimationStreaming") then
	ScriptContext:AddCoreScriptLocal("CoreScripts/FacialAnimationStreaming", script.Parent)
	if game:GetFastFlag("SelfieViewFeature") then
		ScriptContext:AddCoreScriptLocal("CoreScripts/FaceChatSelfieView", RobloxGui)
	end	
	if game:GetEngineFeature("TrackerLodControllerDebugUI") then
		ScriptContext:AddCoreScriptLocal("CoreScripts/TrackerLodControllerDebugUI", script.Parent)
	end
end

if FFlagVRAvatarGestures then
	coroutine.wrap(safeRequire)(RobloxGui.Modules.VR.AvatarGesturesController)
end

if game:GetEngineFeature("NewMoodAnimationTypeApiEnabled") and game:GetFastFlag("MoodsEmoteFix3") then
	ScriptContext:AddCoreScriptLocal("CoreScripts/AvatarMood", script.Parent)
end