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

local function GetAllAssetsInColourGroup(board: Types.Board, colourGroup: string): {Types.Asset}
    local assets: {Types.Asset} = {}
    for _, tile in board.Tiles do
        local colour = TileUtils.GetColour(tile.TileDescription)
        if colour == colourGroup then
            table.insert(assets, tile.Asset or error("Tile has no asset"))
        end
    end

    return assets
end

function module.new(tiles: {Types.Tile}): Types.Board
    local board = {}

    board.Tiles = tiles
    board.TryFindTileByName = TryFindTileByName
    board.FindTileByName = FindTileByName
    board.GetAllAssetsInColourGroup = GetAllAssetsInColourGroup

    return board
end

return module