local ADDON_NAME, addon = ...
local UndauntedWidgets = {}
addon.UndauntedWidgets = UndauntedWidgets

local ACCENT_R, ACCENT_G, ACCENT_B = 1.0, 0.525, 0.282

-- Just in cases need?
-- Instead using WoW default Frame, decided to make coustom one.
local function CreateBackdrop(frame, r, g, b, a, borderR, borderG, borderB)
    if not frame.SetBackdrop then
        local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        bg:SetAllPoints()
        bg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        bg:SetBackdropColor(r or 0.12, g or 0.12, b or 0.12, a or 1)
        bg:SetBackdropBorderColor(borderR or 0.3, borderG or 0.3, borderB or 0.3)
        frame.backdropFrame = bg
        return bg
    end
    
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    frame:SetBackdropColor(r or 0.12, g or 0.12, b or 0.12, a or 1)
    frame:SetBackdropBorderColor(borderR or 0.3, borderG or 0.3, borderB or 0.3)
    return frame
end

function UndauntedWidgets:LayoutVertical(parent, widgets, spacing)
    spacing = spacing or 12
    local previous
    for _, child in ipairs(widgets) do
        child:ClearAllPoints()
        if not previous then
            child:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
        else
            child:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -spacing)
        end
        previous = child
    end
end

function UndauntedWidgets:Checkbox(parent, entry, details)
    local container = CreateFrame("Button", nil, parent)
    container:SetSize(300, 26)
    
    container:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
    container:GetHighlightTexture():SetColorTexture(1, 1, 1, 0.05)
    
    local box = CreateFrame("Frame", nil, container, "BackdropTemplate")
    box:SetSize(18, 18)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    box:SetBackdropColor(0.08, 0.08, 0.08, 1)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    local check = box:CreateTexture(nil, "OVERLAY")
    check:SetAllPoints()
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetTexCoord(0.14, 0.86, 0.14, 0.86)
    check:SetVertexColor(ACCENT_R, ACCENT_G, ACCENT_B)
    check:Hide()
    
    local isChecked = entry.getter(details)
    if isChecked then check:Show() end
    
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", box, "RIGHT", 10, 0)
    label:SetText(entry.label)
    label:SetTextColor(0.85, 0.85, 0.85)
    
    container:SetScript("OnEnter", function()
        box:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
        label:SetTextColor(1, 1, 1)
    end)
    
    container:SetScript("OnLeave", function()
        if not isChecked then
            box:SetBackdropBorderColor(0.4, 0.4, 0.4)
        else
            box:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
        end
        label:SetTextColor(0.85, 0.85, 0.85)
    end)
    
    container:SetScript("OnClick", function()
        isChecked = not isChecked
        entry.setter(details, isChecked)
        
        if isChecked then
            check:Show()
            box:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
        else
            check:Hide()
            box:SetBackdropBorderColor(0.4, 0.4, 0.4)
        end
    end)
    
    container.Box = box
    container.Check = check
    return container
end

