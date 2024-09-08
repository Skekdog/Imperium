local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Participant = require(script.Parent.Participant)
local Tile = require(script.Parent.Tile)
local Types = require(ReplicatedFirst.Types)

local module = {}

function module.new(board: Types.Board): Types.Round
    assert(#board.Tiles % 4 == 0, "Board size must be a multiple of 4")

    local round = {}

    round.Turn = 0
    round.Map = "TestMap"
    round.Theme = "TestTheme"

    round.Tiles = {}
    for i, description in board.Tiles do
        table.insert(round.Tiles, Tile.new(board, i, description))
    end

    round.Participants = {}
    for _, player in Players:GetPlayers() do
        table.insert(round.Participants, Participant.new(player, round))
    end

    return round
end

return module