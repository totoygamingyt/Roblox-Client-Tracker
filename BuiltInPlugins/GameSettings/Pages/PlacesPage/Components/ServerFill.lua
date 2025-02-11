--[[
    ServerFill is a wrapper around RadioButtonSet to display server fill options
    Optimized, Maximum, Custom (input field for custom as a sibling if selected)

    Necessary props:
        Enabled = boolean, whether or not this component is enabled.
        Selected = string, corresponds to ID of button to be selected
        LayoutOrder = number, order in which this component should appear under its parent.

        CustomSocialSlotsCount = number, number of custom social slots
        ErrorState = string, used to change border of input on error
        OnSocialSlotTypeChanged = function(button) callback for when radio button is selected
        OnCustomSocialSlotsCountChanged = function(text) callback for when text inside custom social slot input is changed
]]
local Plugin = script.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local Cryo = require(Plugin.Packages.Cryo)

local Framework = require(Plugin.Packages.Framework)
local FFlagRemoveUILibraryRoundTextBox = Framework.SharedFlags.getFFlagRemoveUILibraryRoundTextBox()

local FitFrameOnAxis = Framework.Util.FitFrame.FitFrameOnAxis

local UI = Framework.UI
local TextInput2 = UI.TextInput2

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local RoundTextBox
if not FFlagRemoveUILibraryRoundTextBox then
    local UILibrary = require(Plugin.Packages.UILibrary)
	RoundTextBox = UILibrary.Component.RoundTextBox
end

local RadioButtonSet = require(Plugin.Src.Components.RadioButtonSet)
local RadioButton = require(Plugin.Src.Components.RadioButton)

local ServerFill = Roact.PureComponent:extend("ServerFill")

function ServerFill:render()
    local props = self.props
    local localization = props.Localization
    local theme = props.Stylizer

    local title = localization:getText("Places", "ServerFill")
    local layoutOrder = props.LayoutOrder

    local enabled = props.Enabled
    local selected = props.Selected

    local customSocialSlotsCount = props.CustomSocialSlotsCount
    local errorMessage = props.ErrorMessage
    local onSocialSlotTypeChanged = props.OnSocialSlotTypeChanged
    local onCustomSocialSlotsCountChanged = props.OnCustomSocialSlotsCountChanged

    local hasInputField = selected == "Custom"

    local buttons = {
        {
            Id = "Automatic",
            Title = localization:getText("Places", "OptimizedTitle"),
            Description = localization:getText("Places", "OptimizedDescription"),
        },
        {
            Id = "Empty",
            Title = localization:getText("Places", "MaximumTitle"),
            Description = localization:getText("Places", "MaximumWarning"),
        },
        {
            Id = "Custom",
            Title = localization:getText("Places", "CustomizeSlotsTitle"),
            Description = localization:getText("Places", "CustomizeSlotsDescription"),
            Children = {
                ErrorMessage = errorMessage and Roact.createElement("TextLabel", Cryo.Dictionary.join(theme.fontStyle.SmallError, {
                    Size = UDim2.new(1, 0, 0, theme.fontStyle.SmallError.Size),

                    BackgroundTransparency = 1,

                    Text = errorMessage,

                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextXAlignment = Enum.TextXAlignment.Left,

                    TextWrapped = true,
                })),
            }
        },
    }

    return Roact.createElement(FitFrameOnAxis, {
        axis = FitFrameOnAxis.Axis.Vertical,
        minimumSize = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,

        LayoutOrder = layoutOrder,
    }, {
        ServerFillToggle = Roact.createElement(RadioButtonSet, {
            Title = title,

            Buttons = buttons,

            Enabled = enabled,
            Selected = selected,

            RenderItem = function(index, button)
                if button.Id == "Custom" then
                    return Roact.createElement(FitFrameOnAxis, {
                        axis = FitFrameOnAxis.Axis.Vertical,
                        minimumSize = UDim2.new(1, 0, 0, 0),
                        contentPadding = UDim.new(0, theme.radioButton.padding),
                        BackgroundTransparency = 1,
                        FillDirection = Enum.FillDirection.Horizontal,

                        LayoutOrder = index,
                    }, {
                        RadioButton = Roact.createElement(RadioButton, {
                            LayoutOrder = 1,
                            Title = button.Title,
                            Id = button.Id,
                            Description = button.Description,
                            Selected = (button.Id == selected) or (index == selected),
                            Index = index,
                            Enabled = props.Enabled,
                            Children = button.Children,
                            OnClicked = function()
                                onSocialSlotTypeChanged(button)
                            end,
                        }),

                        InputField = hasInputField and (if FFlagRemoveUILibraryRoundTextBox then
                            Roact.createElement(TextInput2, {
                                ErrorText = errorMessage,
                                LayoutOrder = 2,
                                OnTextChanged = onCustomSocialSlotsCountChanged,
                                Width = theme.placePage.textBox.length,
                                Text = customSocialSlotsCount,
                            })
                        else
                            Roact.createElement(RoundTextBox, {
                                LayoutOrder = 2,
                                Active = hasInputField,
                                ShowToolTip = false,
                                Size = UDim2.new(0, theme.placePage.textBox.length, 0, theme.textBox.height),
                                Text = customSocialSlotsCount,
                                ErrorMessage = errorMessage,
                                TextSize = theme.fontStyle.Normal.TextSize,

                                SetText = onCustomSocialSlotsCountChanged,
                            })
                        ),
                    })
                else
                    return Roact.createElement(RadioButton, {
                        Title = button.Title,
                        Id = button.Id,
                        Description = button.Description,
                        Selected = (button.Id == selected) or (index == selected),
                        Index = index,
                        Enabled = props.Enabled,
                        LayoutOrder = index,
                        OnClicked = function()
                            onSocialSlotTypeChanged(button)
                        end,
                    })
                end
            end,
        })
    })
end

ServerFill = withContext({
    Localization = ContextServices.Localization,
    Stylizer = ContextServices.Stylizer,
})(ServerFill)

return ServerFill
