local RunService = game:GetService("RunService")
local DURATION = 1

return function(bars: Model, targetCFrame: CFrame): ()
    local startTime = tick()
    local startCFrame = bars:GetPivot()

    local con
    con = RunService.Heartbeat:Connect(function()
        local elapsedTime = tick() - startTime
        local alpha = math.min(elapsedTime / DURATION, 1) ^ 3

        local newCFrame = startCFrame:Lerp(targetCFrame, alpha)
        bars:PivotTo(newCFrame)

        if alpha >= 1 then
            con:Disconnect()
        end
    end)
end
