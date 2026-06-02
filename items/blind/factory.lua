SMODS.Atlas({
    key = 'blind_factory',
    path = 'blind_factory.png',
    px = 34,
    py = 34,
})

local function get_total_consumables_used()
    local total = 0

    if G and G.GAME and G.GAME.consumeable_usage then
        for _, usage in pairs(G.GAME.consumeable_usage) do
            total = total + ((usage and usage.count) or 0)
        end
        return total
    end

    if G and G.GAME and G.GAME.consumeable_usage_total then
        for _, count in pairs(G.GAME.consumeable_usage_total) do
            total = total + (count or 0)
        end
    end

    return total
end

local function get_factory_bonus()
    local ante = (G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1
    return get_total_consumables_used() * 200 * ante
end

local function refresh_blind_chip_ui()
    if not G or not G.hand_text_area or not G.hand_text_area.blind_chips or not G.HUD_blind then
        return
    end

    G.FUNCS.blind_chip_UI_scale(G.hand_text_area.blind_chips)
    G.HUD_blind:recalculate()
    G.hand_text_area.blind_chips:juice_up()
end

SMODS.Blind({
    key = 'factory',
    pos = { x = 0, y = 0 },
    atlas = 'blind_factory',
    dollars = 5,
    mult = 1.75,
    boss = { min = 1, max = 80, showdown = false },
    boss_colour = HEX('aa70eb'),
    debuff = {},
    config = { extra = { bonus_chips = 0 } },
    in_pool = function()
        return not (Aspirant and Aspirant.is_showdown_ante and Aspirant.is_showdown_ante())
    end,

    loc_txt = {
        name = 'The Factory',
        text = {
            'Every consumable used',
            'thus far raises the goal',
        }
    },

    set_blind = function(self)
        local previous_bonus = (self.config.extra and self.config.extra.bonus_chips) or 0
        local new_bonus = get_factory_bonus()

        self.config.extra.bonus_chips = new_bonus

        if G and G.GAME and G.GAME.blind then
            G.GAME.blind.chips = G.GAME.blind.chips - previous_bonus + new_bonus
            G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
            refresh_blind_chip_ui()
        end
    end,
})
