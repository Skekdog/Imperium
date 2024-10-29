local Players = game:GetService("Players")
local Controls = (require)(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local originalMoveFunction = Controls.moveFunction
local originalGetIsJumping = Controls.activeController.GetIsJumping

--todo: if there is ever a case where this is called with enabled = true, it's untested. jump function is especially dodgy.
return function(enabled: boolean): ()
    if enabled then
        Controls.moveFunction = originalMoveFunction
        Controls.activeController.GetIsJumping = originalGetIsJumping
        if Controls.touchJumpController then
            Controls.touchJumpController:Enable(true)
        end
    else
        Controls.moveFunction = function() end
        Controls.activeController.GetIsJumping = function() return false end
        if Controls.touchJumpController then
            Controls.touchJumpController:Enable(false)
        end
    end
end
