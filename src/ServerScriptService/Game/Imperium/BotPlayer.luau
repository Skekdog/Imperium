local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local BotNameFormatting = require(ReplicatedFirst.Shared.BotNameFormatting)
local DisableCharacterCollision = require(script.Parent.Util.DisableCharacterCollision)
local BotCharacters = require(ServerScriptService.Shared.BotNames)
local Participant = require(script.Parent.Participant)
local Types = require(script.Parent.Types)
local module = {}

local function sortAssetPriceAscending(tbl: {[number]: Types.Asset}): ()
    table.sort(tbl, function(a, b)
        return a.AssetDescription.Price < b.AssetDescription.Price
    end)
end

local function sortAssetPriceDescending(tbl: {[number]: Types.Asset}): ()
    table.sort(tbl, function(a, b)
        return a.AssetDescription.Price > b.AssetDescription.Price
    end)
end

local function EvaluateAssetForSale(bot: Types.BotPlayer, asset: Types.Asset, to: Types.Participant): number
    return 0
end

local function EvaluateAssetForPurchase(bot: Types.BotPlayer, asset: Types.Asset, from: Types.AssetOwner): number
    return 0
end

local function EvaluateSkipJail(bot: Types.BotPlayer): boolean
    assert(bot.Participant.JailedOn ~= 0, "Participant is not jailed")
    
    local numAllAssets = 0
    local numOwnedAssets = 0
    for _, v in bot.Participant.Round.Board.Tiles do
        if v.Asset then
            numAllAssets += 1
            if v.Asset.Owner ~= "Bank" then
                numOwnedAssets += 1
            end
        end
    end

    local percentOwned = numOwnedAssets / numAllAssets
    return percentOwned < 0.8
end

local function EvaluateTrade(bot: Types.BotPlayer, tradeManager: Types.TradeManager): boolean
    return false
end

local function DecideMove(bot: Types.BotPlayer): "Dice" | "JailCard" | "Fine"
    if bot.Participant.JailedOn ~= 0 and bot:EvaluateSkipJail() then
        if bot.Participant.JailCards > 0 then
            return "JailCard"
        elseif bot.Participant:CanAfford(bot.Participant.Round.BoardConfiguration.JailFine) then
            return "Fine"
        end
    end
    return "Dice"
end

local function DecidePurchase(bot: Types.BotPlayer, asset: Types.Asset): boolean
    return true
end

local function TryBuildDevelopments(bot: Types.BotPlayer): ()
    -- We want to build on higher value properties first, because that (usually) brings more rent
    sortAssetPriceDescending(bot.Participant.Assets)

    for _, v in bot.Participant.Assets do
        if bot.Participant.Money < bot.MinimumMoneyForDeveloping then
            break
        end

        v:TryDevelopProperty("House")
        v:TryDevelopProperty("Hotel")
    end

    return
end

local function TryUnmortgageAssets(bot: Types.BotPlayer): ()
    -- We want to unmortgage higher value properties first
    sortAssetPriceDescending(bot.Participant.Assets)

    for _, v in bot.Participant.Assets do
        if bot.Participant.Money < bot.MinimumMoneyForUnmortgaging then
            break
        end
        v:TryUnMortgage()
    end

    return
end

local function TryAvoidBankruptcy(bot: Types.BotPlayer, requiredMoney: number): ()
    -- We want to sell off lower value properties first
    sortAssetPriceAscending(bot.Participant.Assets)

    for _, v in bot.Participant.Assets do
        v:TrySellAllDevelopments()
        if bot.Participant.Money >= requiredMoney then
            return
        end
    end

    for _, v in bot.Participant.Assets do
        v:TryMortgage()
        if bot.Participant.Money >= requiredMoney then
            return
        end
    end

    return
end

local function randomNegativeHalf(value: number): number
    return math.random(-value / 2, value / 2)
end

local function spawnCharacter(participant: Types.Participant, char: Model): ()
    char = char:Clone()
    participant.Character = char

    local spawn = assert(workspace:FindFirstChildWhichIsA("SpawnLocation", true), "Missing spawn location")
    char:PivotTo(spawn.CFrame + Vector3.new(randomNegativeHalf(spawn.Size.X), spawn.Size.Y + 2, randomNegativeHalf(spawn.Size.Z)))

    local hum = char:WaitForChild("Humanoid")
    assert(hum:IsA("Humanoid"), "Humanoid is not a humanoid")

    hum.WalkSpeed = StarterPlayer.CharacterWalkSpeed
    hum.JumpPower = StarterPlayer.CharacterJumpPower
    hum.JumpHeight = StarterPlayer.CharacterJumpHeight

    local animate: Script
    if hum.RigType == Enum.HumanoidRigType.R15 then
        animate = script.Parent.Util.BotAnimateR15:Clone()
    elseif hum.RigType == Enum.HumanoidRigType.R6 then
        animate = script.Parent.Util.BotAnimateR6:Clone()
    else
        error(`Unsupported rig type: {hum.RigType}`)
    end
    animate.Enabled = true
    animate.Parent = char :: any

    char.Name = participant.Player.Name
    char.Parent = workspace

    assert(char.PrimaryPart):SetNetworkOwner(nil)

    DisableCharacterCollision(char)

    char.Destroying:Connect(function()
        spawnCharacter(participant, char)
    end)
end

function module.new(round: Types.Round, name: string): Types.BotPlayer
    local index = assert(table.find(BotCharacters, name), `Missing bot {name}`)
    table.remove(BotCharacters, index)

    local char = assert(ReplicatedStorage.Shared.BotModels:FindFirstChild(name), `Missing bot model {name}`):Clone()
    assert(char:IsA("Model"), "Bot model is not a model")

    local player = Instance.new("Configuration")
    player.Name = BotNameFormatting.Format(name)
    player:SetAttribute("Status", "Spectating")
    player.Parent = Players

    local participant = Participant.new(player, round)

    spawnCharacter(participant, char)

    return {
        Participant = participant,
        Player = player,
        Model = char,

        MinimumMoneyForDeveloping = 200,
        MinimumMoneyForUnmortgaging = 250,

        EvaluateAssetForSale = EvaluateAssetForSale,
        EvaluateAssetForPurchase = EvaluateAssetForPurchase,
        EvaluateTrade = EvaluateTrade,

        EvaluateSkipJail = EvaluateSkipJail,

        DecideMove = DecideMove,
        DecidePurchase = DecidePurchase,

        TryBuildDevelopments = TryBuildDevelopments,
        TryUnmortgageAssets = TryUnmortgageAssets,
        TryAvoidBankruptcy = TryAvoidBankruptcy,
    }
end

return module