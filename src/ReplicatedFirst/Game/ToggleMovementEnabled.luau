local Players = game:GetService("Players")
local Controls = (require)(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

return function(enabled: boolean): ()
    Controls:Enable(enabled)
end