function UndauntedWidgets:Slider(parent, entry, details)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(350, 55)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(entry.label)
    label:SetTextColor(0.85, 0.85, 0.85)
    
    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("TOPRIGHT", 0, 0)
    valueText:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)
    
    local track = CreateFrame("Frame", nil, container, "BackdropTemplate")
    track:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -10)
    track:SetSize(280, 6)
    track:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = nil,
        edgeSize = 0
    })
    track:SetBackdropColor(0.08, 0.08, 0.08, 1)
    
    track.border = track:CreateTexture(nil, "BORDER")
    track.border:SetPoint("TOPLEFT", -1, 1)
    track.border:SetPoint("BOTTOMRIGHT", 1, -1)
    track.border:SetColorTexture(0.3, 0.3, 0.3, 1)
    
    local fill = track:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT")
    fill:SetHeight(6)
    fill:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.8)
    
    local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
    thumb:SetSize(14, 20)
    thumb:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    thumb:SetBackdropColor(0.2, 0.2, 0.2, 1)
    thumb:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    local glow = thumb:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("TOPLEFT", -4, 4)
    glow:SetPoint("BOTTOMRIGHT", 4, -4)
    glow:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0)
    
    local rangeText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rangeText:SetPoint("TOPLEFT", track, "BOTTOMLEFT", 0, -6)
    rangeText:SetText(entry.min .. " — " .. entry.max)
    rangeText:SetTextColor(0.5, 0.5, 0.5)
    
    local min, max = entry.min, entry.max
    local step = entry.step or 1
    
    local function UpdateValue(value)
        value = math.max(min, math.min(max, value))
        if step < 1 then
            value = tonumber(string.format("%.2f", value))
        else
            value = math.floor(value + 0.5)
        end
        
        local pct = (value - min) / (max - min)
        fill:SetWidth(280 * pct)
        thumb:SetPoint("CENTER", track, "LEFT", 280 * pct, 0)
        valueText:SetText(value)
        
        entry.setter(details, value)
    end
    
    local currentValue = entry.getter(details)
    UpdateValue(currentValue)
    
    local isDragging = false
    
    thumb:SetScript("OnMouseDown", function()
        isDragging = true
        thumb:SetBackdropColor(0.25, 0.25, 0.25, 1)
        thumb:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
        glow:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)
    end)
    
    thumb:SetScript("OnMouseUp", function()
        isDragging = false
        thumb:SetBackdropColor(0.2, 0.2, 0.2, 1)
        thumb:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        glow:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0)
    end)
    
    track:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            isDragging = true
            thumb:SetBackdropColor(0.25, 0.25, 0.25, 1)
        end
    end)
    
    container:SetScript("OnUpdate", function()
        if isDragging then
            local x = GetCursorPosition()
            local scale = track:GetEffectiveScale()
            local left = track:GetLeft() * scale
            local width = track:GetWidth() * scale
            local pct = math.max(0, math.min(1, (x - left) / width))
            local value = min + (max - min) * pct
            UpdateValue(value)
        end
    end)
    
    container:SetScript("OnMouseUp", function()
        isDragging = false
        thumb:SetBackdropColor(0.2, 0.2, 0.2, 1)
        thumb:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        glow:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0)
    end)
    
    thumb:SetScript("OnEnter", function()
        if not isDragging then
            thumb:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
        end
    end)
    
    thumb:SetScript("OnLeave", function()
        if not isDragging then
            thumb:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        end
    end)
    
    container.Slider = thumb
    return container
end

