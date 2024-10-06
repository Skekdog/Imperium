local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local UIManager = require(ReplicatedFirst.Shared.UIManager)

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

UIManager.RegisterUI(UIManager.UnregisteredUIs.Sidebar)
ReplicatedFirst:SetAttribute("UICanRegister", true)

for _, object in UIManager.UnregisteredUIs:GetChildren() do
	if object:GetAttribute("AlwaysRegister") then
		UIManager.RegisterUI(object :: GuiObject)
	end
end

local ControlManager = require(ReplicatedFirst.Shared.ControlManager)
ControlManager.Register("Close UI", false, function()
	for _, v in UIManager.GetUIs("Popup") do
		if v.Visible and not v.NoClose then
			v:ToggleVisible(false)
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end)

ReplicatedStorage:WaitForChild("Shared").ServerClient.OpenSettings.OnClientEvent:Connect(function()
	UIManager.WaitForUI("Settings"):ToggleVisible(true)
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
StarterGui:SetCore("ResetButtonCallback", false)

-- If we do not have this event, then the server fires various data sync events before the client begins listening, resulting in desync. This is a (bad) fix.
task.wait(1)
ReplicatedStorage:WaitForChild("Shared").ClientServer.RequestData:FireServer()