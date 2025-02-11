-- TODO STM-823: Delete file

local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local Constants = require(Plugin.Src.Util.Constants)

local ContextServices = require(Plugin.Packages.Framework).ContextServices
local withContext = ContextServices.withContext
local UI = require(Plugin.Packages.Framework).UI
local StudioUI = require(Plugin.Packages.Framework).StudioUI
local Dialog = StudioUI.Dialog
local FrameworkButton = UI.Button

local MovedDialog = Roact.PureComponent:extend("MovedDialog")

function MovedDialog:render()
	local props = self.props
	local localization = props.Localization
	local theme = self.props.Stylizer

	return Roact.createElement(Dialog, {
		Title = localization:getText("Moved", "Title"),
		Enabled = true,
		Modal = true,
		Size = Vector2.new(
			Constants.MOVED_DIALOG_WIDTH,
			Constants.MOVED_DIALOG_HEIGHT
		),
		Resizable = false,
		OnClose = props.OnClose,
	}, {
		Background = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = theme.BackgroundColor,
		}, {
			Label = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, Constants.MOVED_DIALOG_LABEL_HEIGHT),
				Position = UDim2.new(
					0, Constants.MOVED_DIALOG_SIDE_PADDING,
					0, Constants.MOVED_DIALOG_TOP_PADDING
				),
				AnchorPoint = Vector2.new(0, 0),
				Text = localization:getText("Moved", "MovedMessage"),
				TextSize = 22,
				TextColor3 = theme.TextColor,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.SourceSans,
				BackgroundTransparency = 1,
			}),

			Label2 = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, Constants.MOVED_DIALOG_LABEL_HEIGHT),
				Position = UDim2.new(
					0, Constants.MOVED_DIALOG_SIDE_PADDING,
					0, Constants.MOVED_DIALOG_TOP_PADDING +
						Constants.MOVED_DIALOG_LABEL_HEIGHT +
						Constants.MOVED_DIALOG_INTRA_PADDING
				),
				AnchorPoint = Vector2.new(0, 0),
				Text = localization:getText("Moved", "NewLocationMessage"),
				TextSize = 17,
				TextColor3 = theme.TextColor,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.SourceSansLight,
				BackgroundTransparency = 1,
			}),

			CloseButton = Roact.createElement(FrameworkButton, {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -Constants.MOVED_DIALOG_BOTTOM_PADDING),
				Size = UDim2.new(0, Constants.MOVED_DIALOG_BUTTON_WIDTH, 0, Constants.MOVED_DIALOG_BUTTON_HEIGHT),
				OnClick = props.OnClose,
				Style = "RoundPrimary",
			}, {
				Label = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					Text = localization:getText("Moved", "GotIt"),
					TextColor3 = theme.White,
					Font = Enum.Font.SourceSans,
					TextSize = 19,
					BackgroundTransparency = 1,
				}),
			}),
		}),
	})
end

MovedDialog = withContext({
	Localization = ContextServices.Localization,
	Stylizer = ContextServices.Stylizer,
})(MovedDialog)

return MovedDialog
