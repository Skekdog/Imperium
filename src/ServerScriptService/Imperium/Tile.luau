local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")
local Types = require(ReplicatedFirst.Types)

local module = {}

function module.new(board: Types.Board, position: number, tileDescription: Types.TileDescription): Types.Tile
    local tile = {}

    local name = tileDescription.Name
    if not name then
        assert(tileDescription.Asset, "Tile description must have either a name or an asset with a name")
        name = tileDescription.Asset.Name
    end
    assert(name)

    local colour = if tileDescription.Asset then tileDescription.Asset.Colour else "Default"

    tile.TileDescription = tileDescription

    local rows = 4
    local tilesPerRow = #board.Tiles / rows
    local row = (position - 1) // tilesPerRow

    local offset = (position - 1) % tilesPerRow
    local isCorner = offset == 0

    local cornerRadius = ServerStorage.CornerTile.Base.Size.X / 2
    local tileSizeZ = ServerStorage.Tile.Base.Size.Z

    local model: Types.TileModel
    if isCorner then
        local corner = ServerStorage.CornerTile:Clone()

        corner.Base.BaseUI.Title.Text = name

        model = corner
    else
        local edge = ServerStorage.Tile:Clone()

        edge.Title.TitleUI.TextLabel.Text = name
        edge.Title.Color = board.Colours[colour] or board.Colours.Default

        edge.Base.BaseUI.Owner.Text = ""

        model = edge
    end
    tile.Model = model

    local posX, posZ = 1000, 1000
    local corner = (tilesPerRow - 1) * tileSizeZ / 2 + cornerRadius
    if row == 0 then
        posX = -corner
        posZ = -corner
    elseif row == 1 then
        posX = corner
        posZ = -corner
    elseif row == 2 then
        posX = corner
        posZ = corner
    elseif row == 3 then
        posX = -corner
        posZ = corner
    end

    if not isCorner then
        local relPos = (cornerRadius + tileSizeZ / 2) + tileSizeZ * (offset - 1)
        if row == 0 then
            posX += relPos
        elseif row == 1 then
            posZ += relPos
        elseif row == 2 then
            posX -= relPos
        elseif row == 3 then
            posZ -= relPos
        end
    end

    model:PivotTo(CFrame.new(posX, 0.6, posZ) * CFrame.Angles(0, math.rad((row * -90) + 90), 0));
    (model :: Model).Parent = workspace.Board

    return tile
end

return module