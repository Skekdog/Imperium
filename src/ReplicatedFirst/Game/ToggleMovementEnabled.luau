local Players = game:GetService("Players")
local Controls = (require)(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local activeController = Controls.activeController
while not activeController do
    activeController = Controls.activeController
    task.wait()
end

local originalMoveFunction = Controls.moveFunction
local originalGetIsJumping = activeController.GetIsJumping

local isEnabled = true

task.defer(function()
    while true do
        task.wait()

        local char = Players.LocalPlayer.Character
        if not char then
            continue
        end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            continue
        end

        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, isEnabled)
    end
end)

--todo: if there is ever a case where this is called with enabled = true, it's untested. jump function is especially dodgy.
return function(enabled: boolean): ()
    isEnabled = enabled
    if enabled then
        Controls.moveFunction = originalMoveFunction
        activeController.GetIsJumping = originalGetIsJumping
        if Controls.touchJumpController then
            Controls.touchJumpController:Enable(true)
        end
    else
        Controls.moveFunction = function() end
        activeController.GetIsJumping = function() return false end
        if Controls.touchJumpController then
            Controls.touchJumpController:Enable(false)
        end

        local char = Players.LocalPlayer.Character
        if not char then
            return
        end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:Move(Vector3.zero)
        end
    end
end
