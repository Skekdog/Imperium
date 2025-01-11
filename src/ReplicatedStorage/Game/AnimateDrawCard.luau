local TweenService = game:GetService("TweenService")

local info = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
return function(card: BasePart?): ()
    if not card then -- May happen if there is an extreme delay in receiving the event
        return
    end

    TweenService:Create(card, info, {
        Size = Vector3.new(15, 7.5, 0.25)
    }):Play()

    task.wait(5)

    TweenService:Create(card, info, {
        Size = Vector3.new()
    }):Play()
end
