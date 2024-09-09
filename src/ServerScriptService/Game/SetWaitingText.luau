local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SetTimeMilestone = require(script.Parent.SetTimeMilestone)

return function(text: string?, duration: number): ()
    ReplicatedStorage:SetAttribute("WaitingText", text)
    SetTimeMilestone(duration)
end
