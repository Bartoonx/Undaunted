local ADDON_NAME, addon = ...

addon.Loot = {}
local Loot = addon.Loot
local Widgets = addon.UndauntedWidgets

local COMM_PREFIX = "UNDAUNTED_LOOT"
local VOTE_TYPES = {
    [1] = { text = "Main Spec", color = {0, 1, 0} },
    [2] = { text = "Off Spec", color = {1, 0.5, 0} },
    [3] = { text = "Transmog", color = {1, 0, 1} },
    [4] = { text = "Pass", color = {0.5, 0.5, 0.5} },
}

local votingFrame, sessionFrame
local sessions = {}
local sessionKeys = {}
local voteQueue = {}
local currentViewSessionID = nil
local sessionRows = {}
local sessionIcons = {}
local votingRows = {}
local renderedRows = 0
local sessionCounter = 0
local knownAddonUsers = {}
local activeIconBorder = {r=1, g=0.8, b=0, a=1}

local function GetSettings()
    return UndauntedDB.loot
end

function Loot:Init()
    if not C_ChatInfo.IsAddonMessagePrefixRegistered(COMM_PREFIX) then
        C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
        if prefix == COMM_PREFIX then
            Loot:OnComm(sender, msg)
        end
    end)

    self:CreateVotingUI()
    self:CreateSessionUI()
end

-- The UI shown to everyone to vote
function Loot:CreateVotingUI()
    local f = CreateFrame("Frame", "UndauntedLootVote", UIParent, "BackdropTemplate")
    f:SetSize(550, 100)
    f:SetPoint("CENTER", -200, 0)
    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:Hide()
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f.Header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.Header:SetPoint("TOP", 0, -10)
    f.Header:SetText("Loot Session")

    f.MoreInfo = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.MoreInfo:SetPoint("BOTTOMRIGHT", -15, 5)
    f.MoreInfo:Hide()

    votingFrame = f
end

function Loot:GetVotingRow(index)
    if not votingRows[index] then
        local row = CreateFrame("Frame", nil, votingFrame, "BackdropTemplate")
        row:SetSize(530, 45)
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        })
        row:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
        row:SetBackdropBorderColor(0, 0, 0, 1)

        row.Icon = row:CreateTexture(nil, "ARTWORK")
        row.Icon:SetSize(36, 36)
        row.Icon:SetPoint("LEFT", 5, 0)

        row.Link = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.Link:SetPoint("LEFT", row.Icon, "RIGHT", 10, 0)
        row.Link:SetWidth(200)
        row.Link:SetJustifyH("LEFT")
        
        row.Buttons = {}
        local x = 260
        for i = 1, 4 do
            local btn = Widgets:Button(row, {
                label = VOTE_TYPES[i].text,
                width = 65,
                height = 25,
            })
            btn:SetPoint("LEFT", x, 0)
            row.Buttons[i] = btn
            x = x + 68
        end
        votingRows[index] = row
    end
    return votingRows[index]
end

-- The UI shown to the Master Looter/Leader
function Loot:CreateSessionUI()
    local f = CreateFrame("Frame", "UndauntedLootSession", UIParent, "BackdropTemplate")
    f:SetSize(350, 350)
    f:SetPoint("CENTER", 300, 100)
    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:Hide()
    
    -- Make it movable
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f.Title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.Title:SetPoint("TOP", 0, -10)
    f.Title:SetText("Votes")

    f.Close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.Close:SetPoint("TOPRIGHT", 0, 0)

    f.Sidebar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.Sidebar:SetPoint("TOPLEFT", 10, -30)
    f.Sidebar:SetPoint("BOTTOMLEFT", 10, 10)
    f.Sidebar:SetWidth(40)
    f.Sidebar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = nil,
        edgeSize = 0,
    })
    f.Sidebar:SetBackdropColor(0, 0, 0, 0.3)

    f.Content = CreateFrame("Frame", nil, f)
    f.Content:SetPoint("TOPLEFT", f.Sidebar, "TOPRIGHT", 5, 0)
    f.Content:SetPoint("BOTTOMRIGHT", -10, 10)

    sessionFrame = f
