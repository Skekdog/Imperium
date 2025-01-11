local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientTypes = require(script.Parent.ClientTypes)

local colourOrders = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ColourOrders")

export type Button = typeof(script.AssetButton)

return function(size: UDim2, asset: ClientTypes.ClientAssetView): Button
    local button = script.AssetButton:Clone()

    button.Visible = true

    local name = asset.Name

    button.Text = name
    button.BackgroundColor3 = asset.Colour

    button.Size = size

    button.LayoutOrder = colourOrders:GetAttribute(asset.Colour:ToHex()) :: number * 1000 + asset.Position

    button.Name = "Asset_" .. name
    button.Visible = true

    return button
end