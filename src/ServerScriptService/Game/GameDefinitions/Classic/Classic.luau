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
    participant:DrawCard(card, tile.Name :: Types.CardType)
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

local ChanceTile: Types.TileDescription = {
    Name = "Chance",
    Icon = "rbxassetid://132370212979970",
    Colour = "Chance",
    OnEnter = DrawCard,
}

local CommunityChestTile: Types.TileDescription = {
    Name = "Community Chest",
    Icon = "rbxassetid://93730445736567",
    Colour = "Community Chest",
    OnEnter = DrawCard,
}

local TaxIcon = "rbxassetid://83973123711431"
local GoIcon = "rbxassetid://135653151798874"
local GoToJailIcon = "rbxassetid://114111426528418"
local FreeParkingIcon = "rbxassetid://138390415994185"

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
    assert(asset.Owner ~= "Bank", "Unable to calculate station rent if asset is owned by Bank")
    for _, asset in asset.Owner.Assets do
        if asset.AssetDescription.Colour == "Station" then
            ownedStations += 1
        end
    end

    if ownedStations == 1 then
        return 25
    elseif ownedStations == 2 then
        return 50
    elseif ownedStations == 3 then
        return 100
    elseif ownedStations == 4 then
        return 200
    end
    return 50 * ownedStations
end

module.Name = "Classic"
module.Colours = Colours

module.HousePrices = {
    ["Brown"] = 50,
    ["Light Blue"] = 50,
    ["Pink"] = 100,
    ["Orange"] = 100,
    ["Red"] = 150,
    ["Yellow"] = 150,
    ["Green"] = 200,
    ["Dark Blue"] = 200,
}

module.StartingJailCards = 0
module.StartingMoney = 1500
module.PassGoMoney = 200

module.JailFine = 50
module.JailLength = 3
module.DoublesConsecutiveJailAmount = 3

module.CanLeaveJailByRollingDoubles = true
module.AllowJailedRentCollection = true
module.AllowJailedTrading = true

module.FreeParkingBonusEnabled = false
module.FreeParkingBonusInitial = 0

