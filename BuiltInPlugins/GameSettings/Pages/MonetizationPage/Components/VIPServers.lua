--[[
    VIPServers is a wrapper around RadioButtonSet to display a Price config (field for price,
    label for fee, label for actual amount earned), and Subscriptions Count and Total VIP Servers Count
    between the "On" and "Off" buttons.

    Necessary props:
        Price = number, the initial price to be shown in the text field.
        TaxRate = number, the percentage of the price that is taken as a fee.
        MinimumFee = number, is the minimum fee that will be levied.
        Enabled = boolean, whether or not this component is enabled.
        Selected = boolean, "true" if On button should be selected, "false" if the off button should be selected.
        LayoutOrder = number, order in which this component should appear under its parent.
        VIPServersData = table, a table of relevant VIP Servers info to populate the component.
            example of VIPServersData:
            {
                isEnabled = true,
                price = 1000000000000000,
                activeServersCount = 1000,
                activeSubscriptionsCount = 1000,
            }

        OnVipServersToggled = function(button), this is a callback thta is invoked with the button info, when the radio button is toggled.
            example of button info:
            {
                Id = true,
                Title = "This is a foo button.",
                Description = "Lorem ipsum",
            }
        OnVipServersPriceChanged = function(price), this is a callback to be invoked when the price field changes values

    Optional props:
        PriceError = string, error message to be shown for this component
]]
local Page = script.Parent.Parent
local Plugin = script.Parent.Parent.Parent.Parent

local Cryo = require(Plugin.Packages.Cryo)
local Roact = require(Plugin.Packages.Roact)
local Framework = require(Plugin.Packages.Framework)

local SharedFlags = Framework.SharedFlags
local FFlagRemoveUILibraryTitledFrame = SharedFlags.getFFlagRemoveUILibraryTitledFrame()
local FFlagDevFrameworkMigrateToggleButton = SharedFlags.getFFlagDevFrameworkMigrateToggleButton()

local Util = Framework.Util
local FitFrameOnAxis = Util.FitFrame.FitFrameOnAxis
local GetTextSize = Util.GetTextSize
local LayoutOrderIterator = Util.LayoutOrderIterator

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local RadioButtonSet = require(Plugin.Src.Components.RadioButtonSet)
local RobuxFeeBase = require(Page.Components.RobuxFeeBase)

local UILibrary
if not FFlagDevFrameworkMigrateToggleButton or not FFlagRemoveUILibraryTitledFrame then
    UILibrary = require(Plugin.Packages.UILibrary)
end

local UI = Framework.UI
local TitledFrame = if FFlagRemoveUILibraryTitledFrame then UI.TitledFrame else UILibrary.Component.TitledFrame
local ToggleButton = if FFlagDevFrameworkMigrateToggleButton then UI.ToggleButton else UILibrary.Component.ToggleButton

local shouldDisablePrivateServersAndPaidAccess = require(Plugin.Src.Util.GameSettingsUtilities).shouldDisablePrivateServersAndPaidAccess

local VIPServers = Roact.PureComponent:extend("VIPServers")

function VIPServers:init()
    self.lastNonFreePrice = 10
end

