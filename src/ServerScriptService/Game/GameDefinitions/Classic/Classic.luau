local ChanceCards = require(script.Parent.ChanceCards)
local CommunityChests = require(script.Parent.CommunityChests)
local Colours = require(script.Parent.Colours)
local Types = require(script.Parent.Parent.Parent.Imperium.Types)
local module = {}

local function DrawCard(tile: Types.TileDescription, participant: Types.Participant): ()
    local deck: {Types.CardDescription}?
    if tile.Name == "Community Chest" then
        deck = CommunityChests
    elseif tile.Name == "Chance" then
        deck = ChanceCards
    end
    assert(deck, `Failed to draw card for tile {tile.Name}`)

    local card = deck[math.random(1, #deck)]
    card.Effect(participant)
end

local function GoToJail(tile: Types.TileDescription, participant: Types.Participant): ()
    participant:SendToJail()
end

local function TaxTile(tile: Types.TileDescription, participant: Types.Participant): ()
    if tile.Name == "Super Tax" then
        participant:TransferMoneyTo("Bank", 100)
    elseif tile.Name == "Income Tax" then
        participant:TransferMoneyTo("Bank", 200)
    end
end

local function GetRentForUtility(asset: Types.Asset, participant: Types.Participant): number
    local roll = math.abs(participant.Position - participant.PreviousPosition)

    local ownedUtilities = 0
    for _, asset in participant.Assets do
        if asset.AssetDescription.Colour == "Utility" then
            ownedUtilities += 1
        end
    end

    if ownedUtilities == 1 then
        return roll * 4
    elseif ownedUtilities == 2 then
        return roll * 10
    elseif ownedUtilities > 0 then
        return roll * (10 + ownedUtilities)
    else
        return 0
    end
end

local function GetRentForStation(asset: Types.Asset, participant: Types.Participant): number
    local ownedStations = 0
    for _, asset in participant.Assets do
        if asset.AssetDescription.Colour == "Station" then
            ownedStations += 1
        end
    end
    return ownedStations * 25
end

module.Name = "Classic"
module.Colours = Colours

module.StartingJailCards = 0
module.StartingMoney = 1500
module.PassGoMoney = 200

module.JailFine = 50
module.JailLength = 3
module.DoublesConsecutiveJailAmount = math.huge

module.CanLeaveJailByRollingDoubles = true
module.AllowJailedRentCollection = true
module.AllowJailedTrading = true

module.FreeParkingBonusEnabled = false
module.FreeParkingBonusInitial = 0

module.Tiles = {
    {
        Name = "Go" :: string?,
        AssetDescription = nil :: Types.AssetDescription?,
        OnEnter = nil :: ((Types.TileDescription, Types.Participant) -> ())?,
    },
    {
        AssetDescription = {
            Name = "Old Kent Road",
            Colour = "Brown",
            Price = 60,
            Rent = {
                Default = 2,
                Houses = {10, 30, 90, 160},
                Hotels = {250},
            },
        }
    },
    {
        Name = "Community Chest",
        OnEnter = DrawCard
    },
    {
        AssetDescription = {
            Name = "Whitechapel Road",
            Colour = "Brown",
            Price = 60,
            Rent = {
                Default = 4,
                Houses = {20, 60, 180, 320},
                Hotels = {450},
            },
        }
    },
    {
        Name = "Income Tax",
        OnEnter = TaxTile
    },
    {
        AssetDescription = {
            Name = "King's Cross Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
        }
    },
    {
        AssetDescription = {
            Name = "The Angel Islington",
            Colour = "Light Blue",
            Price = 100,
            Rent = {
                Default = 6,
                Houses = {30, 90, 270, 400},
                Hotels = {550},
            },
        }
    },
    {
        Name = "Chance",
        OnEnter = DrawCard
    },
    {
        AssetDescription = {
            Name = "Euston Road",
            Colour = "Light Blue",
            Price = 100,
            Rent = {
                Default = 6,
                Houses = {30, 90, 270, 400},
                Hotels = {550},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Pentonville Road",
            Colour = "Light Blue",
            Price = 120,
            Rent = {
                Default = 8,
                Houses = {40, 100, 300, 450},
                Hotels = {600},
            },
        }
    },
    {
        Name = "Jail"
    },
    {
        AssetDescription = {
            Name = "Pall Mall",
            Colour = "Pink",
            Price = 140,
            Rent = {
                Default = 10,
                Houses = {50, 150, 450, 625},
                Hotels = {750},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Electric Company",
            Colour = "Utility",
            Price = 150,
            Rent = GetRentForUtility,
        }
    },
    {
        AssetDescription = {
            Name = "Whitehall",
            Colour = "Pink",
            Price = 140,
            Rent = {
                Default = 10,
                Houses = {50, 150, 450, 625},
                Hotels = {750},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Northumberland Avenue",
            Colour = "Pink",
            Price = 160,
            Rent = {
                Default = 12,
                Houses = {60, 180, 500, 700},
                Hotels = {900},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Marylebone Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
        }
    },
    {
        AssetDescription = {
            Name = "Bow Street",
            Colour = "Orange",
            Price = 180,
            Rent = {
                Default = 14,
                Houses = {70, 200, 550, 750},
                Hotels = {950},
            },
        }
    },
    {
        Name = "Community Chest",
        OnEnter = DrawCard
    },
    {
        AssetDescription = {
            Name = "Marlborough Street",
            Colour = "Orange",
            Price = 180,
            Rent = {
                Default = 14,
                Houses = {70, 200, 550, 750},
                Hotels = {950},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Vine Street",
            Colour = "Orange",
            Price = 200,
            Rent = {
                Default = 16,
                Houses = {80, 220, 600, 800},
                Hotels = {1000},
            },
        }
    },
    {
        Name = "Free Parking"
    },
    {
        AssetDescription = {
            Name = "Strand",
            Colour = "Red",
            Price = 220,
            Rent = {
                Default = 18,
                Houses = {90, 250, 700, 875},
                Hotels = {1050},
            },
        }
    },
    {
        Name = "Chance",
        OnEnter = DrawCard
    },
    {
        AssetDescription = {
            Name = "Fleet Street",
            Colour = "Red",
            Price = 220,
            Rent = {
                Default = 18,
                Houses = {90, 250, 700, 875},
                Hotels = {1050},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Trafalgar Square",
            Colour = "Red",
            Price = 240,
            Rent = {
                Default = 20,
                Houses = {100, 300, 750, 925},
                Hotels = {1100},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Fenchurch St Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
        }
    },
    {
        AssetDescription = {
            Name = "Leicester Square",
            Colour = "Yellow",
            Price = 260,
            Rent = {
                Default = 22,
                Houses = {110, 330, 800, 975},
                Hotels = {1150},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Coventry Street",
            Colour = "Yellow",
            Price = 260,
            Rent = {
                Default = 22,
                Houses = {110, 330, 800, 975},
                Hotels = {1150},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Water Works",
            Colour = "Utility",
            Price = 150,
            Rent = GetRentForUtility,
        }
    },
    {
        AssetDescription = {
            Name = "Piccadilly",
            Colour = "Yellow",
            Price = 280,
            Rent = {
                Default = 24,
                Houses = {120, 360, 850, 1025},
                Hotels = {1200},
            },
        }
    },
    {
        Name = "Go to Jail",
        OnEnter = GoToJail
    },
    {
        AssetDescription = {
            Name = "Regent Street",
            Colour = "Green",
            Price = 300,
            Rent = {
                Default = 26,
                Houses = {130, 390, 900, 1100},
                Hotels = {1275},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Oxford Street",
            Colour = "Green",
            Price = 300,
            Rent = {
                Default = 26,
                Houses = {130, 390, 900, 1100},
                Hotels = {1275},
            },
        }
    },
    {
        Name = "Community Chest",
        OnEnter = DrawCard
    },
    {
        AssetDescription = {
            Name = "Bond Street",
            Colour = "Green",
            Price = 320,
            Rent = {
                Default = 28,
                Houses = {150, 450, 1000, 1200},
                Hotels = {1400},
            },
        }
    },
    {
        AssetDescription = {
            Name = "Liverpool Street Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
        }
    },
    {
        Name = "Chance",
        OnEnter = DrawCard
    },
    {
        AssetDescription = {
            Name = "Park Lane",
            Colour = "Dark Blue",
            Price = 350,
            Rent = {
                Default = 35,
                Houses = {175, 500, 1100, 1300},
                Hotels = {1500},
            },
        }
    },
    {
        Name = "Super Tax",
        OnEnter = TaxTile
    },
    {
        AssetDescription = {
            Name = "Mayfair",
            Colour = "Dark Blue",
            Price = 400,
            Rent = {
                Default = 50,
                Houses = {200, 600, 1400, 1700},
                Hotels = {2000},
            },
        }
    },
}

local typeCheck: Types.BoardConfiguration = module
return typeCheck