Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant
AG.dialogue = AG.dialogue or {}

local DIALOGUE = AG.dialogue
DIALOGUE.registrations = DIALOGUE.registrations or {}
DIALOGUE.categories = DIALOGUE.categories or {}
DIALOGUE.templates = DIALOGUE.templates or {}

local function center_matches(card, center_keys)
    local center = card and card.config and card.config.center
    if not center then
        return false
    end

    for _, key in ipairs(center_keys or {}) do
        if center.key == key or center.original_key == key then
            return true
        end
    end

    return false
end

local function copy_table(source)
    local result = {}

    for key, value in pairs(source or {}) do
        result[key] = value
    end

    return result
end

local function merge_tables(defaults, overrides)
    local result = copy_table(defaults)

    for key, value in pairs(overrides or {}) do
        result[key] = value
    end

    return result
end

function DIALOGUE.categories.banned_challenge(registration, card)
    local game = G and G.GAME
    local center = card and card.config and card.config.center

    return game
        and game.challenge ~= nil
        and game.banned_keys
        and center
        and game.banned_keys[center.key] == true
end

DIALOGUE.templates.banned_challenge = {
    category = 'banned_challenge',
    shop = {
        align = 'tm',
        appear_delay = 0.1,
        duration = 5,
        pitch = 1,
        voice_delay = 0.4,
    },
    owned = {
        align = 'bm',
        appear_delay = 0.1,
        duration = 5,
        pitch = 1,
        voice_delay = 0.4,
    },
}

local function registration_matches(registration, card)
    if not center_matches(card, registration.center_keys) then
        return false
    end

    if type(registration.condition) == 'function'
        and not registration.condition(registration, card)
    then
        return false
    end

    if registration.category then
        local category_condition = DIALOGUE.categories[registration.category]
        return type(category_condition) == 'function'
            and category_condition(registration, card)
    end

    return true
end

function DIALOGUE.remove(card)
    local bubble = card
        and card.children
        and card.children.ag_dialogue_speech

    if bubble then
        bubble:remove()
        card.children.ag_dialogue_speech = nil
    end
end

function DIALOGUE.say(card, quip_key, args)
    if not card or card.removed or not quip_key then
        return
    end

    args = args or {}
    DIALOGUE.remove(card)

    card.ag_dialogue_speech_id = (card.ag_dialogue_speech_id or 0) + 1
    local speech_id = card.ag_dialogue_speech_id
    local align = args.align or 'bm'
    local bubble = UIBox({
        definition = G.UIDEF.speech_bubble(quip_key, { quip = true }),
        config = {
            align = align,
            offset = args.offset or {
                x = 0,
                y = align == 'tm' and -0.15 or 0.15,
            },
            parent = card,
        },
    })

    bubble:set_role({
        role_type = 'Minor',
        xy_bond = 'Strong',
        r_bond = 'Strong',
        major = card,
    })
    bubble.states.visible = true
    card.children.ag_dialogue_speech = bubble

    local function still_current()
        return not card.removed
            and card.ag_dialogue_speech_id == speech_id
            and card.children.ag_dialogue_speech == bubble
    end

    local function talk(remaining)
        if not still_current() then
            return
        end

        if remaining <= 0 then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = args.duration or 4,
                blockable = false,
                blocking = false,
                func = function()
                    if still_current() then
                        DIALOGUE.remove(card)
                    end
                    return true
                end,
            }))
            return
        end

        local pitch = (args.pitch or 1) * (math.random() * 0.2 + 1)
        play_sound(args.sound or ('voice' .. math.random(1, 11)), pitch, 0.5)
        card:juice_up()
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = args.voice_delay or 0.13,
            blockable = false,
            blocking = false,
            func = function()
                talk(remaining - 1)
                return true
            end,
        }), 'other')
    end

    talk(args.times or 5)
end


function DIALOGUE.register(args)
    if not args or not args.id then
        return
    end

    local template = args.template and DIALOGUE.templates[args.template] or {}
    local registration = merge_tables(template, args)
    registration.shop = merge_tables(template.shop, args.shop)
    registration.owned = merge_tables(template.owned, args.owned)
    DIALOGUE.registrations[registration.id] = registration
end

local function schedule_registered_dialogue(area, card, registration, moment)
    local moment_args = registration[moment]
    local quips = moment_args and moment_args.quips
    if not moment_args
        or (not moment_args.quip and not (quips and #quips > 0))
    then
        return
    end

    card.ag_dialogue_seen = card.ag_dialogue_seen or {}
    card.ag_dialogue_seen[registration.id] = card.ag_dialogue_seen[registration.id] or {}
    if card.ag_dialogue_seen[registration.id][moment] then
        return
    end
    card.ag_dialogue_seen[registration.id][moment] = true

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = moment_args.appear_delay or 0.1,
        blockable = false,
        blocking = false,
        func = function()
            if registration_matches(registration, card)
                and card.area == area
            then
                local quip = moment_args.quip
                    or pseudorandom_element(
                        quips,
                        pseudoseed('ag_dialogue_' .. registration.id .. '_' .. moment)
                    )
                DIALOGUE.say(card, quip, moment_args)
            end
            return true
        end,
    }), 'other')
end

function DIALOGUE.on_emplace(area, card)
    if not card or card.removed then
        return
    end

    local moment
    if G and area == G.shop_jokers then
        moment = 'shop'
    elseif G and area == G.jokers then
        moment = 'owned'
    else
        return
    end

    for _, registration in pairs(DIALOGUE.registrations) do
        if registration_matches(registration, card) then
            schedule_registered_dialogue(area, card, registration, moment)
        end
    end
end

if not DIALOGUE.emplace_hook_installed then
    local cardarea_emplace_ref = CardArea.emplace

    function CardArea:emplace(card, location, stay_flipped)
        local result = cardarea_emplace_ref(self, card, location, stay_flipped)
        DIALOGUE.on_emplace(self, card)
        return result
    end

    DIALOGUE.emplace_hook_installed = true
end
