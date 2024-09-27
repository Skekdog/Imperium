export type Setting = {
    Name: string,
    DisplayName: string,
    Default: string | number,
    PossibleValues: {string} | "number",
    Max: number?,
    Min: number?,
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
    },
    Board = {
        Name = "Board",
        DisplayName = "Board",
        Default = "Classic (UK)",
        PossibleValues = {"Classic (UK)", "Classic (US)"},
    },
    TurnTime = {
        Name = "TurnTime",
        DisplayName = "Turn Time",
        Default = 15,
        PossibleValues = "number",
        Max = 60,
        Min = 5,
    },
    AuctionTime = {
        Name = "AuctionTime",
        DisplayName = "Auction Time",
        Default = 10,
        PossibleValues = "number",
        Max = 30,
        Min = 5,
    },
    BankruptcyTime = {
        Name = "BankruptcyTime",
        DisplayName = "Bankruptcy Time",
        Default = 60,
        PossibleValues = "number",
        Max = 300,
        Min = 30,
    }
}

return settings