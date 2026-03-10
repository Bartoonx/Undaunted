local ADDON_NAME, addon = ...
local UI = CreateFrame("Frame")
addon.MainUI = UI

local ACCENT_R, ACCENT_G, ACCENT_B = 1.0, 0.525, 0.282

SLASH_UNDAUNTED1 = "/undaunted"
SLASH_UNDAUNTED2 = "/ud"
SlashCmdList["UNDAUNTED"] = function()
    if not UI.MainFrame then
        UI:Create()
    end
    UI.MainFrame:SetShown(not UI.MainFrame:IsShown())
    if UI.selectedTab == 2 then
        addon.HealerMana:Preview()
    end
end

local function Bg(frame, r,g,b,a)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    frame:SetBackdropColor(r,g,b,a)
end

function UI:Create()

    local f = CreateFrame("Frame", "UndauntedMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(1050, 650)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    Bg(f, 0.05,0.05,0.05,0.95)
    f:Hide()
    self.MainFrame = f

    local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetPoint("TOPRIGHT")
    titleBar:SetHeight(40)
    Bg(titleBar, 0.08,0.08,0.08,1)

    local title = titleBar:CreateFontString(nil,"OVERLAY","GameFontHighlightLarge")
    title:SetPoint("LEFT",20,0)
    title:SetText("Undaunted Raid Tools")

    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT",-5,0)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        addon.HealerMana:HidePreview()
    end)

    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetPoint("TOPLEFT",0,-40)
    sidebar:SetPoint("BOTTOMLEFT")
    sidebar:SetWidth(230)

    local content = CreateFrame("Frame", nil, f, "BackdropTemplate")
    content:SetPoint("TOPLEFT",sidebar,"TOPRIGHT",0,0)
    content:SetPoint("BOTTOMRIGHT")
    Bg(content,0.10,0.10,0.10,1)

    local pages = {}

    local function CreatePage(id)
        local page = CreateFrame("Frame", nil, content)
        page:SetAllPoints()
        page:Hide()
        pages[id] = page
        return page
    end

    local function BuildPage(page, config)
        local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",15,-15)
        scroll:SetPoint("BOTTOMRIGHT",-30,15)

        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(1,1)
        scroll:SetScrollChild(child)

        local yOffset = -10

        for _, section in ipairs(config) do
            local card = CreateFrame("Frame", nil, child, "BackdropTemplate")
            card:SetPoint("TOPLEFT",0,yOffset)
            card:SetPoint("RIGHT",-10,0)
            Bg(card,0.08,0.08,0.08,0.9)

            local prev
            local innerOffset = -10

            for _, entry in ipairs(section.entries) do
                local widget
                if entry.kind == "checkbox" then
                    widget = addon.UndauntedWidgets:Checkbox(card, entry, UndauntedDB)
                elseif entry.kind == "slider" then
                    widget = addon.UndauntedWidgets:Slider(card, entry, UndauntedDB)
                    widget:SetWidth(300)
                elseif entry.kind == "dropdown" then
                    widget = addon.UndauntedWidgets:Dropdown(card, entry, UndauntedDB)
                elseif entry.kind == "color" then
                    widget = addon.UndauntedWidgets:ColorPicker(card, entry, UndauntedDB)
                elseif entry.kind == "button" then
                    widget = addon.UndauntedWidgets:Button(card, entry)
                elseif entry.kind == "editbox" then
                    widget = addon.UndauntedWidgets:EditBox(card, entry)
                elseif entry.kind == "notesContainer" then
                    widget = addon.UndauntedWidgets:NotesContainer(page, 150,30,40)
                    addon.NotesContainer = widget
                    
                end

                if widget then
                    if not prev then
                        widget:SetPoint("TOPLEFT",15,innerOffset)
                    else
                        widget:SetPoint("TOPLEFT",prev,"BOTTOMLEFT",0,-12)
                    end
                    prev = widget
                end
            end

            if prev then
                local _,_,_,_,y = prev:GetPoint()
                card:SetHeight(math.abs(y)+25)
            else
                card:SetHeight(80)
            end

            yOffset = yOffset - card:GetHeight() - 15
        end

        child:SetHeight(math.abs(yOffset)+50)
    end

    for id, config in pairs(addon.WidgetsConfig) do
        local page = CreatePage(id)
        BuildPage(page, config)
    end

    self.MainFrame.pages = pages

    local activeButton

    local function SetActive(button, id)
        if activeButton then
            activeButton.bg:Hide()
        end

        for _, p in pairs(pages) do
            p:Hide()
        end

        activeButton = button
        button.bg:Show()
        pages[id]:Show()

        self.selectedTab = id

        if id == 2 and addon.HealerMana and UndauntedDB.healerMana.enabled then
            addon.HealerMana:Init()
            addon.HealerMana:Refresh()
        else
            addon.HealerMana:HidePreview()
        end
    end

    local previous
    for id, config in ipairs(addon.WidgetsConfig) do
        local label = config[1] and config[1].label or ("Tab "..id)

        local row = CreateFrame("Button", nil, sidebar)
        row:SetHeight(36)
        row:SetPoint("LEFT",10,0)
        row:SetPoint("RIGHT",-10,0)

        if not previous then
            row:SetPoint("TOP",0,-20)
        else
            row:SetPoint("TOP",previous,"BOTTOM",0,-2)
        end

        local hover = row:CreateTexture(nil,"BACKGROUND")
        hover:SetAllPoints()
        hover:SetColorTexture(1,1,1,0.06)
        hover:Hide()
        row.hover = hover

        local bg = row:CreateTexture(nil,"BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(ACCENT_R,ACCENT_G,ACCENT_B,1)
        bg:Hide()
        row.bg = bg

        local text = row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        text:SetPoint("LEFT",12,0)
        text:SetText(label)
        text:SetTextColor(1,1,1)

        row:SetScript("OnEnter",function(self)
            if self ~= activeButton then
                self.hover:Show()
            end
        end)

        row:SetScript("OnLeave",function(self)
            self.hover:Hide()
        end)

        row:SetScript("OnClick",function(self)
            SetActive(self,id)
        end)

        previous = row

        if id == 1 then
            SetActive(row,id)
        end
    end
end
