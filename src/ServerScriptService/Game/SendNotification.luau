local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(msg: string): ()
    ReplicatedStorage.Game.ServerClient.SendNotification:FireAllClients(msg)
end
