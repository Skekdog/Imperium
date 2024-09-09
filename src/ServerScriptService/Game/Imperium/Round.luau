local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SetTimeMilestone = require(script.Parent.Parent.SetTimeMilestone)
local Participant = require(script.Parent.Participant)
local Tile = require(script.Parent.Tile)
local Types = require(ReplicatedFirst.Game.Types)

local module = {}

local function StartNextParticipantTurn(round: Types.Round): ()
    local lastIndex = table.find(round.Participants, round.CurrentParticipant)
    assert(lastIndex, "Round has no current participant")

    if lastIndex >= #round.Participants then
        round.Turn += 1
        lastIndex = 0
    end
    lastIndex += 1

    local lastMovedAt = round.CurrentParticipant.LastMovedAt

    round.CurrentParticipant = round.Participants[lastIndex]
    SetTimeMilestone(round.GameConfiguration.PlayerTurnTime)

    task.delay(round.GameConfiguration.PlayerTurnTime, function()
        if lastMovedAt ~= round.CurrentParticipant.LastMovedAt then
            return
        end
        round.CurrentParticipant:TryPlayMove()
    end)
end

local function GetParticipant(round: Types.Round, player: Player): Types.Participant
    for _, participant in round.Participants do
        if participant.Player == player then
            return participant
        end
    end
    error(`Participant {player} not found`)
end

local function FindTileByName(round: Types.Round, name: string): number
    for i, tile in round.Tiles do
        if tile.TileDescription.Name == name or (tile.TileDescription.Asset and tile.TileDescription.Asset.Name == name) then
            return i
        end
    end
    error(`Tile {name} not found`)
end

local function StartRound(round: Types.Round): ()
    if round.Started then
        error("Round already started")
    end

    round.Started = true

    for _, v in round.Participants do
        v.Player:SetAttribute("Status", "Playing")
        v:MoveTo(1, true)
    end
    ReplicatedStorage.Game.ServerClient.StartGame:FireAllClients()

    StartNextParticipantTurn(round)
end

function module.new(board: Types.Board, gameConfiguration: Types.GameConfiguration): Types.Round
    assert(#board.Tiles % 4 == 0, "Board size must be a multiple of 4")

    local round = {}

    round.Board = board
    round.GameConfiguration = gameConfiguration

    round.Started = false
    round.Turn = 0

    ServerStorage.Game.Maps:FindFirstChild("Happy Home"):Clone().Parent = workspace :: any

    round.Tiles = {}
    for i, description in board.Tiles do
        table.insert(round.Tiles, Tile.new(board, i, description))
    end
    
    round.Participants = {}
    round.CurrentParticipant = nil :: any

    round.StartNextParticipantTurn = StartNextParticipantTurn
    round.GetParticipant = GetParticipant
    round.FindTileByName = FindTileByName
    round.StartRound = StartRound

    for _, player in Players:GetPlayers() do
        table.insert(round.Participants, Participant.new(player, round))
    end

    round.CurrentParticipant = round.Participants[#round.Participants]

    return round
end

return module