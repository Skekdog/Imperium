local function GetCharacter(player: Player | Configuration): Model?
    if player:IsA("Player") then
        return player.Character
    end

    local char = workspace:FindFirstChild(player.Name)
    if not char then
        return nil
    end

    assert(char:IsA("Model"), "Character is not a model")
    return char
end

return GetCharacter