local addonName, addon = ...
local Undaunted = addon
_G[addonName] = Undaunted

-- Database, currently all in one, will split later to different modules.
local defaults = {
    raidWarningScale = 1.0,
    enabledCustomRaidWarning = false,
    hide = false,
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 16,
    font,
    externalRaidWarningWindows = false,
    timerFade = 5,
    textColor = { r = 1, g = 1, b = 1 },

    loot = { enabled = true },

    healerMana = {
        enabled = false,
        point = "TOP",
        x = 0,
        y = -600,
        height = 30,
        width = 250,
        classColor = true,
        onlyInsideRaid = false,
        color = { r = 0, g = 0, b = 0.7 },
        background = { r = 0, g = 0, b = 0, a = 0.6},
        showPercent = true,
        nameText = "name",
        maxBars = 5,
        sortBy = "name",
    },

    notes = {},

    noteDisplay = {
        enabled = false,
        locked = false,
        alpha = 0.8,
        width = 400,
        height = nil, -- auto by default
        point = "CENTER",
        x = 0,
        y = 200,
        font = "GameFontHighlight",
    },

    modules = {
        raidWarnings = true,
        healerMana = true,
        notes = true,
        professionExporter = true,
        loot = true,
    },
}

-- Logger utility
addon.Logger = {}
local Logger = addon.Logger
local ADDON_PREFIX = "|cffFFD147[Undaunted]|r"

function Logger:Info(message)
    print(string.format("%s %s", ADDON_PREFIX, message))
end

function Logger:Success(message)
    print(string.format("%s |cff00FF00%s|r", ADDON_PREFIX, message))
end

function Logger:Warning(message)
    print(string.format("%s |cffFFFF00Warning: %s|r", ADDON_PREFIX, message))
end

function Logger:Error(message)
    print(string.format("%s |cffff0000Error: %s|r", ADDON_PREFIX, message))
end

function Logger:Debug(message)
    print(string.format("%s |cff00ffff%s|r", ADDON_PREFIX, message))
end

-- Create new varaibles if not exist, to avoid nil errors.
local function CopyDefaults(dest, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if dest[k] == nil then
                dest[k] = {}
            end
            CopyDefaults(dest[k], v)
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
end

-- Generated DB
local function LoadSettings()
    if not UndauntedDB then
        UndauntedDB = {}
    end
    CopyDefaults(UndauntedDB, defaults)
end

-- Default RaidWarningFrame, currently Scale not working.
local function ApplyRaidwarningSettings()
    if UndauntedDB.enabledCustomRaidWarning then
        --RaidNotice_AddMessage(RaidWarningFrame, "Undaunted Addon Loaded|r", ChatTypeInfo["RAID_WARNING"])
        RaidWarningFrame:SetScale(UndauntedDB.raidWarningScale)
    else
        RaidWarningFrame:SetScale(1)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

C_ChatInfo.RegisterAddonMessagePrefix("UNDAUNTED_NOTE")

local receivedNotes = {}

-- Recived Notes across Players in raids.
local noteReceiver = CreateFrame("Frame")
noteReceiver:RegisterEvent("CHAT_MSG_ADDON")
noteReceiver:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if prefix ~= "UNDAUNTED_NOTE" then return end
    
    local msgType, data, msg = strsplit("~", message, 3)
    
    if data == "HEADER" then
        local noteName, chunkCount = strsplit("~", msg)
        receivedNotes[sender] = {
            name = noteName,
            totalChunks = tonumber(chunkCount),
            chunks = {},
            received = 0
        }
        
    elseif data == "CHUNK" then
        local chunkIndex, chunkData = strsplit("~", msg, 2)
        chunkIndex = tonumber(chunkIndex)
        
        if not receivedNotes[sender] then return end
        
        receivedNotes[sender].chunks[chunkIndex] = chunkData
        receivedNotes[sender].received = receivedNotes[sender].received + 1
        
        if receivedNotes[sender].received >= receivedNotes[sender].totalChunks then
            local fullNote = table.concat(receivedNotes[sender].chunks)
            local noteName = receivedNotes[sender].name

            local playerName = UnitName("player")
            local senderShort = Ambiguate(sender, "short")
            
            if senderShort == playerName then
                if UndauntedDB.noteDisplay.enabled then
                    addon.NoteDisplay:Show(noteName, fullNote)
                end
                receivedNotes[sender] = nil
                return
            end
            
            Logger:Info(string.format("Received note '%s' from %s", noteName, sender))
            
            table.insert(UndauntedDB.notes, {
                name = noteName .. " (from " .. sender .. ")",
                content = fullNote,
                created = time(),
                modified = time()
            })

            if UndauntedDB.noteDisplay.enabled then
                addon.NoteDisplay:Show(noteName, fullNote)
            end

            if addon.NotesContainer then
                addon.NotesContainer:RefreshProfileList()
            end
            
            receivedNotes[sender] = nil
        end
    end
end)

