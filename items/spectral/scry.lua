SMODS.Atlas({
    key = 'scry',
    path = 'scry.png',
    px = 71,
    py = 95,
})

local function center_matches(center, suffix)
    local key = center and center.key
    local original_key = center and center.original_key

    return center
        and (
            original_key == suffix
            or key == suffix
            or (type(key) == 'string' and key:match(suffix .. '$') ~= nil)
        )
end

local function find_starlight_seal()
    for _, seal in pairs((G and G.P_SEALS) or {}) do
        if center_matches(seal, 'starlight') then
            return seal
        end
    end

    if SMODS and SMODS.Seals then
        for _, seal in pairs(SMODS.Seals) do
            if center_matches(seal, 'starlight') then
                return seal
            end
        end
    end

    return nil
end

local function get_selected_hand_card()
    local highlighted = G and G.hand and G.hand.highlighted
    if highlighted and #highlighted == 1 then
        return highlighted[1]
    end

    return nil
end

SMODS.Consumable({
    key = 'scry',
    set = 'Spectral',
    atlas = 'scry',
    pos = { x = 0, y = 0 },
    cost = 4,

    loc_txt = {
        name = 'Scry',
        text = {
            'Add a {C:starlight,T:starlight_seal}Starlight Seal{}',
            'to {C:attention}1{} selected card',
            'in your hand',
        }
    },

    loc_vars = function(self, info_queue, card)
        local starlight_seal = find_starlight_seal()
        if starlight_seal then
            info_queue[#info_queue + 1] = starlight_seal
        end

        return { vars = {} }
    end,

    can_use = function(self, card)
        return get_selected_hand_card() ~= nil
    end,

    use = function(self, card, area, copier)
        local used_spectral = copier or card
        local target = get_selected_hand_card()
        local starlight_seal = find_starlight_seal()

        if not target or not starlight_seal then
            return
        end

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                used_spectral:juice_up(0.3, 0.5)
                return true
            end
        }))

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.2,
            func = function()
                if target and not target.removed then
                    play_sound('tarot2', 1, 0.6)
                    target:set_seal(starlight_seal.key, true)
                    target:juice_up(0.3, 0.3)
                end
                return true
            end
        }))

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.25,
            func = function()
                if G and G.hand then
                    G.hand:unhighlight_all()
                end
                return true
            end
        }))

        delay(0.3)
    end,
})
