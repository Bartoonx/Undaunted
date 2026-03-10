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
}

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
            
            print(string.format("Undaunted: Received note '%s' from %s", noteName, sender))
            
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

f:SetScript("OnEvent", function(self, event, addon)
    if addon == addonName then
        LoadSettings()
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
            print("Break timer cancelled.")
        end
        return
    end

    if not minutes or minutes < 0 then
        minutes = 15
    end

    local seconds = minutes * 60

    if C_PartyInfo and C_PartyInfo.DoCountdown then
        C_PartyInfo.DoCountdown(seconds)
        print("Break for " .. minutes .. " minute(s).")
    end
end



Undaunted.ApplyRaidwarningSettings = ApplyRaidwarningSettings