local RunService = game:GetService("RunService")

return function(player: Player): string
    if RunService:IsClient() then
        local SettingsManager = require(script.Parent.Parent.Shared.SettingsManager)
        local mode = SettingsManager.GetSetting("Player Names") :: "Username" | "Display Name" | "Both"

        if mode == "Username" then
            return `{player.Name}`
        elseif mode == "Display Name" then
            return `{player.DisplayName}`
        elseif mode == "Both" then
            return `{player.DisplayName} (@{player.Name})`
        else
            return `@{player.Name}`
        end
    end
    if player.Name == player.DisplayName then
        return `@{player.Name}`
    else
        return `{player.DisplayName} (@{player.Name})`
    end
end