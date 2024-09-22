local ServerStorage = game:GetService("ServerStorage")
local Asset = require(script.Parent.Asset)
local TileMath = require(script.Parent.Parent.TileMath)
local TileUtils = require(script.Parent.TileUtils)
local Types = require(script.Parent.Types)

local module = {}

local function makeTileModel(boardConfiguration: Types.BoardConfiguration, position: number, name: string, colour: string, icon: string): Types.TileModel
    local tilesPerRow = TileMath.GetTilesPerRow(#boardConfiguration.Tiles)
    local row = TileMath.GetRowFromPosition(position, #boardConfiguration.Tiles)

    local offset = (position - 1) % tilesPerRow
    local isCorner = offset == 0

    local cornerRadius = ServerStorage.Game.CornerTile.Base.Size.X / 2
    local tileSizeZ = ServerStorage.Game.Tile.Base.Size.Z

    local model: Types.TileModel
    if name == "Jail" then
        local jail = ServerStorage.Game.JailTile:Clone()
        jail.Name = "Jail"

        model = jail
    elseif isCorner then
        local corner = ServerStorage.Game.CornerTile:Clone()
        corner.Name = "TileCorner" .. tostring(row)

        corner.Base.BaseUI.Title.Text = name
        corner.Base.BaseUI.Icon.Image = icon

        model = corner
    else
        local edge = ServerStorage.Game.Tile:Clone()
        edge.Name = "TileEdge" .. tostring(position)

        edge.Title.TitleUI.TextLabel.Text = name
        edge.Title.Color = boardConfiguration.Colours[colour] or boardConfiguration.Colours.Default

        edge.BaseUIPart.BaseUI.Icon.Image = icon
        edge.BaseUIPart.BaseUI.Owner.Text = ""

        model = edge
    end

    local posX, posZ = 1000, 1000
    local corner = (tilesPerRow - 1) * tileSizeZ / 2 + cornerRadius
    if row == 1 then
        posX = -corner
        posZ = -corner
    elseif row == 2 then
        posX = corner
        posZ = -corner
    elseif row == 3 then
        posX = corner
        posZ = corner
    elseif row == 4 then
        posX = -corner
        posZ = corner
    end

    if not isCorner then
        local relPos = (cornerRadius + tileSizeZ / 2) + tileSizeZ * (offset - 1)
        if row == 1 then
            posX += relPos
        elseif row == 2 then
            posZ += relPos
        elseif row == 3 then
            posX -= relPos
        elseif row == 4 then
            posZ -= relPos
        end
    end

    model:PivotTo(CFrame.new(posX, 0.6, posZ) * CFrame.Angles(0, math.rad(((row - 1) * -90) + 90), 0));
    (model :: Model).Parent = workspace:FindFirstChild("Board") or Instance.new("Folder", workspace)
    model.Parent.Name = "Board"

    return model
end

local function serialiseRentTable(t: {{string}}): string
    local result = {}
            
    for _, v in ipairs(t) do
        table.insert(result, v[1] .. v[2])
    end
    
    return table.concat(result, "\n")
end

function module.new(boardConfiguration: Types.BoardConfiguration, position: number, tileDescription: Types.TileDescription): Types.Tile
    local tile = {}

    local name = TileUtils.GetName(tileDescription)
    local colour = TileUtils.GetColour(tileDescription)
    local icon = TileUtils.GetIcon(tileDescription)
    local model = makeTileModel(boardConfiguration, position, name, colour, icon or "")

    tile.Position = position
    tile.TileDescription = tileDescription
    tile.Model = model

    if tileDescription.AssetDescription then
        model:SetAttribute("Name", name)
        model:SetAttribute("Colour", boardConfiguration.Colours[colour] or boardConfiguration.Colours.Default)
        model:SetAttribute("HousePrice", boardConfiguration.HousePrices[colour])
        model:SetAttribute("HotelPrice", boardConfiguration.HousePrices[colour])
        model:SetAttribute("MortgageValue", tileDescription.AssetDescription.Price / 2)

        model:SetAttribute("RentDescription", serialiseRentTable(tileDescription.AssetDescription.RentDescription))
    end

    if tile.TileDescription.AssetDescription then
        tile.Asset = Asset.new(tile.TileDescription.AssetDescription)
    end

    return tile
end

return module