Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant

AG.joker_utils = AG.joker_utils or {}
AG.joker_utils.arm_keys = AG.joker_utils.arm_keys or {
    'armofthewarrior',
    'armofthedemolitionist',
    'armofthearchitect',
    'armofthepioneer',
}
AG.arm_commonness = AG.arm_commonness or {
    boost = 0.10,
    installed = {},
    polling_uncommon_joker = false,
}
AG.destroy_source_stack = AG.destroy_source_stack or {}
AG.destroy_source_hooks_installed = AG.destroy_source_hooks_installed or {}

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

function AG_UTIL.push_card_destroy_source(card)
    if card then
        AG.destroy_source_stack[#AG.destroy_source_stack + 1] = card
    end
end

function AG_UTIL.pop_card_destroy_source(card)
    if not card or #AG.destroy_source_stack == 0 then
        return
    end

    for i = #AG.destroy_source_stack, 1, -1 do
        if AG.destroy_source_stack[i] == card then
            table.remove(AG.destroy_source_stack, i)
            return
        end
    end
end

function AG_UTIL.current_card_destroy_source(excluded_card)
    for i = #AG.destroy_source_stack, 1, -1 do
        local source_card = AG.destroy_source_stack[i]
        if source_card and source_card ~= excluded_card then
            return source_card
        end
    end

    return nil
end

function AG_UTIL.wrap_destroy_source_events(source_card)
    if not (source_card and G and G.E_MANAGER and G.E_MANAGER.add_event) then
        return nil
    end

    local add_event_ref = G.E_MANAGER.add_event

    G.E_MANAGER.add_event = function(event_manager, event)
        if event and type(event.func) == 'function' then
            local func_ref = event.func

            event.func = function(...)
                AG_UTIL.push_card_destroy_source(source_card)
                local results = { func_ref(...) }
                AG_UTIL.pop_card_destroy_source(source_card)
                return unpack(results)
            end
        end

        return add_event_ref(event_manager, event)
    end

    return add_event_ref
end

function AG_UTIL.unwrap_destroy_source_events(add_event_ref)
    if add_event_ref and G and G.E_MANAGER then
        G.E_MANAGER.add_event = add_event_ref
    end
end

function AG_UTIL.count_cards_destroyed_by_card(context, observer_card)
    if not context or context.blueprint then
        return 0
    end

    local source_card = context.source_card or AG_UTIL.current_card_destroy_source(observer_card)
    if not source_card then
        return 0
    end

    local destroyed_card = context.destroyed_card or context.card

    if context.ag_card_destroyed_by_card and destroyed_card and destroyed_card ~= source_card then
        return 1
    end

    if context.joker_type_destroyed
        and destroyed_card
        and destroyed_card ~= source_card
        and not context.selling_self
        and not destroyed_card.ag_destroy_reported_by_aspirant
    then
        return 1
    end

    if context.remove_playing_cards and type(context.removed) == 'table' then
        local destroyed_count = 0

        for _, removed_card in ipairs(context.removed) do
            if removed_card and removed_card ~= source_card then
                destroyed_count = destroyed_count + 1
            end
        end

        return destroyed_count
    end

    return 0
end

function AG_UTIL.install_destroy_source_hooks()
    if not Card then
        return
    end

    if Card.calculate_joker and not AG.destroy_source_hooks_installed.calculate_joker then
        local calculate_joker_ref = Card.calculate_joker

        function Card:calculate_joker(context)
            local tracked_jokers = nil

            if G and G.jokers and G.jokers.cards then
                tracked_jokers = {}

                for _, joker in ipairs(G.jokers.cards) do
                    tracked_jokers[joker] = joker.getting_sliced or false
                end
            end

            local add_event_ref = AG_UTIL.wrap_destroy_source_events(self)
            AG_UTIL.push_card_destroy_source(self)
            local results = { calculate_joker_ref(self, context) }
            AG_UTIL.pop_card_destroy_source(self)
            AG_UTIL.unwrap_destroy_source_events(add_event_ref)

            local effect = results[1]
            local destroyed_target = context and (context.destroy_card or context.other_card)

            if destroyed_target
                and destroyed_target ~= self
                and not context.ag_card_destroyed_by_card
                and not destroyed_target.ag_card_destroy_source_reported
                and effect
                and effect.remove
                and SMODS
                and SMODS.calculate_context
            then
                destroyed_target.ag_card_destroy_source_reported = true
                SMODS.calculate_context({
                    ag_card_destroyed_by_card = true,
                    source_card = self,
                    destroyed_card = destroyed_target,
                    card = destroyed_target,
                })
            end

            if tracked_jokers and SMODS and SMODS.calculate_context then
                for joker, was_getting_sliced in pairs(tracked_jokers) do
                    if joker
                        and joker ~= self
                        and not was_getting_sliced
                        and joker.getting_sliced
                        and not joker.ag_destroy_reported_by_aspirant
                        and not joker.ag_card_destroy_source_reported
                    then
                        joker.ag_card_destroy_source_reported = true
                        SMODS.calculate_context({
                            ag_card_destroyed_by_card = true,
                            source_card = self,
                            destroyed_card = joker,
                            card = joker,
                        })
                    end
                end
            end

            return unpack(results)
        end

        AG.destroy_source_hooks_installed.calculate_joker = true
    end

    if Card.use_consumeable and not AG.destroy_source_hooks_installed.use_consumeable then
        local use_consumeable_ref = Card.use_consumeable

        function Card:use_consumeable(...)
            AG_UTIL.push_card_destroy_source(self)
            local results = { use_consumeable_ref(self, ...) }
            AG_UTIL.pop_card_destroy_source(self)
            return unpack(results)
        end

        AG.destroy_source_hooks_installed.use_consumeable = true
    end
end

AG_UTIL.install_destroy_source_hooks()

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
            ag_card_destroyed_by_card = opts.source_card and opts.source_card ~= card or false,
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

function AG_UTIL.count_other_arm_cards(target_suffix)
    local count = 0
    local arm_cards = AG_UTIL.get_arm_cards()

    for _, suffix in ipairs(AG_UTIL.arm_keys or {}) do
        if suffix ~= target_suffix and arm_cards[suffix] then
            count = count + 1
        end
    end

    return count
end

function AG_UTIL.is_shop_or_booster_append(append)
    return type(append) == 'string'
        and (
            append:find('sho', 1, true) ~= nil
            or append:find('buf', 1, true) ~= nil
        )
end

function AG_UTIL.is_uncommon_rarity(rarity)
    return rarity == 2
        or rarity == 'Uncommon'
        or rarity == 'uncommon'
end

function AG_UTIL.is_uncommon_joker_poll(args)
    if not args or args.type ~= 'Joker' or not AG_UTIL.is_shop_or_booster_append(args.append) then
        return false
    end

    if AG_UTIL.is_uncommon_rarity(args.rarity) then
        return true
    end

    if type(args.rarities) == 'table' then
        for _, rarity in ipairs(args.rarities) do
            if AG_UTIL.is_uncommon_rarity(rarity) then
                return true
            end
        end

        return false
    end

    return args.rarity == nil
end

function AG_UTIL.install_arm_commonness_weights()
    if not (G and G.P_CENTERS) then
        return
    end

    for _, suffix in ipairs(AG_UTIL.arm_keys or {}) do
        local arm_suffix = suffix
        local center = AG_UTIL.find_center_by_suffix('Joker', suffix)
        local install_key = center and center.key

        if center and install_key and not AG.arm_commonness.installed[install_key] then
            local get_weight_ref = center.get_weight

            center.get_weight = function(self, ...)
                local weight = get_weight_ref and get_weight_ref(self, ...) or self.weight or 1

                if AG.arm_commonness.polling_uncommon_joker then
                    local boost_count = AG_UTIL.count_other_arm_cards(arm_suffix)

                    if boost_count > 0 then
                        return weight * (1 + (AG.arm_commonness.boost * boost_count))
                    end
                end

                return weight
            end

            AG.arm_commonness.installed[install_key] = true
        end
    end
end

if SMODS and SMODS.poll_object then
    local ag_arm_poll_object_ref = SMODS.poll_object

    function SMODS.poll_object(args)
        AG_UTIL.install_arm_commonness_weights()

        local previous_polling_uncommon_joker = AG.arm_commonness.polling_uncommon_joker

        AG.arm_commonness.polling_uncommon_joker = AG_UTIL.is_uncommon_joker_poll(args)

        local center = ag_arm_poll_object_ref(args)
        AG.arm_commonness.polling_uncommon_joker = previous_polling_uncommon_joker

        return center
    end
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
