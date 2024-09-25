local Types = require(script.Parent.Parent.Parent.Imperium.Types)

local module = {}

module[1] = {
    Title = "Advance to 'Go'.",
    Effect = function(participant: Types.Participant): ()
        participant:MoveTo(1)
    end,
}

module[2] = {
    Title = "Bank error in your favour. Collect £200.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveMoney(200)
    end,
}

module[3] = {
    Title = "Doctor's fee. Pay £50.",
    Effect = function(participant: Types.Participant): ()
        participant:TransferMoneyTo("Bank", -50)
    end,
}

module[4] = {
    Title = "From sale of stock you get £50.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveMoney(50)
    end,
}

module[5] = {
    Title = "Get out of jail free. This card may be kept until needed or sold/traded.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveJailCards(1)
    end,
}

module[6] = {
    Title = "Go to Jail. Go directly to Jail. Do not pass Go, Do not collect £200.",
    Effect = function(participant: Types.Participant): ()
        participant:SendToJail()
    end,
}

module[7] = {
    Title = "Grand Opera Night. Collect £50 from every player for opening night seats.",
    Effect = function(participant: Types.Participant): ()
        for _, otherParticipant in participant.Round.Participants do
            if otherParticipant ~= participant then
                otherParticipant:TransferMoneyTo(participant, 50)
            end
        end
    end,
}

module[8] = {
    Title = "Holiday Fund matures. Receive £100.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveMoney(100)
    end,
}

module[9] = {
    Title = "Income tax refund. Collect £20.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveMoney(20)
    end,
}

module[10] = {
    Title = "It is your birthday. Collect £10 from every player.",
    Effect = function(participant: Types.Participant): ()
        for _, otherParticipant in participant.Round.Participants do
            if otherParticipant ~= participant then
                otherParticipant:TransferMoneyTo(participant, 10)
            end
        end
    end,
}

module[11] = {
    Title = "Life insurance matures. Collect £100.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveMoney(100)
    end,
}

module[12] = {
    Title = "Hospital fees. Pay £50.",
    Effect = function(participant: Types.Participant): ()
        participant:TransferMoneyTo("Bank", -50)
    end
}

module[13] = {
    Title = "School fees. Pay £50.",
    Effect = function(participant: Types.Participant): ()
        participant:TransferMoneyTo("Bank", -50)
    end
}

module[14] = {
    Title = "Receive £25 consultancy fee.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveMoney(25)
    end
}

module[15] = {
    Title = "You are assessed for street repairs. Pay £40 per house and £115 per hotel you own.",
    Effect = function(participant: Types.Participant): ()
        local houses = 0
        local hotels = 0
        for _, asset in participant.Assets do
            houses += asset.Houses
            hotels += asset.Hotels
        end

        participant:TransferMoneyTo("Bank", -((houses * 40) + (hotels * 115)))
    end
}

module[16] = {
    Title = "You have won second prize in a beauty contest. Collect £10.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveMoney(10)
    end
}

module[17] = {
    Title = "You inherit £100.",
    Effect = function(participant: Types.Participant): ()
        participant:GiveMoney(100)
    end
}

return module