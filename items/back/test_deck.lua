SMODS.Atlas({
    key = "test_deck",
    path = "test_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "test_deck",
    atlas = "test_deck",
    pos = { x = 0, y = 0 },
    unlocked = false,

    loc_txt = {
        name = "Cheater's Deck",
        text = {
            "Left click most things",
            "in the Collection",
            "to summon them to your run",
        },
    },

    config = {},

    apply = function(self)
        G.GAME.ag_test_deck_active = true

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                if not G.play then
                    return false
                end

                attention_text({
                    text = "Open Collection; left-click cards, Tags, or Boss Blinds",
                    scale = 0.9,
                    hold = 3,
                    align = "cm",
                    offset = { x = 0, y = -2.7 },
                    major = G.play,
                })

                return true
            end
        }))
    end,
})
