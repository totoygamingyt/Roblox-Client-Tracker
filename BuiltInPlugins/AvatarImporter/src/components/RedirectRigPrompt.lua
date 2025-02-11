--[[
	RedirectRigPrompt - Screen that is displayed when a rig can be redirected
]]

local root = script.Parent.Parent.Parent

-- imports
local Roact = require(root.Packages.Roact)
local RoactRodux = require(root.Packages.RoactRodux)

local Constants = require(root.src.Constants)
local CustomTextButton = require(root.src.components.CustomTextButton)

local ImportWithoutSceneLoad = require(root.src.thunks.ImportWithoutSceneLoad)

local Studio = settings().Studio

-- component
local RedirectRigPrompt = Roact.Component:extend("RedirectRigPrompt")

function RedirectRigPrompt:render()
	local function importAsR15()
		-- if the user is importing through Rthro or Rthro Narrow, set the rig type to those. Otherwise default to R15.
		if self.props.avatarType == Constants.AVATAR_TYPE.RTHRO_SLENDER then
			self.props.doImportWithoutSceneLoad(Constants.AVATAR_TYPE.RTHRO_SLENDER)
		elseif self.props.avatarType == Constants.AVATAR_TYPE.RTHRO then
			self.props.doImportWithoutSceneLoad(Constants.AVATAR_TYPE.RTHRO)
		else
			self.props.doImportWithoutSceneLoad(Constants.AVATAR_TYPE.R15)
		end
	end

	local function importAsCustom()
		self.props.doImportWithoutSceneLoad(Constants.AVATAR_TYPE.CUSTOM)
	end

	local avatarTypeText = self.props.avatarType == Constants.AVATAR_TYPE.RTHRO_SLENDER and "Rthro Narrow" or self.props.avatarType
	local headerText = (self.props.avatarType == Constants.AVATAR_TYPE.CUSTOM or self.props.avatarType == nil) and "You are trying to import a R15 rig as Custom:" or "You are trying to import a Custom rig as " .. avatarTypeText .. ":"

	local r15ButtonText = "Continue as R15"
	if self.props.avatarType ~= Constants.AVATAR_TYPE.CUSTOM then
		r15ButtonText = "Continue as " .. avatarTypeText
	end

	return Roact.createElement("Frame", {
		Name = "RedirectRigPrompt",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Studio.Theme:GetColor(
			Enum.StudioStyleGuideColor.MainBackground,
			Enum.StudioStyleGuideModifier.Default
		),
	}, {
		header = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Font = Constants.FONT_BOLD,
			Position = UDim2.new(0, 0, 0, 123),
			Size = UDim2.new(1, 0, 0, 18),
			Text = headerText,
			TextSize = Constants.FONT_SIZE_MEDIUM,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextColor3 = Studio.Theme:GetColor(
				Enum.StudioStyleGuideColor.MainText,
				Enum.StudioStyleGuideModifier.Default
			),
		}),
		buttons = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 1, -123),
			Size = UDim2.new(1, 0, 0, 34),
		}, {
			buttonsListLayout = Roact.createElement("UIListLayout", {
				Padding = UDim.new(0, 21),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			cancelButton = Roact.createElement(CustomTextButton, {
				Name = "R15Button",
				labelText = r15ButtonText,
				layoutOrder = 0,
				isLarge = true,
				[Roact.Event.MouseButton1Click] = importAsR15,
			}),
			retryButton = Roact.createElement(CustomTextButton, {
				Name = "CustomButton",
				labelText = "Continue as Custom",
				layoutOrder = 1,
				isLarge = true,
				[Roact.Event.MouseButton1Click] = importAsCustom,
			}),
		})
	})
end

local function mapStateToProps(state)
	state = state or {}

	return {
		avatarType = state.plugin.avatarType
	}
end

local function mapDispatchToProps(dispatch)
	return {
		doImportWithoutSceneLoad = function(avatarType)
			dispatch(ImportWithoutSceneLoad(avatarType))
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(RedirectRigPrompt)