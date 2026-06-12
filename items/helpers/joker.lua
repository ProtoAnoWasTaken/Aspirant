Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant

AG.joker_utils = AG.joker_utils or {}
AG.joker_utils.arm_keys = AG.joker_utils.arm_keys or {
    'armofthewarrior',
    'armofthedemolitionist',
    'armofthearchitect',
    'armofthepioneer',
}

local AG_UTIL = AG.joker_utils

function AG_UTIL.get_extra(card)
    if not card then
        return nil
    end

    card.ability = card.ability or {}
    card.ability.extra = card.ability.extra or {}
    return card.ability.extra
end

function AG_UTIL.center_matches(center, suffix)
    return center
        and (
            center.original_key == suffix
            or center.key == suffix
            or (type(center.key) == 'string' and center.key:match(suffix .. '$') ~= nil)
        )
end

function AG_UTIL.find_center_by_suffix(set_name, suffix)
    if not G or not G.P_CENTERS then
        return nil
    end

    for _, center in pairs(G.P_CENTERS) do
        if center
            and center.set == set_name
            and AG_UTIL.center_matches(center, suffix)
        then
            return center
        end
    end

    return nil
end

function AG_UTIL.is_center_discovered(set_name, suffix)
    local center = AG_UTIL.find_center_by_suffix(set_name, suffix)
    return center and center.discovered or false
end

function AG_UTIL.format_xmult(value)
    local formatted = string.format('%.2f', value)
    formatted = formatted:gsub('(%..-)0+$', '%1')
    return formatted:gsub('%.$', '')
end

function AG_UTIL.is_glass_card(card)
    return card
        and (
            (SMODS and SMODS.has_enhancement and SMODS.has_enhancement(card, 'm_glass'))
            or (card.ability and card.ability.effect == 'Glass Card')
        )
end

function AG_UTIL.is_food_joker(card)
    return card
        and card.is_food
        and card:is_food()
end

function AG_UTIL.center_mentions_self_destruct(center)
    local text = center and center.loc_txt and center.loc_txt.text
    if type(text) ~= 'table' then
        return false
    end

    for _, line in ipairs(text) do
        if type(line) == 'string' then
            local normalized = line:lower():gsub('%b{}', ''):gsub('%-', ' ')
            if normalized:find('self%s+destruct') then
                return true
            end
        end
    end

    return false
end

function AG_UTIL.is_self_destructing_joker(card)
    local center = card and card.config and card.config.center
    return AG_UTIL.is_food_joker(card)
        or AG_UTIL.center_mentions_self_destruct(center)
end

function AG_UTIL.count_self_destructs(context, source_card)
    if not context or context.blueprint then
        return 0
    end

    local destroyed_card = context.destroyed_card or context.card
    if context.ag_card_self_destructed and destroyed_card and destroyed_card ~= source_card then
        return 1
    end

    if context.joker_type_destroyed
        and destroyed_card
        and destroyed_card ~= source_card
        and not context.selling_self
        and not destroyed_card.ag_destroy_reported_by_aspirant
        and AG_UTIL.is_self_destructing_joker(destroyed_card)
    then
        return 1
    end

    if context.remove_playing_cards and type(context.removed) == 'table' then
        local glass_cards = 0

        for _, removed_card in ipairs(context.removed) do
            if AG_UTIL.is_glass_card(removed_card) and not removed_card.ag_self_destruct_reported then
                glass_cards = glass_cards + 1
            end
        end

        return glass_cards
    end

    return 0
end

function AG_UTIL.notify_card_created(source_card, created_card)
    if SMODS and SMODS.calculate_context and source_card and created_card then
        SMODS.calculate_context({
            ag_lemurian_created_card = source_card:is_lemurian(),
            ag_card_created = true,
            source_card = source_card,
            created_card = created_card,
            card = created_card,
        })
    end
end

function AG_UTIL.destroy_card(card, opts)
    opts = opts or {}

    if not card or card.getting_sliced then
        return false
    end

    local self_destruct = opts.self_destruct
    if self_destruct == nil then
        self_destruct = opts.source_card ~= nil and opts.source_card == card
    end

    card.ag_destroy_reported_by_aspirant = true
    if self_destruct then
        card.ag_self_destruct_reported = true
    end

    if SMODS and SMODS.calculate_context then
        SMODS.calculate_context({
            ag_lemurian_destroyed_card = opts.source_card and opts.source_card:is_lemurian() or false,
            ag_card_self_destructed = self_destruct,
            source_card = opts.source_card,
            destroyed_card = card,
            card = card,
        })
    end

    card.getting_sliced = true

    G.E_MANAGER:add_event(Event({
        trigger = opts.trigger or 'after',
        delay = opts.delay or 0.1,
        func = function()
            if card and not card.removed then
                if type(opts.sound) == 'string' then
                    play_sound(opts.sound, opts.pitch or 1, opts.volume or 1)
                elseif opts.sound ~= false then
                    play_sound('glass' .. math.random(1, 6), math.random() * 0.2 + 0.9, 0.5)
                end
                card:start_dissolve(opts.colours, opts.silent, opts.time or 1.6)
            end
            return true
        end,
    }))

    return true
