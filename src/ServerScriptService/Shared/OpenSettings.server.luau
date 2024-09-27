local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.PlayerAdded:Connect(function(plr)
    plr.Chatted:Connect(function(msg)
        if msg:lower() == "!settings" then
            ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("OpenSettings"):FireClient(plr)
        end
    end)
end)