end

function Loot:GetSessionIcon(index)
    if not sessionIcons[index] then
        local btn = CreateFrame("Button", nil, sessionFrame.Sidebar)
        btn:SetSize(36, 36)
        btn:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        
        btn.Border = btn:CreateTexture(nil, "OVERLAY")
        btn.Border:SetAllPoints()
        btn.Border:SetColorTexture(1, 0.8, 0, 0.6) -- Selection highlight
        btn.Border:SetDrawLayer("OVERLAY", 7)
        btn.Border:Hide()
        
        sessionIcons[index] = btn
    end
    return sessionIcons[index]
end

function Loot:StartSession(itemLink)
    if not itemLink then 
        addon.Logger:Error("No item linked.")
        return 
    end

    local channel = IsInRaid() and "RAID" or "PARTY"
    if not IsInGroup() then channel = "WHISPER" end -- For testing

    sessionCounter = sessionCounter + 1
    local sessionID = string.format("%d-%d-%s", GetTime() * 1000, sessionCounter, UnitName("player"))
    local msg = "START~" .. itemLink .. "~" .. sessionID
    
    if channel == "WHISPER" then
        self:OnComm(UnitName("player"), msg) -- Local test
    else
        C_ChatInfo.SendAddonMessage(COMM_PREFIX, "PING", channel) -- Check for addon users
        C_ChatInfo.SendAddonMessage(COMM_PREFIX, msg, channel)    -- Start Session
    end
end

function Loot:SendVote(target, sessionID, voteID)
    local msg = "VOTE~" .. sessionID .. "~" .. voteID
    if Ambiguate(target, "short") == UnitName("player") then
        self:OnComm(target, msg)
    else
        -- Use WHISPER to the session owner to avoid spamming addon channel
        C_ChatInfo.SendAddonMessage(COMM_PREFIX, msg, "WHISPER", target)
    end
end

function Loot:OnComm(sender, msg)
    local parts = { strsplit("~", msg) }
    local cmd = parts[1]
    
    -- Track users who communicate
    local senderShort = Ambiguate(sender, "short")
    knownAddonUsers[senderShort] = true

    if cmd == "PING" then
        C_ChatInfo.SendAddonMessage(COMM_PREFIX, "PONG", "WHISPER", sender)
        return
    elseif cmd == "PONG" then
        if sessionFrame:IsShown() and currentViewSessionID then
            self:UpdateSessionRow(senderShort)
        end
        return
    end

    if cmd == "START" then
        local itemLink = parts[2]
        local sessionID = parts[3]
        if not itemLink or not sessionID then return end
        
        sessions[sessionID] = {
            id = sessionID,
            item = itemLink,
            sender = sender,
            votes = {}
        }
        table.insert(sessionKeys, sessionID)

        -- If I am the sender, show the Council UI
        if Ambiguate(sender, "short") == UnitName("player") then
            self:UpdateSessionSidebar()
            self:ShowSession(sessionID)
            sessionFrame:Show()
        end
        table.insert(voteQueue, sessionID)
        self:UpdateVotingFrame()

    elseif cmd == "VOTE" then
        local sessionID = parts[2]
        local voteID = tonumber(parts[3])

        if not sessions[sessionID] then return end

        -- Only the session owner should process votes.
        if Ambiguate(sessions[sessionID].sender, "short") ~= UnitName("player") then return end

        -- Avoid duplicates
        for _, v in ipairs(sessions[sessionID].votes) do
            if v.player == senderShort then return end
        end
        
        table.insert(sessions[sessionID].votes, {player = senderShort, vote = voteID})

        -- If the frame is visible and showing the correct session, update it live.
        if sessionFrame:IsShown() and currentViewSessionID == sessionID then
            self:UpdateSessionRow(senderShort)
        end
    end
end

