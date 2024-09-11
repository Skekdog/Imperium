local module = {}

local ROWS = 4

function module.GetTilesPerRow(numTiles: number): number
    return numTiles / ROWS
end

function module.GetRowFromPosition(position: number, numTiles: number): number
    return (position - 1) // module.GetTilesPerRow(numTiles) + 1
end

function module.GetNextCornerPosition(position: number, numTiles: number): number
    return math.ceil(position / module.GetTilesPerRow(numTiles)) * module.GetTilesPerRow(numTiles) + 1
end

function module.GetLastCornerPosition(position: number, numTiles: number): number
    return (position // module.GetTilesPerRow(numTiles)) * module.GetTilesPerRow(numTiles)
end

function module.GetWrapAround(position: number, numTiles: number): number
    return math.max(position % (numTiles + 1), 1)
end

return module