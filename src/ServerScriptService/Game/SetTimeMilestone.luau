local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(duration: number?): ()
    ReplicatedStorage:SetAttribute("TimeMilestone", if not duration then nil else workspace:GetServerTimeNow() + duration)
end
