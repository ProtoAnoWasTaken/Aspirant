SMODS.Atlas({
    key = "radicles",
    path = "radicles.png",
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

local function get_xmult(card)
    return (card.ability and card.ability.extra and card.ability.extra.xmult) or 1
end

local function get_gain(card)
    return (card.ability and card.ability.extra and card.ability.extra.gain) or 0.5
end

local function format_xmult(value)
    return AG_UTIL.format_xmult and AG_UTIL.format_xmult(value) or tostring(value)
end

local function center_matches(center, suffix)
    return AG_UTIL.center_matches and AG_UTIL.center_matches(center, suffix) or false
end

local function is_drommo_discovered()
    return AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered("Joker", "drommo")
        or false
end

local function is_common_joker(card, source_card)
    local center = card and card.config and card.config.center
    local rarity = center and center.rarity

    if rarity == "Common" then
        rarity = 1
    end

    if type(rarity) == "string" then
        rarity = rarity:lower()
    end

    return card
        and card ~= source_card
        and not card.getting_sliced
        and center
        and (
            rarity == 1
            or rarity == "common"
        )
end

local function get_special_target_data(target)
    local center = target and target.config and target.config.center

    if center_matches(center, "harvest") then
        return {
            xmult_gain = 3,
            message = "X3",
        }
    end

    if center_matches(center, "erbario") then
        return {
            xmult_gain = 2,
            message = "X2",
        }
    end

    return nil
end

local function get_destroyable_targets(source_card)
    local special_targets = {}
    local common_targets = {}

    if not G or not G.jokers or not G.jokers.cards then
        return special_targets, common_targets
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker ~= source_card and not joker.getting_sliced then
            local special_data = get_special_target_data(joker)

            if special_data then
                special_targets[#special_targets + 1] = {
                    card = joker,
                    xmult_gain = special_data.xmult_gain,
                    message = special_data.message,
                }
            elseif is_common_joker(joker, source_card) then
                common_targets[#common_targets + 1] = joker
            end
        end
    end

    return special_targets, common_targets
end

local function destroy_joker(source_card, target)
    if AG_UTIL.destroy_card then
        AG_UTIL.destroy_card(target, {
            colours = { G.C.RED },
            source_card = source_card,
            self_destruct = false,
        })
    end
end

local function consume_target(card)
    local special_targets, common_targets = get_destroyable_targets(card)
    local target = nil
    local xmult_gain = nil
    local message = nil

    if #special_targets > 0 then
        local selected = pseudorandom_element(special_targets, pseudoseed("ag_radicles_secret"))
        if selected then
            target = selected.card
            xmult_gain = selected.xmult_gain
            message = selected.message
        end
    elseif #common_targets > 0 then
        target = pseudorandom_element(common_targets, pseudoseed("ag_radicles_common"))
        xmult_gain = get_gain(card)
        message = "X" .. format_xmult(get_gain(card))
    end

    if not target or not xmult_gain then
        return nil
    end

    card.ability.extra.xmult = get_xmult(card) + xmult_gain
    destroy_joker(card, target)

    return {
        target = target,
        xmult_gain = xmult_gain,
        message = message,
    }
end

SMODS.Joker({
    key = "radicles",
    atlas = "radicles",
    pos = { x = 0, y = 0 },
    name = "Radicles",
    rarity = 3,
    cost = 8,

    config = { extra = { xmult = 1, gain = 0.5 } },

    loc_txt = {
        name = "Radicles",
        text = {
            "When {C:attention}Blind{} is selected,",
            "destroy a random {C:blue}Common{} Joker",
            "and gain {X:mult,C:white}X#2#{} Mult",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive} Mult){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                format_xmult(get_xmult(card)),
                format_xmult(get_gain(card)),
            }
        }
    end,

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    locked_loc_vars = function()
        return { key = "ag_unlock_discover_drommo", set = "Other" }
    end,

    check_for_unlock = function(self, args)
        if not (args and args.type == "discover_amount") then
            return false
        end

        return is_drommo_discovered()
    end,

    calculate = function(self, card, context)
        if context.setting_blind
            and not context.blueprint
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            local result = consume_target(card)

            if result then
                return {
                    message = result.message,
                    colour = G.C.MULT,
                    card = result.target,
                }
            end
        end

        if context.joker_main and get_xmult(card) > 1 then
            return {
                Xmult_mod = get_xmult(card),
                message = "X" .. format_xmult(get_xmult(card)),
            }
        end
    end,
})
