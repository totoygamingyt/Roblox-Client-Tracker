--[[
	Represents the label for the current Animation Clip being edited,
	and spawns the menu used to load and save animations.

	This component is also responsible for the prompts related to saving
	and creating a new animation when an animation is already loaded.

	Properties:
		string AnimationName = name of the current clip being edited
		int LayoutOrder = display order of this frame, if in a layout
]]

local NEW_KEY = newproxy(true)
local IMPORT_KEY = newproxy(true)
local IMPORT_FBX_KEY = newproxy(true)

local Plugin = script.Parent.Parent.Parent.Parent
local Framework = require(Plugin.Packages.Framework)

local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Constants = require(Plugin.Src.Util.Constants)
local AnimationData = require(Plugin.Src.Util.AnimationData)
local PADDING = UDim.new(0, Constants.INDENT_PADDING)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local AnimationClipMenu = require(Plugin.Src.Components.AnimationClipMenu)
local ContextButton = require(Plugin.Src.Components.ContextButton)
local FocusedPrompt = require(Plugin.Src.Components.EditEventsDialog.FocusedPrompt)
local TextEntryPrompt = require(Plugin.Src.Components.TextEntryPrompt)
local ActionToast = require(Plugin.Src.Components.Toast.ActionToast)
local LoadAnimation = require(Plugin.Src.Thunks.Exporting.LoadAnimation)
local SaveAnimation = require(Plugin.Src.Thunks.Exporting.SaveAnimation)
local ImportKeyframeSequence = require(Plugin.Src.Thunks.Exporting.ImportKeyframeSequence)
local ImportFBXAnimationUserMayChooseModel = require(Plugin.Src.Thunks.Exporting.ImportFBXAnimationUserMayChooseModel)
local CreateFromVideoAndImportFBXAnimationUserMayChooseModel = require(Plugin.Src.Thunks.Exporting.CreateFromVideoAndImportFBXAnimationUserMayChooseModel)
local ImportLoadedFBXAnimation = require(Plugin.Src.Thunks.Exporting.ImportLoadedFBXAnimation)
local LoadAnimationData = require(Plugin.Src.Thunks.LoadAnimationData)
local SetIsDirty = require(Plugin.Src.Actions.SetIsDirty)
local Pause = require(Plugin.Src.Actions.Pause)

local GetFFlagExtendPluginTheme = require(Plugin.LuaFlags.GetFFlagExtendPluginTheme)
local GetFFlagCreateAnimationFromVideoAgeGateSizeFix = require(Plugin.LuaFlags.GetFFlagCreateAnimationFromVideoAgeGateSizeFix)

local AnimationClipDropdown = Roact.PureComponent:extend("AnimationClipDropdown")

