Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant

function AG.unlock_sunken_below()
    if check_for_unlock then
        check_for_unlock({ type = 'sunken_below' })
        return
    end

    if unlock_achievement then
        unlock_achievement('sunken_below')
    end
end

SMODS.Achievement({
    key = 'sunken_below',
    loc_txt = {
        name = 'Sunken Below',
        description = {
            'Reunite the four Arms',
            'into Manmade Nephilim',
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == 'sunken_below'
    end,
})
