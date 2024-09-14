local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MakeMove = require(script.Parent.MakeMove)

return function(): ()
    MakeMove()
    if ReplicatedStorage:GetAttribute("CurrentPlayer") :: string == Players.LocalPlayer.Name and Players.LocalPlayer:GetAttribute("Money") :: number >= ReplicatedStorage:GetAttribute("FineAmount") :: number then
        ReplicatedStorage.Game.ClientServer.PayFine:FireServer()
    end
end
