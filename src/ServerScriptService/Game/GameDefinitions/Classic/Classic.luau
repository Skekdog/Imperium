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
        Asset = nil :: Types.AssetDescription?,
        OnEnter = nil :: ((Types.TileDescription, Types.Participant) -> ())?,
    },
    {
        Asset = {
            Name = "Old Kent Road",
            Colour = "Brown",
            Price = 60,
        }
    },
    {
        Name = "Community Chest",
        OnEnter = DrawCard
    },
    {
        Asset = {
            Name = "Whitechapel Road",
            Colour = "Brown",
            Price = 60,
        }
    },
    {
        Name = "Income Tax",
        OnEnter = TaxTile
    },
    {
        Asset = {
            Name = "King's Cross Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
        }
    },
    {
        Asset = {
            Name = "The Angel Islington",
            Colour = "Light Blue",
            Price = 100,
        }
    },
    {
        Name = "Chance",
        OnEnter = DrawCard
    },
    {
        Asset = {
            Name = "Euston Road",
            Colour = "Light Blue",
            Price = 100,
        }
    },
    {
        Asset = {
            Name = "Pentonville Road",
            Colour = "Light Blue",
            Price = 120,
        }
    },
    {
        Name = "Jail"
    },
    {
        Asset = {
            Name = "Pall Mall",
            Colour = "Pink",
            Price = 140,
        }
    },
    {
        Asset = {
            Name = "Electric Company",
            Colour = "Utility",
            Price = 150,
            Rent = GetRentForUtility,
        }
    },
    {
        Asset = {
            Name = "Whitehall",
            Colour = "Pink",
            Price = 140,
        }
    },
    {
        Asset = {
            Name = "Northumberland Avenue",
            Colour = "Pink",
            Price = 160,
        }
    },
    {
        Asset = {
            Name = "Marylebone Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
        }
    },
    {
        Asset = {
            Name = "Bow Street",
            Colour = "Orange",
            Price = 180,
        }
    },
    {
        Name = "Community Chest",
        OnEnter = DrawCard
    },
    {
        Asset = {
            Name = "Marlborough Street",
            Colour = "Orange",
            Price = 180,
        }
    },
    {
        Asset = {
            Name = "Vine Street",
            Colour = "Orange",
            Price = 200,
        }
    },
    {
        Name = "Free Parking"
    },
    {
        Asset = {
            Name = "Strand",
            Colour = "Red",
            Price = 220,
        }
    },
    {
        Name = "Chance",
        OnEnter = DrawCard
    },
    {
        Asset = {
            Name = "Fleet Street",
            Colour = "Red",
            Price = 220,
        }
    },
    {
        Asset = {
            Name = "Trafalgar Square",
            Colour = "Red",
            Price = 240,
        }
    },
    {
        Asset = {
            Name = "Fenchurch St Station",
            Colour = "Station",
            Price = 200,
            Rent = GetRentForStation,
        }
    },
    {
        Asset = {
            Name = "Leicester Square",
            Colour = "Yellow",
            Price = 260,
        }
    },
    {
        Asset = {
            Name = "Coventry Street",
            Colour = "Yellow",
            Price = 260,
        }
    },
    {
        Asset = {
            Name = "Water Works",
            Colour = "Utility",
            Price = 150,
            Rent = GetRentForUtility,
        }
    },
    {
        Asset = {
            Name = "Piccadilly",
            Colour = "Yellow",
            Price = 280,
        }
    },
    {
        Name = "Go to Jail",
        OnEnter = GoToJail
    },
    {
        Asset = {
            Name = "Regent Street",
            Colour = "Green",
            Price = 300,
        }
    },
    {
        Asset = {
            Name = "Oxford Street",
            Colour = "Green",
            Price = 300,
        }
    },
    {
        Name = "Community Chest",
        OnEnter = DrawCard
    },
    {
        Asset = {
            Name = "Bond Street",
            Colour = "Green",
            Price = 320,
        }
    },
    {
        Asset = {
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
        Asset = {
            Name = "Park Lane",
            Colour = "Dark Blue",
            Price = 350,
        }
    },
    {
        Name = "Super Tax",
        OnEnter = TaxTile
    },
    {
        Asset = {
            Name = "Mayfair",
            Colour = "Dark Blue",
            Price = 400,
        }
    }
}

local typeCheck: Types.BoardConfiguration = module
return typeCheck