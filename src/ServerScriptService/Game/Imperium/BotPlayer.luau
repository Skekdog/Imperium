local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local BotNameFormatting = require(ReplicatedStorage.Shared.BotNameFormatting)
local DisableCharacterCollision = require(script.Parent.Util.DisableCharacterCollision)
local BotCharacters = require(ServerScriptService.Shared.BotNames)
local Participant = require(script.Parent.Participant)
local Types = require(script.Parent.Types)

local JAIL_CARD_VALUE_MULTIPLIER = 0.8

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

local function groupAssetsByColour(assets: {Types.Asset}): {[string]: {Types.Asset}}
    local groupedAssets: {[string]: {Types.Asset}} = {}
    for _, asset in assets do
        local colour = asset.AssetDescription.Colour
        if not groupedAssets[colour] then
            groupedAssets[colour] = {}
        end
        table.insert(groupedAssets[colour], asset)
    end
    return groupedAssets
end

local function getOwnedAssetsInSet(set: {Types.Asset}, participant: Types.Participant): number
    local count = 0

    for _, asset in set do
        if asset.Owner == participant then
            count += 1
        end
    end

    return count
end

local function canAssetBeDeveloped(participant: Types.Participant, asset: Types.Asset): boolean
    return not not participant.Round.BoardConfiguration.HousePrices[asset.AssetDescription.Colour]
end

local function baseAssetMultiplier(participant: Types.Participant, asset: Types.Asset): number
    local multiplier = 1
    if asset.IsMortgaged then
        multiplier -= 0.1
    end

    local canBeDeveloped = canAssetBeDeveloped(participant, asset)

    if not canBeDeveloped then
        multiplier -= 0.2 -- Assets we can't build on are less valuable
    else
        multiplier += 0.1
        for i = 1, asset.Houses do
            multiplier += 0.1
        end

        for i = 1, asset.Hotels do
            multiplier += 0.2
        end
    end

    local set = participant.Board:GetAllAssetsInColourGroup(asset.AssetDescription.Colour)
    local ownedCount = getOwnedAssetsInSet(set, participant)
    local totalCount = #set

    if ownedCount >= totalCount - 1 then
        multiplier += if canBeDeveloped then 3 else 1.5
    else
        local ownedPercent = ownedCount / totalCount
        multiplier += ownedPercent * if canBeDeveloped then 2 else 1.2
    end

    return multiplier
end

local function EvaluateAssetForSale(bot: Types.BotPlayer, asset: Types.Asset, to: Types.Participant): number
    return module.GetAssetValueForSaleTo(bot.Participant, asset, to)
end

local function EvaluateAssetForPurchase(bot: Types.BotPlayer, asset: Types.Asset, from: Types.AssetOwner): number
    return module.GetAssetValueForPurchaseFrom(bot.Participant, asset, from)
end

local validBids = {1, 10, 50, 100}
local function GetAuctionBid(bot: Types.BotPlayer, asset: Types.Asset, currentBid: number, currentWinner: Types.Participant?): number?
    local valuation = bot:EvaluateAssetForPurchase(asset, currentWinner or "Bank")
    if valuation < currentBid then
        return nil -- the price is rice, don't buy
    end

    local availableMoney = bot.Participant.Money - currentBid
    if availableMoney <= 0 then
        return nil
    end

    local highestBid = 0
    for _, bid in validBids do
        if bid <= availableMoney and bid > highestBid and currentBid + bid <= valuation then
            highestBid = bid
        end
    end

    return if highestBid > 0 then highestBid else nil
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
    local trade = assert(tradeManager.Trade, "TradeManager has no trade")

    local them = tradeManager:GetOtherParticipant()

    local outgoingOffer = trade.Offers[bot.Participant]
    local totalOutgoingValue = outgoingOffer.Money + (outgoingOffer.JailCards * bot.Participant.Round.BoardConfiguration.JailFine * JAIL_CARD_VALUE_MULTIPLIER)
    for _, v in outgoingOffer.Assets do
        totalOutgoingValue += bot:EvaluateAssetForSale(v, them)
    end

    local incomingOffer = trade.Offers[them]
    local totalIncomingValue = incomingOffer.Money + (incomingOffer.JailCards * them.Round.BoardConfiguration.JailFine * JAIL_CARD_VALUE_MULTIPLIER)
    for _, v in incomingOffer.Assets do
        totalIncomingValue += bot:EvaluateAssetForPurchase(v, them)
    end

    print(`{bot.Player.Name} evaluates {them.Player.Name}'s trade as Incoming: {totalIncomingValue} and Outgoing: {totalOutgoingValue}.`)
    return totalIncomingValue > totalOutgoingValue
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
    return bot:EvaluateAssetForPurchase(asset, "Bank") / asset.AssetDescription.Price > 0.75
