local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Classic = require(ServerScriptService.Game.GameDefinitions.Classic.Classic)
local Round = require(ServerScriptService.Game.Imperium.Round)
local SetTimeMilestone = require(script.Parent.SetTimeMilestone)

local INTERMISSION_DURATION = 10

local plr = Players.PlayerAdded:Wait()
plr.CharacterAdded:Wait()
local round = Round.new(Classic, {
    PlayerTurnTime = 15,
    AuctionTime = 15
})

ReplicatedStorage.Game.ClientServer.RollDice.OnServerEvent:Connect(function(plr)
    local participant = round:GetParticipant(plr)

    if round.CurrentParticipant == participant then
        participant:TryPlayMove()
    end
end)

SetTimeMilestone(INTERMISSION_DURATION)
task.wait(INTERMISSION_DURATION)

round:StartRound()