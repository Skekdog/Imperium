local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UIManager = require(script.Parent.Parent.Shared.UIManager)

if not ReplicatedFirst:GetAttribute("UICanRegister") then
    ReplicatedFirst:GetAttributeChangedSignal("UICanRegister"):Wait()
end

UIManager.RegisterUI(UIManager.UnregisteredUIs.Playerlist)
UIManager.RegisterUI(UIManager.UnregisteredUIs.CurrentTurnIndicator)
UIManager.RegisterUI(UIManager.UnregisteredUIs.RollDice)
UIManager.RegisterUI(UIManager.UnregisteredUIs.BuyProperty)
UIManager.RegisterUI(UIManager.UnregisteredUIs.AuctionProperty)
UIManager.RegisterUI(UIManager.UnregisteredUIs.MoneyDisplay)
UIManager.RegisterUI(UIManager.UnregisteredUIs.Notification)
UIManager.RegisterUI(UIManager.UnregisteredUIs.PayFine)
UIManager.RegisterUI(UIManager.UnregisteredUIs.UseGetOutOfJailFreeCard)