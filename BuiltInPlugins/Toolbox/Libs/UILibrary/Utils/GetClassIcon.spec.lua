-- Icon location is determined by an offset within a sequential list of icons in a single image.
local ICON_NOTFOUND = Vector2.new(0,0)
local ICON_JOINTINSTANCE = Vector2.new(544,0)
local ICON_SCRIPT = Vector2(96,0)

return function()
    local GetClassIcon = require(script.Parent.GetClassIcon)

    describe("getClassIcon", function()
        it("should correctly return 'JointInstance' classIcon for ManualWelds", function()
            local manualWeld = Instance.new("ManualWeld")
            local classIconTable = GetClassIcon(manualWeld)

            expect(classIconTable.ImageRectOffset).to.equal(ICON_JOINTINSTANCE)
            expect(classIconTable.ImageRectOffset).never.to.equal(ICON_NOTFOUND)
        end)

        it("should correctly return 'JointInstance' classIcon for ManualGlues", function()
            local manualGlue = Instance.new("ManualGlue")
            local classIconTable = GetClassIcon(manualGlue)

            expect(classIconTable.ImageRectOffset).to.equal(ICON_JOINTINSTANCE)
            expect(classIconTable.ImageRectOffset).never.to.equal(ICON_NOTFOUND)
        end)

        it("should return the Script Class Icon for scripts", function()
            local script = Instance.new("Script")
            local classIconTable = GetClassIcon(script)

            expect(classIconTable.ImageRectOffset).to.equal(ICON_SCRIPT)
            expect(classIconTable.ImageRectOffset).never.to.equal(ICON_NOTFOUND)
        end)
    end)
end