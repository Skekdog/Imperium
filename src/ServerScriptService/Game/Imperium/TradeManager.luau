local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Parent.Types)
local module = {}

local tradeRemotes = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Trading")

local function isTradeActive(tradeManager: Types.TradeManager): boolean
    return not not tradeManager.TradingWith
end

local function OfferAsset(tradeManager: Types.TradeManager, assetName: string): ()
    if not isTradeActive(tradeManager) then
        return
    end

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

    for _, v in tradeManager.OfferedAssets do
        if v.AssetDescription.Name == assetName then
            return
        end
    end

    table.insert(tradeManager.OfferedAssets, asset)
end

local function OfferMoney(tradeManager: Types.TradeManager, amount: number): ()
    if not isTradeActive(tradeManager) then
        return
    end

    amount = math.clamp(amount, 0, tradeManager.Participant.Money)
    tradeManager.OfferedMoney = amount
end

local function OfferJailCards(tradeManager: Types.TradeManager, amount: number): ()
    if not isTradeActive(tradeManager) then
        return
    end

    amount = math.clamp(amount, 0, tradeManager.Participant.JailCards)
    tradeManager.OfferedJailCards = amount
end

local function Reset(tradeManager: Types.TradeManager): ()
    tradeManager.SentOfferTo = nil
    tradeManager.TradingWith = nil

    tradeManager.HasAcceptedProposal = false

    tradeManager.OfferedAssets = {}
    tradeManager.OfferedMoney = 0
    tradeManager.OfferedJailCards = 0
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
        finishTradeForParticipant(tradeManager.Participant, tradeManager.TradingWith)
        finishTradeForParticipant(tradeManager.TradingWith, tradeManager.Participant)
    end

    Reset(tradeManager.TradingWith.TradeManager)
    Reset(tradeManager)
end

local function SetProposalAccepted(tradeManager: Types.TradeManager, accepted: boolean): ()
    if not isTradeActive(tradeManager) then
        return
    end
    assert(tradeManager.TradingWith)
    
    tradeManager.HasAcceptedProposal = accepted

    if tradeManager.TradingWith.TradeManager.HasAcceptedProposal and accepted then
        FinishTrade(tradeManager, true)
    end
end

local function RequestTradeWith(tradeManager: Types.TradeManager, to: Types.Participant): ()
    if isTradeActive(tradeManager) or tradeManager.SentOfferTo then
        return
    end

    tradeManager.SentOfferTo = to
    to.TradeManager.SentOfferTo = tradeManager.Participant
    tradeRemotes:WaitForChild("RequestTrade"):FireClient(to.Player, tradeManager.Participant.Player)
end

local function processRequestResponse(tradeManager: Types.TradeManager, with: Types.Participant, accepted: boolean): ()
    if accepted then
        tradeRemotes:WaitForChild("RespondedTradeRequest"):FireClient(with.Player, tradeManager.Participant.Player)
    end

    tradeManager.TradingWith = if accepted then with else nil
    tradeManager.SentOfferTo = nil
end

local function RespondRequest(tradeManager: Types.TradeManager, accepted: boolean): ()
    if isTradeActive(tradeManager) and accepted then
        return RespondRequest(tradeManager, false)
    end

    local sentTo = tradeManager.SentOfferTo
    if not sentTo then
        return
    end

    processRequestResponse(sentTo.TradeManager, tradeManager.Participant, accepted)
    processRequestResponse(tradeManager, sentTo, accepted)
end

function module.new(participant: Types.Participant): Types.TradeManager
    local tradeManager = {}

    tradeManager.Participant = participant

    tradeManager.HasAcceptedProposal = false

    tradeManager.OfferedAssets = {}
    tradeManager.OfferedMoney = 0
    tradeManager.OfferedJailCards = 0

    tradeManager.OfferAsset = OfferAsset
    tradeManager.OfferMoney = OfferMoney
    tradeManager.OfferJailCards = OfferJailCards

    tradeManager.SetProposalAccepted = SetProposalAccepted
    tradeManager.FinishTrade = FinishTrade

    tradeManager.RequestTradeWith = RequestTradeWith
    tradeManager.RespondRequest = RespondRequest

    tradeManager.Reset = Reset

    return tradeManager
end

return module