local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Formatted as "blah blah [PLAYER] blah blah [PLAYER]"
return function(msg: string, players: {Player | Configuration}?, to: {Player | Configuration}?): ()
    if to then
        for _, plr in to do
            if plr:IsA("Player") then
                ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("SendNotification"):FireClient(plr, msg, players)
            end
        end
    else
        ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("SendNotification"):FireAllClients(msg, players)
    end
end
