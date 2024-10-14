local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SafeTeleport = require(script.Parent.Parent.Shared.SafeTeleport)
local SendNotification = require(script.Parent.Parent.Shared.SendNotification)
ReplicatedStorage:WaitForChild("Lobby"):WaitForChild("ClientServer"):WaitForChild("TeleportToTYT").OnServerEvent:Connect(function(plr)
    local success, result = SafeTeleport(2848381272, {plr})
    if not success then
        SendNotification(result :: any, nil, {plr})
    end
end)