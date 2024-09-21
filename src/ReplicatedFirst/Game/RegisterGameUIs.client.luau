local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UIManager = require(script.Parent.Parent.Shared.UIManager)

if not ReplicatedFirst:GetAttribute("UICanRegister") then
    ReplicatedFirst:GetAttributeChangedSignal("UICanRegister"):Wait()
end

local reg = UIManager.RegisterUI
local un = UIManager.UnregisteredUIs
reg(un.Playerlist)
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