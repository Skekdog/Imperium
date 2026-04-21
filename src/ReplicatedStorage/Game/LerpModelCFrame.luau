local RunService = game:GetService("RunService")

return function(model: PVInstance, targetCFrame: CFrame, duration: number): ()
    local startTime = os.clock()
    local startCFrame = model:GetPivot()

    local con
    con = RunService.Heartbeat:Connect(function()
        local elapsedTime = os.clock() - startTime
        local alpha = math.min(elapsedTime / duration, 1) ^ 6

        local newCFrame = startCFrame:Lerp(targetCFrame, alpha)
        model:PivotTo(newCFrame)

        if alpha >= 1 then
            con:Disconnect()
        end
    end)
end