local TileUtils = require(script.Parent.TileUtils)
local Types = require(script.Parent.Types)

local module = {}

local function FindTileByName(board: Types.Board, name: string): number
    for i, tile in board.Tiles do
        if TileUtils.GetName(tile.TileDescription) == name then
            return i
        end
    end
    error(`Tile {name} not found`)
end

function module.new(tiles: {Types.Tile}): Types.Board
    local board = {}

    board.Tiles = tiles
    board.FindTileByName = FindTileByName

    return board
end

return module