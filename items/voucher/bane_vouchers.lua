SMODS.Atlas({
    key = 'cyclopea',
    path = 'cyclopea.png',
    px = 71,
    py = 95,
})

SMODS.Atlas({
    key = 'hyperdontia',
    path = 'hyperdontia.png',
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

local function cyclopea_is_discovered()
    return AG_UTIL
        and AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Voucher', 'cyclopea')
end

local function voucher_used(suffix)
    if not (G and G.GAME and G.GAME.used_vouchers) then
        return false
    end

    return G.GAME.used_vouchers['v_tk9g_' .. suffix]
        or G.GAME.used_vouchers['v_' .. suffix]
end

local function is_shop_append(append)
    return type(append) == 'string' and append:find('sho', 1, true) ~= nil
end

local function is_joker_or_consumable_type(type_key)
    return type_key == 'Joker'
        or type_key == 'Tarot'
        or type_key == 'Planet'
        or type_key == 'Spectral'
        or type_key == 'Tarot_Planet'
        or type_key == 'Consumeables'
        or (SMODS and SMODS.ConsumableTypes and SMODS.ConsumableTypes[type_key] ~= nil)
end

local function hyperdontia_allows_duplicates(type_key, append)
    return voucher_used('hyperdontia')
        and is_shop_append(append)
        and is_joker_or_consumable_type(type_key)
end

local function install_cyclopea_polychrome_weight()
    local polychrome = G and G.P_CENTERS and G.P_CENTERS.e_polychrome

    if not polychrome or AG.voucher_effects.cyclopea_polychrome_weight_installed then
        return
    end

    local get_weight_ref = polychrome.get_weight

    polychrome.get_weight = function(self, ...)
        local weight = get_weight_ref and get_weight_ref(self, ...) or self.weight or 0

        if AG.voucher_effects.polling_joker_edition and voucher_used('cyclopea') then
            return weight * 4
        end

        return weight
    end

    AG.voucher_effects.cyclopea_polychrome_weight_installed = true
end

local ag_create_card_ref = create_card

function create_card(type_key, area, legendary, rarity, skip_materialize, soulable, forced_key, key_append)
    install_cyclopea_polychrome_weight()

    local forced_center = forced_key and G.P_CENTERS and G.P_CENTERS[forced_key]
    type_key = type_key or (forced_center and forced_center.set)
    local polling_joker_edition = type_key == 'Joker' or (forced_center and forced_center.set == 'Joker')
    local allow_shop_duplicates = not forced_key and area == G.shop_jokers and hyperdontia_allows_duplicates(type_key, key_append)
    local previous_polling_joker_edition = AG.voucher_effects.polling_joker_edition

    if polling_joker_edition then
        AG.voucher_effects.polling_joker_edition = true
    end

    if allow_shop_duplicates then
        local previous = SMODS.create_card_allow_duplicates
        SMODS.create_card_allow_duplicates = true
        local card = ag_create_card_ref(type_key, area, legendary, rarity, skip_materialize, soulable, forced_key, key_append)
        SMODS.create_card_allow_duplicates = previous
        AG.voucher_effects.polling_joker_edition = previous_polling_joker_edition
        return card
    end

    local card = ag_create_card_ref(type_key, area, legendary, rarity, skip_materialize, soulable, forced_key, key_append)
    AG.voucher_effects.polling_joker_edition = previous_polling_joker_edition
    return card
end

if SMODS.poll_object then
    local ag_poll_object_ref = SMODS.poll_object

    function SMODS.poll_object(args)
        local allow_duplicates = args and hyperdontia_allows_duplicates(args.type, args.append)

        if allow_duplicates and not args.allow_duplicates then
            args = copy_table(args)
            args.allow_duplicates = true
        end

        local previous = SMODS.poll_object_allow_duplicates
        if allow_duplicates then
            SMODS.poll_object_allow_duplicates = true
        end

        local result = ag_poll_object_ref(args)
        SMODS.poll_object_allow_duplicates = previous
        return result
    end
end

SMODS.Voucher({
    key = 'cyclopea',
    atlas = 'cyclopea',
    pos = { x = 0, y = 0 },
    name = 'Cyclopea',
    cost = 10,
    order = 3,
    unlocked = false,
    config = { extra = { flipped_cards = 7, polychrome_mod = 4 } },

    loc_txt = {
        name = 'Cyclopea',
        text = {
            '{C:green}1 in 7{} cards are',
            'drawn face down',
            '{C:dark_edition}Polychrome{} Jokers are',
            '{C:attention}4X{} as likely to appear',
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
                local current = G.GAME.modifiers.flipped_cards
                G.GAME.modifiers.flipped_cards = current and math.min(current, self.config.extra.flipped_cards)
                    or self.config.extra.flipped_cards
                return true
            end,
        }))
    end,
})

SMODS.Voucher({
    key = 'hyperdontia',
    atlas = 'hyperdontia',
    pos = { x = 0, y = 0 },
    name = 'Hyperdontia',
    cost = 10,
    order = 4,
    requires = { 'v_tk9g_cyclopea' },
    unlocked = false,

    loc_txt = {
        name = 'Hyperdontia',
        text = {
            'Jokers and consumables may',
            'appear in the {C:attention}Shop{}',
            'multiple times',
        },
    },

    locked_loc_vars = function()
        return { key = 'ag_unlock_voucher_precursor', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and cyclopea_is_discovered()
    end,
})
