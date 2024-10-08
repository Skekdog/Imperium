local ServerStorage = game:GetService("ServerStorage")
local ClientTypes = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Game.ClientTypes)
type Turn = number
export type AssetOwner = Participant | "Bank"
export type DiceRollResult = {
    Result: number,
    IsDoubles: boolean,
}

export type BoardConfiguration = {
    Name: string,
    Tiles: {TileDescription},
    Colours: {[string]: Color3, Default: Color3},

    CurrencySymbol: string,

    HousePrices: {[string]: number},

    StartingJailCards: number,
    StartingMoney: number,
    PassGoMoney: number,

    JailFine: number,
    JailLength: number,
    DoublesConsecutiveJailAmount: number,

    CanLeaveJailByRollingDoubles: boolean,
    AllowJailedRentCollection: boolean,
    AllowJailedTrading: boolean,

    FreeParkingBonusEnabled: boolean,
    FreeParkingBonusInitial: number,
}

export type GameConfiguration = {
    AuctionTime: number,
    PlayerTurnTime: number,
    BankruptcyTime: number,
}

export type AssetDescription = {
    Name: string,
    Colour: string,
    Icon: string?,
    Price: number,
    RentDescription: {{string}},
    Rent: ((Asset, Participant) -> number) | {
        Default: number,
        Houses: {[number]: number?},
        Hotels: {[number]: number?},
    }
}

export type TileDescription = {
    Name: string?,
    Colour: string?,
    Icon: string?,
    AssetDescription: AssetDescription?,
    OnEnter: ((TileDescription, Participant) -> ())?,
}

export type CardType = "Chance" | "Community Chest"
export type CardModel = typeof(ServerStorage.Game["Chance Card"]) -- Intersection type causes typechecker fuckyness so only use ChanceCard. They're the same structure anyway
export type CardDescription = {
    Title: string,
    Effect: (Participant) -> (),
}

export type ClientAssetView = ClientTypes.ClientAssetView
export type Asset = {
    AssetDescription: AssetDescription,

    IsMortgaged: boolean,
    Owner: AssetOwner,
    Houses: number,
    Hotels: number,

    TransferTo: (Asset, to: AssetOwner) -> (),
    StartAuction: (Asset, round: Round, transferToBankIfNoWinner: boolean?) -> (),
    
    TryMortgage: (Asset) -> (),
    TryUnMortgage: (Asset) -> (),

    GetMortgageValue: (Asset) -> number,
    GetUnMortgageCost: (Asset) -> number,

    TryGetDevelopmentCost: (Asset, development: "House" | "Hotel", boardConfiguration: BoardConfiguration) -> number?,
    TryGetDevelopmentSellValue: (Asset, development: "House" | "Hotel", boardConfiguration: BoardConfiguration) -> number?,
    TryDevelopProperty: (Asset, development: "House" | "Hotel") -> (),
    TrySellDevelopment: (Asset) -> (),
    TrySellAllDevelopments: (Asset) -> (),
    CanMakeDevelopment: (Asset, development: "House" | "Hotel") -> (boolean, number),

    GetRentCost: (Asset, participant: Participant) -> number,

    GetClientAssetView: (Asset, round: Round) -> ClientAssetView,

    HasAnyDevelopments: (Asset) -> boolean,
}

export type EdgeTile = typeof(ServerStorage.Game.Tile)
export type CornerTile = typeof(ServerStorage.Game.CornerTile)
export type JailTile = typeof(ServerStorage.Game.JailTile)
export type TileModel = EdgeTile | CornerTile | JailTile

export type Tile = {
    TileDescription: TileDescription,
    Position: number,
    Model: TileModel,
    Asset: Asset?,
}

export type TradeManager = {
    Participant: Participant,
    TradingWith: Participant?,

    HasAcceptedTrade: boolean,
    OfferedAssets: {Asset},
    OfferedMoney: number,
    OfferedJailCards: number,

    OfferAsset: (TradeManager, assetName: string) -> (),
    OfferMoney: (TradeManager, amount: number) -> (),
    OfferJailCards: (TradeManager, amount: number) -> (),

    SetTradeAccepted: (TradeManager, accepted: boolean) -> (),
    DeclineTrade: (TradeManager) -> (),

    Reset: (TradeManager) -> (),
    FinishTrade: (TradeManager, accepted: boolean) -> (),

    SendTradeOffer: (TradeManager, to: Participant) -> (),
    RespondTradeOffer: (TradeManager, accepted: boolean) -> (),
}

export type Participant = {
    Player: Player,
    Round: Round,
    Board: Board,
    IsInGame: boolean,
    HasDisconnected: boolean,

    Money: number,
    JailCards: number,
    Assets: {Asset},
    
    TradeManager: TradeManager,

    IsMoving: boolean,
    PreviousPosition: number,
    Position: number,

    ValidPropertyPurchaseTurn: number?,
    
    JailedOn: number,
    DoublesStreak: number,
    LastRoll: DiceRollResult,

    RollDice: (Participant) -> DiceRollResult,
    CanPlayMove: (Participant, move: "Dice" | "JailCard" | "Fine") -> boolean,
    TryPlayMove: (Participant) -> (),
    TryUseJailCard: (Participant) -> (),
    TryPayFine: (Participant) -> (),

    MoveToTileByName: (Participant, name: string, moveDirectly: boolean?) -> (),
    MoveTo: (Participant, position: number, moveDirectly: boolean?, initialMove: boolean?, noRentPayment: boolean?) -> (),
    MoveBy: (Participant, amount: number, moveDirectly: boolean?) -> (),

    SendToJail: (Participant) -> (),
    LeaveJail: (Participant, skipTurn: boolean?) -> (),

    FindClosestForwardPositionByColour: (Participant, colour: string) -> number?,

    TryPayRent: (Participant, Tile) -> (),

    GiveJailCards: (Participant, amount: number) -> (),
    GiveMoney: (Participant, amount: number) -> (),

    TransferMoneyTo: (Participant, to: AssetOwner, amount: number, noNotification: boolean?) -> (),
    TransferJailCards: (Participant, to: AssetOwner, amount: number) -> (),

    DrawCard: (Participant, card: CardDescription, cardType: CardType) -> (),

    PurchaseProperty: (Participant, asset: Asset) -> (),
    PromptPurchaseProperty: (Participant, asset: Asset) -> (),

    BankruptcyWarning: (Participant, targetAmount: number, to: AssetOwner) -> (),
    GoBankrupt: (Participant, to: AssetOwner) -> (),

    GetTheDub: (Participant) -> (),

    HasMonopoly: (Participant, colour: string) -> boolean,
    CanAfford: (Participant, amount: number) -> boolean,

    RemoveParticipant: (Participant) -> (),
}

export type Board = {
    Tiles: {Tile},

    TryFindTileByName: (Board, name: string) -> Tile?,
    FindTileByName: (Board, name: string) -> Tile,

    GetAllAssetsInColourGroup: (Board, colourGroup: string) -> {Asset},
}

export type Round = {
    BoardConfiguration: BoardConfiguration,
    GameConfiguration: GameConfiguration,

    Board: Board,
    Started: boolean,
    Turn: Turn,
   
    Participants: {Participant},
    CurrentParticipant: Participant?,

    StartRound: (Round) -> (),
    TryGetParticipant: (Round, player: Player) -> Participant?,
    StartNextParticipantTurn: (Round, participant: Participant?) -> (),
    SetNextParticipant: (Round) -> (),
}

return {}