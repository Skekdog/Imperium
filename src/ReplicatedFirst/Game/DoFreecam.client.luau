local Freecam = require(script.Parent.Freecam)
local ControlManager = require(script.Parent.Parent.Shared.ControlManager)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

ControlManager.Register("Freecam", false, function()
    Freecam()
    return Enum.ContextActionResult.Sink
end)

local sb = UIManager.WaitForUI("Sidebar").Object :: typeof(UIManager.UnregisteredUIs.Sidebar)

local but = sb.Button:Clone()
but.Name = "Freecam"
but.Text = "Freecam"

but:SetAttribute("Control", "Freecam")
but:SetAttribute("NoStyle", true)
but:SetAttribute("Position", UDim2.fromScale(1, 1))
but:SetAttribute("Size", UDim2.fromScale(0.45, 1))
but:AddTag("ControlHint")

but.Visible = true
but.Parent = sb
but.MouseButton1Click:Connect(Freecam)

--todo: this doesn't work on mobile