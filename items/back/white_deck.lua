SMODS.Atlas({
    key = 'white_deck',
    path = 'white_deck.png',
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "white_deck",
    atlas = 'white_deck',
    pos = { x = 0, y = 0 },
    unlocked = true,

    loc_txt = {
        name = "White Deck",
        text = {
            "Start with a random",
            "Aspirant Joker",
            "{C:inactive}(Cannot be Rare or Legendary){}"
        },
    },

    config = {},

    apply = function(self)
        local pool = {}
        local rarity_map = {
            Common = 1,
            Uncommon = 2,
            Rare = 3,
            Legendary = 4,
        }

        for key, center in pairs(G.P_CENTERS) do
            local rarity = rarity_map[center.rarity] or center.rarity
            if center.set == "Joker" and center.unlocked and string.find(key, "^j_tk9g_") and rarity and rarity <= 2 then
                pool[#pool + 1] = key
            end
        end

        if #pool == 0 then
            sendErrorMessage("[Aspirant] White Deck: no tk9g jokers found")
            return
        end

        local chosen_key = pool[math.random(#pool)]

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0,
            func = function()
                if not G.jokers then return false end

                SMODS.add_card({
                    key = chosen_key,
                    area = G.jokers,
                })

                return true
            end
        }))
    end,
})