function UndauntedWidgets:Dropdown(parent, entry, details)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(300, 55)
    
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(entry.label)
    label:SetTextColor(0.85, 0.85, 0.85)
    
    local dropdown = CreateFrame("Button", nil, container, "BackdropTemplate")
    dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -8)
    dropdown:SetSize(240, 28)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    dropdown:SetBackdropColor(0.08, 0.08, 0.08, 1)
    dropdown:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    local text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", 10, 0)
    text:SetTextColor(0.9, 0.9, 0.9)
    
    local arrow = dropdown:CreateTexture(nil, "ARTWORK")
    arrow:SetPoint("RIGHT", -8, 0)
    arrow:SetSize(12, 12)
    arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    arrow:SetTexCoord(0.3, 0.7, 0.3, 0.7)
    arrow:SetVertexColor(0.7, 0.7, 0.7)
    
    local menu = nil
    local labels, values = entry.getInitData(details)
    local current = entry.getter(details)
    local selectedIndex = 1
    
    for i, v in ipairs(values) do
        if v == current then
            selectedIndex = i
            break
        end
    end
    text:SetText(labels[selectedIndex] or "")
    
    dropdown:SetScript("OnEnter", function()
        dropdown:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
        arrow:SetVertexColor(1, 1, 1)
    end)
    
    dropdown:SetScript("OnLeave", function()
        if not (menu and menu:IsShown()) then
            dropdown:SetBackdropBorderColor(0.4, 0.4, 0.4)
            arrow:SetVertexColor(0.7, 0.7, 0.7)
        end
    end)
    
    dropdown:SetScript("OnClick", function()
        if menu and menu:IsShown() then
            menu:Hide()
            return
        end
        
        if not menu then
            menu = CreateFrame("Frame", nil, dropdown, "BackdropTemplate")
            menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
            menu:SetWidth(240)
            menu:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = {left = 1, right = 1, top = 1, bottom = 1}
            })
            menu:SetBackdropColor(0.1, 0.1, 0.1, 1)
            menu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            local buttons = {}
            local menuHeight = 4
            
            for i, labelText in ipairs(labels) do
                local btn = CreateFrame("Button", nil, menu)
                btn:SetPoint("TOPLEFT", 4, -menuHeight)
                btn:SetSize(232, 24)
                
                btn.bg = btn:CreateTexture(nil, "BACKGROUND")
                btn.bg:SetAllPoints()
                btn.bg:SetColorTexture(0, 0, 0, 0)
                
                btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                btn.text:SetPoint("LEFT", 8, 0)
                btn.text:SetText(labelText)
                btn.text:SetTextColor(0.8, 0.8, 0.8)
                
                btn:SetScript("OnEnter", function()
                    btn.bg:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.2)
                    btn.text:SetTextColor(1, 1, 1)
                end)
                
                btn:SetScript("OnLeave", function()
                    if i ~= selectedIndex then
                        btn.bg:SetColorTexture(0, 0, 0, 0)
                        btn.text:SetTextColor(0.8, 0.8, 0.8)
                    else
                        btn.bg:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)
                        btn.text:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)
                    end
                end)
                
                btn:SetScript("OnClick", function()
                    selectedIndex = i
                    text:SetText(labelText)
                    entry.setter(details, values[i])
                    
                    for j, b in ipairs(buttons) do
                        if j == i then
                            b.bg:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)
                            b.text:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)
                        else
                            b.bg:SetColorTexture(0, 0, 0, 0)
                            b.text:SetTextColor(0.8, 0.8, 0.8)
                        end
                    end
                    
                    menu:Hide()
                end)
                
                buttons[i] = btn
                menuHeight = menuHeight + 26
            end
            
            menu:SetHeight(menuHeight)
            menu.buttons = buttons
            
            menu:SetScript("OnHide", function()
                dropdown:SetBackdropBorderColor(0.4, 0.4, 0.4)
                arrow:SetVertexColor(0.7, 0.7, 0.7)
            end)
        end
        
        for i, btn in ipairs(menu.buttons) do
            if i == selectedIndex then
                btn.bg:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)
                btn.text:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)
            else
                btn.bg:SetColorTexture(0, 0, 0, 0)
                btn.text:SetTextColor(0.8, 0.8, 0.8)
            end
        end
        
        menu:Show()
    end)
    
    dropdown:SetScript("OnHide", function()
        if menu then menu:Hide() end
    end)
    
    container.Dropdown = dropdown
    return container
end

function UndauntedWidgets:ColorPicker(parent, entry, details)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(120, 30)
    
    local btn = CreateFrame("Button", nil, container, "BackdropTemplate")
    btn:SetAllPoints()
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    btn:SetBackdropColor(0.08, 0.08, 0.08, 1)
    btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", 0, 0)
    label:SetText(entry.label)
    label:SetTextColor(0.9, 0.9, 0.9)
    
    local swatch = btn:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("RIGHT", -8, 0)
    swatch:SetSize(14, 14)
    
    local function UpdateSwatch()
        local color = details[entry.key] or {r=1, g=1, b=1, a=1}
        swatch:SetColorTexture(color.r, color.g, color.b, color.a or 1)
    end
    UpdateSwatch()
    
    local swatchBorder = btn:CreateTexture(nil, "BORDER")
    swatchBorder:SetPoint("TOPLEFT", swatch, "TOPLEFT", -1, 1)
    swatchBorder:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", 1, -1)
    swatchBorder:SetColorTexture(0.3, 0.3, 0.3, 1)
    
    btn:SetScript("OnEnter", function()
        btn:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
        label:SetTextColor(1, 1, 1)
    end)
    
    btn:SetScript("OnLeave", function()
        btn:SetBackdropBorderColor(0.4, 0.4, 0.4)
        label:SetTextColor(0.9, 0.9, 0.9)
    end)
    
    btn:SetScript("OnClick", function()
        local color = details[entry.key] or {r=1, g=1, b=1, a=1}
        
        local function ColorChanged()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame:GetColorAlpha()
            if entry.onChange then 
                entry.onChange(details, r, g, b, a) 
            end
            UpdateSwatch()
        end
        
        ColorPickerFrame.func = ColorChanged
        ColorPickerFrame.cancelFunc = function()
            local prev = ColorPickerFrame.previousValues
            if entry.onChange then 
                entry.onChange(details, prev.r, prev.g, prev.b, prev.a) 
            end
            UpdateSwatch()
        end
        ColorPickerFrame.swatchFunc = ColorChanged
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = color.a or 1
        ColorPickerFrame.opacityFunc = function()
            local a = ColorPickerFrame:GetColorAlpha()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            if entry.onChangeAlpha then
                entry.onChangeAlpha(details, a)
            elseif entry.onChange then
                entry.onChange(details, r, g, b, a)
            end
            UpdateSwatch()
        end
        
        ColorPickerFrame.previousValues = {r=color.r, g=color.g, b=color.b, a=color.a or 1}
        
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()

        if ColorPickerFrame.SetColorRGB then
            ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
        elseif ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
            ColorPickerFrame.Content.ColorPicker:SetColorRGB(color.r, color.g, color.b)
        elseif ColorPickerFrame.GetColorPicker then
            ColorPickerFrame:GetColorPicker():SetColorRGB(color.r, color.g, color.b)
        end
        
        if ColorPickerFrame.SetColorAlpha then
            ColorPickerFrame:SetColorAlpha(color.a or 1)
        elseif ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker then
            ColorPickerFrame.Content.ColorPicker:SetColorAlpha(color.a or 1)
        end
    end)
    
    container.Button = btn
    return container
