local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToggleMovementEnabled = require(script.Parent.ToggleMovementEnabled)
local UIManager = require(script.Parent.UIManager)

ReplicatedStorage:WaitForChild("ServerClient").StartGame.OnClientEvent:Wait()
ToggleMovementEnabled(false)
UIManager.WaitForUI("CurrentTurnIndicator"):ToggleVisible(true)