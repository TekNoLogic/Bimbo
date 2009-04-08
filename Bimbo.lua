
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


local playerGlows = setmetatable({}, {
	__index = function(t,i)
		local slot = _G["Character"..i]
		local shine = LibStub("tekShiner").new(slot, 1, 0, 0)
		shine:SetAllPoints(slot)
		t[i] = shine
		return shine
	end
})

local inspectGlows = setmetatable({}, {
	__index = function(t,i)
		local slot = _G["Inspect"..i]
		local shine = LibStub("tekShiner").new(slot, 1, 0, 0)
		shine:SetAllPoints(slot)
		t[i] = shine
		return shine
	end
})

local function Check(unit, report, whisper)
	local printfunc = print
	if whisper then
		printfunc = function(...)
			local targetName = UnitName("target")
			SendChatMessage(string.join(" ", ...), "WHISPER", nil, targetName)
		end
	end

	local glows
	if unit == "target" then 
		glows = inspectGlows 
	else
		glows = playerGlows
	end

	for i in pairs(links) do links[i] = nil end
	for _,v in pairs(slots) do links[v] = GetInventoryItemLink(unit, GetInventorySlotInfo(v)) end
	for _,f in pairs(glows) do f:Hide() end

	enchantables.Finger0Slot = GetSpellInfo((GetSpellInfo(7411))) -- Only check rings if the player is an enchanter
	enchantables.Finger1Slot = enchantables.Finger0Slot

	-- Only check waist enchant if the player is an engineer
	-- Not checking for now, since these enchants don't really have much benefit
--~ 	enchantables.WaistSlot = GetSpellInfo((GetSpellInfo(4036)))

	if links.RangedSlot then
		local _, _, _, _, _, _, rangetype, _, slottype = GetItemInfo(links.RangedSlot)
		enchantables.RangedSlot = slottype ~= "INVTYPE_RELIC" and rangetype ~= "Wands" and rangetype ~= "Thrown" -- Can't enchant wands or thrown weapons
	end
	enchantables.SecondaryHandSlot = links.SecondaryHandSlot and select(9, GetItemInfo(links.SecondaryHandSlot)) ~= "INVTYPE_HOLDABLE" -- nor off-hand frills

	extrasockets.HandsSlot = GetSpellInfo((GetSpellInfo(2018))) -- Make sure smithies are adding sockets
	extrasockets.WristSlot = extrasockets.HandsSlot

	local found = false
	for slot,check in pairs(enchantables) do
		local link = check and links[slot]
		if link and link:match("item:%d+:0") then
			found = true
			glows[slot]:Show()
			if report then printfunc(link, "doesn't have an enchant") end
		end
	end

	for slot,check in pairs(extrasockets) do
		local link = check and links[slot]
		if link then
			local id = link:match("item:(%d+)")
			local _, link2 = GetItemInfo(id)
			local rawnum = GetSocketCount(link2)
			local num = GetSocketCount(link, slot)
			if rawnum == num then
				found = true
				glows[slot]:Show()
				if report then printfunc(link2, "doesn't have an extra socket") end
			end
		end
	end

	for slot,link in pairs(links) do
		local num, filled = GetSocketCount(link, slot)
		if filled < num then
			found = true
			glows[slot]:Show()
			if report then printfunc(link, "has empty sockets") end
		end
	end

	if not found and report then printfunc("All equipped items are enchanted and gemmed") end
end

local function CheckPlayer(report)
	Check("player")
end

local function CheckTarget(report)
	if(not InspectFrame:IsShown()) then return end
	Check('target', false)
end

local butt = LibStub("tekKonfig-Button").new_small(PaperDollFrame, "BOTTOMLEFT", 25, 86)
butt:SetWidth(45) butt:SetHeight(18)
butt:SetText("Bimbo")
butt:SetScript("OnShow", function() CheckPlayer() end)
butt:SetScript("OnEvent", function(self, event, unit) if unit == "player" and self:IsVisible() then CheckPlayer() end end)
butt:RegisterEvent("UNIT_INVENTORY_CHANGED")
butt:SetScript("OnClick", function() CheckPlayer(true) end)
if IsLoggedIn() then CheckPlayer() end

local hook = CreateFrame"Frame"
hook:SetScript("OnEvent", function(self, event, ...) self[event](...) end)

hook["PLAYER_TARGET_CHANGED"] = CheckTarget
hook["ADDON_LOADED"] = function(addon)
	if(addon == "Blizzard_InspectUI") then
		print("here")
		hook:SetScript("OnShow", CheckTarget)
		hook:SetParent"InspectFrame"

		if not InspectFrame.bimboBtn then
			local butt2 = LibStub("tekKonfig-Button").new_small(InspectFrame, "BOTTOMLEFT", 25, 86)
			butt2:SetScript("OnClick", function() 
				if IsShiftKeyDown() then
					Check("target", true, true)
				else
					Check("target", true) 
				end
			end)
			butt2:SetScript("OnEnter", function(self, ...)
				GameTooltip:SetOwner(self, "ANCHOR_NONE")
				GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
				GameTooltip:ClearLines()
				GameTooltip:SetText("Click to print missing gems and enchants.\nShift-click to send that to the player you're inspecting.")
				GameTooltip:Show()
			end)
			butt2:SetScript("OnLeave",  function(self, ...)
				GameTooltip:Hide()
			end)
			butt2:SetWidth(45) butt2:SetHeight(18)
			butt2:SetText("Bimbo")
			InspectFrame.bimboBtn = butt2
		end

		hook:RegisterEvent"PLAYER_TARGET_CHANGED"
		hook:UnregisterEvent"ADDON_LOADED"
	end
end

-- Check if it's already loaded by some add-on
if(IsAddOnLoaded("Blizzard_InspectUI")) then
	hook:SetScript("OnShow", update)
	hook:SetParent"InspectFrame"
else
	hook:RegisterEvent"ADDON_LOADED"
end

