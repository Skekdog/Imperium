return function(player: Player): string
    local plr: Player
    if typeof(player) == "table" then
        plr = player.Player
    else
        plr = player
    end

    if plr.Name == plr.DisplayName then
        return `@{plr.Name}`
    else
        return `{plr.DisplayName} (@{plr.Name})`
    end
end