SMODS.Atlas({
    key = 'firmamentcrystal',
    path = 'firmamentcrystal.png',
    px = 69,
    py = 93,
})

Aspirant = rawget(_G, 'Aspirant') or {}

local function through_solid_ground_is_unlocked()
    if G and G.ACHIEVEMENTS and G.ACHIEVEMENTS.through_solid_ground then
        return G.ACHIEVEMENTS.through_solid_ground.earned or false
    end

    return G
        and G.SETTINGS
        and G.SETTINGS.ACHIEVEMENTS_EARNED
        and G.SETTINGS.ACHIEVEMENTS_EARNED.through_solid_ground
        or false
end

local function get_stone_count()
    local total = 0

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card
            and not playing_card.getting_sliced
            and SMODS.has_enhancement(playing_card, 'm_stone')
        then
            total = total + 1
        end
    end

    return total
end

local function get_mult(card)
    local mult_per_stone = (card.ability and card.ability.extra and card.ability.extra.mult_per_stone) or 5
    return get_stone_count() * mult_per_stone
end

local function get_unenhanced_targets()
    local targets = {}

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card
            and not playing_card.getting_sliced
            and playing_card.config
            and playing_card.config.center
            and playing_card.config.center == G.P_CENTERS.c_base
            and not playing_card.config.center.replace_base
        then
            targets[#targets + 1] = playing_card
        end
    end

    return targets
end

local function crystallize_random_card()
    local targets = get_unenhanced_targets()
    local target = #targets > 0 and pseudorandom_element(targets, pseudoseed('ag_firmamentcrystal')) or nil

    if not target then
        return nil
    end

    target:set_ability(G.P_CENTERS.m_stone, nil, true)
    target:juice_up()
    return target
end

SMODS.Joker({
    key = 'firmamentcrystal',
    atlas = 'firmamentcrystal',
    pos = { x = 0, y = 0 },
    name = 'Firmament Crystal',
    rarity = 3,
    cost = 8,

    config = { extra = { mult_per_stone = 2 } },

    loc_txt = {
        name = 'Firmament Crystal',
        text = {
            "This Joker gains {C:mult}+#2#{} Mult",
            "for each {C:attention,T:m_stone}Stone Card{} in the {C:attention}full deck{}",
            "Changes an unenhanced card",
            "to a {C:attention,T:m_stone}Stone Card{} once per round",
            "{C:inactive}(Currently {C:mult}+#1#{}{C:inactive} Mult){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.m_stone

        return {
            vars = {
                get_mult(card),
                (card.ability and card.ability.extra and card.ability.extra.mult_per_stone) or 5,
            }
        }
    end,

    unlocked = false,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function(self, info_queue, card)
        return { key = 'ag_unlock_achievement_through_solid_ground', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return through_solid_ground_is_unlocked()
    end,

    in_pool = function(self, args)
        return G and G.GAME and G.GAME.ag_andromeda_self_destructed == true
    end,

    calculate = function(self, card, context)
        if context.setting_blind
            and not context.blueprint
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            local target = crystallize_random_card()

            if target then
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
                    message = '+' .. tostring(mult) .. ' Mult',
                }
            end
        end
    end,
})
