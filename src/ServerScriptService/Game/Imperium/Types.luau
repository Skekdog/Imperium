local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ClientTypes = require(ReplicatedStorage.Game.ClientTypes)

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
    StartingMoney: number,
    FreeParkingBonusEnabled: boolean,
    BotPlayers: {string},
    HumanPlayerCount: number,
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
    TextDescription: string?,
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
    CanUnmakeDevelopment: (Asset, development: "House" | "Hotel") -> boolean,

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

export type TradeOffer = {
    Assets: {Asset},
    Money: number,
    JailCards: number,
}

export type Trade = {
    Participant1: Participant,
    Participant2: Participant,

    Offers: {[Participant]: TradeOffer}, -- username: tradeoffer
    Confirmation: {[Participant]: boolean}, -- username: has accepted
}

export type TradeManager = {
    Participant: Participant,

    OutgoingTarget: Participant?,
    LastRequestTimes: {[Participant]: number?},
    
    Trade: Trade?,

    GetOtherParticipant: (TradeManager) -> Participant,
    ResetBoth: (TradeManager, reason: ClientTypes.TradeResetReason) -> (),

    TryRequestTrade: (TradeManager, name: string, initialOffer: ClientTypes.InitialTradeOffer) -> ClientTypes.TradeRequestInvokeResult,

    TryUpdateOffer: (TradeManager, with: string, offer: ClientTypes.TradeOfferUpdate) -> ClientTypes.TradeOfferUpdateInvokeResult,
    TryConfirmOffer: (TradeManager, with: string, confirmed: boolean) -> ClientTypes.TradeOfferAcceptInvokeResult,
    TryRejectOffer: (TradeManager, with: string) -> ClientTypes.TradeOfferRejectInvokeResult,
}

export type Participant = {
    Player: Player | Configuration,
    Character: Model?,
    
    Round: Round,
    Board: Board,
    IsInGame: boolean,
    HasDisconnected: boolean,

    IsGoingBankrupt: boolean,

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

    RollDice: (Participant) -> DiceRollResult,
    CanPlayMove: (Participant, move: "Dice" | "JailCard" | "Fine") -> boolean,
    TryPlayMove: (Participant) -> (),
    TryUseJailCard: (Participant) -> (),
    TryPayFine: (Participant) -> (),

    MoveToTileByName: (Participant, name: string, moveDirectly: boolean?) -> (),
    MoveTo: (Participant, position: number, moveDirectly: boolean?, initialMove: boolean?, noRentPayment: boolean?) -> (),
    MoveBy: (Participant, amount: number, moveDirectly: boolean?) -> (),

    SendToJail: (Participant) -> (),
    LeaveJail: (Participant) -> (),

    FindClosestForwardPositionByColour: (Participant, colour: string) -> number?,

    TryPayRent: (Participant, Tile) -> (),

    GiveJailCards: (Participant, amount: number) -> (),
    GiveMoney: (Participant, amount: number) -> (),

    TransferMoneyTo: (Participant, to: AssetOwner | "FreeParking", amount: number, noNotification: boolean?) -> (),
    TransferJailCards: (Participant, to: AssetOwner, amount: number) -> (),

    DrawCard: (Participant, card: CardDescription, cardType: CardType) -> (),

    PurchaseProperty: (Participant, asset: Asset) -> (),
    PromptPurchaseProperty: (Participant, asset: Asset) -> (),

    BankruptcyWarning: (Participant, targetAmount: number, to: AssetOwner) -> (),
    GoBankrupt: (Participant, to: AssetOwner) -> (),

    GetTheDub: (Participant) -> (),

    HasMonopoly: (Participant, colour: string) -> boolean,
    CanAfford: (Participant, amount: number) -> boolean,

    TryReceiveFreeParkingMoney: (Participant) -> (),

    RemoveParticipant: (Participant, doNotStartNextTurn: boolean?) -> (),
}

export type BotPlayer = {
    Participant: Participant,
    Player: Configuration,
    Model: Model,

    MinimumMoneyForDeveloping: number,
    MinimumMoneyForUnmortgaging: number,

    FinishTurn: (BotPlayer) -> (),

    GetAuctionBid: (BotPlayer, Asset, currentBid: number, currentWinner: Participant?) -> number?,

    EvaluateAssetForSale: (BotPlayer, Asset, to: Participant) -> number,
    EvaluateAssetForPurchase: (BotPlayer, Asset, from: AssetOwner) -> number,

    EvaluateSkipJail: (BotPlayer) -> boolean,
    EvaluateTrade: (BotPlayer, TradeManager) -> boolean,

    DecideMove: (BotPlayer) -> "Dice" | "JailCard" | "Fine",
    DecidePurchase: (BotPlayer, Asset) -> boolean,

    TryBuildDevelopments: (BotPlayer) -> (),
    TryUnmortgageAssets: (BotPlayer) -> (),

    TryAvoidBankruptcy: (BotPlayer, requiredMoney: number) -> (),
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

    IsPaused: boolean,

    Board: Board,
    Started: boolean,
    Turn: Turn,

    _freeParkingMoney: number,
    SetFreeParkingMoney: (Round, amount: number) -> (),
    GetFreeParkingMoney: (Round) -> number,
   
    Participants: {Participant},
    CurrentParticipant: Participant?,

    BotPlayers: {[Participant]: BotPlayer?},
    GetBotPlayer: (Round, participant: Participant) -> BotPlayer?,

    StartRound: (Round) -> (),
    TryGetParticipant: (Round, player: Player | Configuration) -> Participant?,
    StartNextParticipantTurn: (Round, participant: Participant?) -> (),
    SetNextParticipant: (Round) -> (),
}

return {}