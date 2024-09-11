local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SetTimeMilestone = require(script.Parent.Parent.SetTimeMilestone)
local Participant = require(script.Parent.Participant)
local Types = require(script.Parent.Types)

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
    ReplicatedStorage:SetAttribute("CurrentPlayer", round.CurrentParticipant.Player.Name)
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

    ReplicatedStorage.Game.ServerClient.SetMovementEnabled:FireAllClients(false)
    for _, v in round.Participants do
        v.Player:SetAttribute("Status", "Playing")
        task.spawn(v.MoveTo, v, 1, true, true)
    end
    ReplicatedStorage.Game.ServerClient.StartGame:FireAllClients()

    StartNextParticipantTurn(round)
end

local function TryGetAssetFromTile(round: Types.Round, tile: Types.Tile): Types.Asset?
    local tileName = if tile.TileDescription.Asset then tile.TileDescription.Asset.Name else tile.TileDescription.Name
    for _, v in round.Participants do
        for _, asset in v.Assets do
            if asset.AssetDescription.Name == tileName then
                return asset
            end
        end
    end
    return
end

function module.new(board: Types.Board, tiles: {Types.Tile}, gameConfiguration: Types.GameConfiguration): Types.Round
    assert(#board.Tiles % 4 == 0, "Board size must be a multiple of 4")

    local round = {}

    round.Board = board
    round.GameConfiguration = gameConfiguration

    round.Started = false
    round.Turn = 0

    round.Tiles = tiles
    
    round.Participants = {}
    round.CurrentParticipant = nil :: any

    round.StartNextParticipantTurn = StartNextParticipantTurn
    round.GetParticipant = GetParticipant
    round.FindTileByName = FindTileByName
    round.StartRound = StartRound
    round.TryGetAssetFromTile = TryGetAssetFromTile

    for _, player in Players:GetPlayers() do
        table.insert(round.Participants, Participant.new(player, round))
    end

    round.CurrentParticipant = round.Participants[#round.Participants]

    return round
end

return module