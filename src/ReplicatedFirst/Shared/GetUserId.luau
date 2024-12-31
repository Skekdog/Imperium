local function GetUserId(player: Player | Configuration): number
    if player:IsA("Player") then
        return player.UserId
    end

    local userId = player:GetAttribute("UserId")
    assert(typeof(userId) == "number", "UserId is not a number")
    return userId
end

return GetUserId