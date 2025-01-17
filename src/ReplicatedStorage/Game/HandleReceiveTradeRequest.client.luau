local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local currentOffer: string?

local tradeRemotes = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Trading")

local ui = UIManager.WaitForUI("TradeRequest") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.TradeRequest)}

local function updateNotificationDisplay(playerName: string): ()
    local player = Players:FindFirstChild(playerName)
    if not player or (not player:IsA("Player") and not player:IsA("Configuration")) then
        return
    end

    ui.Object.Trader:AddTag("DynamicNames")
    ui.Object.Trader:SetAttribute("Player_1", GetPlayerName(playerName))
    ui.Object.Trader:SetAttribute("Format", "[PLAYER]")

    currentOffer = (player :: Player | Configuration).Name

    ui:ToggleVisible(true)
end

tradeRemotes:WaitForChild("ReceiveTradeRequest").OnClientEvent:Connect(function(from: string): ()
    if not currentOffer then
        updateNotificationDisplay(from)
    end
end)

ui.Object.Response.Accept.Activated:Connect(function(): ()
    assert(currentOffer, "No current offer")

    ui:ToggleVisible(false)
    tradeRemotes:WaitForChild("RespondTradeRequest"):FireServer(currentOffer, true)
    currentOffer = nil
end)

ui.Object.Response.Reject.Activated:Connect(function(): ()
    assert(currentOffer, "No current offer")

    ui:ToggleVisible(false)
    tradeRemotes:WaitForChild("RespondTradeRequest"):FireServer(currentOffer, false)
    currentOffer = nil
end)
