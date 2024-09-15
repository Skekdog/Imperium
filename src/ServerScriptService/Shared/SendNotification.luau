local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Formatted as "blah blah [PLAYER] blah blah [PLAYER]"
return function(msg: string, players: {Player}?, to: {Player}?): ()
    if to then
        for _, plr in to do
            ReplicatedStorage.Shared.ServerClient.SendNotification:FireClient(plr, msg, players)
        end
    else
        ReplicatedStorage.Shared.ServerClient.SendNotification:FireAllClients(msg, players)
    end
end
