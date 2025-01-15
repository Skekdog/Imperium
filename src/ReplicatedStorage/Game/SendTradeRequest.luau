local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetPlayerName = require(ReplicatedStorage.Shared.GetPlayerName)
local ClientTypes = require(script.Parent.ClientTypes)
local ScreenMessage = require(script.Parent.Parent.Shared.ScreenMessage)
local TradingUI = require(script.Parent.TradingUI)

return function(plr: Player | Configuration): ()
    local offer = TradingUI.DraftTrade(plr)
    if not offer then
        return
    end
    
    local response: ClientTypes.TradeRequestInvokeResult = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Trading"):WaitForChild("SendTradeRequest"):InvokeServer(plr.Name, offer)
    
    if response == "Success" then
        return TradingUI.Trading(plr)
    elseif response == "BotAcceptedOffer" then
        return ScreenMessage("Success", `{GetPlayerName(plr)} accepted your trade offer.`)
    elseif response == "BotDeclinedOffer" then
        return ScreenMessage("Error", `{GetPlayerName(plr)} declined your trade offer.`)
    end
    
    if response == "Cooldown" then
        ScreenMessage("Error", "Please wait before sending another trade request to this player.")
    elseif response == "SelfAlreadyTrading" then
        ScreenMessage("Error", "You already have an active trade / request with someone.")
    elseif response == "OtherAlreadyTrading" then
        ScreenMessage("Error", "Target already has an active trade / request with someone.")
    elseif response == "Timeout" then
        ScreenMessage("Error", "Trade request timed out.")
    elseif response == "Declined" then
        ScreenMessage("Error", "Target declined your trade request.")
    elseif response == "Bankrupt" then
        ScreenMessage("Error", "Unable to trade during bankruptcy.")
    elseif response == "Disconnected" then
        ScreenMessage("Error", "Unable to trade with a disconnected player.")
    elseif response == "SelfAlreadyHasOutgoingRequest" then
        ScreenMessage("Error", "You already have an outgoing trade request.")
    elseif response == "OtherAlreadyHasIncomingRequest" then
        ScreenMessage("Error", "Target already has an incoming trade request.")
    else
        ScreenMessage("Error", "An unknown error occurred.")
    end
end