local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPlayerName = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Shared.GetPlayerName)
local GetTime = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Shared.GetTime)
local SendNotification = require(script.Parent.Parent.Parent.Shared.SendNotification)
local SetWaitingText = require(script.Parent.Parent.SetWaitingText)
local TileUtils = require(script.Parent.TileUtils)
local Types = require(script.Parent.Types)

local module = {}

local function updateAsset(participant: Types.Participant, asset: Types.Asset, round: Types.Round): ()
    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("UpdateAsset"):FireClient(participant.Player, asset:GetClientAssetView(round))
end

local function removeAsset(participant: Types.Participant, asset: Types.Asset): ()
    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("RemoveAsset"):FireClient(participant.Player, asset.AssetDescription.Name)
end

local function TransferTo(asset: Types.Asset, to: Types.AssetOwner): ()
    assert(to ~= asset.Owner, "Can't transfer assets to same participant")

    local round: Types.Round
    if asset.Owner ~= "Bank" then
        round = asset.Owner.Round
    else
        assert(to ~= "Bank")
        round = to.Round
    end

    asset:TrySellAllDevelopments()

    if to ~= "Bank" then
        updateAsset(to, asset, round)
        table.insert(to.Assets, asset)
    end

    if asset.Owner ~= "Bank" then
        removeAsset(asset.Owner, asset)
        local index = table.find(asset.Owner.Assets, asset)
        if index then
            table.remove(asset.Owner.Assets, index)
        end
    end

    local board = round.Board

    local tileModel = board:FindTileByName(asset.AssetDescription.Name).Model :: Types.EdgeTile
    tileModel.BaseUIPart.BaseUI.Owner.Text = if to == "Bank" then "" else GetPlayerName(to.Player):gsub(" ", "\n")

    asset.Owner = to
end

local function TryGetDevelopmentCost(asset: Types.Asset, development: "House" | "Hotel", boardConfiguration: Types.BoardConfiguration): number?
    return boardConfiguration.HousePrices[asset.AssetDescription.Colour]
end

local function TryGetDevelopmentSellValue(asset: Types.Asset, development: "House" | "Hotel", boardConfiguration: Types.BoardConfiguration): number?
    local cost = TryGetDevelopmentCost(asset, development, boardConfiguration)
    if cost then
        return cost / 2
    end
    return
end

local function GetMortgageValue(asset: Types.Asset): number
    return asset.AssetDescription.Price / 2
end

local function GetUnMortgageCost(asset: Types.Asset): number
    return (asset.AssetDescription.Price / 2) * 1.1
end

local function TryDevelopProperty(asset: Types.Asset, development: "House" | "Hotel"): ()
    local owner = asset.Owner
    assert(typeof(owner) ~= "string", "The bank cannot buy developments")
    
    if development == "House" and asset.Houses >= 4 then
        return
    elseif development == "Hotel" and (asset.Hotels >= 1 or asset.Houses < 4) then
        return
    end

    local cost = TryGetDevelopmentCost(asset, development, owner.Round.BoardConfiguration)
    if not cost then
        return
    end
    owner:TransferMoneyTo("Bank", cost, true)

    if development == "House" then
        asset.Houses += 1
    elseif development == "Hotel" then
        asset.Hotels += 1
    end

    SendNotification(`[PLAYER] bought a {development} on {asset.AssetDescription.Name}.`, {owner.Player})
    updateAsset(owner, asset, owner.Round)
end

local function TrySellDevelopment(asset: Types.Asset): ()
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
        return
    end

    local sellPrice = TryGetDevelopmentSellValue(asset, development, owner.Round.BoardConfiguration)
    if not sellPrice then
        return
    end

    SendNotification(`[PLAYER] sold a {development} on {asset.AssetDescription.Name}.`, {owner.Player})
    owner:GiveMoney(sellPrice)
    updateAsset(owner, asset, owner.Round)
end

