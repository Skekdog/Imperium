export type Setting = {
    Name: string,
    DisplayName: string,
    Default: string | number,
    PossibleValues: {string} | "number",
    Max: number?,
    Min: number?,
    Order: number,
}

export type Settings = {[string]: Setting}

export type SerialisedSettings = {
    TurnTime: number,
    AuctionTime: number,
    BankruptcyTime: number,
    Map: string,
    Board: string,
}

local settings: Settings = {
    Map = {
        Name = "Map",
        DisplayName = "Map",
        Default = "Happy Home",
        PossibleValues = {"Happy Home", "Doomspires"},
        Order = 1,
    },
    Board = {
        Name = "Board",
        DisplayName = "Board",
        Default = "Classic (UK)",
        PossibleValues = {"Classic (UK)", "Classic (US)"},
        Order = 2,
    },
    TurnTime = {
        Name = "TurnTime",
        DisplayName = "Turn Time",
        Default = 10,
        PossibleValues = "number",
        Max = 45,
        Min = 5,
        Order = 3,
    },
    AuctionTime = {
        Name = "AuctionTime",
        DisplayName = "Auction Time",
        Default = 10,
        PossibleValues = "number",
        Max = 25,
        Min = 5,
        Order = 4,
    },
    BankruptcyTime = {
        Name = "BankruptcyTime",
        DisplayName = "Bankruptcy Time",
        Default = 60,
        PossibleValues = "number",
        Max = 180,
        Min = 30,
        Order = 5,
    }
}

return settings