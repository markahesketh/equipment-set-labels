local MAX_NAME_LENGTH = 5
local BANK_BAG = -1

local itemSetText = {}
local slotSetText = {}

local EQUIP_SLOTS = {}
for _, name in ipairs({
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
    "ShirtSlot", "TabardSlot", "WristSlot", "HandsSlot", "WaistSlot",
    "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot",
    "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot"
}) do
    local slotID = GetInventorySlotInfo(name)
    if slotID then
        EQUIP_SLOTS[#EQUIP_SLOTS + 1] = {id = slotID, button = "Character" .. name}
    end
end

local function RebuildItemSetCache()
    wipe(itemSetText)

    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
        local itemIDs = C_EquipmentSet.GetItemIDs(setID)

        if name and itemIDs then
            local display = #name > MAX_NAME_LENGTH and name:sub(1, MAX_NAME_LENGTH - 1) .. "..." or name

            for _, itemID in pairs(itemIDs) do
                if itemID and itemID > 0 then
                    local existing = itemSetText[itemID]
                    if not existing then
                        itemSetText[itemID] = display
                    elseif not existing:find(display, 1, true) then
                        local lines = select(2, existing:gsub("\n", "")) + 1
                        if lines < 3 then
                            itemSetText[itemID] = existing .. "\n" .. display
                        elseif lines == 3 and not existing:find("+", 1, true) then
                            itemSetText[itemID] = existing .. "\n+"
                        end
                    end
                end
            end
        end
    end
end

local function ScanSlots()
    wipe(slotSetText)

    for bag = 0, 12 do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and itemSetText[info.itemID] then
                slotSetText[bag .. ":" .. slot] = itemSetText[info.itemID]
            end
        end
    end

    local numBankSlots = C_Container.GetContainerNumSlots(BANK_BAG) or 0
    for slot = 1, numBankSlots do
        local info = C_Container.GetContainerItemInfo(BANK_BAG, slot)
        if info and itemSetText[info.itemID] then
            slotSetText[BANK_BAG .. ":" .. slot] = itemSetText[info.itemID]
        end
    end

    for _, slot in ipairs(EQUIP_SLOTS) do
        local itemID = GetInventoryItemID("player", slot.id)
        if itemID and itemSetText[itemID] then
            slotSetText["e" .. slot.id] = itemSetText[itemID]
        end
    end
end

local function UpdateButton(button, key)
    local text = slotSetText[key]
    local label = button.EquipmentSetTagsLabel

    if text then
        if not label then
            label = button:CreateFontString(nil, "OVERLAY")
            label:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            label:SetPoint("CENTER")
            label:SetTextColor(1, 0.82, 0)
            button.EquipmentSetTagsLabel = label
        end
        label:SetText(text)
        label:Show()
    elseif label then
        label:Hide()
    end
end

local function UpdateFrames()
    for i = 1, 13 do
        local frame = _G["ContainerFrame" .. i]
        if frame and frame:IsShown() and frame.Items then
            for _, button in pairs(frame.Items) do
                if button.GetBagID then
                    UpdateButton(button, button:GetBagID() .. ":" .. button:GetID())
                end
            end
        end
    end

    if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() and ContainerFrameCombinedBags.Items then
        for _, button in pairs(ContainerFrameCombinedBags.Items) do
            if button.GetBagID then
                UpdateButton(button, button:GetBagID() .. ":" .. button:GetID())
            end
        end
    end

    if BankFrame and BankFrame:IsShown() then
        for i = 1, 28 do
            local button = _G["BankFrameItem" .. i]
            if button then
                UpdateButton(button, BANK_BAG .. ":" .. i)
            end
        end
    end

    if CharacterFrame and CharacterFrame:IsShown() then
        for _, slot in ipairs(EQUIP_SLOTS) do
            local button = _G[slot.button]
            if button then
                UpdateButton(button, "e" .. slot.id)
            end
        end
    end
end

local pending = false
local function ScheduleUpdate()
    if pending then return end
    pending = true
    C_Timer.After(0.1, function()
        pending = false
        ScanSlots()
        UpdateFrames()
    end)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("EQUIPMENT_SETS_CHANGED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("BANKFRAME_OPENED")
events:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

events:SetScript("OnEvent", function(_, event)
    if event == "EQUIPMENT_SETS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        RebuildItemSetCache()
    end
    ScheduleUpdate()
end)

hooksecurefunc("ToggleAllBags", ScheduleUpdate)
hooksecurefunc("OpenAllBags", ScheduleUpdate)
hooksecurefunc("ToggleCharacter", ScheduleUpdate)

RebuildItemSetCache()