-- Version Checker
C_ChatInfo.RegisterAddonMessagePrefix("UNDAUNTED_VER")

local VersionUI = {}
local verFrame = nil
local verRows = {}
local verData = {}
local myVer = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.0"

function VersionUI:Create()
    if verFrame then return end
    
    verFrame = CreateFrame("Frame", "UndauntedVersionFrame", UIParent, "BackdropTemplate")
    verFrame:SetSize(300, 400)
    verFrame:SetPoint("CENTER")
    verFrame:SetMovable(true)
    verFrame:EnableMouse(true)
    verFrame:RegisterForDrag("LeftButton")
    verFrame:SetScript("OnDragStart", verFrame.StartMoving)
    verFrame:SetScript("OnDragStop", verFrame.StopMovingOrSizing)
    
    verFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    verFrame:SetBackdropColor(0, 0, 0, 0.85)
    verFrame:SetBackdropBorderColor(0.5, 0.5, 0.5)
    
    verFrame.Title = verFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    verFrame.Title:SetPoint("TOP", 0, -10)
    verFrame.Title:SetText("Version Check")
    
    verFrame.SubTitle = verFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    verFrame.SubTitle:SetPoint("TOP", 0, -28)
    verFrame.SubTitle:SetText("My Version: " .. myVer)

    local close = CreateFrame("Button", nil, verFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    
    local scroll = CreateFrame("ScrollFrame", nil, verFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -50)
    scroll:SetPoint("BOTTOMRIGHT", -30, 40)
    
    local content = CreateFrame("Frame")
    content:SetSize(240, 10)
    scroll:SetScrollChild(content)
    verFrame.Content = content
    
    local btn = CreateFrame("Button", nil, verFrame, "UIPanelButtonTemplate")
    btn:SetSize(120, 25)
    btn:SetPoint("BOTTOM", 0, 10)
    btn:SetText("Check Group")
    btn:SetScript("OnClick", function() VersionUI:Scan("GROUP") end)
    
    local btnGuild = CreateFrame("Button", nil, verFrame, "UIPanelButtonTemplate")
    btnGuild:SetSize(80, 25)
    btnGuild:SetPoint("LEFT", btn, "RIGHT", 5, 0)
    btnGuild:SetText("Guild")
    btnGuild:SetScript("OnClick", function() VersionUI:Scan("GUILD") end)
    
    verFrame:Hide()
end

function VersionUI:GetRow(i)
    if not verRows[i] then
        local row = CreateFrame("Frame", nil, verFrame.Content)
        row:SetSize(240, 20)
        
        row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.Name:SetPoint("LEFT", 5, 0)
        row.Name:SetWidth(140)
        row.Name:SetJustifyH("LEFT")
        
        row.Ver = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.Ver:SetPoint("RIGHT", -25, 0)
        
        row.Icon = row:CreateTexture(nil, "ARTWORK")
        row.Icon:SetSize(14, 14)
        row.Icon:SetPoint("LEFT", row.Ver, "RIGHT", 2, 0)
        
        verRows[i] = row
    end
    return verRows[i]
end

function VersionUI:UpdateList()
    if not verFrame then return end
    
    local list = {}
    for name, info in pairs(verData) do
        table.insert(list, {name=name, ver=info.ver, class=info.class})
    end
    table.sort(list, function(a,b) return a.name < b.name end)
    
    for i, row in ipairs(verRows) do row:Hide() end
    
    for i, entry in ipairs(list) do
        local row = self:GetRow(i)
        row:SetPoint("TOPLEFT", 0, (i-1)*-20)
        row:Show()
        
        local nameStr = entry.name
        if entry.class then
            local color = C_ClassColor.GetClassColor(entry.class)
            if color then
                nameStr = string.format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, entry.name)
            end
        end
        row.Name:SetText(nameStr)
        
        row.Ver:SetText(entry.ver)
        
        if entry.ver == "Waiting..." then
            row.Ver:SetTextColor(0.5, 0.5, 0.5)
            row.Icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Waiting")
        elseif entry.ver == myVer then
             row.Ver:SetTextColor(0, 1, 0)
             row.Icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        elseif entry.ver > myVer then
             row.Ver:SetTextColor(0, 0.5, 1)
             row.Icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        else
             row.Ver:SetTextColor(1, 0, 0)
             row.Icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        end
    end
    
    verFrame.Content:SetHeight(math.max(10, #list * 20))
end

function VersionUI:Scan(type)
    self:Create()
    verFrame:Show()
    wipe(verData)
    
    local channel
    if type == "GUILD" then
        channel = "GUILD"
        verData[UnitName("player")] = {ver=myVer, class=select(2, UnitClass("player"))}
    else
        channel = IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or nil)
        if not channel then
            Logger:Info("Not in a group. Scanning Guild instead.")
            channel = "GUILD"
        end
        
        if channel ~= "GUILD" then
            local num = GetNumGroupMembers()
            for i=1, num do
                local unit = IsInRaid() and "raid"..i or "party"..i
                if not IsInRaid() and i==num then unit = "player" end 
                
                local name = GetUnitName(unit, true)
                local _, class = UnitClass(unit)
                if name then
                     name = Ambiguate(name, "short")
                     verData[name] = {ver="Waiting...", class=class}
                end
            end
            local pName = UnitName("player")
            if verData[pName] then verData[pName].ver = myVer
            else verData[pName] = {ver=myVer, class=select(2, UnitClass("player"))} end
        end
    end
    
    self:UpdateList()
    C_ChatInfo.SendAddonMessage("UNDAUNTED_VER", "PING", channel)
end

local verChecker = CreateFrame("Frame")
verChecker:RegisterEvent("CHAT_MSG_ADDON")
verChecker:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if prefix ~= "UNDAUNTED_VER" then return end
    
    local senderShort = Ambiguate(sender, "short")
    local cmd, version = strsplit("~", msg, 2)
    
    if cmd == "PING" then
        if senderShort ~= UnitName("player") then
            C_ChatInfo.SendAddonMessage("UNDAUNTED_VER", "PONG~"..myVer, "WHISPER", sender)
        end
    elseif cmd == "PONG" then
        if not verData[senderShort] then
             verData[senderShort] = {ver=version, class=nil}
        else
             verData[senderShort].ver = version
        end
        VersionUI:UpdateList()
    end
end)

