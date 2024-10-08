local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MakeMove = require(script.Parent.MakeMove)

return function(): ()
    MakeMove()
    if ReplicatedStorage:GetAttribute("CurrentPlayer") :: string? == Players.LocalPlayer.Name then
        ReplicatedStorage:WaitForChild("Game"):WaitForChild("ClientServer"):WaitForChild("RollDice"):FireServer()
    end
end
