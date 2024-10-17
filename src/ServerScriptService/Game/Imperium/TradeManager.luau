local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(script.Parent.Types)
local module = {}

local bidirectional = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Bidirectional")

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
    tradeManager.TradingWith = nil
    tradeManager.HasAcceptedTrade = false
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

local function SetTradeAccepted(tradeManager: Types.TradeManager, accepted: boolean): ()
    if not isTradeActive(tradeManager) then
        return
    end
    assert(tradeManager.TradingWith)
    
    tradeManager.HasAcceptedTrade = accepted

    if tradeManager.TradingWith.TradeManager.HasAcceptedTrade and accepted then
        FinishTrade(tradeManager, true)
    end
end

local function DeclineTrade(tradeManager: Types.TradeManager): ()
    if not isTradeActive(tradeManager) then
        return
    end
    
    FinishTrade(tradeManager, false)
end

local function SendTradeOffer(tradeManager: Types.TradeManager, to: Types.Participant): ()
    if isTradeActive(tradeManager) or tradeManager.SentOfferTo then
        return
    end

    tradeManager.SentOfferTo = to
    to.TradeManager.SentOfferTo = tradeManager.Participant
    bidirectional:WaitForChild("TradeRequest"):FireClient(to.Player, tradeManager.Participant.Player)
end

local function processResponse(tradeManager: Types.TradeManager, with: Types.Participant, accepted: boolean): ()
    if accepted then
        bidirectional:WaitForChild("BeginTrading"):FireClient(with.Player, tradeManager.Participant.Player)
    end

    tradeManager.TradingWith = if accepted then with else nil
    tradeManager.SentOfferTo = nil
end

local function RespondTradeOffer(tradeManager: Types.TradeManager, accepted: boolean): ()
    if isTradeActive(tradeManager) and accepted then
        return RespondTradeOffer(tradeManager, false)
    end

    if not tradeManager.SentOfferTo then
        return
    end

    processResponse(tradeManager.SentOfferTo.TradeManager, tradeManager.Participant, accepted)
    processResponse(tradeManager, tradeManager.SentOfferTo, accepted)
end

function module.new(participant: Types.Participant): Types.TradeManager
    local tradeManager = {}

    tradeManager.Participant = participant
    tradeManager.SentOfferTo = nil
    tradeManager.TradingWith = nil
    tradeManager.HasAcceptedTrade = false
    tradeManager.OfferedAssets = {}
    tradeManager.OfferedMoney = 0
    tradeManager.OfferedJailCards = 0

    tradeManager.OfferAsset = OfferAsset
    tradeManager.OfferMoney = OfferMoney
    tradeManager.OfferJailCards = OfferJailCards
    tradeManager.Reset = Reset
    tradeManager.FinishTrade = FinishTrade
    tradeManager.SetTradeAccepted = SetTradeAccepted
    tradeManager.DeclineTrade = DeclineTrade
    tradeManager.SendTradeOffer = SendTradeOffer
    tradeManager.RespondTradeOffer = RespondTradeOffer

    return tradeManager
end

return module