end

function UndauntedWidgets:Button(parent, entry)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText(entry.label or "Button")
    btn.text:SetTextColor(0.9, 0.9, 0.9)
    
    local textWidth = btn.text:GetStringWidth()
    local width = entry.width or math.max(100, textWidth + 28)
    local height = entry.height or 28
    btn:SetSize(width, height)
    
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    btn:SetBackdropColor(0.3, 0.3, 0.3, 1)
    btn:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
    
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.1)
    btn.highlight:Hide()
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
        self.text:SetTextColor(1, 1, 1)
        self.highlight:Show()
    end)
    
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.3, 0.3, 0.3, 1)
        self:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
        self.text:SetTextColor(0.9, 0.9, 0.9)
        self.highlight:Hide()
    end)
    
    btn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.06, 0.06, 0.06, 1)
        local x, y = self:GetCenter()
        local parentX, parentY = self:GetParent():GetCenter()
        self:SetPoint("CENTER", self:GetParent(), "CENTER", (x - parentX) + 1, (y - parentY) - 1)
    end)
    
    btn:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
        local x, y = self:GetCenter()
        local parentX, parentY = self:GetParent():GetCenter()
        self:SetPoint("CENTER", self:GetParent(), "CENTER", x - parentX, y - parentY)
    end)
    
    if entry.onClick then
        btn:SetScript("OnClick", entry.onClick)
    end
    
    return btn
end

