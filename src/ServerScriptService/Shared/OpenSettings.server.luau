local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.PlayerAdded:Connect(function(plr)
    plr.Chatted:Connect(function(msg)
        if msg:lower() == "!settings" then
            ReplicatedStorage.Shared.ServerClient.OpenSettings:FireClient(plr)
        end
    end)
end)