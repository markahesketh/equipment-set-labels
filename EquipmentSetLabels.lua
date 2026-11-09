local ADDON_NAME = "EquipmentSetLabels"
local DISPLAY_NAME = "Equipment Set Labels"

local defaults = {
    showBags = true,
    showBank = true,
    showCharacter = true,
}

local itemSetText = {}
local slotSetText = {}
local pending = false
local optionsCategory
local checkboxes = {}

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
            local display = #name > 5 and name:sub(1, 5) .. ".." or name

            for _, itemID in pairs(itemIDs) do
                if itemID and itemID > 0 then
                    local existing = itemSetText[itemID]
                    if not existing then
                        itemSetText[itemID] = display
                    elseif not existing:find(display, 1, true) then
                        local lines = select(2, existing:gsub("\n", "")) + 1
                        if lines < 3 then
                            itemSetText[itemID] = existing .. "\n" .. display
                        elseif not existing:find("+", 1, true) then
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

    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and itemSetText[info.itemID] then
                slotSetText[bag .. ":" .. slot] = itemSetText[info.itemID]
            end
        end
    end

    for bag = 6, 12 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and itemSetText[info.itemID] then
                slotSetText[bag .. ":" .. slot] = itemSetText[info.itemID]
            end
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
    local text = key and slotSetText[key]
    local label = button.EquipmentSetLabelsLabel

    if text then
        if not label then
            label = button:CreateFontString(nil, "OVERLAY")
            label:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
            label:SetPoint("CENTER")
            label:SetTextColor(1, 0.82, 0)
            button.EquipmentSetLabelsLabel = label
        end
        label:SetText(text)
        label:Show()
    elseif label then
        label:Hide()
    end
end

local function UpdateFrames()
    local db = EquipmentSetLabelsDB or defaults

    for i = 1, 13 do
        local frame = _G["ContainerFrame" .. i]
        if frame and frame:IsShown() and frame.Items then
            for _, button in pairs(frame.Items) do
                if button.GetBagID then
                    local bagID = button:GetBagID()
                    local isBank = bagID >= 6
                    local enabled = isBank and db.showBank or db.showBags
                    UpdateButton(button, enabled and (bagID .. ":" .. button:GetID()) or nil)
                end
            end
        end
    end

    if ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() and ContainerFrameCombinedBags.Items then
        for _, button in pairs(ContainerFrameCombinedBags.Items) do
            if button.GetBagID then
                UpdateButton(button, db.showBags and (button:GetBagID() .. ":" .. button:GetID()) or nil)
            end
        end
    end

    if BankFrame and BankFrame:IsShown() then
        for button in BankFrame.BankPanel:EnumerateValidItems() do
            UpdateButton(button, db.showBank and (button:GetBankTabID() .. ":" .. button:GetContainerSlotID()) or nil)
        end
    end

    if CharacterFrame and CharacterFrame:IsShown() then
        for _, slot in ipairs(EQUIP_SLOTS) do
            local button = _G[slot.button]
            if button then
                UpdateButton(button, db.showCharacter and ("e" .. slot.id) or nil)
            end
        end
    end
end

local function ScheduleUpdate()
    if pending then return end
    pending = true
    C_Timer.After(0.1, function()
        pending = false
        ScanSlots()
        UpdateFrames()
    end)
end

local function CreateOptionsPanel()
    local panel = CreateFrame("Frame")
    panel.name = DISPLAY_NAME

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 10, -16)
    title:SetText(DISPLAY_NAME)
    title:SetTextColor(1, 1, 1)

    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPRIGHT", -30, -16)
    resetBtn:SetSize(100, 22)
    resetBtn:SetText("Defaults")
    resetBtn:SetScript("OnClick", function()
        for k, v in pairs(defaults) do
            EquipmentSetLabelsDB[k] = v
        end
        for _, cb in ipairs(checkboxes) do
            cb:SetChecked(EquipmentSetLabelsDB[cb.dbKey])
        end
        ScheduleUpdate()
    end)

    local divider = panel:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", 10, -48)
    divider:SetPoint("TOPRIGHT", -30, -48)
    divider:SetColorTexture(0.6, 0.6, 0.6, 0.4)

    local function AddCheckbox(label, dbKey, yOffset)
        local text = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        text:SetPoint("TOPLEFT", 40, yOffset)
        text:SetText(label)
        text:SetTextColor(1, 0.82, 0)

        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("LEFT", text, "LEFT", 220, 0)
        check:SetScript("OnClick", function(self)
            EquipmentSetLabelsDB[dbKey] = self:GetChecked()
            ScheduleUpdate()
        end)
        check.dbKey = dbKey
        return check
    end

    checkboxes[1] = AddCheckbox("Show in bags", "showBags", -70)
    checkboxes[2] = AddCheckbox("Show in bank", "showBank", -106)
    checkboxes[3] = AddCheckbox("Show on equipped", "showCharacter", -142)

    return panel
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("EQUIPMENT_SETS_CHANGED")
events:RegisterEvent("BAG_UPDATE")
events:RegisterEvent("BANKFRAME_OPENED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        EquipmentSetLabelsDB = EquipmentSetLabelsDB or {}
        for k, v in pairs(defaults) do
            if EquipmentSetLabelsDB[k] == nil then
                EquipmentSetLabelsDB[k] = v
            end
        end
        local panel = CreateOptionsPanel()
        optionsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(optionsCategory)
        for _, cb in ipairs(checkboxes) do
            cb:SetChecked(EquipmentSetLabelsDB[cb.dbKey])
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "EQUIPMENT_SETS_CHANGED" then
        RebuildItemSetCache()
        ScheduleUpdate()
    else
        ScheduleUpdate()
    end
end)

hooksecurefunc("ToggleAllBags", ScheduleUpdate)
hooksecurefunc("OpenAllBags", ScheduleUpdate)
hooksecurefunc("ToggleCharacter", ScheduleUpdate)

SLASH_EQUIPMENTSETLABELS1 = "/esl"
SLASH_EQUIPMENTSETLABELS2 = "/equipsetlabels"
SlashCmdList["EQUIPMENTSETLABELS"] = function()
    if optionsCategory then
        Settings.OpenToCategory(optionsCategory:GetID())
    end
end

hooksecurefunc(BankFrame.BankPanel, "GenerateItemSlotsForSelectedTab", ScheduleUpdate)
