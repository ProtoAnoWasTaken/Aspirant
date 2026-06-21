SMODS.Challenge({
    key = 'woodworm_extended',
    loc_txt = {
        name = 'Woodworm Extended',
    },
    unlocked = function(self)
        local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
        local completed = profile and profile.challenge_progress and profile.challenge_progress.completed
        return completed and completed['c_tk9g_expedition_woodworm'] == true or false
    end,
    rules = {
        custom = {
            { id = 'no_reward_specific', value = 'Small' },
            { id = 'no_reward_specific', value = 'Big' },
            { id = 'no_interest' },
            { id = 'ag_woodworm_ante_ten' },
        },
        modifiers = {},
    },
    jokers = {
        { id = 'j_mr_bones' },
        { id = 'j_mr_bones' },
        { id = 'j_mr_bones' },
    },
    consumeables = {},
    vouchers = {},
    deck = {
        type = 'Challenge Deck',
        no_ranks = { K = true },
    },
    restrictions = {
        banned_cards = {
            { id = 'c_hermit' },
            { id = 'c_temperance' },
            { id = 'c_devil' },
            { id = 'c_magician' },
            { id = 'c_talisman' },
            { id = 'j_business' },
            { id = 'j_todo_list' },
            { id = 'j_erosion' },
            { id = 'j_tk9g_deadrabbit' },
            { id = 'j_tk9g_cloudcradle' },
            { id = 'v_clearance_sale' },
            { id = 'v_liquidation' },
        },
        banned_tags = {},
        banned_other = {},
    },
    apply = function(self)
        G.GAME.win_ante = 10
    end,
})
