local Players = game:GetService("Players")
return function(): boolean
    return Players.LocalPlayer:GetAttribute("Status") == "Spectating"
end
