local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientTypes = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Game.ClientTypes)
local GetTime = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Shared.GetTime)
local SendNotification = require(script.Parent.Parent.Parent.Shared.SendNotification)

local Types = require(script.Parent.Types)
local module = {}

local TRADE_COOLDOWN = 5
local TRADE_TIMEOUT = 10

local tradeRemotes = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Trading")

local function isTradeActive(tradeManager: Types.TradeManager): boolean
    return not not tradeManager.TradingWith
end

local function OfferAsset(tradeManager: Types.TradeManager, assetName: string): ()
    if not isTradeActive(tradeManager) then
        return
    end
    assert(tradeManager.TradingWith)

    local asset: Types.Asset?
    for _, v in tradeManager.Participant.Assets do
        if v.AssetDescription.Name == assetName then
            asset = v
            break
        end
    end

    if not asset then
        return
    end

    local indexToRemove: number?
    for i, v in tradeManager.OfferedAssets do
        if v.AssetDescription.Name == assetName then
            indexToRemove = i
            break
        end
    end

    if indexToRemove then
        table.remove(tradeManager.OfferedAssets, indexToRemove)
    else
        table.insert(tradeManager.OfferedAssets, asset)
    end

    local offer: ClientTypes.TradeOfferUpdate = {
        Kind = "Asset",
        Name = assetName,
        Mode = if indexToRemove then "Remove" else "Add",
    }
    tradeRemotes:WaitForChild("UpdateOffer"):FireClient(tradeManager.Participant.Player, tradeManager.Participant.Player, offer)
    tradeRemotes:WaitForChild("UpdateOffer"):FireClient(tradeManager.TradingWith.Player, tradeManager.Participant.Player, offer)
end

local function OfferMoney(tradeManager: Types.TradeManager, amount: number): ()
    if not isTradeActive(tradeManager) then
        return
    end
    assert(tradeManager.TradingWith)

    amount = math.clamp(amount, 0, tradeManager.Participant.Money)
    tradeManager.OfferedMoney = amount

    local offer: ClientTypes.TradeOfferUpdate = {
        Kind = "Money",
        Amount = tradeManager.OfferedMoney,
    }
    tradeRemotes:WaitForChild("UpdateOffer"):FireClient(tradeManager.Participant.Player, tradeManager.Participant.Player, offer)
    tradeRemotes:WaitForChild("UpdateOffer"):FireClient(tradeManager.TradingWith.Player, tradeManager.Participant.Player, offer)
end

local function OfferJailCards(tradeManager: Types.TradeManager, amount: number): ()
    if not isTradeActive(tradeManager) then
        return
    end
    assert(tradeManager.TradingWith)

    amount = math.clamp(amount, 0, tradeManager.Participant.JailCards)
    tradeManager.OfferedJailCards = amount

    local offer: ClientTypes.TradeOfferUpdate = {
        Kind = "JailCards",
        Amount = tradeManager.OfferedJailCards,
    }
    tradeRemotes:WaitForChild("UpdateOffer"):FireClient(tradeManager.Participant.Player, tradeManager.Participant.Player, offer)
    tradeRemotes:WaitForChild("UpdateOffer"):FireClient(tradeManager.TradingWith.Player, tradeManager.Participant.Player, offer)
end

local function Reset(tradeManager: Types.TradeManager, wasRejectedBy: Player?): ()
    tradeManager.SentOfferTo = nil
    tradeManager.TradingWith = nil

    tradeManager.HasAcceptedProposal = false

    tradeManager.OfferedAssets = {}
    tradeManager.OfferedMoney = 0
    tradeManager.OfferedJailCards = 0

    tradeRemotes:WaitForChild("TradeEnded"):FireClient(tradeManager.Participant.Player, wasRejectedBy)
end

local function finishTradeForParticipant(participant: Types.Participant, to: Types.Participant): ()
    for _, v in participant.TradeManager.OfferedAssets do
        v:TransferTo(to)
    end

    participant:TransferMoneyTo(to, participant.TradeManager.OfferedMoney)
    participant:TransferJailCards(to, participant.TradeManager.OfferedJailCards)
end

local function FinishTrade(tradeManager: Types.TradeManager, accepted: boolean): ()
    if not isTradeActive(tradeManager) then
        return
    end
    assert(tradeManager.TradingWith)

    if accepted then
        SendNotification("[PLAYER] accepted a trade with [PLAYER].", {tradeManager.Participant.Player, tradeManager.TradingWith.Player})
        finishTradeForParticipant(tradeManager.Participant, tradeManager.TradingWith)
        finishTradeForParticipant(tradeManager.TradingWith, tradeManager.Participant)
    end

    Reset(tradeManager.TradingWith.TradeManager, if not accepted then tradeManager.Participant.Player else nil)
    Reset(tradeManager, if not accepted then tradeManager.Participant.Player else nil)
end