function AnimationClipDropdown:init()
	self.state = {
		showMenu = false,
		showSaveAsPrompt = false,
		showCreateNewPrompt = false,
		showImportAnimModelChoicePrompt = false,
		showPromotePrompt = false,
		overwriteName = nil,
		loadingName = nil,
		showCreateAnimationFromVideoTutorial = false,
	}

	self.showMenu = function()
		self.props.Pause()
		self:setState({
			showMenu = true,
		})
	end

	self.hideMenu = function()
		self:setState({
			showMenu = false,
		})
	end

	self.showOverwritePrompt = function(name)
		self:setState({
			overwriteName = name,
		})
	end

	self.hideOverwritePrompt = function()
		self:setState({
			overwriteName = Roact.None,
		})
	end

	self.showSaveAsPrompt = function()
		self:setState({
			showSaveAsPrompt = true,
		})
	end

	self.hideSaveAsPrompt = function()
		self:setState({
			showSaveAsPrompt = false,
		})
	end

	self.showImportAnimModelChoicePrompt = function()
		self:setState({
			showImportAnimModelChoicePrompt = true,
		})
	end

	self.hideImportAnimModelChoicePrompt = function()
		self:setState({
			showImportAnimModelChoicePrompt = false,
		})
	end

	self.showAnimationImportProgress = function()
		self.props.ShowAnimationImportProgress()
	end

	self.hideAnimationImportProgress = function()
		self.props.HideAnimationImportProgress()
	end

	self.showCreateNewPrompt = function()
		self:setState({
			showCreateNewPrompt = true,
		})
	end

	self.hideCreateNewPrompt = function()
		self:setState({
			showCreateNewPrompt = false,
		})
	end

	self.showPromotePrompt = function()
		self:setState({
			showPromotePrompt = true,
		})
	end

	self.hidePromotePrompt = function()
		self:setState({
			showPromotePrompt = false,
		})
	end

	self.showLoadNewPrompt = function(name)
		self:setState({
			loadingName = name,
		})
	end

	self.hideLoadNewPrompt = function()
		self:setState({
			loadingName = Roact.None,
		})
	end

	self.setShowCreateAnimationFromVideoTutorial = function(showTutorial)
		self:setState({
			showCreateAnimationFromVideoTutorial = showTutorial,
		})
	end

	self.continueAfterCreateAnimationFromVideoTutorial = function()
		local props = self.props
		props.CreateFromVideoAndImportFBXAnimationUserMayChooseModel(props.plugin, self, props.Analytics)
	end

	self.importRequested = function()
		if self.props.IsDirty then
			self.showLoadNewPrompt(IMPORT_KEY)
		else
			local plugin = self.props.Plugin
			self.props.ImportKeyframeSequence(plugin, self.props.Analytics)
		end
	end

	self.importFbxRequested = function()
		if self.props.IsDirty then
			self.showLoadNewPrompt(IMPORT_FBX_KEY)
		else
			local plugin = self.props.Plugin
			self.props.ImportFBXAnimationUserMayChooseModel(plugin, self, self.props.Analytics)
		end
	end

	self.createFromVideoRequested = function()
		self.props.Analytics:report("onAnimationEditorImportVideoCreate")
        self.setShowCreateAnimationFromVideoTutorial(true)
	end

	self.createNew = function()
		if self.props.IsDirty then
			self.showLoadNewPrompt(NEW_KEY)
		else
			self.showCreateNewPrompt()
		end
	end

	self.loadNew = function(name)
		if self.props.IsDirty then
			self.showLoadNewPrompt(name)
		else
			self.props.LoadAnimation(name, self.props.Analytics)
		end
	end

	self.handleLoadNewPrompt = function()
		local props = self.props
		local state = self.state
		local loadingName = state.loadingName
		local plugin = self.props.Plugin

		if loadingName == NEW_KEY then
			self.hideLoadNewPrompt()
			self.showCreateNewPrompt()
		elseif loadingName == IMPORT_KEY then
			self.hideLoadNewPrompt()
			props.ImportKeyframeSequence(plugin, props.Analytics)
		elseif loadingName == IMPORT_FBX_KEY then
			self.hideLoadNewPrompt()
			props.ImportFBXAnimationUserMayChooseModel(plugin, self, props.Analytics)
		else
			props.LoadAnimation(loadingName, props.Analytics)
			self.hideLoadNewPrompt()
		end
	end
end


