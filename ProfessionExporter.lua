local ADDON_NAME, addon = ...

SLASH_SPECEXPORTMID1 = "/specexport"
-- Export profession specs and recipes to JSON for external use, website.

-- GetProfessionInfo(index) : name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset - (Get Details)
-- GetProfessions() : prof1, prof2, archaeology, fishing, cooking                               (Get ProfessionID)
-- C_ProfSpecs.GetConfigIDForSkillLine(skillLineID) : configID                                  (Get ConfigID)
-- C_Traits.GetTreeCurrencyInfo(configID, treeID, excludeStagedChanges) : treeCurrencyInfo      (Spent Knowledge)
-- C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLineID) : specTabIDs                              (Spec Tab)

PROFESSION_MAP = {
    ["Alchemy"] = 2906,
    ["Blacksmithing"] = 2907,
    --["Cooking"] = 2908,
    ["Enchanting"] = 2909,
    ["Engineering"] = 2910,
    --["Fishing"] = 2911,
    --["Herbalism"] = 2912,
    ["Inscription"] = 2913,
    ["Jewelcrafting"] = 2914,
    ["Leatherworking"] = 2915,
    --["Mining"] = 2916,
    --["Skinning"] = 2917,
    ["Tailoring"] = 2918,
}

BASE_SKILL_LINE = {
    ["Alchemy"] = 171,
    ["Blacksmithing"] = 164,
    --["Cooking"] = 2908,
    ["Enchanting"] = 333,
    ["Engineering"] = 202,
    --["Fishing"] = 2911,
    --["Herbalism"] = 2912,
    ["Inscription"] = 773,
    ["Jewelcrafting"] = 755,
    ["Leatherworking"] = 165,
    --["Mining"] = 2916,
    --["Skinning"] = 2917,
    ["Tailoring"] = 197,
}

local exportFrame
local function ShowJSON(text)
    if not exportFrame then
        exportFrame = CreateFrame("Frame", "ProfExportFrame", UIParent, "BasicFrameTemplateWithInset")
        exportFrame:SetSize(500,400)
        exportFrame:SetPoint("CENTER")
        exportFrame.title = exportFrame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        exportFrame.title:SetPoint("LEFT", exportFrame.TitleBg, "LEFT",5,0)
        exportFrame.title:SetText("Profession Export")

        local scroll = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",5,-30)
        scroll:SetPoint("BOTTOMRIGHT",-25,5)

        local edit = CreateFrame("EditBox", nil, scroll, "InputBoxTemplate")
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject("ChatFontNormal")
        edit:SetWidth(450)
        edit:SetHeight(340)
        scroll:SetScrollChild(edit)

        exportFrame.edit = edit
    end
    exportFrame.edit:SetText(text)
    exportFrame:Show()
end

