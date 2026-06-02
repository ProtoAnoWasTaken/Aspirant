SMODS.Achievement({
    key = "champion_acolyte",
    loc_txt = {
        name = "Champion Acolyte",
        description = {
            "Do whatever it takes to win",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "champion_acolyte"
    end,
})