function Loot:UpdateVotingFrame()
    -- Hide all existing rows first
    for _, row in ipairs(votingRows) do row:Hide() end

    if #voteQueue == 0 then
        votingFrame:Hide()
        return
    end

    local yOffset = -35
    local displayedCount = 0

    for i, sessionID in ipairs(voteQueue) do
        if displayedCount >= 5 then break end

        local session = sessions[sessionID]
        if session then
            displayedCount = displayedCount + 1
            local row = self:GetVotingRow(displayedCount)
            row:SetPoint("TOPLEFT", 10, yOffset)
            row:Show()

            row.Link:SetText(session.item)
            local itemID = GetItemInfoInstant(session.item)
            if itemID then
                local texture = C_Item.GetItemIconByID(itemID)
                row.Icon:SetTexture(texture)
            end

            -- Setup buttons
            for btnID, btn in ipairs(row.Buttons) do
                btn:SetScript("OnClick", function()
                    self:SendVote(session.sender, sessionID, btnID)
                    addon.Logger:Info("Voted: " .. VOTE_TYPES[btnID].text)
                    
                    -- Remove this session from queue
                    table.remove(voteQueue, i)
                    self:UpdateVotingFrame()
                end)
            end

            yOffset = yOffset - 50
        end
    end

    local remaining = #voteQueue - displayedCount
    if remaining > 0 then
        votingFrame.MoreInfo:SetText("+" .. remaining .. " more...")
        votingFrame.MoreInfo:Show()
    else
        votingFrame.MoreInfo:Hide()
    end

    votingFrame:SetHeight(math.abs(yOffset) + 10)
    votingFrame:Show()
end

function Loot:UpdateSessionSidebar()
    for _, icon in ipairs(sessionIcons) do icon:Hide() end

    for i, sessionID in ipairs(sessionKeys) do
        local session = sessions[sessionID]
        local iconBtn = self:GetSessionIcon(i)
        
        iconBtn:SetPoint("TOP", 0, (i-1) * -40)
        
        local itemID = GetItemInfoInstant(session.item)
        if itemID then
            iconBtn:SetNormalTexture(C_Item.GetItemIconByID(itemID))
        end
        
        iconBtn:SetScript("OnClick", function() self:ShowSession(sessionID) end)
        iconBtn:Show()
    end
end

function Loot:ShowSession(sessionID)
    currentViewSessionID = sessionID
    local session = sessions[sessionID]
    if not session then return end

    sessionFrame.Title:SetText(session.item)
    self:ResetSessionFrame()

    -- Highlight sidebar icon
    for i, id in ipairs(sessionKeys) do
        if sessionIcons[i] then
            if id == sessionID then
                sessionIcons[i].Border:Show()
            else
                sessionIcons[i].Border:Hide()
            end
        end
    end
    
    -- Loop through Roster instead of just votes
    local rosterSet = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name then rosterSet[Ambiguate(name, "short")] = true end
        end
    elseif IsInGroup() then
        rosterSet[Ambiguate(UnitName("player"), "short")] = true
        for i = 1, 4 do
            if UnitExists("party"..i) then
                rosterSet[Ambiguate(UnitName("party"..i), "short")] = true
            end
        end
    else
        -- Fallback for testing/solo
        rosterSet[Ambiguate(UnitName("player"), "short")] = true
        -- Add some fake people for testing if in test mode
        if self.isTesting then
            rosterSet["Jaina"] = true
            rosterSet["Thrall"] = true
            rosterSet["Anduin"] = true
            -- Simulate them having addon or not
            knownAddonUsers["Jaina"] = true
        end
    end
    local roster = {}
    for name in pairs(rosterSet) do table.insert(roster, name) end
    table.sort(roster)

    for _, player in ipairs(roster) do
        self:AddSessionRow(player)
    end
end

function Loot:ResetSessionFrame()
    for _, row in ipairs(sessionRows) do
        row:Hide()
    end
    renderedRows = 0
end

function Loot:Award(player)
    local session = sessions[currentViewSessionID]
    if not session then return end
    
    local msg = string.format("Congratulations %s on winning %s!", player, session.item)
    
    if IsInRaid() then
        SendChatMessage(msg, "RAID_WARNING")
    elseif IsInGroup() then
        SendChatMessage(msg, "PARTY")
    else
        addon.Logger:Info("Fake Announce: " .. msg)
    end

    self:EndSession(currentViewSessionID)
