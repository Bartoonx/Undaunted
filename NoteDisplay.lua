local ADDON_NAME, addon = ...

local NoteDisplay = {}
addon.NoteDisplay = NoteDisplay

local displayFrame = nil
local currentDisplayNote = nil
local isInit = false

local function GetSettings()
    return UndauntedDB.noteDisplay
end

function NoteDisplay:Init()
    if displayFrame then return end
    
    local cfg = GetSettings()
    
    displayFrame = CreateFrame("Frame", "UndauntedNoteDisplay", UIParent, "BackdropTemplate")
    displayFrame:SetSize(cfg.width or 400, cfg.height or 300)
    displayFrame:SetPoint(cfg.point or "CENTER", cfg.x or 0, cfg.y or 200)
    displayFrame:Hide()
    
    displayFrame:SetMovable(true)
    displayFrame:EnableMouse(true)
    displayFrame:SetResizable(true)
    displayFrame:RegisterForDrag("LeftButton")
    displayFrame:SetScript("OnDragStart", function(self)
        if not cfg.locked then self:StartMoving() end
    end)
    displayFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        cfg.point = point
        cfg.x = x
        cfg.y = y
    end)
    
    displayFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    displayFrame:SetBackdropColor(0, 0, 0, cfg.alpha or 0.8)
    displayFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local header = CreateFrame("Frame", nil, displayFrame)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(24)
    displayFrame.Header = header
    
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("Raid Note")
    displayFrame.Title = title
    
    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", -2, 0)
    closeBtn:SetSize(20, 20)
    closeBtn:SetScript("OnClick", function()
        NoteDisplay:Hide()
        cfg.enabled = false
    end)
    displayFrame.CloseBtn = closeBtn
    
    local lockBtn = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
    lockBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
    lockBtn:SetSize(60, 18)
    lockBtn:SetText(cfg.locked and "Unlock" or "Lock")
    lockBtn:SetScript("OnClick", function(self)
        NoteDisplay:ToggleLock()
    end)
    displayFrame.LockBtn = lockBtn

    local scroll = CreateFrame("ScrollFrame", nil, displayFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    displayFrame.Scroll = scroll
    
    local content = CreateFrame("Frame")
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
    displayFrame.Content = content
   
    local text = content:CreateFontString(nil, "OVERLAY", cfg.font or "GameFontHighlight")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetWidth((cfg.width or 400) - 40)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetSpacing(2)
    displayFrame.Text = text
    
    local resizeBtn = CreateFrame("Button", nil, displayFrame)
    resizeBtn:SetPoint("BOTTOMRIGHT", -4, 4)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeBtn:SetScript("OnMouseDown", function()
        if not cfg.locked then
            displayFrame:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeBtn:SetScript("OnMouseUp", function()
        displayFrame:StopMovingOrSizing()
        cfg.width = displayFrame:GetWidth()
        cfg.height = displayFrame:GetHeight()
    end)
    displayFrame.ResizeBtn = resizeBtn
    
    isInit = true
    
    if cfg.locked then
        self:ApplyLock(true)
    end
end

function NoteDisplay:ApplyLock(locked)
    local cfg = GetSettings()
    cfg.locked = locked
    
    if locked then
        displayFrame:EnableMouse(false)
        displayFrame:SetMovable(false)
        displayFrame:RegisterForDrag()
        displayFrame:SetBackdropBorderColor(0, 1, 0, 1)
        displayFrame.LockBtn:SetText("Unlock")
    else
        displayFrame:EnableMouse(true)
        displayFrame:SetMovable(true)
        displayFrame:RegisterForDrag("LeftButton")
        displayFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        displayFrame.LockBtn:SetText("Lock")
    end
end

function NoteDisplay:ToggleLock()
    self:ApplyLock(not GetSettings().locked)
end

function NoteDisplay:ParseText(text)
    if not text then return "" end
    
    local parsed = text
    
    -- Raid markers
    for i = 1, 8 do
        parsed = parsed:gsub("{rt" .. i .. "}", "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i .. ":0|t")
    end
    
    -- Role icons
    parsed = parsed:gsub("{healer}", "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:22:41|t")
    parsed = parsed:gsub("{tank}", "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:0:19:22:41|t")
    parsed = parsed:gsub("{dps}", "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:1:20|t")
    
    return parsed
end

function NoteDisplay:Show(noteName, noteContent)
    local cfg = GetSettings()
    
    if not cfg.enabled then return end
    
    self:Init()
    
    displayFrame.Title:SetText(noteName or "Raid Note")
    displayFrame.Text:SetText(self:ParseText(noteContent))
    displayFrame.Text:SetWidth(cfg.width - 40)
    
    -- Auto-height if no saved size
    if not cfg.height then
        local textHeight = displayFrame.Text:GetStringHeight()
        local newHeight = math.min(textHeight + 50, 600)
        displayFrame:SetHeight(math.max(newHeight, 100))
    end
    
    currentDisplayNote = noteName
    displayFrame:Show()
end

function NoteDisplay:Hide()
    if displayFrame then
        displayFrame:Hide()
    end
end

function NoteDisplay:Toggle()
    local cfg = GetSettings()
    
    if displayFrame and displayFrame:IsShown() then
        self:Hide()
        cfg.enabled = false
    else
        cfg.enabled = true
        if currentDisplayNote then
            self:Show(currentDisplayNote, nil)
        else
            self:Show("Test Note", "{rt8} Pull at skull\n{tank} Tank picks up adds\n{healer} Healers stack\n\nPhase 2 at 50%!")
        end
    end
end

function NoteDisplay:Preview()
    self:Init()
    
    local cfg = GetSettings()
    local testContent = "{rt1} Star: Mage stack\n{rt2} Circle: Healers\n{rt3} Diamond: Tank\n\n{tank} Tank duties\n{healer} Healer duties\n{dps} DPS duties\n\n|cff00ff00Green text|r |cffff0000Red text|r"
    
    displayFrame:SetBackdropColor(0, 0, 0, cfg.alpha or 0.8)
    displayFrame.Text:SetFontObject(cfg.font or "GameFontHighlight")
    
    self:Show("Preview Note", testContent)

    displayFrame:Show()
end

function NoteDisplay:HidePreview()
    local cfg = GetSettings()
    if not cfg.enabled then
        self:Hide()
    elseif currentDisplayNote then
        self:Show(currentDisplayNote, nil)
    else
        self:Hide()
    end
end

function NoteDisplay:SetWidth(w)
    GetSettings().width = w
    if displayFrame then
        displayFrame:SetWidth(w)
        displayFrame.Text:SetWidth(w - 40)
    end
end

function NoteDisplay:SetHeight(h)
    GetSettings().height = h
    if displayFrame then
        displayFrame:SetHeight(h)
    end
end

function NoteDisplay:SetAlpha(a)
    GetSettings().alpha = a
    if displayFrame then
        displayFrame:SetBackdropColor(0, 0, 0, a)
    end
end

function NoteDisplay:SetFont(font)
    GetSettings().font = font
    if displayFrame then
        displayFrame.Text:SetFontObject(font)
    end
end

function NoteDisplay:ToggleEnable(enable)
    GetSettings().enabled = enable
    if enable then
        self:Init()
        if currentDisplayNote then
            self:Show(currentDisplayNote, nil)
        end
    else
        self:Hide()
    end
end