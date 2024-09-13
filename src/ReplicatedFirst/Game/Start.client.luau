local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIManager = require(script.Parent.Parent.Shared.UIManager)
local RollDice = require(script.Parent.RollDice)
local ToggleMovementEnabled = require(script.Parent.ToggleMovementEnabled)
ReplicatedStorage:WaitForChild("Game").ServerClient.SetMovementEnabled.OnClientEvent:Connect(ToggleMovementEnabled)

local rollDice = UIManager.WaitForUI("RollDice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.RollDice)}
ReplicatedStorage:GetAttributeChangedSignal("CurrentPlayer"):Connect(function()
    local name = ReplicatedStorage:GetAttribute("CurrentPlayer")
    if not name then
        return rollDice:ToggleVisible(false)
    end

    if name == Players.LocalPlayer.Name then
        rollDice:ToggleVisible(true)
    end
end)

rollDice.Object.Activated:Connect(RollDice)