SMODS.Atlas({
    key = "erbario",
    path = "erbario.png",
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function get_extra(card)
    return AG_UTIL.get_extra and AG_UTIL.get_extra(card) or nil
end

local function get_hands_kept(card)
    local e = get_extra(card)
    return e and e.hands_kept or 0
end

local function get_delay(card)
    local e = get_extra(card)
    return e and e.delay or 5
end

local function get_xmult(card)
    local e = get_extra(card)
    return e and e.xmult or 6
end

local function in_joker_slots(card)
    return G and G.jokers and card and card.area == G.jokers
end

local function destroy(card)
    if AG_UTIL.destroy_card then
        AG_UTIL.destroy_card(card, {
            colours = { G.C.RED },
            delay = 0,
            self_destruct = true,
            source_card = card,
        })
    end
end

SMODS.Joker({
    key = "erbario",
    atlas = "erbario",
    pos = { x = 0, y = 0 },
    name = "Erbario",
    rarity = 1,
    cost = 4,

    config = {
        extra = {
            hands_kept = 0,
            delay = 5,
            xmult = 6,
            destroy_ready = false,
            next_pulse = 0
        }
    },

    loc_txt = {
        name = "Erbario",
        text = {
            "Does nothing for the first",
            "{C:attention}#2#{} hands it is kept",
            "Then gains {X:mult,C:white}X#1#{} Mult",
            "and {C:red,E:2}self destructs{}",
            "{C:inactive}(Hands kept: #3#/#2#){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                get_xmult(card),
                get_delay(card),
                math.min(get_hands_kept(card), get_delay(card)),
            }
        }
    end,

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,

    locked_loc_vars = function()
        return { key = "ag_unlock_discover_drommo", set = "Other" }
    end,

    check_for_unlock = function(self, args)
        if not (args and args.type == "discover_amount") then return false end
        if not (G and G.P_CENTERS) then return false end

        for _, center in pairs(G.P_CENTERS) do
            if center
                and center.set == "Joker"
                and (
                    center.original_key == "drommo"
                    or center.key == "drommo"
                    or (type(center.key) == "string" and center.key:match("drommo$"))
                )
            then
                return center.discovered
            end
        end

        return false
    end,

    add_to_deck = function(self, card)
        get_extra(card)
    end,

    remove_from_deck = function(self, card)
    end,

    update = function(self, card, dt)
        local extra = card and card.ability and card.ability.extra

        if not extra then
            return
        end

        if extra.destroy_ready and not card.getting_sliced then
            AG_UTIL.update_ready_pulse(card, true)
        else
            AG_UTIL.update_ready_pulse(card, false)
        end
    end,

    calculate = function(self, card, context)
        if context.blueprint or card.getting_sliced then return end

        if context.before
            and not context.repetition
            and not context.individual
            and not context.retrigger_joker
        then
            local e = get_extra(card)
            if not e then return end

            if e.hands_kept < e.delay then
                e.hands_kept = e.hands_kept + 1

                if e.hands_kept >= e.delay and not e.destroy_ready then
                    e.destroy_ready = true
                    e.next_pulse = 0
                    card:juice_up(0.3, 0.4)
                end

                return {
                    message = tostring(math.max(0, e.delay - e.hands_kept)) .. " left",
                    colour = G.C.RED,
                }
            else
                if not e.destroy_ready then
                    e.destroy_ready = true
                    card:juice_up(0.3, 0.4)
                end
            end
        end

        if context.joker_main then
            local e = get_extra(card)
            if not e then return end

            if e.hands_kept >= e.delay then
                if not card.protected_from_destruct then
                    card:juice_up(0.8, 0.5)
                    destroy(card)
                else
                    if Aspirant and Aspirant.unlock_stunted then
                        Aspirant.unlock_stunted()
                    end
                    card.protected_from_destruct = nil
                end

                return {
                    Xmult_mod = get_xmult(card),
                    message = "X" .. tostring(get_xmult(card)),
                }
            end
        end
    end,
})
