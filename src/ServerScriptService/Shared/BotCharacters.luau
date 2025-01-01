export type BotCharacter = {
    Name: string,
    UserId: number,
}

local characters: {[string]: BotCharacter} = {
    Phoebe = {
        Name = "Phoebe",
        UserId = 1601997909,
    },
    Al = {
        Name = "Al",
        UserId = 7434129649,
    },
    Prince = {
        Name = "Prince",
        UserId = 4857379599,
    },
    Vanessa = {
        Name = "Vanessa",
        UserId = 7254285719,
    },
    Axle = {
        Name = "Axle",
        UserId = 4857379599,
    },
    Carl = {
        Name = "Carl",
        UserId = 1439420255,
    },
    Dave = {
        Name = "Dave",
        UserId = 4151372282,
    },
    Craig = {
        Name = "Craig",
        UserId = 527327806,
    },
    Paula = {
        Name = "Paula",
        UserId = 4260822909,
    },
    Pamela = {
        Name = "Pamela",
        UserId = 3002950799,
    },
    Charity = {
        Name = "Charity",
        UserId = 1847901300,
    },
    Bob = {
        Name = "Bob",
        UserId = 156,
    }
}

return characters