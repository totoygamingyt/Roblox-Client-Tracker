--!nonstrict
local CorePackages = game:GetService("CorePackages")
local GuiService = game:GetService("GuiService")
local VRService = game:GetService("VRService")

local Thunks = script.Parent
local EmotesMenu = Thunks.Parent
local Actions = EmotesMenu.Actions

local CoreScriptModules = EmotesMenu.Parent

local EventStream = require(CorePackages.AppTempCommon.Temp.EventStream)

local Analytics = require(EmotesMenu.Analytics)
local Backpack = require(CoreScriptModules.BackpackScript)
local ShowMenu = require(Actions.ShowMenu)

local EmotesAnalytics = Analytics.new():withEventStream(EventStream.new())

local EngineFeatureEnableVRUpdate2 = game:GetEngineFeature("EnableVRUpdate2")

local function OpenMenu(emoteName)
    return function(store)
	if GuiService.MenuIsOpen then
		if EngineFeatureEnableVRUpdate2 and VRService.VREnabled then
			GuiService:SetMenuIsOpen(false, "VRMenu")
		else
			return
		end
        end

        if Backpack.IsOpen then
            Backpack.OpenClose()
        end

        -- If user is interacting with the backpack it can stay open
        if Backpack.IsOpen then
            return
        end

        EmotesAnalytics:onMenuOpened()

        -- Backpack was closed, show the emotes menu
        store:dispatch(ShowMenu())
    end
end

return OpenMenu