module.Tiles = {
    {
        Name = "Go",
        Icon = GoIcon,
    } :: Types.TileDescription,
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
            RentDescription = {
                {"Rent:", "£2"},
                {"Rent with Colour Set:", "£4"},
                {"Rent with 1 House:", "£10"},
                {"Rent with 2 Houses:", "£30"},
                {"Rent with 3 Houses:", "£90"},
                {"Rent with 4 Houses:", "£160"},
                {"Rent with Hotel:", "£250"}
            }
        }
    },
    CommunityChestTile,
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
            RentDescription = {
                {"Rent:", "£4"},
                {"Rent with Colour Set:", "£8"},
                {"Rent with 1 House:", "£20"},
                {"Rent with 2 Houses:", "£60"},
                {"Rent with 3 Houses:", "£180"},
                {"Rent with 4 Houses:", "£320"},
                {"Rent with Hotel:", "£450"}
            }
        }
    },
    {
        Name = "Income Tax",
        Icon = TaxIcon,
        OnEnter = TaxTile
    },
    {
        AssetDescription = {
            Name = "King's Cross Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
            RentDescription = {
                {"Rent with 1 owned Station:", "£25"},
                {"Rent with 2 owned Stations:", "£50"},
                {"Rent with 3 owned Stations:", "£100"},
                {"Rent with 4 owned Stations:", "£200"}
            }
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
            RentDescription = {
                {"Rent:", "£6"},
                {"Rent with Colour Set:", "£12"},
                {"Rent with 1 House:", "£30"},
                {"Rent with 2 Houses:", "£90"},
                {"Rent with 3 Houses:", "£270"},
                {"Rent with 4 Houses:", "£400"},
                {"Rent with Hotel:", "£550"}
            }
        }
    },
    ChanceTile,
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
            RentDescription = {
                {"Rent:", "£6"},
                {"Rent with Colour Set:", "£12"},
                {"Rent with 1 House:", "£30"},
                {"Rent with 2 Houses:", "£90"},
                {"Rent with 3 Houses:", "£270"},
                {"Rent with 4 Houses:", "£400"},
                {"Rent with Hotel:", "£550"}
            }
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
            RentDescription = {
                {"Rent:", "£8"},
                {"Rent with Colour Set:", "£16"},
                {"Rent with 1 House:", "£40"},
                {"Rent with 2 Houses:", "£100"},
                {"Rent with 3 Houses:", "£300"},
                {"Rent with 4 Houses:", "£450"},
                {"Rent with Hotel:", "£600"}
            }
        }
    },
    {
        Name = "Jail",
        Icon = "",
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
            RentDescription = {
                {"Rent:", "£10"},
                {"Rent with Colour Set:", "£20"},
                {"Rent with 1 House:", "£50"},
                {"Rent with 2 Houses:", "£150"},
                {"Rent with 3 Houses:", "£450"},
                {"Rent with 4 Houses:", "£625"},
                {"Rent with Hotel:", "£750"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Electric Company",
            Colour = "Utility",
            Price = 150,
            Rent = GetRentForUtility,
            RentDescription = {
                {"Rent with 1 Utility:", "4x dice roll"},
                {"Rent with 2 Utilities:", "10x dice roll"}
            }
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
            RentDescription = {
                {"Rent:", "£10"},
                {"Rent with Colour Set:", "£20"},
                {"Rent with 1 House:", "£50"},
                {"Rent with 2 Houses:", "£150"},
                {"Rent with 3 Houses:", "£450"},
                {"Rent with 4 Houses:", "£625"},
                {"Rent with Hotel:", "£750"}
            }
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
            RentDescription = {
                {"Rent:", "£12"},
                {"Rent with Colour Set:", "£24"},
                {"Rent with 1 House:", "£60"},
                {"Rent with 2 Houses:", "£180"},
                {"Rent with 3 Houses:", "£500"},
                {"Rent with 4 Houses:", "£700"},
                {"Rent with Hotel:", "£900"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Marylebone Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
            RentDescription = {
                {"Rent with 1 owned Station:", "£25"},
                {"Rent with 2 owned Stations:", "£50"},
                {"Rent with 3 owned Stations:", "£100"},
                {"Rent with 4 owned Stations:", "£200"}
            }
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
            RentDescription = {
                {"Rent:", "£14"},
                {"Rent with Colour Set:", "£28"},
                {"Rent with 1 House:", "£70"},
                {"Rent with 2 Houses:", "£200"},
                {"Rent with 3 Houses:", "£550"},
                {"Rent with 4 Houses:", "£750"},
                {"Rent with Hotel:", "£950"}
            }
        }
    },
    CommunityChestTile,
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
            RentDescription = {
                {"Rent:", "£14"},
                {"Rent with Colour Set:", "£28"},
                {"Rent with 1 House:", "£70"},
                {"Rent with 2 Houses:", "£200"},
                {"Rent with 3 Houses:", "£550"},
                {"Rent with 4 Houses:", "£750"},
                {"Rent with Hotel:", "£950"}
            }
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
            RentDescription = {
                {"Rent:", "£16"},
                {"Rent with Colour Set:", "£32"},
                {"Rent with 1 House:", "£80"},
                {"Rent with 2 Houses:", "£220"},
                {"Rent with 3 Houses:", "£600"},
                {"Rent with 4 Houses:", "£800"},
                {"Rent with Hotel:", "£1000"}
            }
        }
    },
    {
        Name = "Free Parking",
        Icon = FreeParkingIcon,
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
            RentDescription = {
                {"Rent:", "£18"},
                {"Rent with Colour Set:", "£36"},
                {"Rent with 1 House:", "£90"},
                {"Rent with 2 Houses:", "£250"},
                {"Rent with 3 Houses:", "£700"},
                {"Rent with 4 Houses:", "£875"},
                {"Rent with Hotel:", "£1050"}
            }
        }
    },
    ChanceTile,
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
            RentDescription = {
                {"Rent:", "£18"},
                {"Rent with Colour Set:", "£36"},
                {"Rent with 1 House:", "£90"},
                {"Rent with 2 Houses:", "£250"},
                {"Rent with 3 Houses:", "£700"},
                {"Rent with 4 Houses:", "£875"},
                {"Rent with Hotel:", "£1050"}
            }
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
            RentDescription = {
                {"Rent:", "£20"},
                {"Rent with Colour Set:", "£40"},
                {"Rent with 1 House:", "£100"},
                {"Rent with 2 Houses:", "£300"},
                {"Rent with 3 Houses:", "£750"},
                {"Rent with 4 Houses:", "£925"},
                {"Rent with Hotel:", "£1100"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Fenchurch St Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
            RentDescription = {
                {"Rent with 1 owned Station:", "£25"},
                {"Rent with 2 owned Stations:", "£50"},
                {"Rent with 3 owned Stations:", "£100"},
                {"Rent with 4 owned Stations:", "£200"}
            }
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
            RentDescription = {
                {"Rent:", "£22"},
                {"Rent with Colour Set:", "£44"},
                {"Rent with 1 House:", "£110"},
                {"Rent with 2 Houses:", "£330"},
                {"Rent with 3 Houses:", "£800"},
                {"Rent with 4 Houses:", "£975"},
                {"Rent with Hotel:", "£1150"}
            }
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
            RentDescription = {
                {"Rent:", "£22"},
                {"Rent with Colour Set:", "£44"},
                {"Rent with 1 House:", "£110"},
                {"Rent with 2 Houses:", "£330"},
                {"Rent with 3 Houses:", "£800"},
                {"Rent with 4 Houses:", "£975"},
                {"Rent with Hotel:", "£1150"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Water Works",
            Colour = "Utility",
            Price = 150,
            Rent = GetRentForUtility,
            RentDescription = {
                {"Rent with 1 Utility:", "4x dice roll"},
                {"Rent with 2 Utilities:", "10x dice roll"}
            }
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
            RentDescription = {
                {"Rent:", "£24"},
                {"Rent with Colour Set:", "£48"},
                {"Rent with 1 House:", "£120"},
                {"Rent with 2 Houses:", "£360"},
                {"Rent with 3 Houses:", "£850"},
                {"Rent with 4 Houses:", "£1025"},
                {"Rent with Hotel:", "£1200"}
            }
        }
    },
    {
        Name = "Go to Jail",
        OnEnter = GoToJail,
        Icon = GoToJailIcon,
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
            RentDescription = {
                {"Rent:", "£26"},
                {"Rent with Colour Set:", "£52"},
                {"Rent with 1 House:", "£130"},
                {"Rent with 2 Houses:", "£390"},
                {"Rent with 3 Houses:", "£900"},
                {"Rent with 4 Houses:", "£1100"},
                {"Rent with Hotel:", "£1275"}
            }
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
            RentDescription = {
                {"Rent:", "£26"},
                {"Rent with Colour Set:", "£52"},
                {"Rent with 1 House:", "£130"},
                {"Rent with 2 Houses:", "£390"},
                {"Rent with 3 Houses:", "£900"},
                {"Rent with 4 Houses:", "£1100"},
                {"Rent with Hotel:", "£1275"}
            }
        }
    },
    CommunityChestTile,
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
            RentDescription = {
                {"Rent:", "£28"},
                {"Rent with Colour Set:", "£56"},
                {"Rent with 1 House:", "£150"},
                {"Rent with 2 Houses:", "£450"},
                {"Rent with 3 Houses:", "£1000"},
                {"Rent with 4 Houses:", "£1200"},
                {"Rent with Hotel:", "£1400"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Liverpool Street Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
            RentDescription = {
                {"Rent with 1 owned Station:", "£25"},
                {"Rent with 2 owned Stations:", "£50"},
                {"Rent with 3 owned Stations:", "£100"},
                {"Rent with 4 owned Stations:", "£200"}
            }
        }
    },
    ChanceTile,
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
            RentDescription = {
                {"Rent:", "£35"},
                {"Rent with Colour Set:", "£70"},
                {"Rent with 1 House:", "£175"},
                {"Rent with 2 Houses:", "£500"},
                {"Rent with 3 Houses:", "£1100"},
                {"Rent with 4 Houses:", "£1300"},
                {"Rent with Hotel:", "£1500"}
            }
        }
    },
    {
        Name = "Super Tax",
        OnEnter = TaxTile,
        Icon = TaxIcon,
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
            RentDescription = {
                {"Rent:", "£50"},
                {"Rent with Colour Set:", "£100"},
                {"Rent with 1 House:", "£200"},
                {"Rent with 2 Houses:", "£600"},
                {"Rent with 3 Houses:", "£1400"},
                {"Rent with 4 Houses:", "£1700"},
                {"Rent with Hotel:", "£2000"}
            }
        }
    },
}


local typeCheck: Types.BoardConfiguration = module
return typeCheck