end

function Loot:EndSession(sessionID)
    sessions[sessionID] = nil

    -- Remove from sessionKeys
    for i, id in ipairs(sessionKeys) do
        if id == sessionID then
            table.remove(sessionKeys, i)
            break
        end
    end

    -- Remove from voteQueue
    for i, id in ipairs(voteQueue) do
        if id == sessionID then
            table.remove(voteQueue, i)
            break
        end
    end

    self:UpdateVotingFrame()
    self:UpdateSessionSidebar()

    if currentViewSessionID == sessionID then
        if #sessionKeys > 0 then
            self:ShowSession(sessionKeys[1])
        else
            currentViewSessionID = nil
            sessionFrame:Hide()
        end
    end
end

function Loot:UpdateSessionRow(player)
    -- Find the row for this player
    for _, row in ipairs(sessionRows) do
        if row.player == player and row:IsShown() then
            self:SetRowState(row, player)
            return
        end
    end
end

function Loot:SetRowState(row, player)
    local session = sessions[currentViewSessionID]
    local voteID = nil
    
    for _, v in ipairs(session.votes) do
        if v.player == player then voteID = v.vote break end
    end

    if voteID then
        local voteData = VOTE_TYPES[voteID]
        local color = voteData.color
        local colorHex = string.format("|cff%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)
        row.Text:SetText(string.format("%s: %s%s|r", player, colorHex, voteData.text))
    elseif knownAddonUsers[player] then
        row.Text:SetText(string.format("%s: |cffffff00Waiting...|r", player))
    else
        row.Text:SetText(string.format("%s: |cff808080NO ADDON|r", player))
    end
end

function Loot:AddSessionRow(player)
    renderedRows = renderedRows + 1
    local idx = renderedRows
    local row = sessionRows[idx]

    if not row then
        row = CreateFrame("Frame", nil, sessionFrame.Content)
        row:SetSize(280, 20)
        
        row.WinBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.WinBtn:SetSize(50, 18)
        row.WinBtn:SetPoint("RIGHT", 0, 0)
        row.WinBtn:SetText("Win")
        row.WinBtn:SetScript("OnClick", function(self) Loot:Award(self:GetParent().player) end)

        row.Text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.Text:SetPoint("LEFT", 5, 0)
        row.Text:SetPoint("RIGHT", row.WinBtn, "LEFT", -5, 0)
        row.Text:SetJustifyH("LEFT")
        sessionRows[idx] = row
    end

    row:SetPoint("TOPLEFT", 0, (idx - 1) * -22)
    row.player = player
    
    self:SetRowState(row, player)
    row:Show()
end

function Loot:Reset()
    sessions = {}
    sessionKeys = {}
    voteQueue = {}
    knownAddonUsers = {}
    currentViewSessionID = nil
    sessionCounter = 0

    self:ResetSessionFrame()
    self:UpdateVotingFrame()
    self:UpdateSessionSidebar()
    
    sessionFrame:Hide()
end

function Loot:Test()
    self:Reset()
    self.isTesting = true
    addon.Logger:Info("Starting Test Loot Session...")
    self:StartSession("|cffff8000|Hitem:49623::::::::80:::::|h[Shadowmourne]|h|r")
    self:StartSession("|cffff8000|Hitem:22691::::::::80:::::|h[Corrupted Ashbringer]|h|r")
    self:StartSession("|cffff8000|Hitem:46017::::::::80:::::|h[Val'anyr, Hammer of Ancient Kings]|h|r")
    self:StartSession("|cffff8000|Hitem:32837::::::::80:::::|h[Warglaive of Azzinoth]|h|r")
    self:StartSession("|cff0070dd|Hitem:50818::::::::80:::::|h[Invincible's Reins]|h|r")
    self:StartSession("|cffff8000|Hitem:19019::::::::80:::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r")
    self:StartSession("|cffff8000|Hitem:18609::::::::80:::::|h[Benediction]|h|r")
end