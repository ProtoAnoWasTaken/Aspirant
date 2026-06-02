Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant
local ADVENTURER_SUFFIX = 'adventurer'
local CONTRACTOR_SUFFIX = 'contractor'

local function center_matches(center, suffix)
    local key = center and center.key
    local original_key = center and center.original_key

    return center
        and (
            original_key == suffix
            or key == suffix
            or (type(key) == 'string' and key:match(suffix .. '$') ~= nil)
        )
end

local function has_joker(suffix)
    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker
            and not joker.getting_sliced
            and joker.config
            and joker.config.center
            and center_matches(joker.config.center, suffix)
        then
            return true
        end
    end

    return false
end

function AG.unlock_cosmic_tapestry()
    if not has_joker(ADVENTURER_SUFFIX) or not has_joker(CONTRACTOR_SUFFIX) then
        return
    end

    if check_for_unlock then
        check_for_unlock({ type = 'cosmic_tapestry' })
        return
    end

    if unlock_achievement then
        unlock_achievement('cosmic_tapestry')
    end
end

SMODS.Achievement({
    key = 'cosmic_tapestry',
    loc_txt = {
        name = 'Cosmic Tapestry',
        description = {
            'Einstein-Rosen Bridge',
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == 'cosmic_tapestry'
    end,
})
