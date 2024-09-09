local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToggleMovementEnabled = require(script.Parent.ToggleMovementEnabled)
ReplicatedStorage:WaitForChild("Game").ServerClient.SetMovementEnabled.OnClientEvent:Connect(ToggleMovementEnabled)