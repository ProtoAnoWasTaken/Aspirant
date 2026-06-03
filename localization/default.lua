local loc = {
    descriptions = {
        Other = {
            ag_locked_joker = {
                name = "Locked",
                text = {
                    "Unlock this Joker to",
                    "read its description",
                }
            },
            ag_unlock_discover_drommo = {
                name = "Locked",
                text = {
                    "Unlock by discovering",
                    "{C:attention}Drommo{}",
                }
            },
            ag_unlock_discover_radicles = {
                name = "Locked",
                text = {
                    "Unlock by discovering",
                    "{C:attention}Radicles{}",
                }
            },
            ag_unlock_discover_peldan = {
                name = "Locked",
                text = {
                    "Unlock by discovering",
                    "{C:attention}Pel Dan{}",
                }
            },
            ag_unlock_discover_grisialfeistr = {
                name = "Locked",
                text = {
                    "Unlock by discovering",
                    "{C:attention}Grisial Feistr{}",
                }
            },
            ag_unlock_discover_weithiwrhaearn = {
                name = "Locked",
                text = {
                    "Unlock by discovering",
                    "{C:attention}Weithiwr Haearn{}",
                }
            },
            ag_unlock_discover_cloudcradle = {
                name = "Locked",
                text = {
                    "Unlock by discovering",
                    "{C:attention}Cloud Cradle{}",
                }
            },
            ag_unlock_voucher_precursor = {
                name = "Locked",
                text = {
                    "Unlock this voucher's",
                    "precursor first",
                }
            },
            ag_proposed_card = {
                name = "Proposed Card",
                text = {
                    "This card was proposed by",
                    "{C:red}#1#{}",
                }
            },
            ag_unlock_achievement_champion_acolyte = {
                name = "Locked",
                text = {
                    "Unlock by earning",
                    "{C:attention}Champion Acolyte{}",
                }
            },
            ag_unlock_achievement_through_solid_ground = {
                name = "Locked",
                text = {
                    "Unlock by earning",
                    "{C:attention}Through Solid Ground{}",
                }
            },
            ag_unlock_achievement_sunken_below = {
                name = "Locked",
                text = {
                    "Unlock by earning",
                    "{C:attention}Sunken Below{}",
                }
            },
            pinned_sticker = {
                name = "Suspended Motion",
                text = {
                    "This Joker cannot be",
                    "moved manually",
                }
            }
        },
        Mod = {
            Aspirant = {
                name = "Aspirant",
                text = {
                    "{s:1.2}An expansion of Balatro utilizing the aesthetics{}", "{s:1.2}and concepts of Termiteking9's Gears.{}",
                    " ",
                    "Programming and management by {C:blue}ProtoAno{}.",
                    "Card art by {C:red}Faowbot{}.",
                    "Minor credits appended where applicable.",
                }
            }
        },
    }
}

loc.descriptions.Back = loc.descriptions.Back or {}
loc.descriptions.Back.ag_unlock_discover_weithiwrhaearn = loc.descriptions.Other.ag_unlock_discover_weithiwrhaearn
loc.descriptions.Back.ag_unlock_discover_cloudcradle = loc.descriptions.Other.ag_unlock_discover_cloudcradle

if SMODS and SMODS.current_mod and SMODS.current_mod.manifest then
    local m = SMODS.current_mod.manifest
    local mod_desc = loc.descriptions.Mod.Aspirant
    if mod_desc and mod_desc.text then
        m.description = mod_desc.text
    end
end

return loc
