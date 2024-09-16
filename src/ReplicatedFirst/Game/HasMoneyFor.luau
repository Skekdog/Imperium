local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

return function(target: number, participant: {Money: number}?): boolean
    if RunService:IsClient() then
        return Players.LocalPlayer:GetAttribute("Money") >= target
    end
    assert(participant)
    return participant.Money >= target
end
