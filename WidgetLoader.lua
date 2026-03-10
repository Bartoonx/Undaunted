local ADDON_NAME, addon = ...

addon.WidgetLoader = {}

function addon.WidgetLoader:Clear()
    local parent = addon.UI.ScrollContainer
    
    for _, child in ipairs({parent:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    for _, region in ipairs({parent:GetRegions()}) do
        region:Hide()
        region:SetParent(nil)
    end
end

function addon.WidgetLoader:Load(tabID)
    self:Clear()

    local parent = addon.UI.ScrollContainer
    local config = addon.WidgetsConfig[tabID]
    if not config then return end

    local anchors = {}
    local currentRow = 1
    
    for _, section in ipairs(config) do
        local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -50)
        header:SetText(section.label)
        header:Show()
        anchors[currentRow] = header
        currentRow = currentRow + 1
        
        local i = 1
        while i <= #section.entries do
            local entry = section.entries[i]
            local nextEntry = section.entries[i + 1]
                        
            local w1, w2
            if entry.kind == "checkbox" then
                w1 = addon.UndauntedWidgets:Checkbox(parent, entry, UndauntedDB)
            elseif entry.kind == "slider" then
                w1 = addon.UndauntedWidgets:Slider(parent, entry, UndauntedDB)
                w1:SetWidth(220)
            elseif entry.kind == "dropdown" then
                w1 = addon.UndauntedWidgets:Dropdown(parent, entry, UndauntedDB)
            elseif entry.kind == "sep" then
                w1 = addon.UndauntedWidgets:Separator(parent)
            elseif entry.kind == "color" then
                w1 = addon.UndauntedWidgets:ColorPicker(parent, entry, UndauntedDB)
            elseif entry.kind == "button" then
                w1 = addon.UndauntedWidgets:Button(parent, entry)
            end
            
            if w1 then
                local anchor = anchors[currentRow - 1]
                local yOffset = -12
                
                if anchor and anchor.isSlider then
                    yOffset = -28
                end
                
                if entry.kind == "sep" then
                    w1:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -15)
                    w1:SetPoint("RIGHT", parent, "RIGHT", -30, 0)
                    w1.isSlider = false
                    
                elseif entry.kind == "slider" or entry.kind == "dropdown" then
                    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                    lbl:SetPoint("BOTTOMLEFT", w1, "TOPLEFT", 0, 2)
                    lbl:SetText(entry.label)
                    lbl:Show()
                    
                    w1:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset - 12)
                    w1.isSlider = true
                    
                    
                else
                    w1:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOffset)
                    w1.isSlider = false
                end
                
                w1:Show()
                anchors[currentRow] = w1
                currentRow = currentRow + 1
            end
            
            i = i + 1
        end
    end

    local last = anchors[currentRow - 1]
    if last then
        local _, _, _, _, y = last:GetPoint()
        parent:SetHeight(math.abs(y) + 50)
    end
end