local function TrySellAllDevelopments(asset: Types.Asset): ()
    local owner = asset.Owner
    if owner == "Bank" then
        return
    end
    assert(typeof(owner) ~= "string", "The bank cannot sell all developments")

    local boardConfiguration = owner.Round.BoardConfiguration
    local houseCost = TryGetDevelopmentSellValue(asset, "House", boardConfiguration)
    local hotelCost = TryGetDevelopmentSellValue(asset, "Hotel", boardConfiguration)
    if not houseCost or not hotelCost then
        return
    end

    local sellPrice = (houseCost * asset.Houses) + (hotelCost * asset.Hotels)
    asset.Houses = 0
    asset.Hotels = 0

    if sellPrice > 0 then
        SendNotification(`[PLAYER] sold all developments on {asset.AssetDescription.Name}.`, {owner.Player})
    end

    owner:GiveMoney(sellPrice)
    updateAsset(owner, asset, owner.Round)
end

local function TryMortgage(asset: Types.Asset): ()
    assert(not asset.IsMortgaged, "Asset is already mortgaged")
    assert(asset.Owner ~= "Bank", "The bank cannot mortgage")

    asset.IsMortgaged = true
    asset:TrySellAllDevelopments()
    asset.Owner:GiveMoney(GetMortgageValue(asset))
end

local function TryUnMortgage(asset: Types.Asset): ()
    assert(asset.IsMortgaged, "Asset is not mortgaged")
    assert(asset.Owner ~= "Bank", "The bank cannot unmortgage")

    asset.IsMortgaged = false
    asset.Owner:TransferMoneyTo("Bank", GetUnMortgageCost(asset), true)

    SendNotification(`[PLAYER] unmortgaged {asset.AssetDescription.Name}`, {asset.Owner.Player})
    updateAsset(asset.Owner, asset, asset.Owner.Round)
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

        local participant = round:TryGetParticipant(plr)
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

local function GetClientAssetView(asset: Types.Asset, round: Types.Round): Types.ClientAssetView
    local tile = round.Board:TryFindTileByName(asset.AssetDescription.Name)
    assert(tile, "Asset is not on a tile")

    local view = {
        Name = asset.AssetDescription.Name,
        Colour = TileUtils.GetColor3(tile.TileDescription, round),
    }

    if asset.IsMortgaged then
        view.UnMortgageCost = GetUnMortgageCost(asset)
    else
        view.MortgageValue = GetMortgageValue(asset)
    end

    if asset.Houses == 4 then
        view.HotelPrice = TryGetDevelopmentCost(asset, "Hotel", round.BoardConfiguration)
    elseif asset.Hotels < 1 then
        view.HousePrice = TryGetDevelopmentCost(asset, "House", round.BoardConfiguration)
    end

    local sellAllValue = 0
    if asset.Houses > 0 then
        local value = TryGetDevelopmentSellValue(asset, "House", round.BoardConfiguration)
        if value then
            for i = 0, asset.Houses do
                sellAllValue += value
            end
    
            if asset.Hotels < 1 then
                view.SellHouseValue = value
            end
        end
    end
    if asset.Hotels > 0 then
        local value = TryGetDevelopmentSellValue(asset, "Hotel", round.BoardConfiguration)
        if value then
            for i = 0, asset.Hotels do
                sellAllValue += value
            end
            view.SellHotelValue = value
        end
    end

    if sellAllValue > 0 then
        view.SellAllValue = sellAllValue
    end

    return view
end

function module.new(description: Types.AssetDescription): Types.Asset
    local asset = {}

    asset.IsMortgaged = false
    asset.AssetDescription = description
    asset.Owner = "Bank" :: any -- Typechecker doesn't play ball
    asset.Houses = 0
    asset.Hotels = 0

    asset.TransferTo = TransferTo
    asset.TryMortgage = TryMortgage
    asset.TryUnMortgage = TryUnMortgage

    asset.GetMortgageValue = GetMortgageValue
    asset.GetUnMortgageCost = GetUnMortgageCost

    asset.TryGetDevelopmentCost = TryGetDevelopmentCost
    asset.TryDevelopProperty = TryDevelopProperty
    asset.TrySellDevelopment = TrySellDevelopment
    asset.TrySellAllDevelopments = TrySellAllDevelopments

    asset.GetRentCost = GetRentCost
    asset.StartAuction = StartAuction

    asset.GetClientAssetView = GetClientAssetView
    asset.TryGetDevelopmentSellValue = TryGetDevelopmentSellValue

    return asset
end

return module