local Players = game:GetService("Players")
local Participant = require(script.Parent.Participant)
local Types = require(script.Parent.Types)
local module = {}

type BotCharacter = {
    Name: string,
    UserId: number,
}

local characters: {BotCharacter} = {
    {
        Name = "Scelly_Dog",
        UserId = 965735486,
    },
    {
        Name = "Roblox",
        UserId = 1,
    }
}

local function EvaluateAsset(bot: Types.BotPlayer, asset: Types.Asset): number
    return 0
end

local function EvaluateSkipJail(bot: Types.BotPlayer): boolean
    return false
end

local function DecideMove(bot: Types.BotPlayer): "Dice" | "JailCard" | "Fine"
    return "Dice"
end

local function TryBuildDevelopments(bot: Types.BotPlayer): ()
    return
end

local function TryUnmortgageAssets(bot: Types.BotPlayer): ()
    return
end

local function TryAvoidBankruptcy(bot: Types.BotPlayer): ()
    return
end

local function spawnCharacter(participant: Types.Participant, char: Model): ()
    char = char:Clone()
    participant.Character = char
    char.Parent = workspace

    char.Destroying:Connect(function()
        spawnCharacter(participant, char)
    end)
end

function module.new(round: Types.Round): Types.BotPlayer
    assert(#characters > 0, "No characters available")
    local characterIndex = math.random(1, #characters)
    local character = characters[characterIndex]
    table.remove(characters, characterIndex)

    local char = Players:CreateHumanoidModelFromUserId(character.UserId)

    local player = Instance.new("Configuration")
    player.Name = `🤖 {character.Name}`
    player:SetAttribute("UserId", character.UserId)
    player.Parent = Players

    local participant = Participant.new(player, round)

    spawnCharacter(participant, char)

    return {
        Participant = participant,
        Player = player,
        Model = char,

        EvaluateAsset = EvaluateAsset,
        EvaluateSkipJail = EvaluateSkipJail,
        DecideMove = DecideMove,
        TryBuildDevelopments = TryBuildDevelopments,
        TryUnmortgageAssets = TryUnmortgageAssets,
        TryAvoidBankruptcy = TryAvoidBankruptcy,
    }
end

return module