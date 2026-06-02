SMODS.Atlas({
    key = 'blind_guard',
    path = 'blind_guard.png',
    px = 34,
    py = 34,
})

local AG_GUARD = rawget(_G, 'Aspirant') or {}
AG_GUARD.guard_blind = AG_GUARD.guard_blind or {}

local CUSTOM_BOSS_KEYS = {
    'bl_tk9g_collector',
    'bl_tk9g_factory',
    'bl_tk9g_doctor',
    'bl_tk9g_guard',
    'bl_tk9g_killer',
}

local CUSTOM_BOSS_KEY_SET = {
    bl_tk9g_collector = true,
    bl_tk9g_doctor = true,
    bl_tk9g_factory = true,
    bl_tk9g_guard = true,
    bl_tk9g_killer = true,
    collector = true,
    doctor = true,
    factory = true,
    guard = true,
    killer = true,
}

function AG_GUARD.is_showdown_ante()
    local ante = G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante
    return type(ante) == 'number' and ante >= 8 and ante % 8 == 0
end

local function custom_bosses_allowed_in_pool()
    return not AG_GUARD.is_showdown_ante()
end

local function ensure_custom_boss_usage_entries(game)
    local current_game = game or (G and G.GAME) or nil
    if not current_game then
        return
    end

    current_game.bosses_used = current_game.bosses_used or {}

    for _, blind_key in ipairs(CUSTOM_BOSS_KEYS) do
        if type(current_game.bosses_used[blind_key]) ~= 'number' then
            current_game.bosses_used[blind_key] = 0
        end
    end
end

local function is_guard_active()
    if not G or not G.GAME or not G.GAME.blind then
        return false
    end

    local blind = G.GAME.blind
    local blind_key = blind.config and blind.config.blind and blind.config.blind.key

    return blind_key == 'bl_tk9g_guard'
        or blind_key == 'guard'
end

local function get_default_hands()
    local game = G and G.GAME
    local defaults = game and game.starting_params or nil
    local hands = defaults and defaults.hands

    if type(hands) == 'number' then
        return hands
    end

    return 4
end

local function get_default_discards()
    local game = G and G.GAME
    local defaults = game and game.starting_params or nil
    local discards = defaults and defaults.discards

    if type(discards) == 'number' then
        return discards
    end

    return 3
end

local function apply_guard_round_limits()
    if not G or not G.GAME then
        return
    end

    local default_hands = get_default_hands()
    local default_discards = get_default_discards()

    G.GAME.round_resets = G.GAME.round_resets or {}
    G.GAME.round_resets.hands = default_hands
    G.GAME.round_resets.discards = default_discards

    G.GAME.current_round = G.GAME.current_round or {}
    G.GAME.current_round.hands_left = default_hands
    G.GAME.current_round.discards_left = default_discards
end

local function disable_vouchers_for_guard(self)
    if not G or not G.GAME or self.guard_original_used_vouchers then
        return
    end

    G.GAME.used_vouchers = G.GAME.used_vouchers or {}
    self.guard_original_used_vouchers = {}

    for voucher_key, is_used in pairs(G.GAME.used_vouchers) do
        if is_used then
            self.guard_original_used_vouchers[voucher_key] = is_used
            G.GAME.used_vouchers[voucher_key] = nil
        end
    end
end

local function restore_vouchers_for_guard(self)
    if not G or not G.GAME or not self.guard_original_used_vouchers then
        return
    end

    G.GAME.used_vouchers = G.GAME.used_vouchers or {}

    for voucher_key, is_used in pairs(self.guard_original_used_vouchers) do
        G.GAME.used_vouchers[voucher_key] = is_used
    end

    self.guard_original_used_vouchers = nil
end

if not AG_GUARD.guard_blind.boss_usage_hook_installed then
    AG_GUARD.guard_blind.boss_usage_hook_installed = true

    if Game and Game.init_game_object then
        local ag_guard_init_game_object_ref = Game.init_game_object

        function Game:init_game_object(...)
            local game_object = ag_guard_init_game_object_ref(self, ...)
            ensure_custom_boss_usage_entries(game_object)
            return game_object
        end
    end

    if type(get_new_boss) == 'function' then
        local ag_guard_get_new_boss_ref = get_new_boss

        function get_new_boss(...)
            ensure_custom_boss_usage_entries()

            if not AG_GUARD.is_showdown_ante() then
                return ag_guard_get_new_boss_ref(...)
            end

            local bosses_used = G and G.GAME and G.GAME.bosses_used
            if not bosses_used then
                return ag_guard_get_new_boss_ref(...)
            end

            local saved = {}
            for blind_key in pairs(CUSTOM_BOSS_KEY_SET) do
                if type(blind_key) == 'string' and blind_key:match('^bl_') then
                    saved[blind_key] = bosses_used[blind_key]
                    bosses_used[blind_key] = 999
                end
            end

            local replacement_key = ag_guard_get_new_boss_ref(...)

            for blind_key, previous_value in pairs(saved) do
                bosses_used[blind_key] = previous_value
            end

            return replacement_key
        end
    end
end

ensure_custom_boss_usage_entries()

if not AG_GUARD.guard_blind.scoring_hook_installed and Card and Card.calculate_joker then
    AG_GUARD.guard_blind.scoring_hook_installed = true

    local ag_guard_calculate_joker_ref = Card.calculate_joker

    function Card:calculate_joker(context)
        if is_guard_active()
            and self
            and self.ability
            and self.ability.set == 'Voucher'
            and self.config
            and self.config.center
            and self.config.center.key == 'v_observatory'
            and context
            and context.other_consumeable
            and context.other_consumeable.ability
            and context.other_consumeable.ability.set == 'Planet'
            and context.other_consumeable.ability.consumeable
            and context.other_consumeable.ability.consumeable.hand_type == context.scoring_name
        then
            return nil
        end

        return ag_guard_calculate_joker_ref(self, context)
    end
end

SMODS.Blind({
    key = 'guard',
    atlas = 'blind_guard',
    pos = { x = 0, y = 0 },
    boss = { min = 1, max = 80, showdown = false },
    boss_colour = HEX('ffd96f'),
    dollars = 5,
    mult = 2.5,
    debuff = {},
    in_pool = custom_bosses_allowed_in_pool,

    loc_txt = {
        name = 'The Guard',
        text = {
            'The effects of',
            'Vouchers are disabled',
        }
    },

    set_blind = function(self)
        ensure_custom_boss_usage_entries()
        apply_guard_round_limits()
        disable_vouchers_for_guard(self)
    end,

    disable = function(self)
        restore_vouchers_for_guard(self)
    end,
})
