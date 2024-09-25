local ChanceCards = require(script.Parent.ChanceCards)
local CommunityChests = require(script.Parent.CommunityChests)
local Colours = require(script.Parent.Colours)
local Types = require(script.Parent.Parent.Parent.Imperium.Types)
local module = {}

local random = Random.new()
random:Shuffle(ChanceCards)
random:Shuffle(CommunityChests)

local function DrawCard(tile: Types.TileDescription, participant: Types.Participant): ()
    local deck: {Types.CardDescription}?
    if tile.Name == "Community Chest" then
        deck = CommunityChests
    elseif tile.Name == "Chance" then
        deck = ChanceCards
    end
    assert(deck, `Failed to draw card for tile {tile.Name}`)

    local card = deck[1]
    table.remove(deck, 1)
    table.insert(deck, card)
    
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
    Icon = "rbxassetid://118048991405187",
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
            Name = "Mediterranean Avenue",
            Colour = "Brown",
            Price = 60,
            Rent = {
                Default = 2,
                Houses = {10, 30, 90, 160},
                Hotels = {250},
            },
            RentDescription = {
                {"Rent:", "£2"},
                {"With Colour Set:", "£4"},
                {"With 1 House:", "£10"},
                {"With 2 Houses:", "£30"},
                {"With 3 Houses:", "£90"},
                {"With 4 Houses:", "£160"},
                {"With Hotel:", "£250"}
            }
        }
    },
    CommunityChestTile,
    {
        AssetDescription = {
            Name = "Baltic Avenue",
            Colour = "Brown",
            Price = 60,
            Rent = {
                Default = 4,
                Houses = {20, 60, 180, 320},
                Hotels = {450},
            },
            RentDescription = {
                {"Rent:", "£4"},
                {"With Colour Set:", "£8"},
                {"With 1 House:", "£20"},
                {"With 2 Houses:", "£60"},
                {"With 3 Houses:", "£180"},
                {"With 4 Houses:", "£320"},
                {"With Hotel:", "£450"}
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
            Name = "Reading Railroad",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
            RentDescription = {
                {"With 1 owned Station:", "£25"},
                {"With 2 owned Stations:", "£50"},
                {"With 3 owned Stations:", "£100"},
                {"With 4 owned Stations:", "£200"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Oriental Avenue",
            Colour = "Light Blue",
            Price = 100,
            Rent = {
                Default = 6,
                Houses = {30, 90, 270, 400},
                Hotels = {550},
            },
            RentDescription = {
                {"Rent:", "£6"},
                {"With Colour Set:", "£12"},
                {"With 1 House:", "£30"},
                {"With 2 Houses:", "£90"},
                {"With 3 Houses:", "£270"},
                {"With 4 Houses:", "£400"},
                {"With Hotel:", "£550"}
            }
        }
    },
    ChanceTile,
    {
        AssetDescription = {
            Name = "Vermont Avenue",
            Colour = "Light Blue",
            Price = 100,
            Rent = {
                Default = 6,
                Houses = {30, 90, 270, 400},
                Hotels = {550},
            },
            RentDescription = {
                {"Rent:", "£6"},
                {"With Colour Set:", "£12"},
                {"With 1 House:", "£30"},
                {"With 2 Houses:", "£90"},
                {"With 3 Houses:", "£270"},
                {"With 4 Houses:", "£400"},
                {"With Hotel:", "£550"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Connecticut Avenue",
            Colour = "Light Blue",
            Price = 120,
            Rent = {
                Default = 8,
                Houses = {40, 100, 300, 450},
                Hotels = {600},
            },
            RentDescription = {
                {"Rent:", "£8"},
                {"With Colour Set:", "£16"},
                {"With 1 House:", "£40"},
                {"With 2 Houses:", "£100"},
                {"With 3 Houses:", "£300"},
                {"With 4 Houses:", "£450"},
                {"With Hotel:", "£600"}
            }
        }
    },
    {
        Name = "Jail",
        Icon = "",
    },
    {
        AssetDescription = {
            Name = "St. Charles Place",
            Colour = "Pink",
            Price = 140,
            Rent = {
                Default = 10,
                Houses = {50, 150, 450, 625},
                Hotels = {750},
            },
            RentDescription = {
                {"Rent:", "£10"},
                {"With Colour Set:", "£20"},
                {"With 1 House:", "£50"},
                {"With 2 Houses:", "£150"},
                {"With 3 Houses:", "£450"},
                {"With 4 Houses:", "£625"},
                {"With Hotel:", "£750"}
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
                {"With 1 Utility:", "4x dice roll"},
                {"With 2 Utilities:", "10x dice roll"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "States Avenue",
            Colour = "Pink",
            Price = 140,
            Rent = {
                Default = 10,
                Houses = {50, 150, 450, 625},
                Hotels = {750},
            },
            RentDescription = {
                {"Rent:", "£10"},
                {"With Colour Set:", "£20"},
                {"With 1 House:", "£50"},
                {"With 2 Houses:", "£150"},
                {"With 3 Houses:", "£450"},
                {"With 4 Houses:", "£625"},
                {"With Hotel:", "£750"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Virginia Avenue",
            Colour = "Pink",
            Price = 160,
            Rent = {
                Default = 12,
                Houses = {60, 180, 500, 700},
                Hotels = {900},
            },
            RentDescription = {
                {"Rent:", "£12"},
                {"With Colour Set:", "£24"},
                {"With 1 House:", "£60"},
                {"With 2 Houses:", "£180"},
                {"With 3 Houses:", "£500"},
                {"With 4 Houses:", "£700"},
                {"With Hotel:", "£900"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Pennsylvania Railroad",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
            RentDescription = {
                {"With 1 owned Station:", "£25"},
                {"With 2 owned Stations:", "£50"},
                {"With 3 owned Stations:", "£100"},
                {"With 4 owned Stations:", "£200"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "St. James Place",
            Colour = "Orange",
            Price = 180,
            Rent = {
                Default = 14,
                Houses = {70, 200, 550, 750},
                Hotels = {950},
            },
            RentDescription = {
                {"Rent:", "£14"},
                {"With Colour Set:", "£28"},
                {"With 1 House:", "£70"},
                {"With 2 Houses:", "£200"},
                {"With 3 Houses:", "£550"},
                {"With 4 Houses:", "£750"},
                {"With Hotel:", "£950"}
            }
        }
    },
    CommunityChestTile,
    {
        AssetDescription = {
            Name = "Tennessee Avenue",
            Colour = "Orange",
            Price = 180,
            Rent = {
                Default = 14,
                Houses = {70, 200, 550, 750},
                Hotels = {950},
            },
            RentDescription = {
                {"Rent:", "£14"},
                {"With Colour Set:", "£28"},
                {"With 1 House:", "£70"},
                {"With 2 Houses:", "£200"},
                {"With 3 Houses:", "£550"},
                {"With 4 Houses:", "£750"},
                {"With Hotel:", "£950"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "New York Avenue",
            Colour = "Orange",
            Price = 200,
            Rent = {
                Default = 16,
                Houses = {80, 220, 600, 800},
                Hotels = {1000},
            },
            RentDescription = {
                {"Rent:", "£16"},
                {"With Colour Set:", "£32"},
                {"With 1 House:", "£80"},
                {"With 2 Houses:", "£220"},
                {"With 3 Houses:", "£600"},
                {"With 4 Houses:", "£800"},
                {"With Hotel:", "£1000"}
            }
        }
    },
    {
        Name = "Free Parking",
        Icon = FreeParkingIcon,
    },
    {
        AssetDescription = {
            Name = "Kentucky Avenue",
            Colour = "Red",
            Price = 220,
            Rent = {
                Default = 18,
                Houses = {90, 250, 700, 875},
                Hotels = {1050},
            },
            RentDescription = {
                {"Rent:", "£18"},
                {"With Colour Set:", "£36"},
                {"With 1 House:", "£90"},
                {"With 2 Houses:", "£250"},
                {"With 3 Houses:", "£700"},
                {"With 4 Houses:", "£875"},
                {"With Hotel:", "£1050"}
            }
        }
    },
    ChanceTile,
    {
        AssetDescription = {
            Name = "Indiana Avenue",
            Colour = "Red",
            Price = 220,
            Rent = {
                Default = 18,
                Houses = {90, 250, 700, 875},
                Hotels = {1050},
            },
            RentDescription = {
                {"Rent:", "£18"},
                {"With Colour Set:", "£36"},
                {"With 1 House:", "£90"},
                {"With 2 Houses:", "£250"},
                {"With 3 Houses:", "£700"},
                {"With 4 Houses:", "£875"},
                {"With Hotel:", "£1050"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Illinois Avenue",
            Colour = "Red",
            Price = 240,
            Rent = {
                Default = 20,
                Houses = {100, 300, 750, 925},
                Hotels = {1100},
            },
            RentDescription = {
                {"Rent:", "£20"},
                {"With Colour Set:", "£40"},
                {"With 1 House:", "£100"},
                {"With 2 Houses:", "£300"},
                {"With 3 Houses:", "£750"},
                {"With 4 Houses:", "£925"},
                {"With Hotel:", "£1100"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "B. & O. Railroad",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
            RentDescription = {
                {"With 1 owned Station:", "£25"},
                {"With 2 owned Stations:", "£50"},
                {"With 3 owned Stations:", "£100"},
                {"With 4 owned Stations:", "£200"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Atlantic Avenue",
            Colour = "Yellow",
            Price = 260,
            Rent = {
                Default = 22,
                Houses = {110, 330, 800, 975},
                Hotels = {1150},
            },
            RentDescription = {
                {"Rent:", "£22"},
                {"With Colour Set:", "£44"},
                {"With 1 House:", "£110"},
                {"With 2 Houses:", "£330"},
                {"With 3 Houses:", "£800"},
                {"With 4 Houses:", "£975"},
                {"With Hotel:", "£1150"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Ventnor Avenue",
            Colour = "Yellow",
            Price = 260,
            Rent = {
                Default = 22,
                Houses = {110, 330, 800, 975},
                Hotels = {1150},
            },
            RentDescription = {
                {"Rent:", "£22"},
                {"With Colour Set:", "£44"},
                {"With 1 House:", "£110"},
                {"With 2 Houses:", "£330"},
                {"With 3 Houses:", "£800"},
                {"With 4 Houses:", "£975"},
                {"With Hotel:", "£1150"}
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
                {"With 1 Utility:", "4x dice roll"},
                {"With 2 Utilities:", "10x dice roll"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Marvin Gardens",
            Colour = "Yellow",
            Price = 280,
            Rent = {
                Default = 24,
                Houses = {120, 360, 850, 1025},
                Hotels = {1200},
            },
            RentDescription = {
                {"Rent:", "£24"},
                {"With Colour Set:", "£48"},
                {"With 1 House:", "£120"},
                {"With 2 Houses:", "£360"},
                {"With 3 Houses:", "£850"},
                {"With 4 Houses:", "£1025"},
                {"With Hotel:", "£1200"}
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
            Name = "Pacific Avenue",
            Colour = "Green",
            Price = 300,
            Rent = {
                Default = 26,
                Houses = {130, 390, 900, 1100},
                Hotels = {1275},
            },
            RentDescription = {
                {"Rent:", "£26"},
                {"With Colour Set:", "£52"},
                {"With 1 House:", "£130"},
                {"With 2 Houses:", "£390"},
                {"With 3 Houses:", "£900"},
                {"With 4 Houses:", "£1100"},
                {"With Hotel:", "£1275"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "North Carolina Avenue",
            Colour = "Green",
            Price = 300,
            Rent = {
                Default = 26,
                Houses = {130, 390, 900, 1100},
                Hotels = {1275},
            },
            RentDescription = {
                {"Rent:", "£26"},
                {"With Colour Set:", "£52"},
                {"With 1 House:", "£130"},
                {"With 2 Houses:", "£390"},
                {"With 3 Houses:", "£900"},
                {"With 4 Houses:", "£1100"},
                {"With Hotel:", "£1275"}
            }
        }
    },
    CommunityChestTile,
    {
        AssetDescription = {
            Name = "Pennsylvania Avenue",
            Colour = "Green",
            Price = 320,
            Rent = {
                Default = 28,
                Houses = {150, 450, 1000, 1200},
                Hotels = {1400},
            },
            RentDescription = {
                {"Rent:", "£28"},
                {"With Colour Set:", "£56"},
                {"With 1 House:", "£150"},
                {"With 2 Houses:", "£450"},
                {"With 3 Houses:", "£1000"},
                {"With 4 Houses:", "£1200"},
                {"With Hotel:", "£1400"}
            }
        }
    },
    {
        AssetDescription = {
            Name = "Short Line",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
            RentDescription = {
                {"With 1 owned Station:", "£25"},
                {"With 2 owned Stations:", "£50"},
                {"With 3 owned Stations:", "£100"},
                {"With 4 owned Stations:", "£200"}
            }
        }
    },
    ChanceTile,
    {
        AssetDescription = {
            Name = "Park Place",
            Colour = "Dark Blue",
            Price = 350,
            Rent = {
                Default = 35,
                Houses = {175, 500, 1100, 1300},
                Hotels = {1500},
            },
            RentDescription = {
                {"Rent:", "£35"},
                {"With Colour Set:", "£70"},
                {"With 1 House:", "£175"},
                {"With 2 Houses:", "£500"},
                {"With 3 Houses:", "£1100"},
                {"With 4 Houses:", "£1300"},
                {"With Hotel:", "£1500"}
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
            Name = "Boardwalk",
            Colour = "Dark Blue",
            Price = 400,
            Rent = {
                Default = 50,
                Houses = {200, 600, 1400, 1700},
                Hotels = {2000},
            },
            RentDescription = {
                {"Rent:", "£50"},
                {"With Colour Set:", "£100"},
                {"With 1 House:", "£200"},
                {"With 2 Houses:", "£600"},
                {"With 3 Houses:", "£1400"},
                {"With 4 Houses:", "£1700"},
                {"With Hotel:", "£2000"}
            }
        }
    },
}

local typeCheck: Types.BoardConfiguration = module
return typeCheck