local function processUpdatedAcceptance(tradeManager: Types.TradeManager): ()
    if not isTradeActive(tradeManager) then
        return
    end

    assert(tradeManager.TradingWith)

    if tradeManager.TradingWith.TradeManager.HasAcceptedProposal and tradeManager.HasAcceptedProposal then
        return FinishTrade(tradeManager, true)
    end

    tradeRemotes:WaitForChild("TradeAcceptance"):FireClient(tradeManager.Participant.Player, tradeManager.Participant.Player, tradeManager.HasAcceptedProposal)
    tradeRemotes:WaitForChild("TradeAcceptance"):FireClient(tradeManager.TradingWith.Player, tradeManager.Participant.Player, tradeManager.HasAcceptedProposal)
end

local function SetProposalAccepted(tradeManager: Types.TradeManager, accepted: boolean?): ()
    if not isTradeActive(tradeManager) then
        return
    end
    assert(tradeManager.TradingWith)

    if accepted == nil then
        return FinishTrade(tradeManager, false)
    end
    
    tradeManager.HasAcceptedProposal = accepted
    processUpdatedAcceptance(tradeManager)
end

local onRequestResponded: {(tradeManager: Types.TradeManager, accepted: boolean) -> ()} = {}

local function RequestTradeWith(tradeManager: Types.TradeManager, to: Types.Participant): ClientTypes.TradeRequestInvokeResult
    if isTradeActive(tradeManager) or tradeManager.SentOfferTo then
        return "SelfAlreadyTrading"
    end

    if isTradeActive(to.TradeManager) or to.TradeManager.SentOfferTo then
        return "OtherAlreadyTrading"
    end

    if tradeManager.LastTradeRequestTimes[to] and GetTime() - (tradeManager.LastTradeRequestTimes[to] :: number) < TRADE_COOLDOWN then
        return "Cooldown"
    end

    if to.IsGoingBankrupt or tradeManager.Participant.IsGoingBankrupt then
        return "Bankrupt"
    end

    assert(to ~= tradeManager.Participant, "Can't trade with yourself")

    tradeManager.SentOfferTo = to
    to.TradeManager.SentOfferTo = tradeManager.Participant
    tradeRemotes:WaitForChild("ReceiveTradeRequest"):FireClient(to.Player, tradeManager.Participant.Player)

    tradeManager.LastTradeRequestTimes[to] = GetTime()

    local responded: boolean?
    local function onResponded(otherTradeManager: Types.TradeManager, accepted: boolean): ()
        if otherTradeManager == tradeManager then
            responded = accepted
        end
    end

    table.insert(onRequestResponded, onResponded)

    while responded == nil and GetTime() - (tradeManager.LastTradeRequestTimes[to] :: number) < TRADE_TIMEOUT do
        task.wait()
    end

    table.remove(onRequestResponded, table.find(onRequestResponded, onResponded))

    if responded == nil then
        to.TradeManager:RespondRequest(false)
        return "Timeout"
    elseif responded == false then
        return "Declined"
    end

    return "Success"
end

local function processRequestResponse(tradeManager: Types.TradeManager, with: Types.Participant, accepted: boolean): ()
    tradeRemotes:WaitForChild("RespondedTradeRequest"):FireClient(with.Player, tradeManager.Participant.Player, accepted)

    tradeManager.TradingWith = if accepted then with else nil
    tradeManager.SentOfferTo = nil
end

local function RespondRequest(tradeManager: Types.TradeManager, accepted: boolean): ()
    local sentTo = tradeManager.SentOfferTo
    if not sentTo then
        return
    end

    if (isTradeActive(tradeManager) or isTradeActive(sentTo.TradeManager)) and accepted then
        return RespondRequest(tradeManager, false)
    end

    processRequestResponse(sentTo.TradeManager, tradeManager.Participant, accepted)
    processRequestResponse(tradeManager, sentTo, accepted)

    for _, v in onRequestResponded do
        v(tradeManager, accepted)
    end
end

local function UpdateOffer(tradeManager: Types.TradeManager, offer: ClientTypes.TradeOfferUpdate): ()
    if not isTradeActive(tradeManager) then
        return
    end
    assert(tradeManager.TradingWith)

    if offer.Kind == "Money" then
        OfferMoney(tradeManager, offer.Amount)
    elseif offer.Kind == "Asset" then
        OfferAsset(tradeManager, offer.Name)
    elseif offer.Kind == "JailCards" then
        OfferJailCards(tradeManager, offer.Amount)
    else
        error("Invalid trade offer kind")
    end

    tradeManager:SetProposalAccepted(false)
    tradeManager.TradingWith.TradeManager:SetProposalAccepted(false)
end

function module.new(participant: Types.Participant): Types.TradeManager
    local tradeManager = {}

    tradeManager.Participant = participant

    tradeManager.HasAcceptedProposal = false

    tradeManager.OfferedAssets = {}
    tradeManager.OfferedMoney = 0
    tradeManager.OfferedJailCards = 0

    tradeManager.UpdateOffer = UpdateOffer

    tradeManager.OfferAsset = OfferAsset
    tradeManager.OfferMoney = OfferMoney
    tradeManager.OfferJailCards = OfferJailCards

    tradeManager.SetProposalAccepted = SetProposalAccepted
    tradeManager.FinishTrade = FinishTrade

    tradeManager.RequestTradeWith = RequestTradeWith
    tradeManager.RespondRequest = RespondRequest

    tradeManager.LastTradeRequestTimes = {}

    tradeManager.Reset = Reset

    return tradeManager
end

return module