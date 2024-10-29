local Players = game:GetService("Players")
local Controls = (require)(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local activeController = Controls.activeController
while not activeController do
    activeController = Controls.activeController
    task.wait()
end

local originalMoveFunction = Controls.moveFunction
local originalGetIsJumping = activeController.GetIsJumping

--todo: if there is ever a case where this is called with enabled = true, it's untested. jump function is especially dodgy.
return function(enabled: boolean): ()
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
    end
end
