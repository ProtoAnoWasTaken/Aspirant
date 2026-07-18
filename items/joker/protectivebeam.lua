SMODS.Atlas({
    key = "protectivebeam",
    path = "protectivebeam.png",
    px = 69,
    py = 93,
})

local AG_UTIL = (rawget(_G, 'Aspirant') or {}).joker_utils or {}

SMODS.Joker({
    key = "protectivebeam",
    atlas = "protectivebeam",
    pos = { x = 0, y = 0 },
    name = "Protective Beam",
    rarity = 1,
    cost = 4,

    loc_txt = {
        name = "Protective Beam",
        text = {
            "Prevents adjacent {c:attention}Jokers{}",
            "from {C:red,E:2}self destructing{},",
            "then {C:red,E:2}self destructs{}",
        }
    },

    unlocked = false,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,

    locked_loc_vars = function()
        return { key = "ag_unlock_discover_drommo", set = "Other" }
    end,

    check_for_unlock = function(self, args)
        return args
            and args.type == "discover_amount"
            and AG_UTIL.is_center_discovered
            and AG_UTIL.is_center_discovered("Joker", "drommo")
    end,

})
