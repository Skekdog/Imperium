local BadgeService = game:GetService("BadgeService")

export type BadgeName = "Monopoly" | "Imperium" | "Bankrupt!"
local badges: {[string]: number} = {
    ["Monopoly"] = 3372918368199180,
    ["Imperium"] = 2989328846691150,
    ["Bankrupt!"] = 2022094759463020,
}

return function(plr: Player, name: BadgeName): ()
    local success, result
    local tries = 0

    repeat
        success, result = pcall(BadgeService.AwardBadge, BadgeService, plr.UserId, badges[name])
        tries += 1
    until (success and result) or (tries >= 3)

    if not success then
        print(`Error awarding badge {name} to {plr.Name}: {result}`)
    elseif not result then
        print(`Failed to award badge {name} to {plr.Name}`)
    end
end
