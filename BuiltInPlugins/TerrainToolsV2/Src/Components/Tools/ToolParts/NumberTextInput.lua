--[[
	NumberTextInput
	Props:
		number LayoutOrder = 0
		string Key : Internal string passed back to the parent
		string Label : Localized text to display next to the text box
		number Value
		number Min optional
		number Max optional
		number Precision optional : How many decimal places to round the number too
		callback OnFocusLost(string key, bool enterPressed, string text, bool isValid)
		callback OnValueChanged(string key, string text, bool isValid)

		See LabeledTextInput for more
]]
local Plugin = script.Parent.Parent.Parent.Parent.Parent

local Framework = require(Plugin.Packages.Framework)
local Cryo = require(Plugin.Packages.Cryo)
local Roact = require(Plugin.Packages.Roact)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext

local ToolParts = script.Parent
local LabeledTextInput = require(ToolParts.LabeledTextInput)

local MAX_GRAPHEMES = 12

local function roundNumber(number, places)
	places = places or 3
	local shift = 10^places
	return math.floor((number * shift) + 0.5) / shift
end

local NumberTextInput = Roact.PureComponent:extend("NumberTextInput")

NumberTextInput.defaultProps = {
	MaxGraphemes = MAX_GRAPHEMES,
}

function NumberTextInput:init(props)
	self.isValid = true

	self.handlePrecision = function(text)
		if self.props.Precision and tonumber(text) then
			return roundNumber(tonumber(text), self.props.Precision)
		end
		return text
	end

	self.onFocusLost = function(enterPressed, text)
		if utf8.len(text) == 0 then
			text = self.props.Value
		end
		local newText = self.handlePrecision(text)
		if self.props.OnFocusLost then
			self.props.OnFocusLost(self.props.Key, enterPressed, newText, self.isValid)
		end
		return newText
	end

	self.getLocalization = function()
		return self.props.Localization
	end

	self.isTextValid = function(text)
		if utf8.len(text) == 0 then
			return true, nil
		end

		local number = tonumber(text)

		local isValid
		local warningMessage

		if number then
			if self.props.Min and number < self.props.Min then
				isValid = false
				warningMessage = self.getLocalization():getText("Warning", "MinimumSize", self.props.Min)
			elseif self.props.Max and number > self.props.Max then
				isValid = false
				warningMessage = self.getLocalization():getText("Warning", "MaximumSize", self.props.Max)
			else
				isValid = true
			end
		else
			isValid = false
			warningMessage = self.getLocalization():getText("Warning", "InvalidNumber")
		end

		if isValid then
			return true, nil
		else
			return false, warningMessage
		end
	end

	self.validateText = function(text)
		local isValid, warningMessage = self.isTextValid(text)
		self.isValid = isValid

		if self.props.OnValueChanged then
			if utf8.len(text) == 0 then
				self.props.OnValueChanged(self.props.Key, self.props.Value, self.isValid)
			else
				self.props.OnValueChanged(self.props.Key, text, self.isValid)
			end
		end

		if self.isValid then
			return text, nil
		else
			return text, warningMessage
		end
	end

	self.isValid = self.isTextValid(self.props.Value)
end

function NumberTextInput:render()
	local newProps = Cryo.Dictionary.join(self.props, {
		-- NumberTextInput wants "Value" but LabeledTextInput wants "Text"
		Value = Cryo.None,
		Text = self.handlePrecision(self.props.Value),

		OnFocusLost = self.onFocusLost,
		ValidateText = self.validateText,

		Key = Cryo.None,
		Min = Cryo.None,
		Max = Cryo.None,
		Precision = Cryo.None,
		OnValueChanged = Cryo.None,
	})

	return Roact.createElement(LabeledTextInput, newProps)
end

NumberTextInput = withContext({
	Localization = ContextServices.Localization,
})(NumberTextInput)

return NumberTextInput
