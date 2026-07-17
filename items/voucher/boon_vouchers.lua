SMODS.Atlas({
    key = 'hyperalgesia',
    path = 'hyperalgesia.png',
    px = 71,
    py = 95,
})

SMODS.Atlas({
    key = 'alexithymia',
    path = 'alexithymia.png',
    px = 71,
    py = 95,
})

local AG = rawget(_G, 'Aspirant') or {}
local AG_UTIL = AG.joker_utils or {}
AG.voucher_effects = AG.voucher_effects or {}

local function drommo_is_discovered()
    return AG_UTIL
        and AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Joker', 'drommo')
end

local function hyperalgesia_is_discovered()
    return AG_UTIL
        and AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Voucher', 'hyperalgesia')
end

local function voucher_used(suffix)
    if not (G and G.GAME and G.GAME.used_vouchers) then
        return false
    end

    return G.GAME.used_vouchers['v_tk9g_' .. suffix]
        or G.GAME.used_vouchers['v_' .. suffix]
end

local function discard_random_hand_card()
    if not (G and G.hand and G.hand.cards and G.discard) then
        return
    end

    if #G.hand.cards <= 0 then
        return
    end

    local target = pseudorandom_element(G.hand.cards, pseudoseed('ag_hyperalgesia_discard'))

    if target then
        G.hand:unhighlight_all()
        G.hand:add_to_highlighted(target, true)
        G.FUNCS.discard_cards_from_highlighted(nil, true)
    end
end

local ag_draw_from_play_to_discard_ref = G.FUNCS.draw_from_play_to_discard

G.FUNCS.draw_from_play_to_discard = function(e)
    local result = ag_draw_from_play_to_discard_ref(e)

    if voucher_used('hyperalgesia') then
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.12,
            func = function()
                discard_random_hand_card()
                return true
            end,
        }))
    end

    return result
end

SMODS.Voucher({
    key = 'hyperalgesia',
    atlas = 'hyperalgesia',
    pos = { x = 0, y = 0 },
    name = 'Hyperalgesia',
    cost = 10,
    order = 5,
    unlocked = false,
    config = { extra = { booster_size = 1 } },

    loc_txt = {
        name = 'Hyperalgesia',
        text = {
            '{C:attention}1{} card is always discarded',
            'after playing a hand',
            '{C:attention}Booster Packs{} have',
            '{C:attention}1{} more option',
        },
    },

    locked_loc_vars = function()
        return { key = 'ag_unlock_discover_drommo', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and drommo_is_discovered()
    end,

    redeem = function(self)
        G.E_MANAGER:add_event(Event({
            func = function()
                G.GAME.modifiers.booster_size_mod = (G.GAME.modifiers.booster_size_mod or 0)
                    + self.config.extra.booster_size
                return true
            end,
        }))
    end,
})

SMODS.Voucher({
    key = 'alexithymia',
    atlas = 'alexithymia',
    pos = { x = 0, y = 0 },
    name = 'Alexithymia',
    cost = 10,
    order = 6,
    requires = { 'v_tk9g_hyperalgesia' },
    unlocked = false,
    config = { extra = { booster_choice = 1 } },

    loc_txt = {
        name = 'Alexithymia',
        text = {
            '{C:attention}Booster Packs{} have',
            '{C:attention}1{} more choice',
        },
    },

    locked_loc_vars = function()
        return { key = 'ag_unlock_voucher_precursor', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and hyperalgesia_is_discovered()
    end,

    redeem = function(self)
        G.E_MANAGER:add_event(Event({
            func = function()
                G.GAME.modifiers.booster_choice_mod = (G.GAME.modifiers.booster_choice_mod or 0)
                    + self.config.extra.booster_choice
                return true
            end,
        }))
    end,
})
