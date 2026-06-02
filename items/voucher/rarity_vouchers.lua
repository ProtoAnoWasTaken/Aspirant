SMODS.Atlas({
    key = 'badge_checker',
    path = 'badge_checker.png',
    px = 71,
    py = 95,
})

SMODS.Atlas({
    key = 'starlight_voucher',
    path = 'starlight.png',
    px = 71,
    py = 95,
})

local AG = rawget(_G, 'Aspirant') or {}
local AG_UTIL = AG.joker_utils or {}

local function cloud_cradle_is_discovered()
    return AG_UTIL
        and AG_UTIL.is_center_discovered
        and AG_UTIL.is_center_discovered('Joker', 'cloudcradle')
end

local function voucher_used(suffix)
    if not (G and G.GAME and G.GAME.used_vouchers) then
        return false
    end

    return G.GAME.used_vouchers['v_tk9g_' .. suffix]
        or G.GAME.used_vouchers['v_' .. suffix]
end

local function should_adjust_joker_rarity(pool_key, rand_key)
    if pool_key ~= 'Joker' or type(rand_key) ~= 'string' then
        return false
    end

    return rand_key:find('sho', 1, true) ~= nil
        or rand_key:find('buf', 1, true) ~= nil
end

local function adjusted_joker_rarity(rand_key)
    local poll = pseudorandom(pseudoseed(rand_key))

    if voucher_used('starlight') then
        return (poll > 0.85 and 3) or (poll > 0.50 and 2) or 1
    end

    if voucher_used('badge_checker') then
        return (poll > 0.95 and 3) or (poll > 0.60 and 2) or 1
    end
end

local ag_poll_rarity_ref = SMODS.poll_rarity

function SMODS.poll_rarity(pool_key, rand_key)
    if should_adjust_joker_rarity(pool_key, rand_key) then
        local rarity = adjusted_joker_rarity(rand_key)

        if rarity then
            return rarity
        end
    end

    return ag_poll_rarity_ref(pool_key, rand_key)
end

SMODS.Voucher({
    key = 'badge_checker',
    atlas = 'badge_checker',
    pos = { x = 0, y = 0 },
    name = 'Badge Checker',
    cost = 10,
    order = 1,
    unlocked = true,

    loc_txt = {
        name = 'Badge Checker',
        text = {
            '{C:green}Uncommon{} Jokers',
            'become more common',
        },
    },
})

SMODS.Voucher({
    key = 'starlight',
    atlas = 'starlight_voucher',
    pos = { x = 0, y = 0 },
    name = 'Starlight',
    cost = 10,
    order = 2,
    requires = { 'v_tk9g_badge_checker' },
    unlocked = false,

    loc_txt = {
        name = 'Starlight',
        text = {
            '{C:red}Rare{} Jokers',
            'become more common',
        },
    },

    locked_loc_vars = function()
        return { key = 'ag_unlock_discover_cloudcradle', set = 'Other' }
    end,

    check_for_unlock = function(self, args)
        return args and args.type == 'discover_amount' and cloud_cradle_is_discovered()
    end,
})
