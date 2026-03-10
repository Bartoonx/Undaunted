local ADDON_NAME, addon = ...

local HealerMana = {}
addon.HealerMana = HealerMana

local container = nil
local isInit = false

local function GetSettings()
    return UndauntedDB.healerMana
end

local previewColors = {
    C_ClassColor.GetClassColor("SHAMAN"),
    C_ClassColor.GetClassColor("PALADIN"),
    C_ClassColor.GetClassColor("PRIEST"),
    C_ClassColor.GetClassColor("EVOKER"),
    C_ClassColor.GetClassColor("DRUID"),
    C_ClassColor.GetClassColor("MONK"),
}

function HealerMana:Init()
    if container then return end
    
    local cfg = GetSettings()
    
    container = CreateFrame("Frame", "UndauntedManaFrame", UIParent)
    container:SetPoint(cfg.point, cfg.x, cfg.y)
    container:SetSize(cfg.width, cfg.height * 4)
    container:Hide()
    
    container.count = 0
    container.bars = {}
    container.units = {}
    
    container:SetMovable(true)
    container:EnableMouse(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", function(self)
        if not cfg.locked then self:StartMoving() end
    end)
    container:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        cfg.point = point
        cfg.x = x
        cfg.y = y
    end)
    
    container.backdrop = container:CreateTexture(nil, "BACKGROUND")
    container.backdrop:SetAllPoints()
    container.backdrop:SetColorTexture(0, 0, 0, 0)
    container.backdrop:Hide()
    
    isInit = true
    self:RegisterEvents()
end

function HealerMana:CreateBar()
    local cfg = GetSettings()
    local idx = #container.bars + 1
    local offset = (idx - 1) * cfg.height * -1
    
    local bar = CreateFrame("StatusBar", nil, container)
    bar:SetPoint("TOP", container, "TOP", 0, offset)
    bar:SetSize(cfg.width, cfg.height)
    bar:SetStatusBarTexture("Interface/Buttons/WHITE8x8")
    bar:SetStatusBarColor(cfg.color.r, cfg.color.g, cfg.color.b, 1)
    
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(cfg.background.r, cfg.background.g, cfg.background.b, cfg.background.a)
    
    bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bar.label:SetPoint("LEFT", 5, 0)
    bar.label:SetShadowOffset(-1, -1)
    
    bar.value = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bar.value:SetPoint("RIGHT", -5, 0)
    bar.value:SetShadowOffset(-1, -1)
    
    bar.active = false
    bar:Hide()
    
    container.bars[idx] = bar
    return idx
end

function HealerMana:Assign(unit)
    local cfg = GetSettings()
    local maxPower = UnitPowerMax(unit, Enum.PowerType.Mana)
    local name = UnitName(unit)
    
    if maxPower == 0 then return end
    
    local slot = nil
    for i, b in ipairs(container.bars) do
        if not b.active then slot = i break end
    end
    
    if not slot then
        if #container.bars >= cfg.maxBars then return end
        slot = self:CreateBar()
    end
    
    local bar = container.bars[slot]
    bar:SetMinMaxValues(0, maxPower)
    bar.bg:SetColorTexture(cfg.background.r, cfg.background.g, cfg.background.b, cfg.background.a)
    
    local a = cfg.color.a or 1
    if cfg.classColor then
        local _, class = UnitClass(unit)
        local color = C_ClassColor.GetClassColor(class)
        if color then bar:SetStatusBarColor(color.r, color.g, color.b, a) end
    else
        bar:SetStatusBarColor(cfg.color.r, cfg.color.g, cfg.color.b, a)
    end

    local displayText = ""
    if cfg.nameText == "name" then
        displayText = name
    elseif cfg.nameText == "class" then
        displayText = className
    end
    
    bar.label:SetText(displayText)
    bar.label:SetShown(cfg.showName)
    bar.value:SetShown(cfg.showPercent)

    container.units[unit] = slot
    self:Update(unit)
    
    container.count = container.count + 1
    container:SetHeight(cfg.height * container.count)
    
    bar.active = true
    bar.unit = unit
    bar.maxPower = UnitPowerMax(unit, Enum.PowerType.Mana)
    bar:Show()
end

function HealerMana:Update(unit)
    local mana = UnitPower(unit, Enum.PowerType.Mana)
    local pct = UnitPowerPercent(unit, Enum.PowerType.Mana, false, CurveConstants.ScaleTo100)
    local idx = container.units[unit]
    local frame = container.bars[idx]
    
    frame:SetValue(mana)
    frame.value:SetText(format("%.4s", pct))

    frame.manaPct = pct
end

