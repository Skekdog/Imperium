local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientTypes = require(ReplicatedStorage.Game.ClientTypes)
local GetTime = require(ReplicatedStorage.Shared.GetTime)
local FireRemote = require(script.Parent.Util.FireRemote)
local SendNotification = require(script.Parent.Parent.Parent.Shared.SendNotification)

local Types = require(script.Parent.Types)
local module = {}

local TRADE_COOLDOWN = 5
local TRADE_TIMEOUT = 10

local tradeRemotes = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Trading")

local function getAssetByName(participant: Types.Participant, name: string): Types.Asset?
    for _, asset in participant.Assets do
        if asset.AssetDescription.Name == name then
            return asset
        end
    end

    return nil
end

local function giveOfferToOtherParticipant(offer: Types.TradeOffer, participant: Types.Participant, to: Types.Participant): ()
    participant:TransferMoneyTo(to, offer.Money)
    participant:TransferJailCards(to, offer.JailCards)
    
    for _, asset in offer.Assets do
        asset:TransferTo(to)
    end
end

local function doTrade(trade: Types.Trade): ()
    SendNotification(`[PLAYER] accepted a trade with [PLAYER]`, {trade.Participant1.Player, trade.Participant2.Player})
    giveOfferToOtherParticipant(trade.Offers[trade.Participant1], trade.Participant1, trade.Participant2)
    giveOfferToOtherParticipant(trade.Offers[trade.Participant2], trade.Participant2, trade.Participant1)

    trade.Participant1.TradeManager:ResetBoth("TradeAccepted")
end

local function tryUpdateMoneyOffer(participant: Types.Participant, currentOffer: Types.TradeOffer, offer: ClientTypes.TradeOfferMoneyUpdate): ClientTypes.TradeOfferUpdateInvokeResult
    if participant.Money < offer.Amount then
        return "NotEnoughMoney"
    end
    currentOffer.Money = offer.Amount
    return "Success"
end

local function tryUpdateJailCardsOffer(participant: Types.Participant, currentOffer: Types.TradeOffer, offer: ClientTypes.TradeOfferJailCardsUpdate): ClientTypes.TradeOfferUpdateInvokeResult
    if participant.JailCards < offer.Amount then
        return "NotEnoughJailCards"
    end
    currentOffer.JailCards = offer.Amount
    return "Success"
end

local function tryUpdateAssetOffer(currentOffer: Types.TradeOffer, offer: ClientTypes.TradeOfferAssetUpdate, participant: Types.Participant): ClientTypes.TradeOfferUpdateInvokeResult
    local asset = getAssetByName(participant, offer.Name)
    if not asset then
        return "UnownedAsset"
    end

    if offer.Mode == "Add" then
        if table.find(currentOffer.Assets, asset) then
            return "AssetAlreadyAdded"
        end

        table.insert(currentOffer.Assets, asset)
    elseif offer.Mode == "Remove" then
        local index = table.find(currentOffer.Assets, asset)
        if index then
            table.remove(currentOffer.Assets, index)
        else
            return "AssetAlreadyRemoved"
        end
    end

    return "Success"
end

local function ResetBoth(tradeManager: Types.TradeManager, reason: ClientTypes.TradeResetReason): ()
    assert(tradeManager.Trade, "TradeManager has no trade")

    local otherParticipant = tradeManager:GetOtherParticipant()

    tradeManager.Trade = nil
    otherParticipant.TradeManager.Trade = nil

    FireRemote(tradeRemotes.TradeEnded, tradeManager.Participant, reason)
    FireRemote(tradeRemotes.TradeEnded, otherParticipant, reason)
end

local function TryUpdateOffer(tradeManager: Types.TradeManager, with: string, offer: ClientTypes.TradeOfferUpdate): ClientTypes.TradeOfferUpdateInvokeResult
    if not tradeManager.Trade then
        return "Expired"
    end

    if tradeManager:GetOtherParticipant().Player.Name ~= with then
        return "Expired"
    end

    local participant = tradeManager.Participant

    local currentOffer = tradeManager.Trade.Offers[participant]
    local res: ClientTypes.TradeOfferUpdateInvokeResult
    if offer.Kind == "Money" then
        res = tryUpdateMoneyOffer(participant, currentOffer, offer)
    elseif offer.Kind == "JailCards" then
        res = tryUpdateJailCardsOffer(participant, currentOffer, offer)
    elseif offer.Kind == "Asset" then
        res = tryUpdateAssetOffer(currentOffer, offer, participant)
    else
        return "OtherError"
    end

    if res ~= "Success" then
        return res
    end

    FireRemote(tradeRemotes.ReceiveUpdatedTradeOffer, tradeManager:GetOtherParticipant(), offer)

    return "Success"
