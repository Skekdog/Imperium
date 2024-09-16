local ServerStorage = game:GetService("ServerStorage")
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

export type CardDescription = {
    Title: string,
    Effect: (Participant) -> (),
}

export type Asset = {
    AssetDescription: AssetDescription,

    IsMortgaged: boolean,
    Owner: AssetOwner,
    Houses: number,
    Hotels: number,

    TransferTo: (Asset, to: AssetOwner) -> (),
    StartAuction: (Asset, round: Round) -> (),
    
    Mortgage: (Asset) -> (),
    UnMortgage: (Asset) -> (),

    GetMortgageValue: (Asset) -> number,
    GetUnMortgageCost: (Asset) -> number,

    GetDevelopmentCost: (Asset, development: "House" | "Hotel") -> number,
    DevelopProperty: (Asset, development: "House" | "Hotel") -> (),
    SellDevelopment: (Asset) -> (),
    TrySellAllDevelopments: (Asset) -> (),

    GetRentCost: (Asset, participant: Participant) -> number,
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

export type Participant = {
    Player: Player,
    Round: Round,
    Board: Board,

    Money: number,
    JailCards: number,
    Assets: {Asset},

    IsMoving: boolean,
    LastMovedAt: number,
    PreviousPosition: number,
    Position: number,

    ValidPropertyPurchaseTurn: number?,
    
    JailedOn: number,
    DoublesStreak: number,

    RollDice: (Participant) -> DiceRollResult,
    TryPlayMove: (Participant) -> (),
    TryUseJailCard: (Participant) -> (),
    TryPayFine: (Participant) -> (),

    MoveToTileByName: (Participant, name: string, moveDirectly: boolean?) -> (),
    MoveTo: (Participant, position: number, moveDirectly: boolean?, initialMove: boolean?) -> (),
    MoveBy: (Participant, amount: number) -> (),

    SendToJail: (Participant) -> (),
    LeaveJail: (Participant, skipTurn: boolean?) -> (),

    FindClosestForwardPositionByColour: (Participant, colour: string) -> number?,

    TryPayRent: (Participant, Tile) -> (),

    GiveJailCards: (Participant, amount: number) -> (),
    GiveMoney: (Participant, amount: number) -> (),

    TransferMoneyTo: (Participant, to: AssetOwner, amount: number, noNotification: boolean?) -> (),
    TransferJailCards: (Participant, to: AssetOwner, amount: number) -> (),

    DrawCard: (Participant, card: CardDescription) -> (),

    PurchaseProperty: (Participant, asset: Asset) -> (),
    PromptPurchaseProperty: (Participant, asset: Asset) -> (),

    BankruptcyWarning: (Participant, targetAmount: number, to: AssetOwner) -> (),
    GoBankrupt: (Participant, to: AssetOwner) -> (),
}

export type Board = {
    Tiles: {Tile},

    TryFindTileByName: (Board, name: string) -> Tile?,
    FindTileByName: (Board, name: string) -> Tile,
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
    GetParticipant: (Round, player: Player) -> Participant,
    StartNextParticipantTurn: (Round) -> (),
}

return {}