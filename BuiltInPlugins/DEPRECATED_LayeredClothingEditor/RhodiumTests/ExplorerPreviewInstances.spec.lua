return function()
	local Plugin = script.Parent.Parent
	local Rhodium = require(Plugin.Packages.Dev.Rhodium)
	local XPath = Rhodium.XPath
	local Element = Rhodium.Element

	local TestHelper = require(Plugin.Src.Util.TestHelper)
	local TestRunner = require(Plugin.Src.Util.TestRunner)
	local runRhodiumTest = TestRunner.runRhodiumTest

	local PreviewConstants = require(Plugin.Src.Util.PreviewConstants)
	local MathUtil = require(Plugin.Src.Util.MathUtil)

	local LayeredClothingEditorPreviewPath = XPath.new("game.Workspace.LayeredClothingEditorPreview")
	local ScrollerPath = TestHelper.getEditScreenContainer()
	local editSwizzlePath = ScrollerPath:cat(XPath.new("EditSwizzle.TopBar.DoubleClickDetector.Swizzle"))
	local previewAvatarPath = LayeredClothingEditorPreviewPath:cat(XPath.new(PreviewConstants.PreviewAvatarName))
	local previewClothesPath = previewAvatarPath:cat(XPath.new(TestHelper.DefaultClothesName))

	it("LayeredClothingEditorPreview folder should exist in Workspace", function()
		runRhodiumTest(function()
			TestHelper.goToEditScreenFromStart(true)
			expect(TestHelper.waitForXPathInstance(LayeredClothingEditorPreviewPath)).to.be.ok()
		end)
	end)

	it("Transformations to rigid item should also be shown in Preview", function()
		runRhodiumTest(function(_, _, _, editingItemContext)
			TestHelper.goToEditScreenFromStart(false)

			local editingItem = editingItemContext:getItem()

			-- minimize edit swizzle in case UI is too big and cuts off animation slider
			TestHelper.clickXPath(editSwizzlePath)

			-- make sure we have the LayeredClothingEditorPreview folder, and it initially has no children
			expect(TestHelper.waitForXPathInstance(LayeredClothingEditorPreviewPath)).to.be.ok()
			expect(#TestHelper.waitForXPathInstance(LayeredClothingEditorPreviewPath):GetChildren()).to.equal(0)

			TestHelper.addAvatarToGrid() -- calling TestHelper.addLCItemWithoutCageFromExplorer() earlier makes avatar tab active

			-- click the avatar tile created with TestHelper.addAvatarToGrid() to put it in the scene
			TestHelper.clickEquippableGridTile(1) -- click the tile added with TestHelper.addAvatarToGrid()

			local previewAvatar = TestHelper.waitForXPathInstance(previewAvatarPath)
			expect(previewAvatar).to.be.ok()

			-- avatar should be wearing a clone of the accessory
			local itemClone = TestHelper.waitForXPathInstance(previewClothesPath)
			expect(itemClone).to.be.ok()

			local sourceAttachment = editingItem:WaitForChild(TestHelper.DefaultAttachmentName)
			local cloneAttachment = itemClone:WaitForChild(TestHelper.DefaultAttachmentName)

			expect(sourceAttachment).to.be.ok()
			expect(cloneAttachment).to.be.ok()

			-- expand edit swizzle to resume editing
			TestHelper.clickXPath(editSwizzlePath)

			-- test changing cframe
			local newCFrame = editingItem.CFrame + Vector3.new(0, 1, 0)
			newCFrame = newCFrame * CFrame.fromEulerAnglesXYZ(math.pi/6, 0, 0)
			editingItem.CFrame = newCFrame

			TestHelper.delay()

			expect(MathUtil:fuzzyEq_CFrame(sourceAttachment.CFrame, cloneAttachment.CFrame)).to.equal(true)

			-- test changing size
			local cloneOriginalSize = itemClone.Size
			editingItem.Size = editingItem.Size * 2

			TestHelper.delay()

			expect(itemClone.Size:FuzzyEq(cloneOriginalSize * 2)).to.equal(true)
		end)
	end)

	it("clicking an avatar grid tile should put it in the scene", function()
		runRhodiumTest(function()
			TestHelper.goToEditScreenFromStart(true)

			-- minimize edit swizzle in case UI is too big and cuts off animation slider
			TestHelper.clickXPath(editSwizzlePath)

			-- make sure we have the LayeredClothingEditorPreview folder, and it initially has no children
			expect(TestHelper.waitForXPathInstance(LayeredClothingEditorPreviewPath)).to.be.ok()
			expect(#TestHelper.waitForXPathInstance(LayeredClothingEditorPreviewPath):GetChildren()).to.equal(0)

			TestHelper.addAvatarToGrid() -- calling TestHelper.addLCItemWithoutCageFromExplorer() earlier makes avatar tab active

			-- click the avatar tile created with TestHelper.addAvatarToGrid() to put it in the scene
			TestHelper.clickEquippableGridTile(1) -- click the tile added with TestHelper.addAvatarToGrid()
			expect(TestHelper.waitForXPathInstance(previewAvatarPath)).to.be.ok()
		end)
	end)

	it("clicking an avatar grid tile twice should put it in the scene, then remove it", function()
		runRhodiumTest(function()
			TestHelper.goToEditScreenFromStart(true)

			-- minimize edit swizzle in case UI is too big and cuts off animation slider
			TestHelper.clickXPath(editSwizzlePath)

			-- make sure we have the LayeredClothingEditorPreview folder, and it initially has no children
			expect(TestHelper.waitForXPathInstance(LayeredClothingEditorPreviewPath)).to.be.ok()
			expect(#TestHelper.waitForXPathInstance(LayeredClothingEditorPreviewPath):GetChildren()).to.equal(0)

			TestHelper.addAvatarToGrid() -- calling TestHelper.addLCItemWithoutCageFromExplorer() earlier makes avatar tab active

			-- click the avatar tile created with TestHelper.addAvatarToGrid() to put it in the scene
			TestHelper.clickEquippableGridTile(1) -- click the tile added with TestHelper.addAvatarToGrid()
			expect(TestHelper.waitForXPathInstance(previewAvatarPath)).to.be.ok()

			-- click the avatar tile again to remove it from the scene
			TestHelper.clickEquippableGridTile(1)
			expect(#TestHelper.waitForXPathInstance(LayeredClothingEditorPreviewPath):GetChildren()).to.equal(0)
		end)
	end)

	it("clicking a clothes grid tile should make it a child of the preview avatar", function()
		runRhodiumTest(function(_, store)
			TestHelper.goToEditScreenFromStart(true)

			-- minimize edit swizzle in case UI is too big and cuts off animation slider
			TestHelper.clickXPath(editSwizzlePath)

			-- make sure we have the LayeredClothingEditorPreview folder, and it initially has no children
			expect(TestHelper.waitForXPathInstance(LayeredClothingEditorPreviewPath)).to.be.ok()
			expect(#TestHelper.waitForXPathInstance(LayeredClothingEditorPreviewPath):GetChildren()).to.equal(0)

			TestHelper.addAvatarToGrid() -- calling TestHelper.addLCItemWithoutCageFromExplorer() earlier makes avatar tab active

			-- click the avatar tile created with TestHelper.addAvatarToGrid() to put it in the scene
			TestHelper.clickEquippableGridTile(1) -- click the tile added with TestHelper.addAvatarToGrid()
			expect(TestHelper.waitForXPathInstance(previewAvatarPath)).to.be.ok()

			-- change to the clothes tab
			local PreviewTabsRibbonPath = ScrollerPath:cat(XPath.new("PreviewSwizzle.ViewArea.PreviewFrame.PreviewTabsRibbon"))
			local clothesButtonPath = PreviewTabsRibbonPath:cat(XPath.new("2 TAB_KEY_Clothing"))
			local clothesButtonDecorationPath = clothesButtonPath:cat(XPath.new("1.Decoration"))
			local clothesButtonTextButtonPath = clothesButtonPath:cat(XPath.new("1.Contents.TextButton"))

			local clothesButtonDecoration = Element.new(clothesButtonDecorationPath)
			TestHelper.clickXPath(clothesButtonTextButtonPath)
			expect(clothesButtonDecoration:getAttribute("BackgroundTransparency")).to.equal(0) -- clothes tab selected

			-- add a clothes item tile to the clothing grid
			TestHelper.addClothesItemToGrid()

			-- click the clothing grid tile we added with TestHelper.addClothesItemToGrid()
			TestHelper.clickEquippableGridTile(1)

			-- wait for the store to register the tile click
			expect(TestHelper.waitForValid(function()
				return nil ~= next(store:getState().previewStatus.selectedAssets[PreviewConstants.TABS_KEYS.Clothing])
			end)).to.equal(true)

			-- check the correct item exists as a child of the preview avatar
			local clothesItemName = next(store:getState().previewStatus.selectedAssets[PreviewConstants.TABS_KEYS.Clothing])
			local avatarClothesItemPath = XPath.new(PreviewConstants.PreviewAvatarName .. "." .. tostring(clothesItemName))
			local avatarClothesItem = LayeredClothingEditorPreviewPath:cat(avatarClothesItemPath)
			expect(TestHelper.waitForXPathInstance(avatarClothesItem)).to.be.ok()
		end)
	end)
end