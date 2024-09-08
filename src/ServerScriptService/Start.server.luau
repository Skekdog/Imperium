local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classic = require(script.Parent.GameDefinitions.Classic.Classic)
local Round = require(script.Parent.Imperium.Round)
local SetTimeMilestone = require(script.Parent.SetTimeMilestone)

local INTERMISSION_DURATION = 5

Players.PlayerAdded:Wait()
local round = Round.new(Classic, {
    PlayerTurnTime = 15,
    AuctionTime = 15
})

ReplicatedStorage.ClientServer.RollDice.OnServerEvent:Connect(function(plr)
    local participant = round:GetParticipant(plr)

    if round.CurrentParticipant == participant then
        participant:TryPlayMove()
    end
end)

SetTimeMilestone(INTERMISSION_DURATION)
task.wait(INTERMISSION_DURATION)

round:StartRound()