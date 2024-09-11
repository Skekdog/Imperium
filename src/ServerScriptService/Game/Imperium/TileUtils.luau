local Types = require(script.Parent.Types)

local module = {}

function module.GetName(tile: Types.TileDescription): string
    if tile.AssetDescription then
        return tile.AssetDescription.Name
    else
        assert(tile.Name)
        return tile.Name
    end
end

function module.GetColour(tile: Types.TileDescription): "Default" | string
    return if tile.AssetDescription then tile.AssetDescription.Colour else "Default"
end

return module