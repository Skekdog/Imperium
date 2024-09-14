local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MakeMove = require(script.Parent.MakeMove)

return function(): ()
    MakeMove()
    if ReplicatedStorage:GetAttribute("CurrentPlayer") :: string == Players.LocalPlayer.Name then
        ReplicatedStorage.Game.ClientServer.RollDice:FireServer()
    end
end
