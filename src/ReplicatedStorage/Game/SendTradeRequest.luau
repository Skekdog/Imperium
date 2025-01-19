local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetPlayerName = require(ReplicatedStorage.Shared.GetPlayerName)
local ClientTypes = require(script.Parent.ClientTypes)
local ScreenMessage = require(script.Parent.Parent.Shared.ScreenMessage)
local TradingUI = require(script.Parent.TradingUI)

return function(plr: Player | Configuration): ()
    local offer = TradingUI.DraftTrade(plr)
    TradingUI.UI:ToggleVisible(false)
    
    if not offer then
        return
    end

    ScreenMessage("Success", "Trade request sent!")
    
    local response: ClientTypes.TradeRequestInvokeResult = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Trading"):WaitForChild("SendTradeRequest"):InvokeServer(plr.Name, offer)
    
    if response == "Success" then
        return TradingUI.Trading(plr, offer)
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
    elseif response == "OtherNotEnoughJailCards" then
        ScreenMessage("Error", "Target no longer has enough jail cards.")
    elseif response == "OtherNotEnoughMoney" then
        ScreenMessage("Error", "Target no longer has enough money.")
    elseif response == "SelfNotEnoughJailCards" then
        ScreenMessage("Error", "You no longer have enough jail cards.")
    elseif response == "SelfNotEnoughMoney" then
        ScreenMessage("Error", "You no longer have enough money.")
    elseif response == "SelfUnownedAsset" then
        ScreenMessage("Error", "You no longer own some of the assets in your offer.")
    elseif response == "OtherUnownedAsset" then
        ScreenMessage("Error", "Target no longer owns some of the assets in their offer.")
    elseif response == "OtherJailCardsBelowZero" then
        ScreenMessage("Error", "Target offer has a negative amount of jail cards.")
    elseif response == "OtherMoneyBelowZero" then
        ScreenMessage("Error", "Target offer has a negative amount of money.")
    elseif response == "SelfJailCardsBelowZero" then
        ScreenMessage("Error", "Your offer has a negative amount of jail cards.")
    elseif response == "SelfMoneyBelowZero" then
        ScreenMessage("Error", "Your offer has a negative amount of money.")
    else
        ScreenMessage("Error", "An unknown error occurred: " .. tostring(response))
    end
end