end

local function TryConfirmOffer(tradeManager: Types.TradeManager, with: string, confirmed: boolean): ClientTypes.TradeOfferAcceptInvokeResult
    if not tradeManager.Trade then
        return "Expired"
    end

    if tradeManager:GetOtherParticipant().Player.Name ~= with then
        return "Expired"
    end

    tradeManager.Trade.Confirmation[tradeManager.Participant] = confirmed
    FireRemote(tradeRemotes.ReceiveUpdatedTradeAcceptance, tradeManager:GetOtherParticipant(), confirmed)

    if tradeManager.Trade.Confirmation[tradeManager.Participant] and tradeManager.Trade.Confirmation[tradeManager:GetOtherParticipant()] then
        doTrade(tradeManager.Trade)
    end

    return "Success"
end

local function TryRejectOffer(tradeManager: Types.TradeManager, with: string): ClientTypes.TradeOfferRejectInvokeResult
    if not tradeManager.Trade then
        return "Success"
    end

    if tradeManager:GetOtherParticipant().Player.Name ~= with then
        return "Expired"
    end

    tradeManager:ResetBoth("TradeRejected")

    return "Success"
end

local function TryRequestTrade(tradeManager: Types.TradeManager, name: string): ClientTypes.TradeRequestInvokeResult
    if tradeManager.OutgoingTarget then
        return "SelfAlreadyTrading"
    end

    if tradeManager.Trade or tradeManager.OutgoingTarget then
        return "SelfAlreadyTrading"
    end

    local otherPlayer = Players:FindFirstChild(name)
    if not otherPlayer or not otherPlayer:IsA("Player") or not otherPlayer:IsA("Configuration") then
        return "OtherError"
    end

    local otherParticipant = tradeManager.Participant.Round:TryGetParticipant(otherPlayer)
    if not otherParticipant then
        return "OtherError"
    end

    if otherParticipant.TradeManager.Trade then
        return "OtherAlreadyTrading"
    end

    local lastTradeAttempt = tradeManager.LastRequestTimes[otherParticipant]
    if lastTradeAttempt and GetTime() - lastTradeAttempt < TRADE_COOLDOWN then
        return "Cooldown"
    end

    local response: boolean?

    local botPlayer = tradeManager.Participant.Round:GetBotPlayer(tradeManager.Participant)
    if botPlayer then
        if botPlayer:EvaluateTrade() then
            return "BotAcceptedOffer"
        end
        return "BotDeclinedOffer"
    end

    local con: RBXScriptConnection
    con = tradeRemotes.RespondTradeRequest.OnServerEvent:Connect(function(plr: Player, accepted: unknown)
        if plr ~= otherPlayer then
            return
        end

        if typeof(accepted) ~= "boolean" then
            return
        end

        response = accepted
    end)

    FireRemote(tradeRemotes.ReceiveTradeRequest, otherPlayer)

    local startTime = GetTime()
    while response == nil and startTime + TRADE_TIMEOUT > GetTime() do
        task.wait()
    end

    con:Disconnect()

    if response == nil then
        return "Timeout"
    elseif response == false then
        return "Declined"
    end

    return "Success"
end

local function GetOtherParticipant(tradeManager: Types.TradeManager): Types.Participant
    assert(tradeManager.Trade, "TradeManager has no trade")
    return if tradeManager.Trade.Participant1 == tradeManager.Participant then tradeManager.Trade.Participant2 else tradeManager.Trade.Participant1
end

function module.new(participant: Types.Participant): Types.TradeManager
    return {
        Participant = participant,
        LastRequestTimes = {},

        Trade = nil,
        OutgoingTarget = nil,
        
        GetOtherParticipant = GetOtherParticipant,
        ResetBoth = ResetBoth,

        TryRequestTrade = TryRequestTrade,

        TryUpdateOffer = TryUpdateOffer,
        TryConfirmOffer = TryConfirmOffer,
        TryRejectOffer = TryRejectOffer,
    }
end

return module