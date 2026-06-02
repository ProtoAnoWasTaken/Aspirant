SMODS.Atlas({
    key = 'kyawatsarr',
    path = 'kyawatsarr.png',
    px = 69,
    py = 93,
})

local function copy_edition_state(edition)
    if not edition then
        return nil
    end

    if type(edition) == 'string' then
        return edition
    end

    return copy_table and copy_table(edition) or {
        foil = edition.foil,
        holo = edition.holo,
        polychrome = edition.polychrome,
        negative = edition.negative,
    }
end

local function get_targets(card)
    local extra = card and card.ability and card.ability.extra
    if not extra then
        return {}
    end

    extra.targets = extra.targets or {}
    return extra.targets
end

local function has_active_targets(card)
    return #get_targets(card) > 0
end

local function set_ready_to_assign(card, value)
    if card and card.ability and card.ability.extra then
        card.ability.extra.ready_to_assign = value == true
    end
end

local function is_ready_to_assign(card)
    return card
        and card.ability
        and card.ability.extra
        and card.ability.extra.ready_to_assign == true
end

local function restore_original_edition(target)
    if not target or not target.card or target.card.removed then
        return
    end

    if target.original_edition then
        local edition = copy_edition_state(target.original_edition)

        if type(edition) == 'string' then
            target.card:set_edition(edition)
        else
            target.card:set_edition(edition, true, true)
        end
    else
        target.card:set_edition(nil, true, true)
    end
end

local function choose_random_cards(cards, amount)
    local pool = {}
    local chosen = {}

    for _, playing_card in ipairs(cards or {}) do
        if playing_card and not playing_card.getting_sliced then
            pool[#pool + 1] = playing_card
        end
    end

    for i = 1, math.min(amount, #pool) do
        local selected = pseudorandom_element(pool, pseudoseed('ag_kyawatsarr_' .. tostring(i))) or nil
        if not selected then
            break
        end

        chosen[#chosen + 1] = selected

        for pool_index, pool_card in ipairs(pool) do
            if pool_card == selected then
                table.remove(pool, pool_index)
                break
            end
        end
    end

    return chosen
end

local function get_drawn_cards(context)
    if context and context.hand_drawn and #context.hand_drawn > 0 then
        return context.hand_drawn
    end

    if context and context.first_hand_drawn and G and G.hand and G.hand.cards then
        return G.hand.cards
    end

    return {}
end

local function assign_temp_foils(card, drawn_cards)
    if not is_ready_to_assign(card) or has_active_targets(card) then
        return 0
    end

    local chosen_cards = choose_random_cards(drawn_cards, 2)
    local targets = get_targets(card)

    for _, playing_card in ipairs(chosen_cards) do
        targets[#targets + 1] = {
            card = playing_card,
            original_edition = copy_edition_state(playing_card.edition),
        }

        playing_card:set_edition({ foil = true }, true, true)
        playing_card:juice_up()
    end

    if #targets > 0 then
        set_ready_to_assign(card, false)
    end

    return #targets
end

local function mark_played_targets(card, played_cards)
    local targets = get_targets(card)
    local any_newly_played = false

    for _, target in ipairs(targets) do
        if not target.played then
            for _, played_card in ipairs(played_cards or {}) do
                if target.card == played_card then
                    target.played = true
                    restore_original_edition(target)
                    any_newly_played = true
                    break
                end
            end
        end
    end

    if not any_newly_played then
        return false
    end

    for _, target in ipairs(targets) do
        if not target.played and target.card and not target.card.removed then
            return false
        end
    end

    card.ability.extra.targets = {}
    set_ready_to_assign(card, true)
    return true
end

local function mark_discarded_targets(card, discarded_cards)
    local targets = get_targets(card)
    local any_newly_discarded = false

    for _, target in ipairs(targets) do
        if not target.played then
            for _, discarded_card in ipairs(discarded_cards or {}) do
                if target.card == discarded_card then
                    target.played = true
                    restore_original_edition(target)
                    any_newly_discarded = true
                    break
                end
            end
        end
    end

    if not any_newly_discarded then
        return false
    end

    for _, target in ipairs(targets) do
        if not target.played and target.card and not target.card.removed then
            return false
        end
    end

    card.ability.extra.targets = {}
    set_ready_to_assign(card, true)
    return true
end

SMODS.Joker({
    key = 'kyawatsarr',
    atlas = 'kyawatsarr',
    pos = { x = 0, y = 0 },
    name = 'Kyawatsarr',
    rarity = 3,
    cost = 7,

    config = { extra = { targets = {}, ready_to_assign = true } },

    loc_txt = {
        name = 'Kyawatsarr',
        text = {
            "Give {C:attention}2{} random drawn cards",
            "temporary {C:dark_edition}Foil{}",
            "Foils recharge after play"
        }
    },

    unlocked = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    calculate = function(self, card, context)
        if (context.hand_drawn or context.first_hand_drawn) and not context.blueprint and not card.getting_sliced then
            if assign_temp_foils(card, get_drawn_cards(context)) > 0 then
                return {
                    message = 'Discharged!',
                    colour = G.C.ATTENTION,
                }
            end
        end

        if context.after
            and not context.blueprint
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            if mark_played_targets(card, context.scoring_hand or {}) then
                card:juice_up(0.3, 0.4)
                return {
                    message = 'Recharged!',
                    colour = G.C.GREEN,
                }
            end
        end

        if context.pre_discard
            and not context.blueprint
            and not card.getting_sliced
        then
            if mark_discarded_targets(card, context.full_hand or {}) then
                card:juice_up(0.3, 0.4)
                return {
                    message = 'Recharged!',
                    colour = G.C.GREEN,
                }
            end
        end
    end,
})
