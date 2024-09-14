local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MakeMove = require(script.Parent.MakeMove)

return function(): ()
    MakeMove()
    if ReplicatedStorage:GetAttribute("CurrentPlayer") :: string == Players.LocalPlayer.Name and Players.LocalPlayer:GetAttribute("GetOutOfJailFreeCards") :: number > 0 then
        ReplicatedStorage.Game.ClientServer.UseGetOutOfJailFreeCard:FireServer()
    end
end
