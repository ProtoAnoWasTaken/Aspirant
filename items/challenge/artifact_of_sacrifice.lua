local function buffoon_packs()
    local banned = {}

    for _, center in pairs((G and G.P_CENTERS) or {}) do
        if center.key and center.set == 'Booster' and center.kind == 'Buffoon' then
            banned[#banned + 1] = { id = center.key }
        end
    end

    table.sort(banned, function(a, b) return a.id < b.id end)
    return banned
end

SMODS.Challenge({
    key = 'artifact_of_sacrifice',
    loc_txt = {
        name = 'Artifact of Sacrifice',
    },
    rules = {
        custom = {
            { id = 'ag_artifact_boss_buffoon' },
            { id = 'ag_no_buffoon_packs' },
            { id = 'no_shop_jokers' },
        },
        modifiers = {},
    },
    jokers = {},
    consumeables = {},
    vouchers = {
        { id = 'v_tk9g_badge_checker' },
        { id = 'v_tk9g_starlight' },
    },
    deck = {
        type = 'Challenge Deck',
    },
    restrictions = {
        banned_cards = buffoon_packs,
        banned_tags = {
            { id = 'tag_uncommon' },
            { id = 'tag_rare' },
            { id = 'tag_negative' },
            { id = 'tag_foil' },
            { id = 'tag_holo' },
            { id = 'tag_polychrome' },
        },
        banned_other = {},
    },
    calculate = function(self, context)
        if context.end_of_round and context.main_eval and context.beat_boss and not context.game_over then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.3,
                func = function()
                    add_tag(Tag('tag_buffoon'))
                    play_sound('generic1', 0.9 + math.random() * 0.1, 0.8)
                    return true
                end,
            }))
        end
    end,
})
