local ClientTypes = require(script.Parent.ClientTypes)
local UIAnimation = require(script.Parent.Parent.Shared.UIAnimation)

export type Button = typeof(script.AssetButton)

return function(size: UDim2, asset: ClientTypes.ClientAssetView): Button
    local button = script.AssetButton:Clone()

    button.Visible = true

    local name = asset.Name

    button.Text = name
    button.BackgroundColor3 = asset.Colour

    button.Size = UDim2.new(size.X, UDim.new())
    UIAnimation.Animate(button, TweenInfo.new(0.25), {Size = size})

    -- todo: this can cause problems if there are two similar colours. woo.
    button.LayoutOrder = (tonumber(asset.Colour:ToHex(), 16) or error("Failed to convert colour to hex")) + asset.Position

    button.Name = "Asset_" .. name
    button.Visible = true

    return button
end