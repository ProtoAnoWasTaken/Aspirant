SMODS.Challenge({
    key = 'expedition_woodworm',
    loc_txt = {
        name = 'Expedition: Woodworm',
    },
    rules = {
        custom = {
            { id = 'no_reward_specific', value = 'Small' },
            { id = 'no_reward_specific', value = 'Big' },
            { id = 'no_interest' },
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
    },
    restrictions = {
        banned_cards = {},
        banned_tags = {},
        banned_other = {},
    },
})
