local UIAnimation = require(script.Parent.UIAnimation)
local UIManager = require(script.Parent.UIManager)

return function(alignment: "Left" | "Right"): ()
    local ui = UIManager.WaitForUI("Sidebar").Object :: typeof(UIManager.UnregisteredUIs.Sidebar)

    local position, anchorPoint, textAlignment, paddingProperty
    if alignment == "Left" then
        position = UDim2.new(0, -5, 0.28, 0)
        anchorPoint = Vector2.new(0, 0)
        textAlignment = Enum.TextXAlignment.Right
        paddingProperty = "PaddingRight"
    elseif alignment == "Right" then
        position = UDim2.new(1, 5, 0.28, 0)
        anchorPoint = Vector2.new(1, 0)
        textAlignment = Enum.TextXAlignment.Left
        paddingProperty = "PaddingLeft"
    end

    UIAnimation.Animate(ui, TweenInfo.new(0.1), {Position = position, AnchorPoint = anchorPoint})
    for _, v in ui:GetChildren() do
        if not v:IsA("TextButton") then
            continue
        end

        v.TextXAlignment = textAlignment;
        (v :: any).UIPadding[paddingProperty] = UDim.new(0, 8)
    end
end
