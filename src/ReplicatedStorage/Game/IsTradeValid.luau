local ClientTypes = require(script.Parent.ClientTypes)

type Asset = string | {AssetDescription: {Name: string, [any]: any}, [any]: any}

export type ParticipantView = {
	Money: number,
	JailCards: number,
	Assets: {Asset},
}

local module = {}

function module.IsJailCardOfferValid(participant: ParticipantView, offer: ClientTypes.InitialTradeOffer, isOwn: boolean): ClientTypes.TradeValidationResult
	local offerToConsider = if isOwn then offer.OurOffer else offer.TheirOffer
	if participant.JailCards < offerToConsider.JailCards then
        return if isOwn then "SelfNotEnoughJailCards" else "OtherNotEnoughJailCards"
    end

    if offerToConsider.JailCards < 0 then
        return if isOwn then "SelfJailCardsBelowZero" else "OtherJailCardsBelowZero"
    end

	return "Success"
end

function module.IsMoneyOfferValid(participant: ParticipantView, offer: ClientTypes.InitialTradeOffer, isOwn: boolean): ClientTypes.TradeValidationResult
	local offerToConsider = if isOwn then offer.OurOffer else offer.TheirOffer
	if participant.Money < offerToConsider.Money then
		return if isOwn then "SelfNotEnoughMoney" else "OtherNotEnoughMoney"
	end

	if offerToConsider.Money < 0 then
		return if isOwn then "SelfMoneyBelowZero" else "OtherMoneyBelowZero"
	end

	return "Success"
end

function module.IsAssetOfferValid(participant: ParticipantView, offer: ClientTypes.InitialTradeOffer, isOwn: boolean): ClientTypes.TradeValidationResult
	local offerToConsider = if isOwn then offer.OurOffer else offer.TheirOffer
	for _, asset in (offerToConsider.Assets :: {string}) do
		local found = false
		for _, asset2 in participant.Assets do
			if asset == (if typeof(asset2) == "string" then asset2 else asset2.AssetDescription.Name) then
				found = true
				break
			end
		end
		if not found then
			return if isOwn then "SelfUnownedAsset" else "OtherUnownedAsset"
		end
	end

	return "Success"
end

function module.IsTradeValid(trade: ClientTypes.InitialTradeOffer, ourParticipant: ParticipantView, otherParticipant: ParticipantView): ClientTypes.TradeValidationResult
	local selfMoneyValid: ClientTypes.TradeValidationResult = module.IsMoneyOfferValid(ourParticipant, trade, true)
	if selfMoneyValid ~= "Success" then
		return selfMoneyValid
	end

	local otherMoneyValid: ClientTypes.TradeValidationResult = module.IsMoneyOfferValid(otherParticipant, trade, false)
	if otherMoneyValid ~= "Success" then
		return otherMoneyValid
	end

	local selfJailCardsValid: ClientTypes.TradeValidationResult = module.IsJailCardOfferValid(ourParticipant, trade, true)
	if selfJailCardsValid ~= "Success" then
		return selfJailCardsValid
	end

	local otherJailCardsValid: ClientTypes.TradeValidationResult = module.IsJailCardOfferValid(otherParticipant, trade, false)
	if otherJailCardsValid ~= "Success" then
		return otherJailCardsValid
	end

	local selfAssetValid: ClientTypes.TradeValidationResult = module.IsAssetOfferValid(ourParticipant, trade, true)
	if selfAssetValid ~= "Success" then
		return selfAssetValid
	end

	local otherAssetValid: ClientTypes.TradeValidationResult = module.IsAssetOfferValid(otherParticipant, trade, false)
	if otherAssetValid ~= "Success" then
		return otherAssetValid
	end

    return "Success"
end

return module