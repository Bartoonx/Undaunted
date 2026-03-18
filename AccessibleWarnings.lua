local ADDON_NAME, addon = ...

local frame
local maxLines = 3
local lines = {}
local activeTimers = {}


-- Update the GUI Position, Currently static, due can't use GetHeight while in combat.
local function UpdatePositions()
    local visibleLines = {}
    for _, line in ipairs(lines) do
        if line:IsShown() then
            table.insert(visibleLines, line)
        end
    end
    
    table.sort(visibleLines, function(a, b) return a.created < b.created end)

    local lineHeight = (UndauntedDB.fontSize or 20) * 1.5
    local yOffset = 0
    for i = #visibleLines, 1, -1 do
        local line = visibleLines[i]
        line:ClearAllPoints()
        line:SetPoint("BOTTOM", frame, "CENTER", 0, yOffset)
        yOffset = yOffset + lineHeight + 10
    end
end

-- Get the Free line, else get the oldest line one.
local function GetFreeLine()
    for _, line in ipairs(lines) do
        if not line:IsShown() then
            return line
        end
    end

    local oldest = lines[1]
    for _, line in ipairs(lines) do
        if line.created < oldest.created then
            oldest = line
        end
    end

    if activeTimers[oldest] then
        activeTimers[oldest]:Cancel()
        activeTimers[oldest] = nil
    end
    
    return oldest
end

-- Function to show the warning at external frame
function Undaunted_ShowWarning(msg, r, g, b, size)
    if not frame then return end

    local line = GetFreeLine()

    if activeTimers[line] then
        activeTimers[line]:Cancel()
        activeTimers[line] = nil
    end
    UIFrameFadeRemoveFrame(line)
    
    local color = UndauntedDB.textColor
    if r and g and b then
        line:SetTextColor(r, g, b)
    else
        line:SetTextColor(color.r, color.g, color.b)
    end
    
    line:SetText(msg)
    
    local fSize = size or UndauntedDB.fontSize
    line:SetFont(UndauntedDB.font or "Fonts\\FRIZQT__.TTF", fSize)
    
    line:SetWidth(frame:GetWidth() - 40)
    line:SetAlpha(1)
    line.created = GetTime()
    line:Show()

    UpdatePositions()

    activeTimers[line] = C_Timer.NewTimer(UndauntedDB.timerFade, function()
        UIFrameFadeOut(line, 2, 1, 0)
        C_Timer.After(2, function()
            line:Hide()
            line:SetAlpha(0)
            activeTimers[line] = nil
            UpdatePositions()
        end)
    end)
end

function addon:InitAccessibleWarnings()
    frame = CreateFrame("Frame", "UndauntedWarningFrame", UIParent)
    frame:SetSize(UIParent:GetWidth() * 0.8, 400)
    frame:SetPoint("CENTER", 0, 200)

    -- prepare creating lines
    for i = 1, maxLines do
        local line = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
        line:SetJustifyH("CENTER")
        line:SetJustifyV("MIDDLE")
        line:SetWordWrap(true)
        line:SetWidth(frame:GetWidth() - 40)
        line:SetAlpha(0)
        line:Hide()
        lines[i] = line
    end

    hooksecurefunc("RaidNotice_AddMessage", function(_, msg)
        if UndauntedDB.externalRaidWarningWindows then
            Undaunted_ShowWarning(msg)
        end
        if UndauntedDB.hide then
            RaidWarningFrame:Hide()
        end
    end)
end
