local ContextActionService = game:GetService("ContextActionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UIManager = require(script.Parent.Parent.Shared.UIManager)

if not ReplicatedFirst:GetAttribute("UICanRegister") then
    ReplicatedFirst:GetAttributeChangedSignal("UICanRegister"):Wait()
end

local reg = UIManager.RegisterUI
local un = UIManager.UnregisteredUIs
reg(un.CurrentTurnIndicator)
reg(un.RollDice)
reg(un.BuyProperty)
reg(un.AuctionProperty)
reg(un.MoneyDisplay)
reg(un.Notification)
reg(un.PayFine)
reg(un.UseGetOutOfJailFreeCard)
reg(un.AssetManager)
reg(un.EventLog)
reg(un.PropertyDeed)
reg(un.Trading)
reg(un.TradeRequest)

ContextActionService:BindAction("a", function(_, state)
    if state == Enum.UserInputState.End then
        UIManager.WaitForUI("TradeRequest"):ToggleVisible()
    end
    return nil
end, false, Enum.KeyCode.P)