function HealerMana:Refresh()
    if not container then return end
    
    local cfg = GetSettings()
    if not cfg.enabled then
        container:Hide()
        return
    end
    if addon.MainUI.MainFrame and addon.MainUI.MainFrame:IsShown() and addon.MainUI.selectedTab == 2 then
       self:Preview()
       return 
    end
    
    container.count = 0
    container.units = {}
    for _, b in ipairs(container.bars) do
        b.active = false
        b:Hide()
    end
    
    local inRaid = IsInRaid()
    if not IsInGroup() or (cfg.onlyInsideRaid and not inRaid) then
        container:Hide()
        return
    end
    
    container:Show()
    
    local healers = {}
    
    if inRaid then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitGroupRolesAssigned(unit) == "HEALER" then
                table.insert(healers, unit)
            end
        end
    else
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "HEALER" then
                table.insert(healers, unit)
            end
        end
        if UnitGroupRolesAssigned("player") == "HEALER" then
            table.insert(healers, "player")
        end
    end
    
    if cfg.sortBy == "name" then
        table.sort(healers, function(a, b) return UnitName(a) < UnitName(b) end)
    end
    
    for _, unit in ipairs(healers) do
        self:Assign(unit)
    end
    
    self:Arrange()
end

function HealerMana:Arrange()
    local cfg = GetSettings()
    local active = {}
    
    for _, b in ipairs(container.bars) do
        if b.active then table.insert(active, b) end
    end
    --[[ 
    if cfg.sortBy == "mana" then
        table.sort(active, function(a, b)
            return (a.manaPct or 0) < (b.manaPct or 0)
        end)
    end
    ]]--
    
    for i, bar in ipairs(active) do
        bar:ClearAllPoints()
        bar:SetPoint("TOP", container, "TOP", 0, (i - 1) * cfg.height * -1)
    end
end

function HealerMana:RegisterEvents()
    if not container then return end
    
    local events = {
        "UNIT_POWER_UPDATE",
        "GROUP_ROSTER_UPDATE",
        "PLAYER_ROLES_ASSIGNED",
    }
    
    for _, e in ipairs(events) do
        container:RegisterEvent(e)
    end
    
    container:SetScript("OnEvent", function(_, event, unit, powerType)
        if event == "UNIT_POWER_UPDATE" and powerType == "MANA" and container.units[unit] then
            self:Update(unit)
            if GetSettings().sortBy == "mana" then self:Arrange() end
        elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" then
            self:Refresh()
        end
    end)
end

function HealerMana:Preview()
    if not container then self:Init() end
    
    local cfg = GetSettings()
    isPreview = true
    container:Show()
    container.backdrop:Show()
    
    for _, b in ipairs(container.bars) do
        b.active = false
        b:Hide()
    end
    
    local samples = {
        { n = "RestoSham", c = "SHAMAN", m = 22 },
        { n = "HolyPally", c = "PALADIN", m = 100 },
        { n = "DiscPriest", c = "PRIEST", m = 55 },
        { n = "PresEvoker", c = "EVOKER", m = 33 },
    }

    if cfg.sortBy == "name" then
        table.sort(samples, function(a, b) return a.n < b.n end)
    elseif cfg.sortBy == "mana" then
        table.sort(samples, function(a, b) return a.m < b.m end)
    end
    
    for i, data in ipairs(samples) do
        if i > cfg.maxBars then break end
        if not container.bars[i] then self:CreateBar() end
        
        local bar = container.bars[i]
        
        bar:ClearAllPoints()
        bar:SetPoint("TOP", container, "TOP", 0, (i - 1) * cfg.height * -1)
        bar:SetHeight(cfg.height)
        
        local a = cfg.color.a or 1
        if cfg.classColor then
            local clr = C_ClassColor.GetClassColor(data.c)
            bar:SetStatusBarColor(clr.r, clr.g, clr.b, a)
        else
            bar:SetStatusBarColor(cfg.color.r, cfg.color.g, cfg.color.b, a)
        end

        bar.bg:SetColorTexture(cfg.background.r, cfg.background.g, cfg.background.b, cfg.background.a)

        local displayText = ""
        if cfg.nameText == "name" then
            displayText = data.n
        elseif cfg.nameText == "class" then
            displayText = data.c
        end
        
        bar:SetMinMaxValues(0, 100)
        bar:SetValue(data.m)
        bar.label:SetText(displayText)
        --bar.label:SetShown(cfg.nameText ~= "none")
        bar.value:SetText(cfg.showPercent and (data.m .. "%") or "")
        bar.value:SetShown(cfg.showPercent)
        bar:Show()
    end
    
    container:SetHeight(cfg.height * #samples)
end

function HealerMana:HidePreview()
    if container then
        container.backdrop:Hide()
        self:Refresh()
    end
end

function HealerMana:SetWidth(w)
    GetSettings().width = w
    if container then
        container:SetWidth(w)
        for _, b in ipairs(container.bars) do b:SetWidth(w) end
    end
end

function HealerMana:SetHeight(h)
    GetSettings().height = h
    if not container then return end
    for _, bar in ipairs(container.bars) do
        bar:SetHeight(h)
    end
    
    self:Refresh()
end

function HealerMana:Toggle(enable)
    GetSettings().enabled = enable
    if enable then
        self:Init()
        self:Refresh()
    elseif container then
        container:Hide()
    end
end

C_Timer.After(2, function()
    if UndauntedDB.healerMana.enabled then
        HealerMana:Init()
        HealerMana:Refresh()
    end
end)