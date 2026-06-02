SMODS.Atlas({
    key = "skiron",
    path = "skiron.png",
    px = 69,
    py = 93,
})

Aspirant = rawget(_G, "Aspirant") or {}

local AG = Aspirant

SMODS.Joker({
    key = "skiron",
    atlas = "skiron",
    pos = { x = 0, y = 0 },
    name = "Skiron",
    rarity = 2,
    cost = 6,

    loc_txt = {
        name = "Skiron",
        text = {
            "{C:attention,t:m_glass}Glass Cards{} never break",
        },
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_glass
    end,

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function(self, info_queue, card)
        return { key = "ag_unlock_achievement_champion_acolyte", set = "Other" }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == "champion_acolyte"
    end,

    add_to_deck = function(self, card, from_debuff)
        if AG.refresh_glass_state then
            AG.refresh_glass_state()
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        if AG.refresh_glass_state then
            AG.refresh_glass_state(card)
        end
    end,

    update = function(self, card, dt)
        if AG.ensure_glass_state_current then
            AG.ensure_glass_state_current()
        end
    end,

    calculate = function(self, card, context)
        if context.blueprint then
            return
        end

        if AG.ensure_glass_state_current then
            AG.ensure_glass_state_current()
        end

        if context.fix_probability
            and context.identifier == "glass"
            and AG.glass_state
            and AG.glass_state.skiron_active
        then
            return {
                numerator = 0,
                denominator = 1,
            }
        end
    end,
})
