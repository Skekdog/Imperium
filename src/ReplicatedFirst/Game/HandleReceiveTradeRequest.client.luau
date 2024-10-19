local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local offerQueue: {Player} = {}
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

local function processNext(): ()
    table.remove(offerQueue, 1)
    currentOffer = offerQueue[1]

    if currentOffer then
        updateNotificationDisplay(currentOffer)
    else
        ui:ToggleVisible(false)
    end
end

tradeRemotes:WaitForChild("RequestTrade").OnClientEvent:Connect(function(from: Player): ()
    if table.find(offerQueue, from) or currentOffer == from then
        return
    end

    table.insert(offerQueue, from)

    if not currentOffer then
        updateNotificationDisplay(from)
    end
end)

ui.Object.Response.Accept.Activated:Connect(function(): ()
    assert(currentOffer, "No current offer")

    ui:ToggleVisible(false)

    tradeRemotes:WaitForChild("AnswerTradeRequest"):FireServer(currentOffer, true)
    processNext()
end)

ui.Object.Response.Reject.Activated:Connect(function(): ()
    assert(currentOffer, "No current offer")

    ui:ToggleVisible(false)

    tradeRemotes:WaitForChild("AnswerTradeRequest"):FireServer(currentOffer, false)
    processNext()
end)
