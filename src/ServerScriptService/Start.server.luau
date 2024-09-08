local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Classic = require(script.Parent.GameDefinitions.Classic.Classic)
local Round = require(script.Parent.Imperium.Round)

Players.PlayerAdded:Wait()
local round = Round.new(Classic)

local INTERMISSION_DURATION = 5
local TURN_DURATION = 15

ReplicatedStorage.ClientServer.RollDice.OnServerEvent:Connect(function(plr)
    local participant = round:GetParticipant(plr)

    if round.CurrentParticipant == participant then
        participant:TryPlayMove()
    end
end)

ReplicatedStorage:SetAttribute("TimeMilestone", workspace:GetServerTimeNow() + INTERMISSION_DURATION)
task.wait(INTERMISSION_DURATION)

round:StartRound()