end

function AG_UTIL.get_adjacent_jokers(card)
    if not G or not G.jokers or not G.jokers.cards then
        return {}
    end

    local adjacent = {}
    local card_index = nil

    for i, joker in ipairs(G.jokers.cards) do
        if joker == card then
            card_index = i
            break
        end
    end

    if not card_index then
        return adjacent
    end

    if card_index > 1 then
        adjacent[#adjacent + 1] = G.jokers.cards[card_index - 1]
    end

    if card_index < #G.jokers.cards then
        adjacent[#adjacent + 1] = G.jokers.cards[card_index + 1]
    end

    return adjacent
end

function AG_UTIL.consume_protective_beam(card)
    for _, adjacent_joker in ipairs(AG_UTIL.get_adjacent_jokers(card)) do
        local center = adjacent_joker and adjacent_joker.config and adjacent_joker.config.center

        if adjacent_joker
            and not adjacent_joker.getting_sliced
            and AG_UTIL.center_matches(center, 'protectivebeam')
        then
            card.protected_from_destruct = true
            adjacent_joker:juice_up(0.8, 0.5)
            play_sound('glass' .. math.random(1, 6), math.random() * 0.2 + 0.9, 0.5)
            AG_UTIL.destroy_card(adjacent_joker, {
                colours = { G.C.RED },
                delay = 0,
                self_destruct = true,
                source_card = adjacent_joker,
            })
            card.protected_from_destruct = nil
            return true
        end
    end

    return false
end

function AG_UTIL.get_arm_cards()
    local arm_cards = {}

    if not G or not G.jokers or not G.jokers.cards then
        return arm_cards
    end

    for _, suffix in ipairs(AG_UTIL.arm_keys or {}) do
        for _, joker in ipairs(G.jokers.cards) do
            local center = joker and joker.config and joker.config.center
            if joker
                and not joker.getting_sliced
                and center
                and AG_UTIL.center_matches(center, suffix)
            then
                arm_cards[suffix] = joker
                break
            end
        end
    end

    return arm_cards
end

function AG_UTIL.try_combine_arms(trigger_card)
    if AG.arm_combine_in_progress then
        return false
    end

    local arm_cards = AG_UTIL.get_arm_cards()

    for _, suffix in ipairs(AG_UTIL.arm_keys or {}) do
        if not arm_cards[suffix] then
            return false
        end
    end

    local nephilim_center = AG_UTIL.find_center_by_suffix('Joker', 'manmadenephilim')
    if not nephilim_center or not G or not G.jokers then
        return false
    end

    AG.arm_combine_in_progress = true

    local inherited_mult = 0

    for _, suffix in ipairs({
        'armofthewarrior',
        'armofthedemolitionist',
        'armofthearchitect',
    }) do
        local arm_card = arm_cards[suffix]
        local extra = AG_UTIL.get_extra and AG_UTIL.get_extra(arm_card) or nil
        inherited_mult = inherited_mult + ((extra and extra.mult) or 0)
    end

    for _, suffix in ipairs(AG_UTIL.arm_keys or {}) do
        AG_UTIL.destroy_card(arm_cards[suffix], {
            colours = { G.C.RED },
            source_card = trigger_card or arm_cards[suffix],
            sound = false,
            delay = 0.1,
        })
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.25,
        func = function()
            local nephilim = create_card('Joker', G.jokers, nil, nil, true, nil, nephilim_center.key, 'ag_arm_reunion')
            local nephilim_extra = AG_UTIL.get_extra and AG_UTIL.get_extra(nephilim) or nil

            if nephilim_extra then
                nephilim_extra.mult = inherited_mult
            end

            nephilim:add_to_deck()
            G.jokers:emplace(nephilim)
            nephilim:start_materialize()

            if G.jokers.align_cards then
                G.jokers:align_cards()
            end

            if AG.unlock_sunken_below then
                AG.unlock_sunken_below()
            end

            AG_UTIL.notify_card_created(trigger_card or nephilim, nephilim)
            AG.arm_combine_in_progress = false
            return true
        end,
    }))

    return true
end

function AG_UTIL.update_ready_pulse(card, ready, pulse_key, interval)
    local extra = AG_UTIL.get_extra(card)
    local now = (G and G.TIMERS and G.TIMERS.REAL) or 0

    pulse_key = pulse_key or 'next_pulse'
    interval = interval or 0.8

    if ready then
        if now >= (extra[pulse_key] or 0) then
            card:juice_up(0.15, 0.2)
            extra[pulse_key] = now + interval
        end
    else
        extra[pulse_key] = 0
    end

    return ready
end