function VIPServers:render()
    -- Remove this block once economy team enables the double wallets workflow (see STUDIOCORE-24488 & STUDIOCORE-24576)
    if shouldDisablePrivateServersAndPaidAccess() then
        return nil
    end

    local props = self.props
    local localization = props.Localization
    local theme = props.Stylizer
    local mouse = props.Mouse

    local layoutIndex = LayoutOrderIterator.new()

    local title = localization:getText("Monetization", "PrivateServersTitle")
    local priceTitle = localization:getText("Monetization", "PriceTitle")

    local layoutOrder = props.LayoutOrder
    local vipServersData = props.VIPServersData and props.VIPServersData or {}

    local enabled = props.Enabled

    local taxRate = props.TaxRate
    local minimumFee = props.MinimumFee

    local selected = vipServersData.isEnabled
    local price =  vipServersData.price and vipServersData.price or 0
    local serversCount = vipServersData.activeServersCount and vipServersData.activeServersCount or 0
    local subsCount = vipServersData.activeSubscriptionsCount and vipServersData.activeSubscriptionsCount or 0
    local hasPriceChanged = vipServersData.changed
    local willShutdown = vipServersData.willShutdown
    local isFree = price == 0

    if not isFree then
        self.lastNonFreePrice = price
    end

    local onVipServersToggled = props.OnVipServersToggled
    local onVipServersPriceChanged = props.OnVipServersPriceChanged

    local subscriptionsText
    local totalVIPServersText
    -- We're checking if subscription count is less than 0 here because the BE returns a negative value to indicate that the text about "over X" should be used.
    if subsCount < 0 then
        subscriptionsText = localization:getText("Monetization", "OverPrivateServerSubscriptions", { numOfSubscriptions = subsCount * -1 })
    else
        subscriptionsText = localization:getText("Monetization", "PrivateServerSubscriptions", { numOfSubscriptions = subsCount })
    end
    totalVIPServersText = localization:getText("Monetization", "PrivateServersActive", { totalVipServers = serversCount })

    local transparency = enabled and theme.robuxFeeBase.transparency.enabled or theme.robuxFeeBase.transparency.disabled

    local subText
    local toggleSubText
    local priceError = props.PriceError
    local showPriceChangeWarning

    if enabled and priceError then
        subText = priceError
    elseif hasPriceChanged then
        subText = localization:getText("Monetization", "PrivateServersPriceChangeWarning")
        showPriceChangeWarning = true
    end

    toggleSubText = localization:getText("Monetization", "PrivateServersHint")
    if willShutdown then
        toggleSubText = localization:getText("Monetization", "PrivateServersShutdownWarning")
    end

    local toggleSubTextSize = GetTextSize(toggleSubText, theme.fontStyle.Subtext.TextSize, theme.fontStyle.Subtext.Font,
        Vector2.new(theme.robuxFeeBase.subText.width, math.huge))

    local maxToggleHeight = theme.toggleButton.height + (not selected and toggleSubTextSize.Y or (2 * theme.rowHeight))
    local maxPriceConfigHeight = subText and theme.robuxFeeBase.height.withSubText or theme.robuxFeeBase.height.withoutSubText

    local showToggleSubText = not selected or (not selected and hasPriceChanged)
    local toggleSubTextTheme = (not selected and (hasPriceChanged or willShutdown)) and theme.fontStyle.SmallError or theme.fontStyle.Subtext

    local buttons = {
        {
            Id = true,
            Title = localization:getText("Monetization", "Free"),
        },
        {
            Id = false,
            Title = localization:getText("Monetization", "Paid"),
            Children = {
                RobuxFeeBase = Roact.createElement(RobuxFeeBase, {
                    Price = price,
                    TaxRate = taxRate,
                    MinimumFee = minimumFee,
                    SubText = subText,

                    Enabled = not isFree,

                    OnPriceChanged = onVipServersPriceChanged,
                    HasPriceChanged = hasPriceChanged,

                    LayoutOrder = layoutIndex:getNextOrder(),
                    ShowPriceChangeWarning = showPriceChangeWarning
                }),
            }
        }
    }

    return Roact.createElement(FitFrameOnAxis, {
        axis = FitFrameOnAxis.Axis.Vertical,
        minimumSize = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,

        LayoutOrder = layoutOrder,
    }, {
        ToggleAndSubscriptionsAndTotal = Roact.createElement(TitledFrame, if FFlagRemoveUILibraryTitledFrame then {
            LayoutOrder = 1,
            Title = title,
        } else {
            Title = title,
            TextSize = theme.fontStyle.Title.TextSize,

            MaxHeight = maxToggleHeight,

            LayoutOrder = 1,
        }, {
            UIListLayout = Roact.createElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Vertical,
            }),

            ToggleButton = Roact.createElement(ToggleButton, if FFlagDevFrameworkMigrateToggleButton then {
				Disabled = not enabled,
				Selected = selected,
				OnClick = onVipServersToggled,
				LayoutOrder = 1,
			} else {
                Enabled = enabled,
                IsOn = selected,
                Mouse = mouse:get(),

                onToggle = function(value)
                    if enabled then
                        onVipServersToggled(value)
                    end
                end,

                LayoutOrder = 1,
            }),

            SubText = showToggleSubText and Roact.createElement("TextLabel", Cryo.Dictionary.join(toggleSubTextTheme, {
                Size = UDim2.new(0, math.ceil(toggleSubTextSize.X), 0, toggleSubTextSize.Y),

                BackgroundTransparency = 1,

                Text = toggleSubText,

                TextYAlignment = Enum.TextYAlignment.Center,
                TextXAlignment = Enum.TextXAlignment.Left,

                TextWrapped = true,

                LayoutOrder = 2,
            })),

            Subscriptions = selected and Roact.createElement("TextLabel", {
                Font = theme.fontStyle.Normal.Font,
                TextSize = theme.fontStyle.Normal.TextSize,
                TextColor3 = selected and theme.fontStyle.Normal.TextColor3 or theme.fontStyle.Subtext.TextColor3,

                Text = subscriptionsText,
                Size = UDim2.new(1, 0, 0, theme.rowHeight),
                BackgroundTransparency = 1,

                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextTransparency = transparency,

                LayoutOrder = 2,
            }),

            TotalVIPServers = selected and Roact.createElement("TextLabel", {
                Font = theme.fontStyle.Normal.Font,
                TextSize = theme.fontStyle.Normal.TextSize,
                TextColor3 = selected and theme.fontStyle.Normal.TextColor3 or theme.fontStyle.Subtext.TextColor3,
                Text = totalVIPServersText,
                Size = UDim2.new(1, 0, 0, theme.rowHeight),
                BackgroundTransparency = 1,

                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextTransparency = transparency,

                LayoutOrder = 3,
            }),
        }),
        PriceConfig = selected and Roact.createElement(RadioButtonSet, {
            Title = priceTitle,

            Buttons = buttons,

            Enabled = selected,
            Selected = isFree,
            SelectionChanged = function(button)
                if button.Id then
                    onVipServersPriceChanged(0)
                else
                    onVipServersPriceChanged(self.lastNonFreePrice)
                end
            end,

            LayoutOrder = 2,
        }),
    })
end

VIPServers = withContext({
    Localization = ContextServices.Localization,
    Stylizer = ContextServices.Stylizer,
    Mouse = ContextServices.Mouse,
})(VIPServers)

return VIPServers
