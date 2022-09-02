--!nonstrict
local CorePackages = game:GetService("CorePackages")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local RobloxGui = CoreGui:WaitForChild("RobloxGui")

local FFlagPlayerListRoactInspector = game:DefineFastFlag("PlayerListRoactInspector", false)

local AppDarkTheme = require(CorePackages.AppTempCommon.LuaApp.Style.Themes.DarkTheme)
local AppFont = require(CorePackages.AppTempCommon.LuaApp.Style.Fonts.Gotham)

local TenFootInterface = require(RobloxGui.Modules.TenFootInterface)
local SettingsUtil = require(RobloxGui.Modules.Settings.Utility)
local PolicyService = require(RobloxGui.Modules.Common.PolicyService)

local Roact = require(CorePackages.Roact)
local Rodux = require(CorePackages.Rodux)
local RoactRodux = require(CorePackages.RoactRodux)
local UIBlox = require(CorePackages.UIBlox)

local PlayerList = script.Parent

local EnableInGameMenuV3 = require(RobloxGui.Modules.InGameMenuV3.Flags.GetFFlagEnableInGameMenuV3)
local BackpackScript = require(RobloxGui.Modules.BackpackScript)
local EmotesMenuMaster = require(RobloxGui.Modules.EmotesMenu.EmotesMenuMaster)

local PlayerListApp = require(PlayerList.Components.Presentation.PlayerListApp)
local Reducer = require(PlayerList.Reducers.Reducer)
local GlobalConfig = require(PlayerList.GlobalConfig)
local CreateLayoutValues = require(PlayerList.CreateLayoutValues)
local Connection = PlayerList.Components.Connection
local LayoutValues = require(Connection.LayoutValues)
local LayoutValuesProvider = LayoutValues.Provider
local PlayerListSwitcher = require(PlayerList.PlayerListSwitcher)

-- Actions
local SetPlayerListEnabled = require(PlayerList.Actions.SetPlayerListEnabled)
local SetPlayerListVisibility = require(PlayerList.Actions.SetPlayerListVisibility)
local SetTempHideKey = require(PlayerList.Actions.SetTempHideKey)
local SetTenFootInterface = require(PlayerList.Actions.SetTenFootInterface)
local SetSmallTouchDevice = require(PlayerList.Actions.SetSmallTouchDevice)
local SetIsUsingGamepad = require(PlayerList.Actions.SetIsUsingGamepad)
local SetHasPermissionToVoiceChat = require(PlayerList.Actions.SetHasPermissionToVoiceChat)
local SetMinimized = require(PlayerList.Actions.SetMinimized)
local SetSubjectToChinaPolicies = require(PlayerList.Actions.SetSubjectToChinaPolicies)

local FFlagMobilePlayerList = require(RobloxGui.Modules.Flags.FFlagMobilePlayerList)

if not Players.LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

local XPRIVILEGE_COMMUNICATION_VOICE_INGAME = 205

local function isSmallTouchScreen()
	if _G.__TESTEZ_RUNNING_TEST__ then
		return false
	end
	return SettingsUtil:IsSmallTouchScreen()
end

local layerCollector
if FFlagMobilePlayerList then
	layerCollector = Instance.new("ScreenGui")
	layerCollector.Parent = CoreGui
	layerCollector.Name = "PlayerList"
	layerCollector.DisplayOrder = 1
	layerCollector.IgnoreGuiInset = true
	layerCollector.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
end

local PlayerListMaster = {}
PlayerListMaster.__index = PlayerListMaster

