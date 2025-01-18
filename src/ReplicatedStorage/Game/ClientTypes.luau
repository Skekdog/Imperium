export type ClientAssetView = {
    Name: string,
    Colour: Color3,
    Position: number,

    MortgageValue: number?,
    UnMortgageCost: number?,
    
    HousePrice: number?,
    HotelPrice: number?,

    SellAllValue: number?,
    SellHotelValue: number?,
    SellHouseValue: number?,
}

export type TradeOfferJailCardsUpdate = {
    Kind: "JailCards",
    Amount: number,
}

export type TradeOfferMoneyUpdate = {
    Kind: "Money",
    Amount: number,
}

export type TradeOfferAssetUpdate = {
    Kind: "Asset",
    Name: string,
    Mode: "Add" | "Remove",
}

export type InitialTradeOffer = {
    OurOffer: {
        Money: number,
        JailCards: number,
        Assets: {string},
    },
    TheirOffer: {
        Money: number,
        JailCards: number,
        Assets: {string},
    }
}

export type TradeOfferUpdate = TradeOfferJailCardsUpdate | TradeOfferMoneyUpdate | TradeOfferAssetUpdate

export type TradeRequestInvokeResult = "Success" | "Cooldown"
                                    | "SelfAlreadyTrading" | "OtherAlreadyTrading" | "Timeout" | "Declined" | "Bankrupt" | "Disconnected"
                                    | "BotDeclinedOffer" | "BotAcceptedOffer" | "OtherError" | "SelfUnownedAsset" | "OtherUnownedAsset"
                                    | "SelfNotEnoughMoney" | "OtherNotEnoughMoney" | "SelfNotEnoughJailCards" | "OtherNotEnoughJailCards"
                                    | "ValueBelowZero"

export type TradeRequestAcceptInvokeResult = "Success" | "Expired" | "OtherError"

export type TradeOfferUpdateInvokeResult = "Success" | "Expired" | "NotEnoughMoney" | "NotEnoughJailCards" | "ValueBelowZero"
                                    | "UnownedAsset" | "AssetAlreadyAdded" | "AssetAlreadyRemoved" | "OtherError"

export type TradeOfferAcceptInvokeResult = "Success" | "Expired" | "OtherError"

export type TradeOfferRejectInvokeResult = "Success" | "Expired" | "OtherError"

export type TradeResetReason = "TradeAccepted" | "TradeRejected" | "GoingBankrupt" | "Disconnected" | "BotDeclinedOffer"

return {}