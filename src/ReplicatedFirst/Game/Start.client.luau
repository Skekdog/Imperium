local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToggleMovementEnabled = require(script.Parent.ToggleMovementEnabled)
local UIManager = require(ReplicatedFirst.Shared.UIManager)

ReplicatedStorage:WaitForChild("Game").ServerClient.StartGame.OnClientEvent:Wait()
ToggleMovementEnabled(false)
UIManager.WaitForUI("CurrentTurnIndicator"):ToggleVisible(true)