function PlayerListMaster.new()
	local self = setmetatable({}, PlayerListMaster)

	if GlobalConfig.propValidation then
		Roact.setGlobalConfig({
			propValidation = true,
		})
	end
	if GlobalConfig.elementTracing then
		Roact.setGlobalConfig({
			elementTracing = true,
		})
	end

	self.store = Rodux.Store.new(Reducer, nil, {
		Rodux.thunkMiddleware,
	})

	if not StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList) then
		self.store:dispatch(SetPlayerListEnabled(false))
	end

	coroutine.wrap(function()
		self.store:dispatch(SetSmallTouchDevice(isSmallTouchScreen()))
	end)()

	self.store:dispatch(SetTenFootInterface(TenFootInterface:IsEnabled()))
	if TenFootInterface:IsEnabled() then
		coroutine.wrap(function()
			pcall(function()
				--This is pcalled because platformService won't exist in Roblox studio when emulating xbox.
				local platformService = game:GetService("PlatformService")
				if platformService:BeginCheckXboxPrivilege(
					XPRIVILEGE_COMMUNICATION_VOICE_INGAME).PrivilegeCheckResult == "NoIssue" then
					self.store:dispatch(SetHasPermissionToVoiceChat(true))
				end
			end)
		end)()
	end

	coroutine.wrap(function()
		self.store:dispatch(SetSubjectToChinaPolicies(PolicyService:IsSubjectToChinaPolicies()))
	end)()

	local lastInputType = UserInputService:GetLastInputType()
	local isGamepad = lastInputType and lastInputType.Name:find("Gamepad")
	self.store:dispatch(SetIsUsingGamepad(isGamepad ~= nil))

	self:_trackEnabled()

	local appStyle = {
		Theme = AppDarkTheme,
		Font = AppFont,
	}

	if FFlagMobilePlayerList then
		self.root = Roact.createElement(RoactRodux.StoreProvider, {
			store = self.store,
		}, {
			Roact.createElement(PlayerListSwitcher, {
				appStyle = appStyle,
				setLayerCollectorEnabled = function(enabled)
					layerCollector.Enabled = enabled
				end,
			})
		})
		self.element = Roact.mount(self.root, layerCollector, "PlayerListMaster")

	else
		self.root = Roact.createElement(RoactRodux.StoreProvider, {
			store = self.store,
		}, {
			LayoutValuesProvider = Roact.createElement(LayoutValuesProvider, {
				layoutValues = CreateLayoutValues(TenFootInterface:IsEnabled())
			}, {
				ThemeProvider = Roact.createElement(UIBlox.Style.Provider, {
					style = appStyle,
				}, {
					PlayerListApp = Roact.createElement(PlayerListApp)
				})
			})
		})

		self.element = Roact.mount(self.root, RobloxGui, "PlayerListMaster")
	end

	if FFlagPlayerListRoactInspector then
		local hasInternalPermission = game:GetService("RunService"):IsStudio()
			and game:GetService("StudioService"):HasInternalPermission()
		if hasInternalPermission then
			local DeveloperTools = require(CorePackages.DeveloperTools)
			local parent = FFlagMobilePlayerList and layerCollector or RobloxGui
			self.inspector = DeveloperTools.forCoreGui("PlayerList", {
				rootInstance = parent:FindFirstChild("PlayerListMaster"),
				pickerParent = "RobloxGui",
			})
			self.inspector:addRoactTree("Roact tree", self.element, Roact)
		end
	end

	self.topBarEnabled = true
	self.mounted = true
	self.coreGuiEnabled = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
	self:_updateMounted()

	self.SetVisibleChangedEvent = Instance.new("BindableEvent")

	if EnableInGameMenuV3() then
		BackpackScript.StateChanged.Event:Connect(function(isBackpackOpen)
			if isBackpackOpen then
				if self:GetVisibility() then
					self:SetVisibility(false)
				end
			end
		end)
	
		EmotesMenuMaster.EmotesMenuToggled.Event:Connect(function(isEmotesOpen)
			if isEmotesOpen then
				if self:GetVisibility() then
					self:SetVisibility(false)
				end
			end
		end)
	end

	self.store.changed:connect(function(newState, oldState)
		if newState.displayOptions.setVisible ~= oldState.displayOptions.setVisible then
			self.SetVisibleChangedEvent:Fire(newState.displayOptions.setVisible)
		end
	end)

	return self
end

function PlayerListMaster:_updateMounted()
	if not TenFootInterface:IsEnabled() then
		local shouldMount = self.coreGuiEnabled and self.topBarEnabled
		if shouldMount and not self.mounted then
			local root = FFlagMobilePlayerList and layerCollector or RobloxGui
			self.element = Roact.mount(self.root, root, "PlayerListMaster")
			self.mounted = true
		elseif not shouldMount and self.mounted then
			Roact.unmount(self.element)
			self.mounted = false
			if self.inspector then
				self.inspector:destroy()
				self.inspector = nil
			end
		end
	end
end

function PlayerListMaster:_trackEnabled()
	StarterGui.CoreGuiChangedSignal:Connect(function(coreGuiType, enabled)
		if coreGuiType == Enum.CoreGuiType.All or coreGuiType == Enum.CoreGuiType.PlayerList then
			self.coreGuiEnabled = enabled
			self:_updateMounted()
			self.store:dispatch(SetPlayerListEnabled(enabled))
		end
	end)
end

function PlayerListMaster:GetVisibility()
	return self.store:getState().displayOptions.isVisible
end

function PlayerListMaster:GetSetVisible()
	return self.store:getState().displayOptions.setVisible
end

function PlayerListMaster:GetSetVisibleChangedEvent()
	return self.SetVisibleChangedEvent
end

function PlayerListMaster:SetVisibility(value)
	if EnableInGameMenuV3() and value then
		if BackpackScript.IsOpen then
			BackpackScript:OpenClose()
		end
		if EmotesMenuMaster:isOpen() then
			EmotesMenuMaster:close()
		end
	end
	self.store:dispatch(SetPlayerListVisibility(value))
end

function PlayerListMaster:HideTemp(requester, hidden)
	if hidden == false then
		hidden = nil
	end
	self.store:dispatch(SetTempHideKey(requester, hidden))
end

function PlayerListMaster:SetTopBarEnabled(value)
	self.topBarEnabled = value
	self:_updateMounted()
end

function PlayerListMaster:SetMinimized(value)
	self.store:dispatch(SetMinimized(value))
end

return PlayerListMaster
