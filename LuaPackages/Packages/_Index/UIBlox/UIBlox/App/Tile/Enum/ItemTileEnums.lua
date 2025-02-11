local Tile = script.Parent.Parent
local App = Tile.Parent
local UIBlox = App.Parent
local Packages = UIBlox.Parent

local enumerate = require(Packages.enumerate)
local UIBloxConfig = require(Packages.UIBlox.UIBloxConfig)

local strict = require(UIBlox.Utility.strict)

local ItemIconType

if UIBloxConfig.useDynamicHeadIcon then
	ItemIconType = enumerate("ItemIconType", {
		"AnimationBundle",
		"Bundle",
		"DynamicHead",
	})
else
	ItemIconType = enumerate("ItemIconType", {
		"AnimationBundle",
		"Bundle",
	})
end

return strict({
	ItemIconType = ItemIconType,
	StatusStyle = enumerate("StatusStyle", {
		"Alert",
		"Info",
	}),
	Restriction = enumerate("Restriction", {
		"Limited",
		"LimitedUnique",
	}),
}, script.Name)
