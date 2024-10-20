local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local currentOffer: Player?

local tradeRemotes = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Trading")

local ui = UIManager.WaitForUI("TradeRequest") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.TradeRequest)}

local function updateNotificationDisplay(player: Player): ()
    ui.Object.Trader:AddTag("DynamicNames")
    ui.Object.Trader:SetAttribute("Player_1", GetPlayerName(player))
    ui.Object.Trader:SetAttribute("Format", "[PLAYER]")

    currentOffer = player

    ui:ToggleVisible(true)
end

tradeRemotes:WaitForChild("ReceiveTradeRequest").OnClientEvent:Connect(function(from: Player): ()
    if not currentOffer then
        updateNotificationDisplay(from)
    end
end)

tradeRemotes:WaitForChild("RespondedTradeRequest").OnClientEvent:Connect(function(with: Player, accepted: boolean): ()
    if currentOffer == with and not accepted then
        currentOffer = nil
        ui:ToggleVisible(false)
    end
end)

ui.Object.Response.Accept.Activated:Connect(function(): ()
    assert(currentOffer, "No current offer")
    ui:ToggleVisible(false)
    tradeRemotes:WaitForChild("AnswerTradeRequest"):FireServer(currentOffer, true)
    currentOffer = nil
end)

ui.Object.Response.Reject.Activated:Connect(function(): ()
    assert(currentOffer, "No current offer")
    ui:ToggleVisible(false)
    tradeRemotes:WaitForChild("AnswerTradeRequest"):FireServer(currentOffer, false)
    currentOffer = nil
end)
