Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant

local function has_andromeda()
    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker
            and joker.config
            and joker.config.center
            and (
                joker.config.center.original_key == 'andromeda'
                or joker.config.center.key == 'andromeda'
                or (type(joker.config.center.key) == 'string' and joker.config.center.key:match('andromeda$') ~= nil)
            )
            and not joker.getting_sliced
        then
            return true
        end
    end

    return false
end

function AG.unlock_through_solid_ground(args)
    if not (args and args.force) and not has_andromeda() then
        return
    end

    if check_for_unlock then
        check_for_unlock({ type = 'through_solid_ground' })
    end

    if unlock_achievement then
        unlock_achievement('through_solid_ground')
    end
end

SMODS.Achievement({
    key = 'through_solid_ground',
    loc_txt = {
        name = 'Through Solid Ground',
        description = {
            "So Below,",
            "As Above",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == 'through_solid_ground'
    end,
})