function UndauntedWidgets:EditBox(parent, entry)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(entry.width or 500, entry.height or 150)
    
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(entry.label or "")
    label:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)
    
    local bg = CreateFrame("Frame", nil, container, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    bg:SetPoint("BOTTOMRIGHT", 0, 0)
    bg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    bg:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    bg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    local edit = CreateFrame("EditBox", nil, bg)
    edit:SetPoint("TOPLEFT", 6, -6)
    edit:SetPoint("BOTTOMRIGHT", -6, 6)
    edit:SetFontObject(GameFontHighlight)
    edit:SetAutoFocus(false)
    edit:SetMultiLine(true)
    edit:SetMaxLetters(entry.maxLetters or 4000)
    edit:SetText(entry.default or "")
    edit:SetJustifyH("LEFT")
    edit:SetJustifyV("TOP")
    edit:SetTextInsets(4, 4, 4, 4)
    edit:SetCursorPosition(0)
    
    edit:SetScript("OnEditFocusGained", function()
        bg:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
    end)
    
    edit:SetScript("OnEditFocusLost", function()
        bg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)
    
    edit:SetScript("OnEscapePressed", function(self) 
        self:ClearFocus() 
    end)
    
    container.EditBox = edit
    container.Background = bg
    return container
end

function UndauntedWidgets:NotesContainer(parent, leftWidth, topHeight, bottomHeight)
    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints(parent)
    
    local profiles = {}
    local currentNoteIndex = nil
    local leftPanelWidth = leftWidth or 150
    
    local function GetNotesDB()
        if not UndauntedDB.notes then
            UndauntedDB.notes = {}
        end
        return UndauntedDB.notes
    end
    
    local profileList = CreateFrame("Frame", nil, container, "BackdropTemplate")
    profileList:SetPoint("TOPLEFT", 5, -5)
    profileList:SetPoint("BOTTOMLEFT", 5, 5)
    profileList:SetWidth(leftPanelWidth)
    profileList:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    profileList:SetBackdropColor(0.06, 0.06, 0.06, 1)
    profileList:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    
    local profileScroll = CreateFrame("ScrollFrame", nil, profileList, "UIPanelScrollFrameTemplate")
    profileScroll:SetPoint("TOPLEFT", 6, -6)
    profileScroll:SetPoint("BOTTOMRIGHT", -26, 38)
    
    local profileContent = CreateFrame("Frame")
    profileContent:SetSize(1, 1)
    profileScroll:SetScrollChild(profileContent)
    
    local addBtn = self:Button(profileList, {
        label = "+ Add Note",
        width = leftPanelWidth - 20,
        height = 26
    })
    addBtn:SetPoint("BOTTOM", 0, 6)
    addBtn:SetScript("OnClick", function()
        container:SaveCurrentNote()
        container:CreateNewNote()
    end)
    
    local rightOffset = leftPanelWidth + 15
    
    local nameLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", container, "TOPLEFT", rightOffset, -10)
    nameLabel:SetText("Note Name:")
    nameLabel:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)
    
    local nameEdit = CreateFrame("EditBox", nil, container, "BackdropTemplate")
    nameEdit:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -6)
    nameEdit:SetPoint("RIGHT", -5, 0)
    nameEdit:SetHeight(28)
    nameEdit:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    nameEdit:SetBackdropColor(0.06, 0.06, 0.06, 1)
    nameEdit:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    nameEdit:SetFontObject("GameFontHighlight")
    nameEdit:SetTextColor(1, 1, 1)
    nameEdit:SetAutoFocus(false)
    nameEdit:SetMaxLetters(14)
    nameEdit:SetText("New Note")
    nameEdit:SetTextInsets(8, 8, 0, 0)
    
    nameEdit:SetScript("OnEditFocusGained", function()
        nameEdit:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
    end)
    nameEdit:SetScript("OnEditFocusLost", function()
        nameEdit:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)
    nameEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    local formatBar = CreateFrame("Frame", nil, container, "BackdropTemplate")
    formatBar:SetPoint("TOPLEFT", nameEdit, "BOTTOMLEFT", 0, -10)
    formatBar:SetPoint("RIGHT", -5, 0)
    formatBar:SetHeight(32)
    formatBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    formatBar:SetBackdropColor(0.06, 0.06, 0.06, 1)
    formatBar:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    
    local editLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editLabel:SetPoint("TOPLEFT", formatBar, "BOTTOMLEFT", 0, -10)
    editLabel:SetText("Note Content:")
    editLabel:SetTextColor(0.6, 0.6, 0.6)
    
    local editWrapper = CreateFrame("Frame", nil, container, "BackdropTemplate")
    editWrapper:SetPoint("TOPLEFT", editLabel, "BOTTOMLEFT", 0, -6)
    editWrapper:SetPoint("RIGHT", -5, 0)
    editWrapper:SetPoint("BOTTOM", 0, 42)
    editWrapper:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    editWrapper:SetBackdropColor(0.04, 0.04, 0.06, 0.95)
    editWrapper:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    
    local editBox = CreateFrame("EditBox", nil, editWrapper)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlight)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(4000)
    editBox:SetPoint("TOPLEFT", 8, -8)
    editBox:SetPoint("BOTTOMRIGHT", -8, 8)
    editBox:SetTextInsets(4, 4, 4, 4)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetText("")
    
    editBox:SetScript("OnEditFocusGained", function()
        editWrapper:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
    end)
    editBox:SetScript("OnEditFocusLost", function()
        editWrapper:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    end)
    
    local formatButtons = {
        {icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t", text = "{rt1}"},
        {icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t", text = "{rt2}"},
        {icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t", text = "{rt3}"},
        {icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t", text = "{rt4}"},
        {icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t", text = "{rt5}"},
        {icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t", text = "{rt6}"},
        {icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t", text = "{rt7}"},
        {icon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t", text = "{rt8}"},
        {icon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:22:41|t", text = "{dps}"},
        {icon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:0:19:22:41|t", text = "{tank}"},
        {icon = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES:0:0:0:0:64:64:20:39:1:20|t", text = "{healer}"},
    }
    
    local lastBtn
    for _, data in ipairs(formatButtons) do
        local btn = CreateFrame("Button", nil, formatBar, "BackdropTemplate")
        btn:SetSize(26, 26)
        if not lastBtn then
            btn:SetPoint("LEFT", formatBar, "TOPLEFT", 6, -16)
        else
            btn:SetPoint("LEFT", lastBtn, "RIGHT", 3, 0)
        end
        
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER", 0, 0)
        btn.text:SetText(data.icon)
        
        btn:SetScript("OnEnter", function()
            btn:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B)
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropBorderColor(0.3, 0.3, 0.3)
        end)
        btn:SetScript("OnClick", function()
            local cur = editBox:GetText()
            local pos = editBox:GetCursorPosition()
            local newText = cur:sub(1, pos) .. data.text .. cur:sub(pos + 1)
            editBox:SetText(newText)
            editBox:SetCursorPosition(pos + #data.text)
            editBox:SetFocus()
        end)
        
        lastBtn = btn
    end
    
    local sep = formatBar:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("LEFT", lastBtn, "RIGHT", 8, 0)
    sep:SetSize(2, 20)
    sep:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    lastBtn = sep
    
    local function CreatePlayerButtons()
        if formatBar.playerButtons then
            for _, btn in ipairs(formatBar.playerButtons) do
                btn:Hide()
                btn:SetParent(nil)
            end
        end
        formatBar.playerButtons = {}
        
        local players = {}
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local unit = "raid" .. i
                local name = UnitName(unit)
                local _, class = UnitClass(unit)
                if name and class then
                    table.insert(players, {name = name, class = class})
                end
            end
        elseif IsInGroup() then
            for i = 1, GetNumGroupMembers() - 1 do
                local unit = "party" .. i
                local name = UnitName(unit)
                local _, class = UnitClass(unit)
                if name and class then
                    table.insert(players, {name = name, class = class})
                end
            end
            local playerName = UnitName("player")
            local _, playerClass = UnitClass("player")
            table.insert(players, {name = playerName, class = playerClass})
        end
        
        table.sort(players, function(a, b) return a.name < b.name end)
        
        local barWidth = formatBar:GetWidth() - 12
        local buttonWidth = 70
        local buttonHeight = 22
        local spacing = 4

        local symbolRowHeight = 32
        local maxButtonsPerRow = math.floor(barWidth / (buttonWidth + spacing))
        
        for i, player in ipairs(players) do
            local color = C_ClassColor.GetClassColor(player.class)
            local hexColor = string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
            
            local col = (i - 1) % maxButtonsPerRow
            local row = math.floor((i - 1) / maxButtonsPerRow)
            
            local btn = CreateFrame("Button", nil, formatBar, "BackdropTemplate")
            btn:SetSize(buttonWidth, buttonHeight)
            btn:SetFrameLevel(formatBar:GetFrameLevel() + 2)
            
            local xOffset = 6 + (col * (buttonWidth + spacing))
            local yOffset = -symbolRowHeight - 2 - (row * (buttonHeight + spacing))
            
            btn:SetPoint("TOPLEFT", formatBar, "TOPLEFT", xOffset, yOffset)
            
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
                insets = {left = 1, right = 1, top = 1, bottom = 1}
            })
            btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
            btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.text:SetPoint("CENTER", 0, 0)
            btn.text:SetText(hexColor .. player.name .. "|r")
            
            btn:SetScript("OnEnter", function()
                btn:SetBackdropBorderColor(color.r, color.g, color.b)
            end)
            btn:SetScript("OnLeave", function()
                btn:SetBackdropBorderColor(0.3, 0.3, 0.3)
            end)
            btn:SetScript("OnClick", function()
                local text = hexColor .. player.name .. "|r"
                local cur = editBox:GetText()
                local pos = editBox:GetCursorPosition()
                local newText = cur:sub(1, pos) .. text .. cur:sub(pos + 1)
                editBox:SetText(newText)
                editBox:SetCursorPosition(pos + #text - 10)
                editBox:SetFocus()
            end)
            
            table.insert(formatBar.playerButtons, btn)
        end

        local numRows = math.max(1, math.ceil(#players / maxButtonsPerRow))
        local newHeight = symbolRowHeight + 2 + (numRows * (buttonHeight + spacing))
        
        formatBar:SetHeight(newHeight)
        
        editLabel:ClearAllPoints()
        editLabel:SetPoint("TOPLEFT", formatBar, "BOTTOMLEFT", 0, -8)
    end
    
    CreatePlayerButtons()
    formatBar:RegisterEvent("GROUP_ROSTER_UPDATE")
    formatBar:SetScript("OnEvent", CreatePlayerButtons)
    
    local deleteBtn = self:Button(container, {
        label = "Delete",
        width = 80,
        height = 26
    })
    deleteBtn:SetPoint("BOTTOMLEFT", rightOffset, 6)
    deleteBtn:SetScript("OnClick", function()
        container:DeleteCurrentNote()
    end)
    
    local sendBtn = self:Button(container, {
        label = "Send to Raid",
        width = 120,
        height = 26
    })
    sendBtn:SetPoint("BOTTOMRIGHT", -5, 6)
    sendBtn:SetScript("OnClick", function()
        container:SendToRaid()
    end)
    
    local saveBtn = self:Button(container, {
        label = "Save",
        width = 80,
        height = 26
    })
    saveBtn:SetPoint("RIGHT", sendBtn, "LEFT", -8, 0)
    saveBtn:SetScript("OnClick", function()
        container:SaveCurrentNote()
    end)
    
    function container:AddProfileButton(name, index)
        local btn = CreateFrame("Button", nil, profileContent)
        btn:SetSize(leftPanelWidth - 35, 28)
        
        if index == 1 then
            btn:SetPoint("TOPLEFT", 0, 0)
        else
            btn:SetPoint("TOPLEFT", profiles[index-1], "BOTTOMLEFT", 0, -2)
        end
        
        btn.noteIndex = index
        
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0, 0, 0, 0)
        
        btn.hover = btn:CreateTexture(nil, "BACKGROUND")
        btn.hover:SetAllPoints()
        btn.hover:SetColorTexture(1, 1, 1, 0.05)
        btn.hover:Hide()
        
        btn.selected = btn:CreateTexture(nil, "BACKGROUND")
        btn.selected:SetAllPoints()
        btn.selected:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.25)
        btn.selected:Hide()
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("LEFT", 10, 0)
        btn.text:SetText(name)
        btn.text:SetTextColor(0.7, 0.7, 0.7)
        
        btn:SetScript("OnEnter", function(self)
            if self ~= container.activeProfileBtn then
                self.hover:Show()
                self.text:SetTextColor(0.9, 0.9, 0.9)
            end
        end)
        
        btn:SetScript("OnLeave", function(self)
            self.hover:Hide()
            if self ~= container.activeProfileBtn then
                self.text:SetTextColor(0.7, 0.7, 0.7)
            end
        end)
        
        btn:SetScript("OnClick", function(self)
            container:LoadNote(index)
        end)
        
        profiles[index] = btn
        return btn
    end
    
    function container:CreateNewNote()
        if currentNoteIndex then
            container:SaveCurrentNote()
        end
        nameEdit:SetText("New Note " .. (#GetNotesDB() + 1))
        editBox:SetText("")
        currentNoteIndex = nil
        container.activeProfileBtn = nil
        container:RefreshProfileList()
        nameEdit:SetFocus()
    end
    
    function container:SaveCurrentNote()
        local noteName = nameEdit:GetText()
        local noteContent = editBox:GetText()
        
        if noteName == "" then
            addon.Logger:Error("Note name cannot be empty!")
            return
        end
        
        local notes = GetNotesDB()
        
        if currentNoteIndex and notes[currentNoteIndex] then
            notes[currentNoteIndex].name = noteName
            notes[currentNoteIndex].content = noteContent
            notes[currentNoteIndex].modified = time()
        else
            table.insert(notes, {
                name = noteName,
                content = noteContent,
                created = time(),
                modified = time()
            })
            currentNoteIndex = #notes
        end
        
        container:RefreshProfileList()
        container:SelectProfileButton(currentNoteIndex)
    end
    
    function container:LoadNote(index)
        local notes = GetNotesDB()
        local note = notes[index]
        if not note then return end
        
        currentNoteIndex = index
        nameEdit:SetText(note.name)
        editBox:SetText(note.content or "")
        container:SelectProfileButton(index)
    end
    
    function container:DeleteCurrentNote()
        local notes = GetNotesDB()
        
        if not currentNoteIndex then
            local noteName = nameEdit:GetText()
            for i, note in ipairs(notes) do
                if note.name == noteName then
                    currentNoteIndex = i
                    break
                end
            end
        end
        
        if not currentNoteIndex or not notes[currentNoteIndex] then
            addon.Logger:Error("No note selected to delete!")
            return
        end
        
        local noteName = notes[currentNoteIndex].name
        table.remove(notes, currentNoteIndex)
        addon.Logger:Info("Deleted note '" .. noteName .. "'")
        
        currentNoteIndex = nil
        container.activeProfileBtn = nil
        nameEdit:SetText("")
        editBox:SetText("")
        container:RefreshProfileList()
        
        local updatedNotes = GetNotesDB()
        if #updatedNotes > 0 then
            container:LoadNote(1)
        else
            container:CreateNewNote()
        end
    end
    
    function container:SendToRaid()
        if not (UnitIsGroupLeader("player") or (IsInRaid() and UnitIsGroupAssistant("player"))) then
            addon.Logger:Error("You need leader or assistant permissions!")
            return
        end
        
        local noteName = nameEdit:GetText()
        local noteContent = editBox:GetText()
        
        if noteContent == "" then
            addon.Logger:Error("Note is empty!")
            return
        end
        
        if not IsInRaid() and not IsInGroup() then
            addon.Logger:Error("Not in a group!")
            return
        end
        
        local channel = IsInRaid() and "RAID" or "PARTY"
        local prefix = "UNDAUNTED_NOTE"
        
        local chunks = {}
        local maxChunkSize = 200
        
        for i = 1, #noteContent, maxChunkSize do
            table.insert(chunks, noteContent:sub(i, i + maxChunkSize - 1))
        end
        
        C_ChatInfo.SendAddonMessage(prefix, prefix.."~HEADER~"..noteName.."~"..#chunks, channel)
        
        for i, chunk in ipairs(chunks) do
            local msg = string.format("%s~CHUNK~%d~%s", prefix, i, chunk)
            C_ChatInfo.SendAddonMessage(prefix, msg, channel)
        end
        
        addon.Logger:Success(string.format("Sent note '%s' in %d chunks", noteName, #chunks))
    end
    
    function container:RefreshProfileList()
        for _, btn in ipairs(profiles) do
            btn:Hide()
            btn:SetParent(nil)
        end
        wipe(profiles)
        
        local notes = GetNotesDB()
        for i, note in ipairs(notes) do
            container:AddProfileButton(note.name, i)
        end
        
        profileContent:SetHeight(math.max(#notes * 30, 10))
    end
    
    function container:SelectProfileButton(index)
        for i, btn in ipairs(profiles) do
            if btn.noteIndex == index or i == index then
                btn.selected:Show()
                btn.text:SetTextColor(1, 1, 1)
                btn.hover:Hide()
                container.activeProfileBtn = btn
            else
                btn.selected:Hide()
                btn.text:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end
    
    function container:GetCurrentNote()
        return nameEdit:GetText(), editBox:GetText()
    end
    
    C_Timer.After(0.1, function()
        local notes = GetNotesDB()
        if #notes > 0 then
            container:LoadNote(1)
        else
            container:CreateNewNote()
        end
        container:RefreshProfileList()
    end)
    
    container.EditBox = editBox
    container.NameEdit = nameEdit
    container.ProfileList = profileList
    container.Profiles = profiles
    container.SaveBtn = saveBtn
    container.SendBtn = sendBtn
    container.DeleteBtn = deleteBtn
    
    return container
end