local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local DisableCharacterCollision = require(script.Parent.DisableCharacterCollision)
local BotCharacters = require(ServerScriptService.Shared.BotCharacters)
local Participant = require(script.Parent.Participant)
local Types = require(script.Parent.Types)
local module = {}

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

    local hum = char:WaitForChild("Humanoid")
    assert(hum:IsA("Humanoid"), "Humanoid is not a humanoid")

    hum.WalkSpeed = StarterPlayer.CharacterWalkSpeed
    hum.JumpPower = StarterPlayer.CharacterJumpPower
    hum.JumpHeight = StarterPlayer.CharacterJumpHeight

    char.Name = participant.Player.Name
    char.Parent = workspace

    assert(char.PrimaryPart):SetNetworkOwner(nil)

    DisableCharacterCollision(char)

    char.Destroying:Connect(function()
        spawnCharacter(participant, char)
    end)
end

function module.new(round: Types.Round, name: string): Types.BotPlayer
    local character = assert(BotCharacters[name], `Bot character {name} does not exist`)
    BotCharacters[name] = nil

    local char = Players:CreateHumanoidModelFromUserId(character.UserId)

    local player = Instance.new("Configuration")
    player.Name = `🤖 {character.Name}` --note: don't use normal whitespace here because that messes with name formatting
    player:SetAttribute("UserId", character.UserId)
    player:SetAttribute("Status", "Spectating")
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