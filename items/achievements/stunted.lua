Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant

function AG.unlock_stunted()
    if check_for_unlock then
        check_for_unlock({ type = 'stunted' })
        return
    end

    if unlock_achievement then
        unlock_achievement('stunted')
    end
end

SMODS.Achievement({
    key = 'stunted',
    loc_txt = {
        name = 'Stunted',
        description = {
            'Prevent an Erbario',
            'from self-destructing',
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == 'stunted'
    end,
})
