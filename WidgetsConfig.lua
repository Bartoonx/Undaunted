local ADDON_NAME, addon = ...

addon.Settings = {
    enabled = true,
    style = "Custom",
}
-- self explained, kind is from WidgetsLoader.lua
addon.WidgetsConfig = {
    [1] = {
        {
            label = "Raid Warning",
            entries = {
                {
                    kind = "checkbox",
                    label = "Enable scaling default Raid Warning Message",
                    setter = function(s, v) s.enabledCustomRaidWarning = v end,
                    getter = function(s) return s.enabledCustomRaidWarning end,
                },
                {
                    kind = "slider",
                    label = "Default Raid Warning Scale",
                    min = 1.0,
                    max = 3.0,
                    step = 0.1,
                    setter = function (s, v) s.raidWarningScale = v end,
                    getter = function(s) return s.raidWarningScale end
                },
                {
                    kind = "checkbox",
                    label = "Hide the default Raid Warning Message",
                    setter = function(s, v) s.hide = v end,
                    getter = function(s) return s.hide end,
                },
                {
                    kind = "sep"
                },
                {
                    kind = "checkbox",
                    label = "Enable external raid warning windows",
                    setter = function(s, v) s.externalRaidWarningWindows = v end,
                    getter = function(s) return s.externalRaidWarningWindows end,
                },
                {
                    kind = "color",
                    label = "Text Color",
                    key = "textColor",
                    onChange = function(s, r,g,b) 
                        s.textColor.r = r
                        s.textColor.g = g
                        s.textColor.b = b
                    end
                },
                {
                    kind = "slider",
                    label = "Font Size",
                    min = 16,
                    max = 128,
                    step = 1,
                    setter = function(s,v) s.fontSize = v end,
                    getter = function(s) return s.fontSize end,
                },
                {
                    kind = "slider",
                    label = "Seconds to fade out",
                    min = 1,
                    max = 10,
                    step = 1,
                    setter = function(s,v) s.timerFade = v end,
                    getter = function (s) return s.timerFade end,
                },
                {
                    kind = "dropdown",
                    label = "Font",
                    isFont = true,
                    getInitData = function() 
                        return {
                            "Friz Quadrata TT", 
                            "Arial Narrow", 
                            "Skurri", 
                            "Morpheus"
                        }, {
                            "Fonts\\FRIZQT__.TTF",
                            "Fonts\\ARIALN.TTF", 
                            "Fonts\\SKURRI.TTF",
                            "Fonts\\MORPHEUS.TTF"
                        }
                    end,
                    setter = function(s, v) s.font = v end,
                    getter = function(s) return s.font end
                },
                {
                    kind = "button",
                    label = "Test Raid Warning",
                    onClick = function()
                        local messages = {
                            "Hello there! I hope you're enjoying using this addon and all its neat features. Keep up the great work in your raids!",
                            "Howdy! Just a friendly reminder to check your buffs, watch your cooldowns, and have fun in this raid!",
                            "Attention everyone! Make sure to stay aware of mechanics and communicate with your team. This addon helps, but teamwork matters most!",
                            "This is a really long test message to see how it looks inside the RaidWarningFrame. It should display fully and wrap nicely if it's too long."
                        }
                        local msg = messages[random(#messages)]
                        RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
                    end
                }

            }
        }
    },
    [2] = {
        {
            label = "Healer Mana",
            entries = {
                {
                    kind = "checkbox",
                    label = "Enable",
                    setter = function(s, v) addon.HealerMana:Toggle(v) end,
                    getter = function(s) return s.healerMana.enabled end,
                },
                {
                    kind = "checkbox",
                    label = "Raid Only",
                    setter = function(s, v) s.healerMana.onlyInsideRaid = v addon.HealerMana:Refresh() end,
                    getter = function(s) return s.healerMana.onlyInsideRaid end,
                },
                {
                    kind = "checkbox",
                    label = "Class Colors",
                    setter = function(s, v) s.healerMana.classColor = v addon.HealerMana:Refresh() end,
                    getter = function(s) return s.healerMana.classColor end,
                },
                {
                    kind = "dropdown",
                    label = "Name Text",
                    getInitData = function() 
                        return {"Player Name", "Class Name", "Hidden"}, 
                            {"name", "class", "none"}
                    end,
                    setter = function(s, v) 
                        s.healerMana.nameText = v 
                        addon.HealerMana:Refresh()
                    end,
                    getter = function(s) return s.healerMana.nameText or "name" end,
                },
                {
                    kind = "checkbox",
                    label = "Show %",
                    setter = function(s, v) s.healerMana.showPercent = v addon.HealerMana:Refresh() end,
                    getter = function(s) return s.healerMana.showPercent end,
                },
                {
                    kind = "sep"
                },
                {
                    kind = "slider",
                    label = "Width",
                    min = 100,
                    max = 400,
                    step = 10,
                    setter = function(s, v) addon.HealerMana:SetWidth(v) end,
                    getter = function(s) return s.healerMana.width end,
                },
                {
                    kind = "slider",
                    label = "Height",
                    min = 15,
                    max = 50,
                    step = 1,
                    setter = function(s, v) addon.HealerMana:SetHeight(v) end,
                    getter = function(s) return s.healerMana.height end,
                },
                {
                    kind = "slider",
                    label = "Max Bars",
                    min = 1,
                    max = 20,
                    step = 1,
                    setter = function(s, v) s.healerMana.maxBars = v addon.HealerMana:Refresh() end,
                    getter = function(s) return s.healerMana.maxBars end,
                },
                {
                    kind = "sep"
                },
                {
                    kind = "dropdown",
                    label = "Sort By",
                    getInitData = function() 
                        return {"Mana %", "Name"}, {"mana", "name"}
                    end,
                    setter = function(s, v) s.healerMana.sortBy = v addon.HealerMana:Refresh() end,
                    getter = function(s) return s.healerMana.sortBy end,
                },
                {
                    kind = "color",
                    label = "Color",
                    key = "healerMana.color",
                    onChange = function(s, r, g, b, a) 
                        s.healerMana.color.r = r
                        s.healerMana.color.g = g
                        s.healerMana.color.b = b
                        if a then s.healerMana.color.a = a end
                        addon.HealerMana:Refresh()
                    end
                },
                {
                    kind = "color",
                    label = "Background Color",
                    key = "healerMana.background",
                    onChange = function(s, r, g, b, a) 
                        s.healerMana.background.r = r
                        s.healerMana.background.g = g
                        s.healerMana.background.b = b
                        if a then s.healerMana.background.a = a end
                        addon.HealerMana:Refresh()
                    end
                }
            }
        }
    },
    [3] = {
        {
            label = "Notes",
            entries = {
                {
                    kind = "notesContainer",
                    leftWidth = 150,
                    topHeight = 30,
                    bottomHeight = 40
                }
            }
        }
    },
    [4] = {
    {
        label = "Note Display",
        entries = {
            {
                kind = "checkbox",
                label = "Enable On-Screen Note Display",
                getter = function(s) return s.noteDisplay.enabled end,
                setter = function(s, v) 
                    s.noteDisplay.enabled = v
                    if v then
                        addon.NoteDisplay:Show("Test Note", "This is a test note.\n\n{rt1} Star marker\n{rt2} Circle marker\n\n{tank} Tank role\n{healer} Healer role")
                    else
                        addon.NoteDisplay:Hide()
                    end
                end
            },
            {
                kind = "slider",
                label = "Background Opacity",
                min = 0.1,
                max = 1.0,
                step = 0.1,
                getter = function(s) return s.noteDisplay.alpha or 0.8 end,
                setter = function(s, v)
                    s.noteDisplay.alpha = v
                    addon.NoteDisplay:SetAlpha(v)  -- Use addon here too
                end
            },
            {
                kind = "button",
                label = "Test Display",
                onClick = function()
                    addon.NoteDisplay:Show("Test Note", "{rt8} Pull at skull\n{tank} Tank picks up adds\n{healer} Healers stack on green\n\nPhase 2 at 50%!")
                end
            }
        }
    }
    },

}
