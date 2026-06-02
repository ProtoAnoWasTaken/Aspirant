Aspirant = rawget(_G, 'Aspirant') or {}

local AG = Aspirant

local function is_etrog(joker)
    local center = joker and joker.config and joker.config.center

    return joker
        and not joker.getting_sliced
        and center
        and (
            center.original_key == 'etrog'
            or center.key == 'etrog'
            or (type(center.key) == 'string' and center.key:match('etrog$') ~= nil)
        )
end

local function has_five_etrogs()
    if not G or not G.jokers or not G.jokers.cards then
        return false
    end

    local count = 0

    for _, joker in ipairs(G.jokers.cards) do
        if is_etrog(joker) then
            count = count + 1
            if count >= 5 then
                return true
            end
        end
    end

    return false
end

function AG.unlock_fools_garden()
    if not has_five_etrogs() then
        return
    end

    if check_for_unlock then
        check_for_unlock({ type = 'fools_garden' })
        return
    end

    if unlock_achievement then
        unlock_achievement('fools_garden')
    end
end

function AG.queue_unlock_fools_garden()
    if not G or not G.E_MANAGER then
        AG.unlock_fools_garden()
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0,
        func = function()
            AG.unlock_fools_garden()
            return true
        end,
    }))
end

SMODS.Achievement({
    key = 'fools_garden',
    loc_txt = {
        name = "Fool's Garden",
        description = {
            'Go on an Etrog hunt',
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == 'fools_garden'
    end,
})
