local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientTypes = require(script.Parent.ClientTypes)
local ScreenMessage = require(script.Parent.Parent.Shared.ScreenMessage)

return function(plr: Player | Configuration): ()
    local response: ClientTypes.TradeRequestInvokeResult = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Trading"):WaitForChild("RequestTrade"):InvokeServer(plr)
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
    elseif response == "Success" then
        return
    else
        ScreenMessage("Error", "An unknown error occurred.")
    end
end