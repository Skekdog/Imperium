local Players = game:GetService("Players")
return function(target: number): boolean
    return Players.LocalPlayer:GetAttribute("Money") >= target
end
