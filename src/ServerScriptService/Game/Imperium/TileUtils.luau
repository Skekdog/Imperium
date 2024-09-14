local Types = require(script.Parent.Types)

local module = {}

function module.GetName(tile: Types.TileDescription): string
    if tile.Name then
        return tile.Name
    else
        assert(tile.AssetDescription)
        return tile.AssetDescription.Name
    end
end

function module.GetIcon(tile: Types.TileDescription): string?
    if tile.Icon then
        return tile.Icon
    elseif tile.AssetDescription then
        return tile.AssetDescription.Icon
    end
    return
end

function module.GetColour(tile: Types.TileDescription): "Default" | string
    if tile.Colour then
        return tile.Colour
    elseif tile.AssetDescription then
        return tile.AssetDescription.Colour
    else
        return "Default"
    end
end

return module