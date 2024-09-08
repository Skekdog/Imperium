local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classic = require(script.Parent.GameDefinitions.Classic.Classic)
local Round = require(script.Parent.Imperium.Round)

Players.PlayerAdded:Wait()
local round = Round.new(Classic)

ReplicatedStorage.ClientServer.RollDice.OnServerEvent:Connect(function(plr)
    local participant = round:GetParticipant(plr)

    if round.CurrentParticipant == participant then
        participant:TryPlayMove()
    end
end)

round:StartNextParticipantTurn()