--!nonstrict
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local PlayerHelper = require(script.Parent.PlayerHelper)
local CorePackages = game:GetService("CorePackages")
local Rhodium = require(CorePackages.Rhodium)
local RoactAct = require(game.CoreGui.RobloxGui.Modules.act)

local testMenuKey = "ProximityPromptTestsMenuKey"

return function()
	local part, prompt, promptUI, promptUICorners
	local promptTriggeredCount, promptTriggerEndedCount
	local promptScreenGui

	if not game:GetEngineFeature("ProximityPrompts") then
		return
	end

	local function getNewPromptUICreatedInNextFrame()
		local newPromptUIs = {}
		local promptGuiConnection = promptScreenGui.ChildAdded:Connect(function(child)
			table.insert(newPromptUIs, child)
		end)
		PlayerHelper.WaitNFrames(1)
		promptGuiConnection:Disconnect()
		expect(#newPromptUIs).to.equal(1)
		local newPromptUI = newPromptUIs[1]
		expect(newPromptUI).to.be.ok()
		expect(newPromptUI:IsA("BillboardGui")).to.equal(true) -- Should be a BillboardGui
		expect(newPromptUI.Active).to.equal(true) -- Expect BillboardGui to respond to mouse clicks
		promptUI = newPromptUI
		promptUICorners = PlayerHelper.GetCornersOfBillboardGui(promptUI)
	end

	-- Calling this will regenerate the prompt UI. It is very slow, since we wait for fade out and prompt UI deletion!
	local function rebuildPromptUI()
		prompt.Enabled = false
		PlayerHelper.WaitNFrames(1)
		-- Wait for prompt UI to be removed from the player gui:
		PlayerHelper.WaitForExpression(function()
			return #promptScreenGui:GetChildren() == 0
		end, 5, "Prompt UI was not removed")
		prompt.Enabled = true
		
		getNewPromptUICreatedInNextFrame()
		PlayerHelper.WaitNFrames(1)
	end

	beforeAll(function()
		PlayerHelper.Init()
		PlayerHelper.SetCameraFOV(70.0)
		PlayerHelper.hrp.Anchored = true -- Anchor hrp so it doesn't fall away!
		PlayerHelper.MovePlayerToPosition(Vector3.new(0,0,0))
		PlayerHelper.SetPlayerCamera(Vector3.new(0, -0.2, -1), 10)
		PlayerHelper.WaitNFrames(1)

		part = PlayerHelper.AddInstance("Part")
		part.Size = Vector3.new(2,2,2)
		part.Position = Vector3.new(0,0,-5)
		part.Anchored = true

		promptTriggeredCount = 0
		promptTriggerEndedCount = 0

		prompt = Instance.new("ProximityPrompt")
		prompt.Parent = part
		prompt.MaxActivationDistance = 10

		prompt.Triggered:Connect(function(player)
			promptTriggeredCount += 1
		end)
		prompt.TriggerEnded:Connect(function(player)
			promptTriggerEndedCount += 1
		end)

		-- Wait for Proximity prompts ScreenGui to be added
		promptScreenGui = PlayerHelper.PlayerGui:WaitForChild("ProximityPrompts", 10)
		expect(promptScreenGui).to.be.ok()

		
		rebuildPromptUI()
		PlayerHelper.WaitNFrames(1)
		wait(0.5) -- Wait for fade in to be over

		-- Unsure of why this is needed, but it seems the first Rhodium mouse event is ignored only for BillboardGui's, so we send a click beforehand:
		Rhodium.VirtualInput.Mouse.sendMouseButtonEvent(200, 200, 0, true)
		Rhodium.VirtualInput.Mouse.sendMouseButtonEvent(200, 200, 0, false)
		PlayerHelper.WaitNFrames(1)
	end)

	afterAll(function()
		PlayerHelper.CleanUpAfterTest()
	end)

	local function setKeyboardInputType()
		Rhodium.VirtualInput.Keyboard.hitKey(Enum.KeyCode.L)
		PlayerHelper.WaitNFrames(1)
	end

	local function setMobileInputType()
		Rhodium.VirtualInput.Touch.tap(Vector2.new(100,100))
		PlayerHelper.WaitNFrames(1)
	end

	local function setGamepadInputType(gamepad)
		PlayerHelper.WaitNFrames(1)
		gamepad:pressButton(Enum.KeyCode.ButtonB)
		gamepad:releaseButton(Enum.KeyCode.ButtonB)
		PlayerHelper.WaitNFrames(1)
	end

	describe("Default prompt UI appearance", function()
		it("Should display touch icon for mobile tap input instead of keycode", function()
			setMobileInputType()
			rebuildPromptUI()

			local buttonTextLabel = promptUI:FindFirstChild("ButtonText", true)
			local buttonImageLabel = promptUI:FindFirstChild("ButtonImage", true)
			expect(buttonTextLabel).to.equal(nil) -- Should have no text
			expect(buttonImageLabel).to.be.ok() -- Should be an image
			expect(buttonImageLabel:IsA("ImageLabel")).to.be.equal(true)
			expect(buttonImageLabel.Visible).to.be.equal(true)
			local assetURL = tostring(buttonImageLabel.Image)
			-- Check if asset URL contains tap icon
			expect(string.find(assetURL, "TouchTapIcon.png") == nil).to.equal(false)
		end)

		it("Should display correct gamepad button for triggering", function()
			-- First, put in some gamepad input to show gamepad input icons
			local gamepad = Rhodium.VirtualInput.GamePad.new()
			setGamepadInputType(gamepad)

			local keycodes = {Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY}
			local expectedAssetNames = {"xboxA.png", "xboxB.png", "xboxX.png", "xboxY.png"}
			for idx,keycode in pairs(keycodes) do
				prompt.GamepadKeyCode = keycode

				rebuildPromptUI()

				local buttonTextLabel = promptUI:FindFirstChild("ButtonText", true)
				local buttonImageLabel = promptUI:FindFirstChild("ButtonImage", true)
				expect(buttonTextLabel).to.equal(nil) -- Should have no text
				expect(buttonImageLabel).to.be.ok() -- Should be an image
				expect(buttonImageLabel:IsA("ImageLabel")).to.be.equal(true)
				expect(buttonImageLabel.Visible).to.be.equal(true)
				local assetURL = tostring(buttonImageLabel.Image)
				-- Check if asset URL contains expected button name
				expect(string.find(assetURL, expectedAssetNames[idx]) == nil).to.equal(false)
			end

			gamepad:disconnect()
		end)

		it("Should display correct keyboard key for triggering", function()
			setKeyboardInputType()
			for keycode = Enum.KeyCode.A.Value,Enum.KeyCode.C.Value do
				prompt.KeyboardKeyCode = keycode
				local keyString = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
				rebuildPromptUI()
				
				local buttonTextLabel = promptUI:FindFirstChild("ButtonText", true)
				expect(buttonTextLabel).to.be.ok()
				expect(buttonTextLabel:IsA("TextLabel")).to.be.equal(true)
				expect(buttonTextLabel.Text).to.be.equal(keyString) -- Check button text is correct
				expect(buttonTextLabel.TextFits).to.be.equal(true) -- Text should not be cut off
			end
		end)

		it("Should have correct ActionText and ObjectText", function()
			setKeyboardInputType()
			prompt.ActionText = "My test Action Text D&@%1"
			prompt.ObjectText = "My test Object Text A1f56"
			PlayerHelper.WaitNFrames(1)

			local actionTextLabel = promptUI:FindFirstChild("ActionText", true)
			local objectTextLabel = promptUI:FindFirstChild("ObjectText", true)
			expect(actionTextLabel:IsA("TextLabel")).to.be.equal(true)
			expect(objectTextLabel:IsA("TextLabel")).to.be.equal(true)
			-- Check text is correct:
			expect(actionTextLabel.Text).to.be.equal(prompt.ActionText)
			expect(objectTextLabel.Text).to.be.equal(prompt.ObjectText)
		end)

		it("ActionText and ObjectText should not be cut off/should fit in prompt frame", function()
			setKeyboardInputType()
			prompt.ActionText = "My test Action Text 1234 Long Text 1234"
			prompt.ObjectText = "Even longer text I could write a whole paragraph here"
			PlayerHelper.WaitNFrames(1)

			local actionTextLabel = promptUI:FindFirstChild("ActionText", true)
			local objectTextLabel = promptUI:FindFirstChild("ObjectText", true)
			expect(actionTextLabel:IsA("TextLabel")).to.be.equal(true)
			expect(objectTextLabel:IsA("TextLabel")).to.be.equal(true)
			expect(actionTextLabel.Text).to.be.equal(prompt.ActionText)
			expect(objectTextLabel.Text).to.be.equal(prompt.ObjectText)
			expect(actionTextLabel.TextFits).to.be.equal(true) -- Text should not be cut off
			expect(objectTextLabel.TextFits).to.be.equal(true)
		end)

		it("ActionText and ObjectText should update within 1 frame when prompt properties changed", function()
			setKeyboardInputType()
			prompt.ActionText = "ActionText 1"
			prompt.ObjectText = "ObjectText 1"
			PlayerHelper.WaitNFrames(1)

			local firstXSize = promptUI.AbsoluteSize.x
			expect(firstXSize > 0).to.be.equal(true)

			-- First setting
			local actionTextLabel = promptUI:FindFirstChild("ActionText", true)
			local objectTextLabel = promptUI:FindFirstChild("ObjectText", true)
			expect(actionTextLabel:IsA("TextLabel")).to.be.equal(true)
			expect(objectTextLabel:IsA("TextLabel")).to.be.equal(true)
			expect(actionTextLabel.Text).to.be.equal(prompt.ActionText)
			expect(objectTextLabel.Text).to.be.equal(prompt.ObjectText)
			expect(actionTextLabel.TextFits).to.be.equal(true) -- Text should not be cut off
			expect(objectTextLabel.TextFits).to.be.equal(true)

			prompt.ActionText = "ActionText 2B Longer"
			prompt.ObjectText = "ObjectText 2B Longer"
			PlayerHelper.WaitNFrames(1)

			-- Second setting
			local actionTextLabel = promptUI:FindFirstChild("ActionText", true)
			local objectTextLabel = promptUI:FindFirstChild("ObjectText", true)
			expect(actionTextLabel:IsA("TextLabel")).to.be.equal(true)
			expect(objectTextLabel:IsA("TextLabel")).to.be.equal(true)
			expect(actionTextLabel.Text).to.be.equal(prompt.ActionText)
			expect(objectTextLabel.Text).to.be.equal(prompt.ObjectText)
			expect(actionTextLabel.TextFits).to.be.equal(true) -- Text should not be cut off
			expect(objectTextLabel.TextFits).to.be.equal(true)

			local secondXSize = promptUI.AbsoluteSize.x
			expect(secondXSize > firstXSize).to.be.equal(true) -- Prompt x size should have gotten bigger.
		end)
	end)
	
	describe("Triggered behavior", function()
		beforeAll(function()
			-- Rebuild UI to get accurate corner positions
			rebuildPromptUI()
			PlayerHelper.WaitNFrames(1)
		end)

		it("prompt UI BillboardGui should be visible and correct size", function()
			prompt.RequiresLineOfSight = true
			prompt.Enabled = true

			PlayerHelper.WaitNFrames(1)
			expect(PlayerHelper.IsPartOnscreen(part)).to.equal(true)

			prompt.MaxActivationDistance = 10
			local dist = part.Position - PlayerHelper.hrp.Position
			expect(dist.Magnitude < prompt.MaxActivationDistance).to.equal(true) -- should be inside of radius

			expect(promptUI).to.be.ok()

			PlayerHelper.WaitNFrames(1)

			expect(promptUI.Enabled).to.equal(true) -- Visible
			local rhoElement = Rhodium.Element.new(promptUI)
			local dimensions = rhoElement:getSize()
			expect(dimensions).to.be.ok()
			expect(dimensions.x > 10).to.equal(true) -- Prompts can be variable size but expect larger than 10x10px
			expect(dimensions.y > 10).to.equal(true)

			-- Check BillboardGui is OK
			expect(promptUI:IsA("BillboardGui"))
			expect(promptUI.Active).to.be.equal(true) -- responds to mouse events
			expect(promptUI.Adornee.Name).to.be.equal(part.Name) -- Check Adornee is correct
		end)
		
		it("should fire Triggered signal when clicked if .ClickablePrompt=true", function()
			prompt.RequiresLineOfSight = true
			prompt.Enabled = true
			prompt.ClickablePrompt = true
			prompt.HoldDuration = 0 -- No hold required
			part.Position = Vector3.new(0, 0, -5)
			PlayerHelper.WaitNFrames(1)
			
			promptTriggeredCount = 0
			local promptScreenPos = promptUICorners.center
			-- Send left mouse button down event
			Rhodium.VirtualInput.Mouse.sendMouseButtonEvent(math.floor(promptScreenPos.x), math.floor(promptScreenPos.y), 0, true) -- mouse down
			PlayerHelper.WaitNFrames(1)
			Rhodium.VirtualInput.Mouse.sendMouseButtonEvent(math.floor(promptScreenPos.x), math.floor(promptScreenPos.y), 0, false) -- mouse up
			expect(promptTriggeredCount).to.equal(1)
		end)

		it("should not fire Triggered signal for all keyboard keys except .KeyboardKeyCode", function()
			prompt.RequiresLineOfSight = false
			prompt.Enabled = true
			prompt.ClickablePrompt = false
			prompt.HoldDuration = 0 -- No hold required
			PlayerHelper.WaitNFrames(1)

			prompt.KeyboardKeyCode = Enum.KeyCode.A

			local k = Enum.KeyCode
			-- Exclude prompt trigger keycodes
			-- Exclude keycodes that trigger contextual actions (in-game menu, emotes menu, etc)
			local excludeKeyCodes = {prompt.KeyboardKeyCode, prompt.GamepadKeyCode,
				k.Escape, k.ButtonSelect, k.ButtonStart, k.Period, k.Backquote,
				k.F9, k.F11, k.F12, k.Print, k.SysReq, k.Undo, k.Power, k.Break, k.Mode, k.Compose}
			local excludeKeyCodesMap = {}
			for _, v in pairs(excludeKeyCodes) do
				excludeKeyCodesMap[v] = true
			end

			-- Try all keycodes except correct one:
			local keycodes = Enum.KeyCode:GetEnumItems()
			for _, v in pairs(keycodes) do
				if not excludeKeyCodesMap[v] then
					promptTriggeredCount = 0
					Rhodium.VirtualInput.Keyboard.SendKeyEvent(true, v, false)
					Rhodium.VirtualInput.Keyboard.SendKeyEvent(false, v, false)
					PlayerHelper.WaitNFrames(1)
					expect(promptTriggeredCount).to.equal(0)
				end
			end

			promptTriggeredCount = 0
			Rhodium.VirtualInput.Keyboard.SendKeyEvent(true, prompt.KeyboardKeyCode, false)
			Rhodium.VirtualInput.Keyboard.SendKeyEvent(false, prompt.KeyboardKeyCode, false)
			PlayerHelper.WaitNFrames(1)
			expect(promptTriggeredCount).to.equal(1)
		end)

		it("should fire Triggered signal for correct gamepad input", function()
			prompt.RequiresLineOfSight = false
			prompt.Enabled = true
			prompt.ClickablePrompt = false
			prompt.HoldDuration = 0 -- No hold required
			PlayerHelper.WaitNFrames(1)

			prompt.GamepadKeyCode = Enum.KeyCode.ButtonA
			
			-- Try all buttons except correct one:
			local keycodes = Rhodium.VirtualInput.GamePad.KeyCode

			local gamepad = Rhodium.VirtualInput.GamePad.new()
			PlayerHelper.WaitNFrames(1)
			
			for _, v in pairs(keycodes) do
				-- NOTE: Enum.KeyCode.ButtonSelect enables gamepad virtual cursor selection mode! Do not press it!
				if v ~= prompt.GamepadKeyCode and v ~= Enum.KeyCode.ButtonSelect and v ~= Enum.KeyCode.ButtonStart then
					promptTriggeredCount = 0
					gamepad:pressButton(v)
					gamepad:releaseButton(v)
					PlayerHelper.WaitNFrames(1)
					expect(promptTriggeredCount).to.equal(0)
				end
			end
			
			promptTriggeredCount = 0
			gamepad:pressButton(prompt.GamepadKeyCode)
			gamepad:releaseButton(prompt.GamepadKeyCode)
			PlayerHelper.WaitNFrames(1)
			expect(promptTriggeredCount).to.equal(1)

			gamepad:disconnect()
		end)

		it("should fire Triggered signal on touch, even if .ClickablePrompt=false", function()
			prompt.RequiresLineOfSight = false
			prompt.Enabled = true
			prompt.ClickablePrompt = false
			prompt.KeyboardKeyCode = Enum.KeyCode.Q
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonA
			part.Position = Vector3.new(0, 0, -5)
			
			setMobileInputType()
			rebuildPromptUI()

			PlayerHelper.WaitNFrames(1)

			local touchpoints = promptUICorners
			
			for _,point in pairs(touchpoints) do
				promptTriggeredCount = 0
				PlayerHelper.WaitNFrames(1)
				Rhodium.VirtualInput.Touch.touchStart(point)
				Rhodium.VirtualInput.Touch.touchStop(point)
				PlayerHelper.WaitNFrames(1)

				expect(promptTriggeredCount).to.equal(1)
			end
		end)
		
		it("should not fire Triggered signal when clicked or keypressed when in-game menu is open (CLIPLAYEREX-4155)", function()
			prompt.RequiresLineOfSight = false
			prompt.Enabled = true
			prompt.ClickablePrompt = true
			prompt.HoldDuration = 0
			prompt.KeyboardKeyCode = Enum.KeyCode.F
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonX

			expect(GuiService.MenuIsOpen).to.equal(false) -- Menu should be closed at first
			
			-- Click should work
			promptTriggeredCount = 0
			local promptScreenPos = promptUICorners.center
			
			Rhodium.VirtualInput.Mouse.sendMouseButtonEvent(promptScreenPos.x, promptScreenPos.y, 0, true) -- mouse down
			Rhodium.VirtualInput.Mouse.sendMouseButtonEvent(promptScreenPos.x, promptScreenPos.y, 0, false) -- mouse up
			PlayerHelper.WaitNFrames(1)
			expect(promptTriggeredCount).to.equal(1)

			-- Keypress should work
			promptTriggeredCount = 0
			Rhodium.VirtualInput.Keyboard.SendKeyEvent(true, prompt.KeyboardKeyCode, false)
			Rhodium.VirtualInput.Keyboard.SendKeyEvent(false, prompt.KeyboardKeyCode, false)
			PlayerHelper.WaitNFrames(1)
			expect(promptTriggeredCount).to.equal(1)
			
			RoactAct(function()
				-- Open in-game menu:
				GuiService:SetMenuIsOpen(true, testMenuKey)
				wait()
			end)

			PlayerHelper.WaitForExpression(function()
				return GuiService.MenuIsOpen
			end, 5, "Menu did not open")
			
			-- Try click
			promptTriggeredCount = 0
			Rhodium.VirtualInput.Mouse.sendMouseButtonEvent(promptScreenPos.x, promptScreenPos.y, 0, true) -- mouse down
			Rhodium.VirtualInput.Mouse.sendMouseButtonEvent(promptScreenPos.x, promptScreenPos.y, 0, false) -- mouse up
			PlayerHelper.WaitNFrames(1)
			expect(promptTriggeredCount).to.equal(0)

			expect(GuiService.MenuIsOpen).to.equal(true) -- Menu should still be open
			-- Try keypress
			promptTriggeredCount = 0
			Rhodium.VirtualInput.Keyboard.SendKeyEvent(true, prompt.KeyboardKeyCode, false)
			Rhodium.VirtualInput.Keyboard.SendKeyEvent(false, prompt.KeyboardKeyCode, false)
			PlayerHelper.WaitNFrames(1)
			expect(promptTriggeredCount).to.equal(0)

			RoactAct(function()
				-- Close the test menu
				GuiService:SetMenuIsOpen(false, testMenuKey)
				wait()
			end)

			PlayerHelper.WaitForExpression(function()
				return GuiService.MenuIsOpen == false
			end, 5, "Menu did not close")
		end)

		it("should not fire Triggered signal on gamepad button pressed while gamepad menu is open (CLIPLAYEREX-4155)", function()
			prompt.RequiresLineOfSight = false
			prompt.ClickablePrompt = true
			prompt.HoldDuration = 0
			prompt.KeyboardKeyCode = Enum.KeyCode.F
			-- NOTE: In the new gamepad menu, the buttons A, B, X, Y, are all mapped to buttons and X quits the game.
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonR1

			PlayerHelper.WaitNFrames(1)

			local gamepad
			RoactAct(function()
				gamepad = Rhodium.VirtualInput.GamePad.new()
				wait(1)
			end)

			-- Button press should work
			promptTriggeredCount = 0
			gamepad:hitButton(prompt.GamepadKeyCode)
			PlayerHelper.WaitNFrames(1)
			expect(promptTriggeredCount).to.equal(1)

			-- Open the in-game menu by pressing start button on console
			RoactAct(function()
				GuiService:SetMenuIsOpen(true, testMenuKey)
				wait()
			end)

			PlayerHelper.WaitForExpression(function()
				return GuiService.MenuIsOpen
			end, 5, "Menu did not open")

			-- Button press should NOT work
			promptTriggeredCount = 0
			gamepad:hitButton(prompt.GamepadKeyCode)
			PlayerHelper.WaitNFrames(1)
			expect(promptTriggeredCount).to.equal(0)

			-- Close the in-game menu by pressing start button on console
			RoactAct(function()
				GuiService:SetMenuIsOpen(false, testMenuKey)
				wait()
			end)
			
			PlayerHelper.WaitForExpression(function()
				return GuiService.MenuIsOpen == false
			end, 5, "Menu did not close")

			gamepad:disconnect()
			PlayerHelper.WaitNFrames(2)
		end)

		it("Should only fire triggered signal after .HoldDuration time has elapsed for keypress", function()
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
			prompt.HoldDuration = 0.7239  -- seconds

			setKeyboardInputType()
			PlayerHelper.WaitNFrames(1)
			
			promptTriggeredCount = 0
			Rhodium.VirtualInput.Keyboard.SendKeyEvent(true, prompt.KeyboardKeyCode, false) -- key down

			PlayerHelper.WaitGameTime(prompt.HoldDuration)

			-- Prompt should not have triggered yet
			expect(promptTriggeredCount).to.equal(0)

			promptTriggeredCount = 0
			promptTriggerEndedCount = 0
			PlayerHelper.WaitNFrames(1)
			-- Prompt should have triggered on this frame
			expect(promptTriggeredCount).to.equal(1)

			PlayerHelper.WaitNFrames(1)
			expect(promptTriggerEndedCount).to.equal(0)

			Rhodium.VirtualInput.Keyboard.SendKeyEvent(false, prompt.KeyboardKeyCode, false) -- key up
			-- Prompt triggerEnded event should be fired
			promptTriggerEndedCount = 0
			PlayerHelper.WaitNFrames(1)
			expect(promptTriggerEndedCount).to.equal(1)
		end)

		it("Should only fire triggered signal after .HoldDuration time has elapsed for click", function()
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
			prompt.ClickablePrompt = true
			prompt.HoldDuration = 0.23456  -- seconds
			
			local buttonPos = promptUICorners
			promptTriggeredCount = 0
			promptTriggerEndedCount = 0
			Rhodium.VirtualInput.Mouse.sendMouseButtonEvent(buttonPos.center.x, buttonPos.center.y, 0, true) -- mouse down

			PlayerHelper.WaitGameTime(prompt.HoldDuration)

			-- Prompt should not have triggered yet
			expect(promptTriggeredCount).to.equal(0)
			expect(promptTriggerEndedCount).to.equal(0)
			
			PlayerHelper.WaitNFrames(2)
			-- Prompt should have triggered on this frame
			expect(promptTriggeredCount).to.equal(1)

			Rhodium.VirtualInput.Mouse.sendMouseButtonEvent(buttonPos.center.x, buttonPos.center.y, 0, false) -- mouse up
			PlayerHelper.WaitNFrames(1)
			expect(promptTriggerEndedCount).to.equal(1)
		end)

		it("Should only fire triggered signal after .HoldDuration time has elapsed for tap", function()
			-- Set touch input type
			setMobileInputType()
			PlayerHelper.WaitNFrames(1)

			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
			prompt.ClickablePrompt = true
			prompt.HoldDuration = 0.54321  -- seconds
			
			rebuildPromptUI() -- Need to rebuild to respond to touch input
			local buttonPos = promptUICorners

			promptTriggeredCount = 0
			promptTriggerEndedCount = 0
			Rhodium.VirtualInput.Touch.touchStart(buttonPos.center) -- touch down

			PlayerHelper.WaitGameTime(prompt.HoldDuration)

			-- Prompt should not have triggered yet
			expect(promptTriggeredCount).to.equal(0)
			expect(promptTriggerEndedCount).to.equal(0)
			
			PlayerHelper.WaitNFrames(2)
			-- Prompt should have triggered on this frame
			expect(promptTriggeredCount).to.equal(1)

			Rhodium.VirtualInput.Touch.touchStop(buttonPos.center) -- touch up
			PlayerHelper.WaitNFrames(1)
			
			-- Prompt triggerEnded event should be fired
			expect(promptTriggerEndedCount).to.equal(1)
		end)

		
	end)
end
