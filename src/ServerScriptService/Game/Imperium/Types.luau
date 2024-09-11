local ServerStorage = game:GetService("ServerStorage")
type Turn = number
export type AssetOwner = Participant | "Bank"
export type DiceRollResult = {
    Result: number,
    IsDoubles: boolean,
}

export type Board = {
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
}

export type AssetDescription = {
    Name: string,
    Colour: string,
    Price: number,
    Rent: ((Asset, Participant) -> number)?,
}

export type TileDescription = {
    Name: string?,
    Asset: AssetDescription?,
    OnEnter: ((TileDescription, Participant) -> ())?,
}

export type CardDescription = {
    Title: string,
    Effect: (Participant) -> (),
}

export type Asset = {
    AssetDescription: AssetDescription,

    Owner: AssetOwner,
    Houses: number,
    Hotels: number,

    TransferTo: (Asset, AssetOwner) -> (),
    
    Mortgage: (Asset) -> (),
    Unmortgaged: (Asset) -> (),
}

export type EdgeTile = typeof(ServerStorage.Game.Tile)
export type CornerTile = typeof(ServerStorage.Game.CornerTile)
export type TileModel = EdgeTile | CornerTile

export type Tile = {
    TileDescription: TileDescription,
    Model: TileModel
}

export type Participant = {
    Player: Player,
    Round: Round,

    Money: number,
    JailCards: number,
    Assets: {Asset},

    LastMovedAt: number,
    PreviousPosition: number,
    Position: number,
    JailedOn: number,
    DoublesStreak: number,

    RollDice: (Participant) -> DiceRollResult,
    TryPlayMove: (Participant) -> (),

    MoveToTileByName: (Participant, name: string, moveDirectly: boolean?) -> (),
    MoveTo: (Participant, position: number, moveDirectly: boolean?, initialMove: boolean?) -> (),
    MoveBy: (Participant, amount: number) -> (),

    SendToJail: (Participant) -> (),
    LeaveJail: (Participant, skipTurn: boolean?) -> (),

    FindClosestForwardPositionByColour: (Participant, colour: string) -> number?,

    TryPayRent: (Participant, Tile) -> (),

    GiveJailCard: (Participant) -> (),
    GiveMoney: (Participant, amount: number) -> (),
    GiveAsset: (Participant, asset: Asset) -> (),
    RemoveAsset: (Participant, asset: Asset) -> (),

    TransferAssetTo: (Participant, to: AssetOwner, asset: Asset) -> (),
    TransferMoneyTo: (Participant, to: AssetOwner, amount: number) -> (),
    TransferJailCard: (Participant, to: AssetOwner) -> (),
}

export type Round = {
    Board: Board,
    GameConfiguration: GameConfiguration,

    Started: boolean,
    Turn: Turn,
    CurrentParticipant: Participant,

    Participants: {Participant},
    Tiles: {Tile},

    StartRound: (Round) -> (),
    GetParticipant: (Round, player: Player) -> Participant,
    StartNextParticipantTurn: (Round) -> (),
    FindTileByName: (Round, name: string) -> number,

    TryGetAssetFromTile: (Round, tile: Tile) -> Asset?,
}

return {}