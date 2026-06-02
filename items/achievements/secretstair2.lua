Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant

function AG.unlock_secret_stair_2()
    if check_for_unlock then
        check_for_unlock({ type = 'secret_stair_2' })
        return
    end

    if unlock_achievement then
        unlock_achievement('secret_stair_2')
    end
end

SMODS.Achievement({
    key = 'secret_stair_2',
    loc_txt = {
        name = 'Secret Stair #2',
        description = {
            'Destroy the Molten Maggot',
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == 'secret_stair_2'
    end,
})