function AnimationClipDropdown:render()
	local localization = self.props.Localization
	local props = self.props
	local state = self.state
	local theme = GetFFlagExtendPluginTheme() and props.Stylizer or props.Stylizer.PluginTheme

	local animationName = props.AnimationName
	local layoutOrder = props.LayoutOrder
	local isChannelAnimation = props.IsChannelAnimation

	local dropdownTheme = theme.dropdownTheme

	local showMenu = state.showMenu
	local showSaveAsPrompt = state.showSaveAsPrompt
	local showCreateNewPrompt = state.showCreateNewPrompt
	local showImportAnimModelChoicePrompt = state.showImportAnimModelChoicePrompt
	local overwriteName = state.overwriteName
	local loadingName = state.loadingName
	local showPromotePrompt = state.showPromotePrompt
	local style = theme.button

	local showCreateAnimationFromVideoTutorial = state.showCreateAnimationFromVideoTutorial

	local isCreateAnimationFromVideoAgeRestricted = false
	if showCreateAnimationFromVideoTutorial then
		-- Before showing the create animation from video tutorial, check the age
		-- restriction and display that instead if required.
		isCreateAnimationFromVideoAgeRestricted = game:GetService("AnimationFromVideoCreatorStudioService"):IsAgeRestricted()
		if isCreateAnimationFromVideoAgeRestricted then
			showCreateAnimationFromVideoTutorial = false
		end
	end

	return Roact.createElement("ImageButton", {
		Size = UDim2.new(1, -Constants.CONTROLS_WIDTH - Constants.TIME_DISPLAY_WIDTH, 1, 0),
		BackgroundTransparency = 1,
		ImageTransparency = 1,
		AutoButtonColor = false,
		LayoutOrder = layoutOrder,

		[Roact.Event.Activated] = self.showMenu,
	}, {
		Padding = Roact.createElement("UIPadding", {
			PaddingLeft = PADDING,
			PaddingRight = PADDING,
		}),

		AnimationClipLabel = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, -Constants.TRACKLIST_BUTTON_SIZE - Constants.INDENT_PADDING, 1, 0),
			BackgroundTransparency = 1,

			Text = animationName,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextSize = dropdownTheme.textSize,
			Font = theme.font,
			TextColor3 = dropdownTheme.textColor,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),

		ContextButton = Roact.createElement(ContextButton, {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			OnActivated = self.showMenu,
		}),

		AnimationClipMenu = Roact.createElement(AnimationClipMenu, {
			ShowMenu = showMenu,
			CurrentAnimation = animationName,
			IsChannelAnimation = isChannelAnimation,
			OnMenuOpened = self.hideMenu,
			OnOverwriteRequested = self.showOverwritePrompt,
			OnSaveAsRequested = self.showSaveAsPrompt,
			OnCreateNewRequested = self.createNew,
			OnLoadRequested = self.loadNew,
			OnImportRequested = self.importRequested,
			OnImportFbxRequested = self.importFbxRequested,
			OnCreateFromVideoRequested = self.createFromVideoRequested,
			OnPromoteRequested = self.showPromotePrompt,
		}),

		CreateNewPrompt = showCreateNewPrompt and Roact.createElement(TextEntryPrompt, {
			PromptText = localization:getText("Title", "CreateNew"),
			InputText = localization:getText("Dialog", "AnimationName"),
			Text = localization:getText("Title", "DefaultAnimationName"),
			Buttons = {
				{Key = false, Text = localization:getText("Dialog", "Cancel"), Style = "Round"},
				{Key = true, Text = localization:getText("Dialog", "Create"), Style = "RoundPrimary"},
			},
			OnTextSubmitted = function(text)
				self.hideCreateNewPrompt()
				local newData = AnimationData.newRigAnimation(text)
				props.LoadAnimationData(newData, self.props.Analytics)
				props.SetIsDirty(false)
				props.Analytics:report("onCreateNewAnimation", text)
			end,
			OnClose = self.hideCreateNewPrompt,
		}),

		SaveAsPrompt = showSaveAsPrompt and Roact.createElement(TextEntryPrompt, {
			PromptText = localization:getText("Title", "SaveAsNew"),
			InputText = localization:getText("Dialog", "AnimationName"),
			NoticeText = localization:getText("Dialog", "SaveLocation"),
			Text = animationName,
			Buttons = {
				{Key = false, Text = localization:getText("Dialog", "Cancel"), Style = "Round"},
				{Key = true, Text = localization:getText("Dialog", "Save"), Style = "RoundPrimary"},
			},
			OnTextSubmitted = function(text)
				self.hideSaveAsPrompt()
				props.SaveAnimation(text, props.Analytics)
			end,
			OnClose = self.hideSaveAsPrompt,
		}),

		ImportAnimModelChoicePrompt = showImportAnimModelChoicePrompt and Roact.createElement(ActionToast, {
			Text = localization:getText("Toast", "AnimationImportModelsDiffer"),
			ButtonWidth = Constants.PROMPT_BUTTON_SIZE.X * 1.5,
			Buttons = {
				{Key = true, Text = localization:getText("Toast", "AnimationImportUseFBX"), Style = "Round"},
				{Key = false, Text = localization:getText("Toast", "AnimationImportUseSelected"), Style = "Round"},
			},
			OnButtonClicked = function(useFBXModel)
				self.hideImportAnimModelChoicePrompt()
				self.props.ImportLoadedFBXAnimation(plugin, useFBXModel, self.props.Analytics)
			end,
		}),

		OverwritePrompt = overwriteName and Roact.createElement(FocusedPrompt, {
			PromptText = localization:getText("Menu", "Overwrite_Migrated", {overwriteName = overwriteName}),
			Buttons = {
				{Key = false, Text = localization:getText("Dialog", "No"), Style = "Round"},
				{Key = true, Text = localization:getText("Dialog", "Yes"), Style = "RoundPrimary"},
			},
			OnButtonClicked = function(didSave)
				self.hideOverwritePrompt()
				if didSave then
					props.SaveAnimation(overwriteName, props.Analytics)
				end
			end,
			OnClose = self.hideOverwritePrompt,
		}),

		PromotePrompt = showPromotePrompt and Roact.createElement(FocusedPrompt, {
			PromptText = localization:getText("Dialog", "PromotePrompt"),
			Buttons = {
				{Key = false, Text = localization:getText("Dialog", "Cancel"), Style = "Round"},
				{Key = true, Text = localization:getText("Dialog", "Confirm"), Style = "RoundPrimary"},
			},
			OnButtonClicked = function(didPromote)
				self.hidePromotePrompt()
				if didPromote then
					props.PromoteKeyframeSequence(props.Analytics)
				end
			end,
			OnClose = self.hidePromotePrompt
		}) or nil,

		LoadNewPrompt = loadingName and Roact.createElement(TextEntryPrompt, {
			PromptText = localization:getText("Title", "ConfirmSave"),
			InputText = localization:getText("Dialog", "AnimationName"),
			NoticeText = localization:getText("Dialog", "SaveLocation"),
			Text = animationName,
			Buttons = {
				{Key = "Delete", Text = localization:getText("Dialog", "Delete"), Style = "Round"},
				{Key = false, Text = localization:getText("Dialog", "Cancel"), Style = "Round"},
				{Key = true, Text = localization:getText("Dialog", "Save"), Style = "RoundPrimary"},
			},
			OnButtonClicked = function(text)
				if text == "Delete" then
					self.handleLoadNewPrompt()
				end
			end,
			OnTextSubmitted = function(text)
				props.SaveAnimation(text, props.Analytics)
				self.handleLoadNewPrompt()
			end,
			OnClose = self.hideLoadNewPrompt,
		}),

		CreateAnimationFromVideoTutorial = showCreateAnimationFromVideoTutorial and Roact.createElement(FocusedPrompt, {
			PromptText = localization:getText("AnimationFromVideo", "TutorialText"),
			Buttons = {
				{Key = false, Text = localization:getText("Dialog", "Cancel"), Style = "Round"},
				{Key = true, Text = localization:getText("AnimationFromVideo", "ChooseVideo"), Style = "RoundPrimary"},
			},
			OnButtonClicked = function(shouldContinue)
				self.setShowCreateAnimationFromVideoTutorial(false)
				if shouldContinue then
					self.continueAfterCreateAnimationFromVideoTutorial()
				end
			end,
			OnClose = function()
				self.setShowCreateAnimationFromVideoTutorial(false)
			end
		}),

		CreateAnimationFromVideoAgeGate = isCreateAnimationFromVideoAgeRestricted and Roact.createElement(FocusedPrompt, {
			Size = GetFFlagCreateAnimationFromVideoAgeGateSizeFix() and UDim2.new(0, Constants.PROMPT_SIZE.Width.Offset, 0, 180) or nil,
			PromptText = localization:getText("AnimationFromVideo", "AgeRestricted"),
			Buttons = {
				{Key = false, Text = localization:getText("Dialog", "Cancel"), Style = "Round"},
			},
			OnButtonClicked = function()
				self.setShowCreateAnimationFromVideoTutorial(false)
			end,
			OnClose = function()
				self.setShowCreateAnimationFromVideoTutorial(false)
			end
		}),
	})
