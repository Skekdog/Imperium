local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function(name: string, displayName: string, callback: () -> ()): ()
    coroutine.wrap(function()
        local sb = Players.LocalPlayer.PlayerGui:WaitForChild("Buttons"):WaitForChild("Sidebar") :: typeof(ReplicatedStorage.Shared.UnregisteredUIs.Sidebar)
        local but = sb.Button:Clone()
        but.Name = name
        but.Text = displayName
    
        but:SetAttribute("Control", name)
        but:SetAttribute("NoStyle", true)
        but:SetAttribute("Position", UDim2.fromScale(1, 1))
        but:SetAttribute("Size", UDim2.fromScale(0.45, 1))
        but:AddTag("ControlHint")
    
        but.Visible = true
        but.Parent = sb
        but.MouseButton1Click:Connect(callback)
    end)()
end
