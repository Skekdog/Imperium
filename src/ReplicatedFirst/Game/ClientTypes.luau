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

type TradeOfferJailCardsUpdate = {
    Kind: "JailCards",
    Amount: number,
}

type TradeOfferMoneyUpdate = {
    Kind: "Money",
    Amount: number,
}

type TradeOfferAssetUpdate = {
    Kind: "Asset",
    Name: string,
    Mode: "Add" | "Remove",
}

export type TradeOfferUpdate = TradeOfferJailCardsUpdate | TradeOfferMoneyUpdate | TradeOfferAssetUpdate

export type TradeRequestInvokeResult = "Success" | "Cooldown" | "SelfAlreadyTrading" | "OtherAlreadyTrading" | "Timeout" | "Declined"?

return {}