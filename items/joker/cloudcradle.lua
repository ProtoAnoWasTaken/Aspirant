SMODS.Atlas({
    key = 'cloudcradle',
    path = 'cloudcradle.png',
    px = 69,
    py = 93,
})

local function get_heart_count()
    local total = 0

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card:is_suit('Hearts') then
            total = total + 1
        end
    end

    return total
end

local function get_mult(card)
    return get_heart_count() * card.ability.extra.mult_per_heart
end

local function get_drawn_heart_targets(context)
    local targets = {}

    for _, drawn_card in ipairs(context.hand_drawn or {}) do
        if drawn_card:is_suit('Hearts') and not drawn_card.config.center.replace_base and drawn_card.config.center == G.P_CENTERS.c_base then
            targets[#targets + 1] = drawn_card
        end
    end

    return targets
end

SMODS.Joker({
    key = 'cloudcradle',
    atlas = 'cloudcradle',
    pos = { x = 0, y = 0 },
    name = 'Cloud Cradle',
    rarity = 3,
    cost = 8,

    config = { extra = { mult_per_heart = 2, changed_this_round = false } },

    loc_txt = {
        name = 'Cloud Cradle',
        text = {
            "{C:mult}+#2#{} Mult for every {C:hearts}Hearts{} card in the {C:attention}full deck{}",
            "Changes a drawn unenhanced {C:hearts}Hearts{} card",
            "to a {C:gold,T:m_gold}Gold Card{} once per round",
            "{C:inactive}(Currently {C:mult}+#1#{}{C:inactive} Mult){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_gold
        return { vars = { get_mult(card), card.ability.extra.mult_per_heart } }
    end,

    unlocked = false,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function(self, info_queue, card)
        return { key = "ag_unlock_achievement_champion_acolyte", set = "Other" }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == "champion_acolyte"
    end,

    calculate = function(self, card, context)
        if context.hand_drawn and not context.blueprint and not card.ability.extra.changed_this_round then
            local targets = get_drawn_heart_targets(context)
            local target = #targets > 0 and pseudorandom_element(targets, pseudoseed('ag_cloudcradle')) or nil

            if target then
                target:set_ability(G.P_CENTERS.m_gold, nil, true)
                target:juice_up()
                card.ability.extra.changed_this_round = true
                return {
                    message = localize('k_upgrade_ex'),
                    colour = G.C.SECONDARY_SET.Enhanced,
                    card = target,
                }
            end
        end

        if context.joker_main then
            local mult = get_mult(card)

            if mult > 0 then
                return {
                    mult_mod = mult,
                    message = '+' .. mult .. ' Mult',
                }
            end
        end

        if context.end_of_round and context.main_eval and not context.blueprint then
            card.ability.extra.changed_this_round = false
        end
    end,
})
