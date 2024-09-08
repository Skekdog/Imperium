local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(duration: number): ()
    ReplicatedStorage:SetAttribute("TimeMilestone", workspace:GetServerTimeNow() + duration)
end