end

AnimationClipDropdown = withContext({
	Stylizer = ContextServices.Stylizer,
	Localization = ContextServices.Localization,
	Plugin = ContextServices.Plugin,
	Analytics = ContextServices.Analytics,
})(AnimationClipDropdown)

local function mapStateToProps(state, props)
	return {
		IsDirty = state.Status.IsDirty,
		Analytics = state.Analytics,
	}
end

local function mapDispatchToProps(dispatch)
	return {
		LoadAnimationData = function(name, analytics)
			dispatch(LoadAnimationData(name, analytics))
		end,

		LoadAnimation = function(name, analytics)
			dispatch(LoadAnimation(name, analytics))
		end,

		SaveAnimation = function(name, analytics)
			dispatch(SaveAnimation(name, analytics))
		end,

		Pause = function()
			dispatch(Pause())
		end,

		ImportKeyframeSequence = function(plugin, analytics)
			dispatch(ImportKeyframeSequence(plugin, analytics))
		end,

		ImportFBXAnimationUserMayChooseModel = function(plugin, animationClipDropdown, analytics)
			dispatch(ImportFBXAnimationUserMayChooseModel(plugin, animationClipDropdown, analytics))
		end,

		CreateFromVideoAndImportFBXAnimationUserMayChooseModel = function(plugin, animationClipDropdown, analytics)
			dispatch(CreateFromVideoAndImportFBXAnimationUserMayChooseModel(plugin, animationClipDropdown, analytics))
		end,

		ImportLoadedFBXAnimation = function(plugin, useFBXModel, analytics)
			dispatch(ImportLoadedFBXAnimation(plugin, useFBXModel, analytics))
		end,

		SetIsDirty = function(isDirty)
			dispatch(SetIsDirty(isDirty))
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(AnimationClipDropdown)
