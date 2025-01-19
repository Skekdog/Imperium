local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientTypes = require(ReplicatedStorage.Game.ClientTypes)
local IsTradeValid = require(ReplicatedStorage.Game.IsTradeValid)
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

local function tradeToClientTrade(tradeManager: Types.TradeManager): {
    TradeOffer: ClientTypes.InitialTradeOffer,
    OurAssets: {string},
    TheirAssets: {string},
}
    assert(tradeManager.Trade, "TradeManager has no trade")

    local ourParticipant = tradeManager.Participant
    local otherParticipant = tradeManager:GetOtherParticipant()

    local ourOffer = tradeManager.Trade.Offers[ourParticipant]
    local theirOffer = tradeManager.Trade.Offers[otherParticipant]

    local ourAssets: {string} = {}
    for _, asset in ourOffer.Assets do
        table.insert(ourAssets, asset.AssetDescription.Name)
    end

    local theirAssets: {string} = {}
    for _, asset in theirOffer.Assets do
        table.insert(theirAssets, asset.AssetDescription.Name)
    end

    return {
            TradeOffer = {
                OurOffer = {
                    Money = ourOffer.Money,
                    JailCards = ourOffer.JailCards,
                    Assets = ourAssets,
                },
                TheirOffer = {
                    Money = theirOffer.Money,
                    JailCards = theirOffer.JailCards,
                    Assets = theirAssets,
                }
            },
            OurAssets = ourAssets,
            TheirAssets = theirAssets,
        }
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

    if offer.Amount < 0 then
        return "MoneyBelowZero"
    end

    currentOffer.Money = offer.Amount
    return "Success"
end

local function tryUpdateJailCardsOffer(participant: Types.Participant, currentOffer: Types.TradeOffer, offer: ClientTypes.TradeOfferJailCardsUpdate): ClientTypes.TradeOfferUpdateInvokeResult
    if participant.JailCards < offer.Amount then
        return "NotEnoughJailCards"
    end

    if offer.Amount < 0 then
        return "JailCardsBelowZero"
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

    if reason ~= "BotDeclinedOffer" then
        FireRemote(tradeRemotes.TradeEnded, tradeManager.Participant, otherParticipant.Player.Name, reason)
        FireRemote(tradeRemotes.TradeEnded, otherParticipant, tradeManager.Participant.Player.Name, reason)
    end
end

local function IsTradeOfferValid(tradeManager: Types.TradeManager): ClientTypes.TradeValidationResult
    assert(tradeManager.Trade, "TradeManager has no trade")

    local participant = tradeManager.Participant
    local otherParticipant = tradeManager:GetOtherParticipant()

    local res = tradeToClientTrade(tradeManager)

    local ourView = {
        Money = participant.Money,
        JailCards = participant.JailCards,
        Assets = res.OurAssets,
    }

    local theirView = {
        Money = otherParticipant.Money,
        JailCards = otherParticipant.JailCards,
        Assets = res.TheirAssets,
    }

    return require(ReplicatedStorage.Game.IsTradeValid).IsTradeValid(res.TradeOffer, ourView, theirView)
end

local function TryUpdateOffer(tradeManager: Types.TradeManager, with: string, offer: ClientTypes.TradeOfferUpdate): ClientTypes.TradeOfferUpdateInvokeResult
    if not tradeManager.Trade then
        return "Expired"
    end

    local otherParticipant = tradeManager:GetOtherParticipant()
    if otherParticipant.Player.Name ~= with then
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

    tradeManager:TryConfirmOffer(otherParticipant.Player.Name, false)
    otherParticipant.TradeManager:TryConfirmOffer(participant.Player.Name, false)

    FireRemote(tradeRemotes.ReceiveUpdatedTradeOffer, otherParticipant, participant.Player.Name, offer)

    return "Success"
end

local function TryConfirmOffer(tradeManager: Types.TradeManager, with: string, confirmed: boolean): ClientTypes.TradeOfferAcceptInvokeResult
    if not tradeManager.Trade then
        return "Expired"
    end

    if tradeManager:GetOtherParticipant().Player.Name ~= with then
        return "Expired"
    end

    if confirmed == tradeManager.Trade.Confirmation[tradeManager.Participant] then
        return "Success"
    end

    tradeManager.Trade.Confirmation[tradeManager.Participant] = confirmed
    FireRemote(tradeRemotes.ReceiveUpdatedTradeAcceptance, tradeManager:GetOtherParticipant(), tradeManager.Participant.Player.Name, confirmed)

    

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