end

local function TryBuildDevelopments(bot: Types.BotPlayer): ()
    -- We want to build on higher value properties first, because that (usually) brings more rent
    sortAssetPriceDescending(bot.Participant.Assets)

    local groupedAssets = groupAssetsByColour(bot.Participant.Assets)
    for _, assets in groupedAssets do
        local cantDevelopAgain = false
        repeat
            for _, asset in assets do
                if bot.Participant.Money < bot.MinimumMoneyForDeveloping then
                    cantDevelopAgain = true
                    break
                end

                asset:TryDevelopProperty("House")
                asset:TryDevelopProperty("Hotel")

                if not asset:CanMakeDevelopment("House") then -- don't need to check for hotel here because we would have already made it
                    cantDevelopAgain = true
                end
            end
        until cantDevelopAgain
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

    -- Mortgage stuff first because it's cheaper to do that
    for _, v in bot.Participant.Assets do
        v:TryMortgage()
        if bot.Participant.Money >= requiredMoney then
            return
        end
    end

    local groupedAssets = groupAssetsByColour(bot.Participant.Assets)

    for _, assets in groupedAssets do
        local cantSellAgain = false
        repeat
            for _, asset in assets do
                asset:TrySellDevelopment()
                if bot.Participant.Money >= requiredMoney then
                    return
                end

                if not asset:HasAnyDevelopments() then
                    cantSellAgain = true
                end
            end
        until cantSellAgain
    end

    return
end

local function FinishTurn(bot: Types.BotPlayer): ()
    bot:TryUnmortgageAssets()
    bot:TryBuildDevelopments()
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

function module.GetAssetValueForPurchaseFrom(participant: Types.Participant, asset: Types.Asset, from: Types.AssetOwner): number
    local multiplier = baseAssetMultiplier(participant, asset)

    if from ~= "Bank" then
        multiplier += 0.1 -- depriving people of things is good
        local set = participant.Board:GetAllAssetsInColourGroup(asset.AssetDescription.Colour)
        local countOwnedByFrom = getOwnedAssetsInSet(set, from)
        local countTotal = #set

        if countOwnedByFrom == countTotal then
            multiplier += 2 -- if we can deprive them of a set, great!
        end
    end

    -- If we have more money we are happy to spend a little more. If not we should be a little stingy.
    local relativePrice = participant.Money / asset.AssetDescription.Price
    if relativePrice < 2 then
        multiplier -= 1 / relativePrice / 3
    else
        multiplier += relativePrice / 10
    end

    print(`{participant.Player.Name} evaluates {asset.AssetDescription.Name} for purchasing {asset.AssetDescription.Price * multiplier} from {if from == "Bank" then "the Bank" else from.Player.Name}. Normal price {asset.AssetDescription.Price}.`)

    return asset.AssetDescription.Price * multiplier
end

function module.GetAssetValueForSaleTo(participant: Types.Participant, asset: Types.Asset, to: Types.Participant): number
    local multiplier = baseAssetMultiplier(participant, asset)

    local set = participant.Board:GetAllAssetsInColourGroup(asset.AssetDescription.Colour)
    local countOwnedByTo = getOwnedAssetsInSet(set, to)
    local countTotal = #set

    if countOwnedByTo >= countTotal - 1 then
        multiplier += 2 -- this asset is more valuable to them if they get a set for it
    end

    -- If they have more money we can squeeze them more
    local relativePrice = to.Money / asset.AssetDescription.Price
    if relativePrice > 1.5 then
        multiplier += relativePrice / 15
    end

    print(`{participant.Player.Name} evaluates {asset.AssetDescription.Name} for selling {asset.AssetDescription.Price * multiplier} to {to.Player.Name}. Normal price {asset.AssetDescription.Price}.`)

    return asset.AssetDescription.Price * multiplier
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

        MinimumMoneyForDeveloping = 400,
        MinimumMoneyForUnmortgaging = 450,

        FinishTurn = FinishTurn,

        GetAuctionBid = GetAuctionBid,

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