SLASH_UDVER1 = "/udver"
SlashCmdList["UDVER"] = function()
    VersionUI:Scan("GROUP")
end

local function InitializeModules()
    local db = UndauntedDB.modules
    
    if db.raidWarnings and addon.InitAccessibleWarnings then
        addon:InitAccessibleWarnings()
    end

    if db.healerMana and addon.HealerMana then
        addon.HealerMana:Init()
        addon.HealerMana:Refresh()
    end

    if db.notes and addon.NoteDisplay then
        addon.NoteDisplay:Init()
    end

    if db.loot and addon.Loot then
        addon.Loot:Init()
    end
end

f:SetScript("OnEvent", function(self, event, addon)
    if addon == addonName then
        LoadSettings()
        InitializeModules()
        ApplyRaidwarningSettings()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Slash commands for Pull
SLASH_PULL1 = "/pull"
SlashCmdList["PULL"] = function(msg)
    local time = tonumber(msg)
    if not time then
        time = 10
    end
    
    if C_PartyInfo and C_PartyInfo.DoCountdown then
        C_PartyInfo.DoCountdown(time)
    end
end

-- Slash command for Ready Check
SLASH_RCREADY1 = "/rc"
SlashCmdList["RCREADY"] = function()
    if DoReadyCheck then
        DoReadyCheck()
    end
end

-- Slash command for Break, with cancel option.
-- ToDo: Add external timer display for break, and maybe pull timer as well, to make it more visible.
SLASH_BREAK1 = "/break"
SlashCmdList["BREAK"] = function(msg)
    local minutes = tonumber(msg)

    if minutes == 0 then
        if C_PartyInfo and C_PartyInfo.DoCountdown then
            C_PartyInfo.DoCountdown(0)
            Logger:Info("Break timer cancelled.")
        end
        return
    end

    if not minutes or minutes < 0 then
        minutes = 15
    end

    local seconds = minutes * 60

    if C_PartyInfo and C_PartyInfo.DoCountdown then
        C_PartyInfo.DoCountdown(seconds)
        Logger:Info("Break for " .. minutes .. " minute(s).")
    end
end

SLASH_UNDAUNTEDLOOT1 = "/uloot"
SlashCmdList["UNDAUNTEDLOOT"] = function(msg)
    if msg == "test" then
        if addon.Loot then addon.Loot:Test() end
    else
        if addon.Loot then addon.Loot:StartSession(msg) end
    end
end


Undaunted.ApplyRaidwarningSettings = ApplyRaidwarningSettings