local function reverseInitialOffer(initialOffer: ClientTypes.InitialTradeOffer): ClientTypes.InitialTradeOffer
    return {
        OurOffer = initialOffer.TheirOffer,
        TheirOffer = initialOffer.OurOffer,
    }
end

local function createOffersFromInitialOffer(ourParticipant: Types.Participant, theirParticipant: Types.Participant, initialOffer: ClientTypes.InitialTradeOffer): {
    Success: true,
    OurOffer: Types.TradeOffer,
    TheirOffer: Types.TradeOffer,
} | {
    Success: false,
    Reason: ClientTypes.TradeRequestInvokeResult,
}
    local isValid: ClientTypes.TradeValidationResult = IsTradeValid.IsTradeValid(initialOffer, ourParticipant, theirParticipant)
    if isValid ~= "Success" then
        return {
            Success = false,
            Reason = isValid,
        }
    end

    local ourAssets: {Types.Asset} = {}
    for _, assetName in initialOffer.OurOffer.Assets do
        local asset = getAssetByName(ourParticipant, assetName)
        assert(asset, "Asset not found")
        table.insert(ourAssets, asset)
    end

    local theirAssets: {Types.Asset} = {}
    for _, assetName in initialOffer.TheirOffer.Assets do
        local asset = getAssetByName(theirParticipant, assetName)
        assert(asset, "Asset not found")
        table.insert(theirAssets, asset)
    end

    local ourOffer: Types.TradeOffer = {
        Money = initialOffer.OurOffer.Money,
        JailCards = initialOffer.OurOffer.JailCards,
        Assets = ourAssets,
    }

    local theirOffer: Types.TradeOffer = {
        Money = initialOffer.TheirOffer.Money,
        JailCards = initialOffer.TheirOffer.JailCards,
        Assets = theirAssets,
    }

    return {
        Success = true,
        OurOffer = ourOffer,
        TheirOffer = theirOffer,
    }
end

local function TryRequestTrade(tradeManager: Types.TradeManager, name: string, initialOffer: ClientTypes.InitialTradeOffer): ClientTypes.TradeRequestInvokeResult
    if tradeManager.Trade then
        return "SelfAlreadyTrading"
    end

    local otherPlayer = Players:FindFirstChild(name)
    if not otherPlayer or (not otherPlayer:IsA("Player") and not otherPlayer:IsA("Configuration")) then
        return "OtherError"
    end

    local otherParticipant = tradeManager.Participant.Round:TryGetParticipant(otherPlayer :: Player)
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

    local offerResult = createOffersFromInitialOffer(tradeManager.Participant, otherParticipant, initialOffer)
    if not offerResult.Success then
        return offerResult.Reason
    end

    tradeManager.LastRequestTimes[otherParticipant] = GetTime()

    tradeManager.Trade = {
        Participant1 = tradeManager.Participant,
        Participant2 = otherParticipant,
        Confirmation = {
            [tradeManager.Participant] = false,
            [otherParticipant] = false,
        },
        Offers = {
            [tradeManager.Participant] = offerResult.OurOffer,
            [otherParticipant] = offerResult.TheirOffer,
        }
    }

    otherParticipant.TradeManager.Trade = tradeManager.Trade

    local response: boolean?

    local botPlayer = tradeManager.Participant.Round:GetBotPlayer(otherParticipant)
    if botPlayer then
        if botPlayer:EvaluateTrade(otherParticipant.TradeManager) then
            doTrade(assert(tradeManager.Trade))
            return "BotAcceptedOffer"
        end
        tradeManager:ResetBoth("TradeRejected")
        return "BotDeclinedOffer"
    end

    local con: RBXScriptConnection
    con = tradeRemotes.RespondTradeRequest.OnServerEvent:Connect(function(plr: Player, trader: string, accepted: unknown)
        if plr ~= otherPlayer or trader ~= tradeManager.Participant.Player.Name then
            return
        end

        if typeof(accepted) ~= "boolean" then
            return
        end

        response = accepted
    end)

    FireRemote(tradeRemotes.ReceiveTradeRequest, otherParticipant, tradeManager.Participant.Player.Name, reverseInitialOffer(initialOffer))

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
        
        GetOtherParticipant = GetOtherParticipant,
        ResetBoth = ResetBoth,

        IsTradeOfferValid = IsTradeOfferValid,
        TryRequestTrade = TryRequestTrade,

        TryUpdateOffer = TryUpdateOffer,
        TryConfirmOffer = TryConfirmOffer,
        TryRejectOffer = TryRejectOffer,
    }
end

return module