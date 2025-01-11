local RunService = game:GetService("RunService")

return function(model: PVInstance, targetCFrame: CFrame, duration: number): ()
    local startTime = tick()
    local startCFrame = model:GetPivot()

    local con
    con = RunService.Heartbeat:Connect(function()
        local elapsedTime = tick() - startTime
        local alpha = math.min(elapsedTime / duration, 1) ^ 6

        local newCFrame = startCFrame:Lerp(targetCFrame, alpha)
        model:PivotTo(newCFrame)

        if alpha >= 1 then
            con:Disconnect()
        end
    end)
end