local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local manager = require(script.Parent.Parent)

local orders = {
	Special = 4,
	Popup = 3,
	Buttons = 2,
	HUD = 1,
}

for _, layer in {"Popup", "HUD", "Special", "Buttons"} do
	local screenUi = Instance.new("ScreenGui")
	screenUi.Name = layer
	screenUi.IgnoreGuiInset = true
	screenUi.DisplayOrder = orders[layer]
	screenUi.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenUi.ClipToDeviceSafeArea = false
	screenUi.ResetOnSpawn = false

	if layer == "Buttons" then
		screenUi.ScreenInsets = Enum.ScreenInsets.None
	end

	screenUi.Parent = Players.LocalPlayer.PlayerGui
end

manager.RegisterUI(manager.UnregisteredUIs.Sidebar)
for _, object in manager.UnregisteredUIs:GetChildren() do
	if object:GetAttribute("DoNotRegister") then
		continue
	end
	manager.RegisterUI(object :: GuiObject)
end

local ControlManager = require(script.Parent.Parent.Parent.ControlManager)
ControlManager.Register("Close UI", false, function()
	for _, v in manager.GetUIs("Popup") do
		if v.Visible and not v.NoClose then
			v:ToggleVisible(false)
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end)

ReplicatedStorage:WaitForChild("ServerClient").OpenSettings.OnClientEvent:Connect(function()
	manager.WaitForUI("Settings"):ToggleVisible(true)
end)

-- If we do not have this event, then the server fires various data sync events before the client begins listening, resulting in desync. This is a (bad) fix.
task.wait(1)
ReplicatedStorage:WaitForChild("ClientServer").RequestData:FireServer()

local CASui = Players.LocalPlayer.PlayerGui:WaitForChild("ContextActionGui", math.huge)
assert(CASui and CASui:IsA("ScreenGui"))

local CASFrame = CASui:WaitForChild("ContextButtonFrame")
assert(CASFrame:IsA("Frame"))

CASFrame.Size = UDim2.fromScale(1, 1)
CASFrame.Position = UDim2.fromScale(0, 0)
CASui.DisplayOrder = 4
CASui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
CASui.ClipToDeviceSafeArea = false
CASui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension