
local tip = BimboScanTip
TEKTIP = tip

local links = {}
local slots = {"BackSlot", "ChestSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "HandsSlot", "HeadSlot", "LegsSlot", "MainHandSlot", "NeckSlot", "RangedSlot", "SecondaryHandSlot", "ShoulderSlot", "Trinket0Slot", "Trinket1Slot", "WaistSlot", "WristSlot"}
local enchantables = {BackSlot = true, ChestSlot = true, FeetSlot = true, HandsSlot = true, HeadSlot = true, LegsSlot = true, MainHandSlot = true, ShoulderSlot = true, WristSlot = true}
local extrasockets = {WaistSlot = true}


local function GetSocketCount(link, slot)
	local num, filled = 0, 0
	if slot then tip:SetInventoryItem("player", GetInventorySlotInfo(slot)) else tip:SetHyperlink(link) end
	for i=1,10 do if tip.icon[i] then num = num + 1 end end

	local gem1, gem2, gem3, gem4 = link:match("item:%d+:%d+:(%d+):(%d+):(%d+):(%d+)")
	local filled = (gem1 ~= "0" and 1 or 0) + (gem2 ~= "0" and 1 or 0) + (gem3 ~= "0" and 1 or 0) + (gem4 ~= "0" and 1 or 0)

	return num, filled
end


local glows = setmetatable({}, {
	__index = function(t,i)
		local slot = _G["Character"..i]
		local shine = LibStub("tekShiner").new(slot, 1, 0, 0)
		shine:SetAllPoints(slot)
		t[i] = shine
		return shine
	end
})


local function Check(report)
	for i in pairs(links) do links[i] = nil end
	for _,v in pairs(slots) do links[v] = GetInventoryItemLink("player", GetInventorySlotInfo(v)) end
	for _,f in pairs(glows) do f:Hide() end

	enchantables.Finger0Slot = GetSpellInfo((GetSpellInfo(7411))) -- Only check rings if the player is an enchanter
	enchantables.Finger1Slot = enchantables.Finger0Slot

	-- Only check waist enchant if the player is an engineer
	-- Not checking for now, since these enchants don't really have much benefit
--~ 	enchantables.WaistSlot = GetSpellInfo((GetSpellInfo(4036)))

	local _, _, _, _, _, _, rangetype, _, slottype = GetItemInfo(links.RangedSlot)
	enchantables.RangedSlot = links.RangedSlot and slottype ~= "INVTYPE_RELIC" and rangetype ~= "Wands" and rangetype ~= "Thrown" -- Can't enchant wands or thrown weapons
	enchantables.SecondaryHandSlot = links.SecondaryHandSlot and select(9, GetItemInfo(links.SecondaryHandSlot)) ~= "INVTYPE_HOLDABLE" -- nor off-hand frills

	extrasockets.HandsSlot = GetSpellInfo((GetSpellInfo(2018))) -- Make sure smithies are adding sockets
	extrasockets.WristSlot = extrasockets.HandsSlot

	local found = false
	for slot,check in pairs(enchantables) do
		local link = check and links[slot]
		if link and link:match("item:%d+:0") then
			found = true
			glows[slot]:Show()
			if report then print(link, "doesn't have an enchant") end
		end
	end

	for slot,check in pairs(extrasockets) do
		if check then
			local link = links[slot]
			local id = link:match("item:(%d+)")
			local _, link2 = GetItemInfo(id)
			local rawnum = GetSocketCount(link2)
			local num = GetSocketCount(link, slot)
			if rawnum == num then
				found = true
				glows[slot]:Show()
				if report then print(link2, "doesn't have an extra socket") end
			end
		end
	end

	for slot,link in pairs(links) do
		local num, filled = GetSocketCount(link, slot)
		if filled < num then
			found = true
			glows[slot]:Show()
			if report then print(link, "has empty sockets") end
		end
	end

	if not found and report then print("All equipped items are enchanted and gemmed") end
end


local butt = LibStub("tekKonfig-Button").new_small(PaperDollFrame, "BOTTOMLEFT", 25, 86)
butt:SetWidth(45) butt:SetHeight(18)
butt:SetText("Bimbo")
butt:SetScript("OnShow", function() Check() end)
butt:SetScript("OnClick", function() Check(true) end)
Check()
