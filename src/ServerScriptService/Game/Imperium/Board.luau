local TileUtils = require(script.Parent.TileUtils)
local Types = require(script.Parent.Types)

local module = {}

local function TryFindTileByName(board: Types.Board, name: string): Types.Tile?
    for i, tile in board.Tiles do
        if TileUtils.GetName(tile.TileDescription) == name then
            return tile
        end
    end
    return
end

local function FindTileByName(board: Types.Board, name: string): Types.Tile
    return TryFindTileByName(board, name) or error(`Tile {name} not found`)
end

function module.new(tiles: {Types.Tile}): Types.Board
    local board = {}

    board.Tiles = tiles
    board.TryFindTileByName = TryFindTileByName
    board.FindTileByName = FindTileByName

    return board
end

return module