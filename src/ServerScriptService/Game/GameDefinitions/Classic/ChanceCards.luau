local Types = require(script.Parent.Parent.Parent.Imperium.Types)

local module = {}

module[1] = {
    Title = "Advance to 'Go'.",
    Effect = function(participant: Types.Participant): ()
        participant:MoveTo(1)
    end
}

module[2] = {
    Title = "Advance to Trafalgar Square. If you pass Go, collect £200.",
    Effect = function(participant: Types.Participant): ()
        participant:MoveToTileByName("Trafalgar Square")
    end
}

module[3] = {
    Title = "Advance to Pall Mall. If you pass Go, collect £200.",
    Effect = function(participant: Types.Participant): ()
        participant:MoveToTileByName("Pall Mall")
    end
}

module[4] = {
    Title = "Advance to the nearest Utility. If unowned, you may buy it from the Bank. If owned, throw dice and pay owner a total ten times the amount thrown.",
    Effect = function(participant: Types.Participant): ()
        local closestUtility = participant:FindClosestForwardPositionByColour("Utility")
        assert(closestUtility, "No utilities found")
        participant:MoveTo(closestUtility)
    end
}

module[5] = {
    Title = "Advance to the nearest Railroad. If unowned, you may buy it from the Bank. If owned, pay owner twice the rental to which they are otherwise entitled.",
    Effect = function(participant: Types.Participant): ()
        local closestRailroad = participant:FindClosestForwardPositionByColour("Station")
        assert(closestRailroad, "No railroads found")
        participant:MoveTo(closestRailroad)
    end
}

module[6] = {
    Title = "Bank pays you dividend of £50.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveMoney(50)
    end
}

module[7] = {
    Title = "Get Out of Jail Free. This card may be kept until needed, or traded.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveJailCards(1)
    end
}

module[8] = {
    Title = "Go Back 3 Spaces.",
    Effect = function(participant: Types.Participant): ()
        participant:MoveBy(-3)
    end
}

module[9] = {
    Title = "Go to Jail. Go directly to Jail. Do not pass Go. Do not collect £200.",
    Effect = function(participant: Types.Participant): ()
        participant:SendToJail()
    end
}

module[10] = {
    Title = "Make general repairs on all your property. For each house, pay £25. For each hotel, pay £100.",
    Effect = function(participant: Types.Participant): ()
        local houses = 0
        local hotels = 0
        for _, asset in participant.Assets do
            houses += asset.Houses
            hotels += asset.Hotels
        end

        participant:TransferMoneyTo("Bank", -((houses * 25) + (hotels * 100)))
    end
}

module[11] = {
    Title = "Take a trip to King's Cross Station. If you pass Go, collect £200.",
    Effect = function(participant: Types.Participant): ()
        participant:MoveToTileByName("King's Cross Station")
    end
}

module[12] = {
    Title = "Pay poor tax of £15.",
    Effect = function(participant: Types.Participant): ()
        participant:TransferMoneyTo("Bank", -15)
    end
}

module[13] = {
    Title = "Take a walk on the Boardwalk. Advance token to Mayfair.",
    Effect = function(participant: Types.Participant): ()
        participant:MoveToTileByName("Mayfair")
    end
}

module[14] = {
    Title = "You have been elected Chairman of the Board. Pay each player £50.",
    Effect = function(participant: Types.Participant): ()
        for _, otherParticipant in participant.Round.Participants do
            if otherParticipant ~= participant then
                participant:TransferMoneyTo(otherParticipant, 50)
            end
        end
    end
}

module[15] = {
    Title = "Your building loan matures. Collect £150.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveMoney(150)
    end
}

return module