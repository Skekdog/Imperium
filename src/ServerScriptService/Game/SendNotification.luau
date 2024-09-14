local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Formatted as "blah blah [PLAYER] blah blah [PLAYER]"
return function(msg: string, players: {Player}?): ()
    ReplicatedStorage.Game.ServerClient.SendNotification:FireAllClients(msg, players)
end
