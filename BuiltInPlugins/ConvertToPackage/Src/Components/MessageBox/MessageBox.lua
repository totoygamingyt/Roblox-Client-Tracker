local FFlagUpdateConvertToPackageToDFContextServices = game:GetFastFlag("UpdateConvertToPackageToDFContextServices")
local Plugin = script.Parent.Parent.Parent.Parent

local Packages = Plugin.Packages
local Roact = require(Packages.Roact)
local UILibrary = require(Packages.UILibrary)
local Framework = require(Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = if FFlagUpdateConvertToPackageToDFContextServices then ContextServices.withContext else require(Plugin.Src.ContextServices.withContext)

local SharedFlags = Framework.SharedFlags
local FFlagDevFrameworkMigrateDialog = SharedFlags.getFFlagDevFrameworkMigrateDialog() and FFlagUpdateConvertToPackageToDFContextServices
local FFlagRemoveUILibraryButton = SharedFlags.getFFlagRemoveUILibraryButton()

local GetTextSize = Framework.Util.GetTextSize

local Constants = require(Plugin.Src.Util.Constants)

local UI = Framework.UI
local Button = if FFlagRemoveUILibraryButton then UI.Button else UILibrary.Component.Button
local Dialog = if FFlagDevFrameworkMigrateDialog then UI.Dialog else UILibrary.Component.Dialog

local MessageBox = Roact.PureComponent:extend("MessageBox")

function MessageBox:init(props)
	-- If the owner of the message box calls setState() when the user clicks
	-- a button, it triggers this and the dialog to be destroyed. Because we
	-- listen for ancestry changed on the dialog to get when it's closing,
	-- and then pass that to the parent, it can lead to setState() being
	-- called during a render. Using this and checking for it before sending
	-- to parent prevents that.
	self.isDead = false

	self.onEnabledChanged = function(rbx)
		if self.isDead then
			return
		end
		if not rbx.Enabled and self.props.onClose then
			self.props.onClose()
		end
	end

	self.onAncestryChanged = function(rbx, child, parent)
		if self.isDead then
			return
		end
		if not parent and self.props.onClose then
			self.props.onClose()
		end
	end
end

function MessageBox:willUnmount()
	-- Mark this message box as dead so we don't send signals from the
	-- dialog to the parent
	self.isDead = true
end

function MessageBox:render()
	local style = self.props.Stylizer

	local function renderWithContext(localization, theme)
		local props = self.props

		local title = props.Title or ""
		-- TODO(@rbujnowicz): remove with FFlagDevFrameworkMigrateDialog
		local name = if FFlagDevFrameworkMigrateDialog then nil else (props.Name or title)
		local id = if FFlagDevFrameworkMigrateDialog then nil else (props.Id or nil)

		local text = props.Text or ""
		local informativeText = props.InformativeText or ""
		local icon = props.Icon or ""
		local mockTesting = props.mockTesting or ""

		local showInformativeText = #informativeText ~= 0
		local showIcon = icon ~= ""

		local textFont = Constants.FONT
		local textFontSize = Constants.FONT_SIZE_MEDIUM

		local informativeTextFont = Constants.FONT
		local informativeTextFontSize = Constants.FONT_SIZE_SMALL

		local messageBoxTheme = theme.messageBox

		local buttonTexts = props.buttons or {}
		if #buttonTexts == 0 then
			buttonTexts = {
				{
					Text = localization:getText("General", "OK"),
					action = "ok",
				}
			}
		end

		local buttonWidth = Constants.MESSAGE_BOX_BUTTON_WIDTH
		local buttonPadding = 15

		local buttons = { }
		buttons.UIListLayout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, buttonPadding),
		})

		for i, button in ipairs(buttonTexts) do
			buttons[i] = Roact.createElement(Button, if FFlagRemoveUILibraryButton then {
				OnClick = button.OnClick,
				Size = UDim2.new(0, buttonWidth, 1, 0),
				Text = button.Text,
			} else {
				OnClick = button.OnClick,
				Size = UDim2.new(0, buttonWidth, 1, 0),
				RenderContents = function(buttonTheme, hovered, selected)
					return {
						TextLabel = Roact.createElement("TextLabel", {
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 0, 0, -1),
							Size = UDim2.new(1, 0, 1, 0),
							Text = button.Text,
							Font = Constants.FONT,
							TextColor3 = messageBoxTheme.textColor,
							TextSize = Constants.FONT_SIZE_MEDIUM,
							TextXAlignment = Enum.TextXAlignment.Center})
					}
				end
			})
		end

		local minWidth = 120
		-- Wrap the 2 texts at different sizes
		local wrapTextWidth = 424
		local wrapInformativeTextWidth = 192

		local textOneLineSize = GetTextSize(text, textFontSize, textFont, Vector2.new(0, 0))
		local informativeOneLineTextSize = GetTextSize(informativeText, informativeTextFontSize, informativeTextFont, Vector2.new(0, 0))

		-- Wrap both texts, get the bigger of the 2
		local textWidth = math.max(math.min(textOneLineSize.X, wrapTextWidth),
			math.min(informativeOneLineTextSize.X, wrapInformativeTextWidth))

		-- Need to still have the icon instance for list layout padding to work
		-- But set the width to 0 so it's not visible
		local iconSize = showIcon and 32 or 0
		local iconToTextPadding = showIcon and 20 or 0
		local fullIconWidth = iconSize + iconToTextPadding
		local topWidth = fullIconWidth + textWidth

		-- Buttons + padding between
		local buttonsWidth = (#buttonTexts * buttonWidth)
			+ ((#buttonTexts - 1) * buttonPadding)

		-- Bigger of the buttons and text+icon, but also no less than min
		local innerMaxWidth = math.max(math.max(buttonsWidth, topWidth), minWidth)

		local maxTextWidth = innerMaxWidth - fullIconWidth

		local textSize = GetTextSize(text, textFontSize, textFont, Vector2.new(maxTextWidth, 1000))
		local informativeTextSize = GetTextSize(informativeText, informativeTextFontSize, informativeTextFont, Vector2.new(maxTextWidth, 1000))

		local textHeight = textSize.Y
		local textToInformativeTextPadding = 8
		local informativeTextHeight = informativeTextSize.Y

		local topHeight = math.max(iconSize,
			textHeight + (showInformativeText and textToInformativeTextPadding + informativeTextHeight or 0))

		local topPadding = 20
		local outerPadding = 12

		local textToButtonsPadding = 20
		local buttonsHeight = 30

		local boxWidth = outerPadding + innerMaxWidth + outerPadding
		local boxHeight = topPadding + topHeight + textToButtonsPadding + buttonsHeight + outerPadding
		-- added to avoid trying to test an untestable dialog
		if mockTesting ~= "" then
			return nil
		end
		return Roact.createElement(Dialog, if FFlagDevFrameworkMigrateDialog then {
			Title = title,
			Modal = true,
			Resizable = false,
			Size = Vector2.new(boxWidth, boxHeight),
			MinSize = Vector2.new(boxWidth, boxHeight),
			Enabled = true,
			OnClose = props.onClose,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			[Roact.Change.Enabled] = self.onEnabledChanged,
			[Roact.Event.AncestryChanged] = self.onAncestryChanged,
		} else {
			Name = name,
			Title = title,
			Id = id,
			Options = {
				Size = Vector2.new(boxWidth, boxHeight),
				MinSize = Vector2.new(boxWidth, boxHeight),
				Resizable = false,
				Modal = true,
				InitialEnabled = true,
			},
			Size = Vector2.new(boxWidth, boxHeight),
			Enabled = true,
			OnClose = props.onClose,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			[Roact.Change.Enabled] = self.onEnabledChanged,
			[Roact.Event.AncestryChanged] = self.onAncestryChanged,
		}, {
			Background = Roact.createElement("Frame", {
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),

				BackgroundColor3 = messageBoxTheme.backgroundColor,
			}, {
				UIPadding = Roact.createElement("UIPadding", {
					PaddingBottom = UDim.new(0, outerPadding),
					PaddingLeft = UDim.new(0, outerPadding),
					PaddingRight = UDim.new(0, outerPadding),
					PaddingTop = UDim.new(0, topPadding),
				}),

				UIListLayout = Roact.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Top,
					Padding = UDim.new(0, textToButtonsPadding),
				}),

				Information = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, topHeight),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
				}, {
					UIListLayout = Roact.createElement("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
						Padding = UDim.new(0, iconToTextPadding),
						FillDirection = Enum.FillDirection.Horizontal,
					}),

					Icon = Roact.createElement("ImageLabel", {
						Size = UDim2.new(0, iconSize, 0, iconSize),
						BackgroundTransparency = 1,
						LayoutOrder = 0,
						Image = icon,
					}),

					Texts = Roact.createElement("Frame", {
						LayoutOrder = 1,
						Size = UDim2.new(1, -fullIconWidth, 1, 0),
						BackgroundTransparency = 1,
					}, {
						UIListLayout = Roact.createElement("UIListLayout", {
							SortOrder = Enum.SortOrder.LayoutOrder,
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							VerticalAlignment = Enum.VerticalAlignment.Top,
							Padding = UDim.new(0, textToInformativeTextPadding),
							FillDirection = Enum.FillDirection.Vertical,
						}),

						TextLabel = Roact.createElement("TextLabel", {
							LayoutOrder = 0,
							Size = UDim2.new(1, 0, 0, textHeight),

							BackgroundTransparency = 1,
							Text = text,
							Font = textFont,
							TextSize = textFontSize,
							TextColor3 = messageBoxTheme.textColor,
							TextXAlignment = Enum.TextXAlignment.Center,
							TextYAlignment = Enum.TextYAlignment.Top,
							TextWrapped = true,
						}),

						InformativeLabel = showInformativeText and Roact.createElement("TextLabel", {
							LayoutOrder = 1,
							Size = UDim2.new(1, 0, 0, informativeTextHeight),

							BackgroundTransparency = 1,
							Text = informativeText,
							Font = informativeTextFont,
							TextSize = informativeTextFontSize,
							TextColor3 = messageBoxTheme.informativeTextColor,
							TextXAlignment = Enum.TextXAlignment.Center,
							TextYAlignment = Enum.TextYAlignment.Top,
							TextWrapped = true,
						})
					}),
				}),

				Buttons = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, buttonsHeight),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
				}, buttons)
			})
		})
	end

	return if FFlagUpdateConvertToPackageToDFContextServices then renderWithContext(self.props.Localization, style) else withContext(renderWithContext)
end

if FFlagUpdateConvertToPackageToDFContextServices then
	MessageBox = withContext({
		Localization = ContextServices.Localization,
		Stylizer = ContextServices.Stylizer,
	})(MessageBox)
end

return MessageBox
