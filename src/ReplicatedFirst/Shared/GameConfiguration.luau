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
    StartingMoney: number,
    TurnTime: number,
    AuctionTime: number,
    BankruptcyTime: number,
    Map: string,
    Board: string,
    FreeParkingBonusEnabled: "Enabled" | "Disabled",
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
    StartingMoney = {
        Name = "StartingMoney",
        DisplayName = "Starting Money",
        Default = 1500,
        PossibleValues = "number",
        Max = 5000,
        Min = 100,
        Order = 3,
    },
    FreeParkingBonusEnabled = {
        Name = "FreeParkingBonusEnabled",
        DisplayName = "Free Parking Bonus",
        Default = "Disabled",
        PossibleValues = {"Enabled", "Disabled"},
        Order = 4,
    },
    TurnTime = {
        Name = "TurnTime",
        DisplayName = "Turn Time",
        Default = 10,
        PossibleValues = "number",
        Max = 45,
        Min = 5,
        Order = 5,
    },
    AuctionTime = {
        Name = "AuctionTime",
        DisplayName = "Auction Time",
        Default = 10,
        PossibleValues = "number",
        Max = 25,
        Min = 5,
        Order = 6,
    },
    BankruptcyTime = {
        Name = "BankruptcyTime",
        DisplayName = "Bankruptcy Time",
        Default = 60,
        PossibleValues = "number",
        Max = 180,
        Min = 30,
        Order = 7,
    }
}

return settings