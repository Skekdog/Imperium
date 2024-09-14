local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPlayerName = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Shared.GetPlayerName)
local GetTime = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Shared.GetTime)
local SendNotification = require(script.Parent.Parent.SendNotification)
local SetWaitingText = require(script.Parent.Parent.SetWaitingText)
local Types = require(script.Parent.Types)

local module = {}

local function TransferTo(asset: Types.Asset, to: Types.AssetOwner): ()
    assert(to ~= asset.Owner, "Can't transfer assets to same participant")
    asset:TrySellAllDevelopments()

    if to ~= "Bank" then
        table.insert(to.Assets, asset)
    end

    if asset.Owner ~= "Bank" then
        local index = table.find(asset.Owner.Assets, asset)
        if index then
            table.remove(asset.Owner.Assets, index)
        end
    end

    local board = if asset.Owner ~= "Bank" then asset.Owner.Board elseif to ~= "Bank" then to.Board else nil
    assert(board)

    local tileModel = board:FindTileByName(asset.AssetDescription.Name).Model :: Types.EdgeTile
    tileModel.Base.BaseUI.Owner.Text = if to == "Bank" then "" else GetPlayerName(to.Player)

    asset.Owner = to
end

local function GetDevelopmentCost(asset: Types.Asset, development: "House" | "Hotel"): number
    return asset.AssetDescription.Price / (if development == "House" then 2 else 4)
end

local function GetMortgageValue(asset: Types.Asset): number
    return asset.AssetDescription.Price / 2
end

local function GetUnMortgageCost(asset: Types.Asset): number
    return (asset.AssetDescription.Price / 2) * 1.1
end

local function DevelopProperty(asset: Types.Asset, development: "House" | "Hotel"): ()
    local owner = asset.Owner
    assert(typeof(owner) ~= "string", "The bank cannot buy developments")
    
    if development == "House" then
        assert(asset.Houses < 4, "Cannot buy more than 4 houses")
    elseif development == "Hotel" then
        assert(asset.Hotels < 1, "Cannot buy more than 1 hotel")
        assert(asset.Houses == 4, "Cannot buy hotels without 4 houses")
    end

    local cost = GetDevelopmentCost(asset, development)
    owner:TransferMoneyTo("Bank", cost, true)

    if development == "House" then
        asset.Houses += 1
    elseif development == "Hotel" then
        asset.Hotels += 1
    end

    SendNotification(`[PLAYER] bought a {development} on {asset.AssetDescription.Name}.`, {owner.Player})
end

local function SellDevelopment(asset: Types.Asset): ()
    local owner = asset.Owner
    assert(typeof(owner) ~= "string", "The bank cannot sell developments")

    local development: "House" | "Hotel"
    if asset.Hotels > 0 then
        development = "Hotel"
        asset.Hotels -= 1
    elseif asset.Houses > 0 then
        development = "House"
        asset.Houses -= 1
    else
        assert(false, "No development to sell")
    end

    SendNotification(`[PLAYER] sold a {development} on {asset.AssetDescription.Name}.`, {owner.Player})

    local sellPrice = GetDevelopmentCost(asset, development) / 2
    owner:GiveMoney(sellPrice)
end

local function TrySellAllDevelopments(asset: Types.Asset): ()
    local owner = asset.Owner
    if owner == "Bank" then
        return
    end
    assert(typeof(owner) ~= "string", "The bank cannot sell all developments")

    SendNotification(`[PLAYER] sold all developments on {asset.AssetDescription.Name}.`, {owner.Player})

    local sellPrice = (GetDevelopmentCost(asset, "House") * asset.Houses) + (GetDevelopmentCost(asset, "Hotel") * asset.Hotels)
    asset.Houses = 0
    asset.Hotels = 0

    owner:GiveMoney(sellPrice)
end

local function Mortgage(asset: Types.Asset): ()
    assert(not asset.IsMortgaged, "Asset is already mortgaged")
    assert(asset.Owner ~= "Bank", "The bank cannot mortgage")

    asset.IsMortgaged = true
    asset:TrySellAllDevelopments()
    asset.Owner:GiveMoney(GetMortgageValue(asset))
end

local function UnMortgage(asset: Types.Asset): ()
    assert(asset.IsMortgaged, "Asset is not mortgaged")
    assert(asset.Owner ~= "Bank", "The bank cannot unmortgage")

    asset.IsMortgaged = false
    asset.Owner:TransferMoneyTo("Bank", GetUnMortgageCost(asset), true)

    SendNotification(`[PLAYER] unmortgaged {asset.AssetDescription.Name}`, {asset.Owner.Player})
end

local function GetRentCost(asset: Types.Asset, participant: Types.Participant): number
    if typeof(asset.AssetDescription.Rent) == "function" then
        return asset.AssetDescription.Rent(asset, participant)
    end

    local rentTable = asset.AssetDescription.Rent
    return rentTable.Houses[asset.Houses] or rentTable.Hotels[asset.Hotels] or rentTable.Default
end

local function StartAuction(asset: Types.Asset, round: Types.Round): ()
    ReplicatedStorage.Game.ServerClient.StartAuction:FireAllClients(asset.AssetDescription)

    local auctionDuration = round.GameConfiguration.AuctionTime
    SetWaitingText("Auction in progress...", auctionDuration)

    local highestBid = 0
    local highestBidder: Types.Participant?

    local endTime = GetTime() + auctionDuration

    local con: RBXScriptConnection
    con = ReplicatedStorage.Game.ClientServer.MakeBid.OnServerEvent:Connect(function(plr, property: unknown, amount: unknown)
        if property ~= asset.AssetDescription.Name then
            return
        end
        
        if typeof(amount) ~= "number" or amount <= highestBid then
            return
        end

        local participant = round:GetParticipant(plr)
        if not participant then
            return
        end

        ReplicatedStorage.Game.ServerClient.UpdateAuction:FireAllClients(participant.Player, amount)

        highestBidder = participant
        highestBid = amount

        endTime = GetTime() + auctionDuration
        SetWaitingText("Auction in progress...", auctionDuration)
    end)

    while GetTime() < endTime do
        task.wait()
    end
    
    ReplicatedStorage.Game.ServerClient.StartAuction:FireAllClients(nil)
    con:Disconnect()

    if not highestBidder then
        return
    end

    SendNotification(`[PLAYER] won the auction for {asset.AssetDescription.Name} at £{highestBid}.`, {highestBidder.Player})

    highestBidder:TransferMoneyTo("Bank", highestBid, true)
    asset:TransferTo(highestBidder)
end

function module.new(description: Types.AssetDescription): Types.Asset
    local asset = {}

    asset.IsMortgaged = false
    asset.AssetDescription = description
    asset.Owner = "Bank" :: any -- Typechecker doesn't play ball
    asset.Houses = 0
    asset.Hotels = 0

    asset.TransferTo = TransferTo
    asset.Mortgage = Mortgage
    asset.UnMortgage = UnMortgage

    asset.GetMortgageValue = GetMortgageValue
    asset.GetUnMortgageCost = GetUnMortgageCost

    asset.GetDevelopmentCost = GetDevelopmentCost
    asset.DevelopProperty = DevelopProperty
    asset.SellDevelopment = SellDevelopment
    asset.TrySellAllDevelopments = TrySellAllDevelopments

    asset.GetRentCost = GetRentCost
    asset.StartAuction = StartAuction

    return asset
end

return module