local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIManager = require(script.Parent.Parent.Shared.UIManager)
local ui = UIManager.WaitForUI("RollDice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.RollDice)}
local payFineUI = UIManager.WaitForUI("PayFine")
local useGetOutOfJailFreeCardUI = UIManager.WaitForUI("UseGetOutOfJailFreeCard")

return function(): ()
    ui:ToggleVisible(false)
    payFineUI:ToggleVisible(false)
    useGetOutOfJailFreeCardUI:ToggleVisible(false)

    if ReplicatedStorage:GetAttribute("CurrentPlayer") ~= Players.LocalPlayer.Name then
        return
    end

    ReplicatedStorage.Game.ClientServer.RollDice:FireServer()
end