local function serialize(value)
    local t = type(value)
    if t == "table" then
        local isArray = (#value > 0)
        local parts = {}
        if isArray then
            for _, v in ipairs(value) do
                table.insert(parts, serialize(v))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(value) do
                table.insert(parts, '"' .. k .. '":' .. serialize(v))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    elseif t == "string" then
        return '"' .. value .. '"'
    else
        return tostring(value)
    end
end


local exportResults = {}
local currentStep = 0
local professionsToScan = {}

local watchFrame = CreateFrame("Frame")

local function FinishExport()
    watchFrame:UnregisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
    watchFrame:SetScript("OnEvent", nil)
    
    local name = UnitName("player")
    local realm = GetRealmName()
    local region = GetCVar("portal")
    
    local playerInfo = string.format('{"player":"%s", "realm":"%s","region":"%s"}', name, realm, region)
    local combined = "[" .. table.concat(exportResults, ",") .. "," .. playerInfo .. "]"
    
    ShowJSON(combined)
    addon.Logger:Success("Export ready! Copy the JSON from the window.")
end

local function ScrapeActiveProfession()
    local baseID = C_TradeSkillUI.GetChildProfessionInfo()
    local recipes = C_TradeSkillUI.GetAllRecipeIDs()

    local profName = professionsToScan[currentStep].name or "Unknown"
    local skillLevel = professionsToScan[currentStep].skillLevel
    local skillLine = PROFESSION_MAP[profName] or 0
    




    local profData = {
        name = profName,
        skillLevel = skillLevel,
        recipes = {},
        specs = {}
    }

    -- 1. RECIPE SCAN (Bonus Skill & Difficulty)
    for _, recipeID in ipairs(recipes) do
        local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
        if info then
            local profInfo = C_TradeSkillUI.GetProfessionInfoByRecipeID(recipeID)
            
            if profInfo and profInfo.expansionName == "Midnight" then
                local opInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {}, nil, false)
                if opInfo then
                    profData.recipes[info.skillLineAbilityID] = { 
                        bonusSkill = opInfo.bonusSkill 
                    }
                end
            end
        end
    end

    -- 2. SPECS & NODES SCAN (The original logic)
    local configID = C_ProfSpecs.GetConfigIDForSkillLine(skillLine)
    local specTabIDs = C_ProfSpecs.GetSpecTabIDsForSkillLine(skillLine)
    
    if configID and specTabIDs then
        for _, specTabID in ipairs(specTabIDs) do
            local specRootPathID = C_ProfSpecs.GetRootPathForTab(specTabID)
            local pathIDs = {}
            
            local function appendChildPathIDs(t, pathID)
                t[pathID] = 1
                local children = C_ProfSpecs.GetChildrenForPath(pathID)
                if children then
                    for _, childID in ipairs(children) do appendChildPathIDs(t, childID) end
                end
            end
            appendChildPathIDs(pathIDs, specRootPathID)
            
            local nodes = {}
            local knowledgeSpent = 0
            for pathID, _ in pairs(pathIDs) do
                local pathInfo = C_Traits.GetNodeInfo(configID, pathID)
                if pathInfo then
                    local spent = math.max(0, (pathInfo.activeRank - 1))
                    knowledgeSpent = knowledgeSpent + spent
                    table.insert(nodes, {
                        pathID = pathID,
                        activeRank = pathInfo.activeRank,
                        spent = spent
                    })
                end
            end

            table.insert(profData.specs, {
                specTabID = specTabID,
                knowledgeSpent = knowledgeSpent,
                nodes = nodes
            })
        end
    end

    table.insert(exportResults, serialize(profData))
end

watchFrame:SetScript("OnEvent", function(self, event)
    if currentStep == 1 then
        addon.Logger:Debug("[Step 1] Scanned " .. (professionsToScan[1].name or "Primary Profession"))
        ScrapeActiveProfession()
        
        if #professionsToScan > 1 then
            currentStep = 2
            -- Due Blizzard restricted API, can't open 2x Profession, even giving them some time...
            addon.Logger:Debug("[Step 2] Almost there! Click your |cffffd100SECOND|r profession tab.")
        else
            FinishExport()
        end
    elseif currentStep == 2 then
        addon.Logger:Debug("[Step 2] Scanned Second Profession.")
        ScrapeActiveProfession()
        FinishExport()
    end
end)

SlashCmdList["SPECEXPORTMID"] = function()
    exportResults = {}
    professionsToScan = {}
    currentStep = 1
    
    local prof1, prof2 = GetProfessions()
    local temp = {prof1, prof2}
    
    for _, p in pairs(temp) do
        if p then
            local pName, _, skillLevel = GetProfessionInfo(p)
            if PROFESSION_MAP[pName] then
                table.insert(professionsToScan, { name = pName, baseID = BASE_SKILL_LINE[pName], skillLevel = skillLevel })
            end
        end
    end

    if #professionsToScan > 0 then
        watchFrame:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
        C_TradeSkillUI.OpenTradeSkill(professionsToScan[1].baseID)
    else
        addon.Logger:Error("No supported professions found.")
    end
end