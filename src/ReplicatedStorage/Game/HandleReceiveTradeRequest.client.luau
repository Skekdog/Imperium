local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientTypes = require(script.Parent.ClientTypes)
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local UIManager = require(script.Parent.Parent.Shared.UIManager)
local TradingUI = require(script.Parent.TradingUI)

local currentTrader: string?
local currentOffer: ClientTypes.InitialTradeOffer?

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

    currentTrader = (player :: Player | Configuration).Name

    ui:ToggleVisible(true)
end

tradeRemotes:WaitForChild("ReceiveTradeRequest").OnClientEvent:Connect(function(from: string, offer: ClientTypes.InitialTradeOffer): ()
    if not currentTrader then
        updateNotificationDisplay(from)
        currentOffer = offer
    end
end)

ui.Object.Response.Accept.Activated:Connect(function(): ()
    assert(currentTrader and currentOffer, "No current offer")

    ui:ToggleVisible(false)
    
    local player = Players:FindFirstChild(currentTrader)
    assert(player and (player:IsA("Player") or player:IsA("Configuration")), "Player not found")
    TradingUI.Trading(player :: Player | Configuration, currentOffer)

    tradeRemotes:WaitForChild("RespondTradeRequest"):FireServer(currentTrader, true)
    currentTrader = nil
end)

ui.Object.Response.Reject.Activated:Connect(function(): ()
    assert(currentTrader and currentOffer, "No current offer")

    ui:ToggleVisible(false)
    tradeRemotes:WaitForChild("RespondTradeRequest"):FireServer(currentTrader, false)
    currentTrader = nil
end)
