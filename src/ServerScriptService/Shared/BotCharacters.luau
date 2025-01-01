export type BotCharacter = {
    Name: string,
    UserId: number,
}

local characters: {[string]: BotCharacter} = {
    Scelly_Dog = {
        Name = "Scelly_Dog",
        UserId = 965735486,
    },
    Roblox = {
        Name = "Roblox",
        UserId = 1,
    }
}

return characters