local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(script.Parent.Parent.Shared.UIManager)
local ui = UIManager.WaitForUI("RollDice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.RollDice)}

return function(): ()
    ui:ToggleVisible(false)

    if ReplicatedStorage:GetAttribute("CurrentPlayer") ~= Players.LocalPlayer.Name then
        return
    end

    ReplicatedStorage.Game.ClientServer.RollDice:FireServer()
end
