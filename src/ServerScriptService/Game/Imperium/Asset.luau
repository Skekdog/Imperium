local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local AwardBadge = require(script.Parent.Parent.AwardBadge)
local GetCurrencySymbol = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Game.GetCurrencySymbol)
local PlaySoundAtPart = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Game.PlaySoundAtPart)
local GetPlayerName = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Shared.GetPlayerName)
local GetTime = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Shared.GetTime)
local SendNotification = require(script.Parent.Parent.Parent.Shared.SendNotification)
local SetWaitingText = require(script.Parent.Parent.SetWaitingText)
local TileUtils = require(script.Parent.TileUtils)
local Types = require(script.Parent.Types)

local module = {}

local function updateAsset(participant: Types.Participant, asset: Types.Asset, round: Types.Round): ()
    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("UpdateAsset"):FireAllClients(participant.Player, asset:GetClientAssetView(round))
end

local function removeAsset(participant: Types.Participant, asset: Types.Asset): ()
    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("RemoveAsset"):FireAllClients(participant.Player, asset.AssetDescription.Name)
end

local function updateAssetsInParticipantColourGroup(participant: Types.Participant, colourGroup: string, round: Types.Round): ()
    for _, asset in participant.Assets do
        if asset.AssetDescription.Colour == colourGroup then
            updateAsset(participant, asset, round)
        end
    end
end

local function TransferTo(asset: Types.Asset, to: Types.AssetOwner): ()
    assert(to ~= asset.Owner, "Can't transfer assets to same participant")

    if to ~= "Bank" and not to.IsInGame then
        return
    end

    local round: Types.Round
    if asset.Owner ~= "Bank" then
        round = asset.Owner.Round
    else
        assert(to ~= "Bank")
        round = to.Round
    end

    if to ~= "Bank" and asset.Owner ~= "Bank" then
        SendNotification(`[PLAYER] transferred {asset.AssetDescription.Name} to [PLAYER].`, {asset.Owner.Player, to.Player})
    end

    asset:TrySellAllDevelopments()

    local colour = asset.AssetDescription.Colour
    if asset.Owner ~= "Bank" then
        removeAsset(asset.Owner, asset)
        local index = table.find(asset.Owner.Assets, asset)
        if index then
            table.remove(asset.Owner.Assets, index)
        end
        updateAssetsInParticipantColourGroup(asset.Owner, colour, round)
    end

    asset.Owner = to -- Important that we do it here otherwise updateAsset() will not account for a new monopoly

    if to ~= "Bank" then
        table.insert(to.Assets, asset)
        updateAssetsInParticipantColourGroup(to, colour, round)

        task.defer(function() -- Defer so that if TransferTo() is called in a loop we don't award the badge erroneously
            local shouldAward = true
            for _, tile in round.Board.Tiles do
                local new = tile.Asset
                if not new then
                    continue
                end

                if new.Owner ~= to then
                    shouldAward = false
                    break
                end
            end

            if shouldAward then
                AwardBadge(to.Player, "Monopoly")
            end
        end)
    end

    local board = round.Board

    local tileModel = board:FindTileByName(asset.AssetDescription.Name).Model :: Types.EdgeTile
    local label = tileModel.BaseUIPart.BaseUI.Owner

    label:SetAttribute("Player_1", if to == "Bank" then nil else GetPlayerName(to.Player))
    label:SetAttribute("Format", if to == "Bank" then "" else "[PLAYER]")
    label:AddTag("DynamicNames")
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
    return math.round(asset.AssetDescription.Price / 2)
end

local function GetUnMortgageCost(asset: Types.Asset): number
    return math.round((asset.AssetDescription.Price / 2) * 1.1)
end

local function CanMakeDevelopment(asset: Types.Asset, development: "House" | "Hotel", ignoreCost: boolean?): (boolean, number)
    if asset.Owner == "Bank" then
        return false, 0
    end

    local cost = TryGetDevelopmentCost(asset, development, asset.Owner.Round.BoardConfiguration)
    if not ignoreCost and (not cost or not asset.Owner:CanAfford(cost)) then
        return false, 0
    end

    if asset.IsMortgaged then
        return false, 0
    end

    if development == "House" and asset.Houses >= 4 then
        return false, 0
    elseif development == "Hotel" and (asset.Hotels >= 1 or asset.Houses < 4) then
        return false, 0
    end

    if not asset.Owner:HasMonopoly(asset.AssetDescription.Colour) then
        return false, 0
    end

    for _, v in asset.Owner.Assets do
        if v.AssetDescription.Colour == asset.AssetDescription.Colour then
            if v.IsMortgaged then
                return false, 0
            elseif development == "House" and v.Houses < asset.Houses then
                return false, 0
            elseif development == "Hotel" and (v.Hotels < asset.Hotels or v.Houses < asset.Houses) then
                return false, 0
            end
        end
    end

    return true, cost
end

local function CanUnmakeDevelopment(asset: Types.Asset, development: "House" | "Hotel"): boolean
    if asset.Owner == "Bank" or asset.IsMortgaged or not asset.Owner:HasMonopoly(asset.AssetDescription.Colour) then
        return false
    end

    for _, v in asset.Owner.Assets do
        if v.AssetDescription.Colour == asset.AssetDescription.Colour then
            if development == "House" and (v.Houses > asset.Houses or v.Hotels > asset.Hotels) then
                return false
            elseif development == "Hotel" and v.Hotels > asset.Hotels then
                return false
            end
        end
    end

    return true
end

local animateDevelopmentRemote = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("AnimateDevelopmentModel")
function tryRemoveDevelopmentModel(asset: Types.Asset, development: "House" | "Hotel", index: number, playSound: boolean, shouldReplaceWithHouses: boolean): ()
    assert(asset.Owner ~= "Bank", "The bank cannot buy developments")
    local tile = asset.Owner.Round.Board:FindTileByName(asset.AssetDescription.Name)

    local name = development .. tostring(index)

    local model = (tile :: any).Model:FindFirstChild(name) :: Model?
    if not model then
        return
    end

    local heightOffset = Vector3.new(0, model:GetExtentsSize().Y, 0)
    local targetCFrame = model:GetPivot() - heightOffset

    animateDevelopmentRemote:FireAllClients(model, targetCFrame)

    if development == "Hotel" and shouldReplaceWithHouses then
        for i = 1, asset.Houses do
            addDevelopmentModel(asset, "House", i, false)
        end
    end

    if playSound then
        PlaySoundAtPart("Construction", (tile :: any).Model.Base)
    end

    task.delay(1.5, model.Destroy, model)
end

function addDevelopmentModel(asset: Types.Asset, development: "House" | "Hotel", index: number, playSound: boolean): ()
    assert(asset.Owner ~= "Bank", "The bank cannot buy developments")
    local tile = asset.Owner.Round.Board:FindTileByName(asset.AssetDescription.Name)

    local model = (if development == "House" then ServerStorage.Game.House:Clone() else ServerStorage.Game.Hotel:Clone()) :: Model

    local attachmentName = development .. tostring(index)
    local attachment = (tile :: any).Model.Base:FindFirstChild(attachmentName) :: Attachment or error(`Failed to find Attachment {attachmentName}`)

    if development == "Hotel" then
        for i = 1, asset.Houses do
            tryRemoveDevelopmentModel(asset, "House", i, false, false)
        end
    end

    local targetCFrame = attachment.WorldCFrame

    local heightOffset = Vector3.new(0, model:GetExtentsSize().Y, 0)
    local adjustedCFrame = targetCFrame + (heightOffset / 2)

    model:PivotTo(targetCFrame - heightOffset)

    model.Name = attachmentName
    model.Parent = tile.Model
    animateDevelopmentRemote:FireAllClients(model, adjustedCFrame)

    if playSound then
        PlaySoundAtPart("Construction", (tile :: any).Model.Base)
    end

    task.delay(1.5, model.PivotTo, model, adjustedCFrame)
end

local function TryDevelopProperty(asset: Types.Asset, development: "House" | "Hotel"): ()
    local owner = asset.Owner
    assert(typeof(owner) ~= "string", "The bank cannot buy developments")

    local canMake, cost = CanMakeDevelopment(asset, development)

    if not canMake then
        return
    end

    owner:TransferMoneyTo("Bank", cost, true)

    if development == "House" then
        asset.Houses += 1
        addDevelopmentModel(asset, development, asset.Houses, true)
    elseif development == "Hotel" then
        asset.Hotels += 1
        addDevelopmentModel(asset, development, asset.Hotels, true)
    end

    SendNotification(`[PLAYER] bought a {development} on {asset.AssetDescription.Name}.`, {owner.Player})
    updateAssetsInParticipantColourGroup(owner, asset.AssetDescription.Colour, owner.Round)
end

local function TrySellDevelopment(asset: Types.Asset): ()
    local owner = asset.Owner
    assert(typeof(owner) ~= "string", "The bank cannot sell developments")

    local development: "House" | "Hotel"
    if asset.Hotels > 0 then
        development = "Hotel"
    elseif asset.Houses > 0 then
        development = "House"
    else
        return
    end

    if not CanUnmakeDevelopment(asset, development) then
        return
    end

    if development == "Hotel" then
        tryRemoveDevelopmentModel(asset, development, asset.Hotels, true, true)
        asset.Hotels -= 1
    elseif development == "House" then
        tryRemoveDevelopmentModel(asset, development, asset.Houses, true, false)
        asset.Houses -= 1
    end

    updateAssetsInParticipantColourGroup(owner, asset.AssetDescription.Colour, owner.Round)
    SendNotification(`[PLAYER] sold a {development} on {asset.AssetDescription.Name}.`, {owner.Player})

    local sellPrice = TryGetDevelopmentSellValue(asset, development, owner.Round.BoardConfiguration)
    if not sellPrice then
        return
    end
    owner:GiveMoney(sellPrice)
end

local function getSellAllValue(asset: Types.Asset): number
    local owner = asset.Owner
    assert(typeof(owner) ~= "string", "The bank cannot sell all developments")

    local boardConfiguration = owner.Round.BoardConfiguration

    local totalSellPrice = 0
    for _, v in owner.Assets do
        if v.AssetDescription.Colour ~= asset.AssetDescription.Colour then
            continue
        end

        local houseCost = TryGetDevelopmentSellValue(v, "House", boardConfiguration)
        local hotelCost = TryGetDevelopmentSellValue(v, "Hotel", boardConfiguration)
        if not houseCost or not hotelCost then
            continue
        end

        local sellPrice = (houseCost * v.Houses) + (hotelCost * v.Hotels)

        totalSellPrice += sellPrice
    end

    return totalSellPrice
end

local function TrySellAllDevelopments(asset: Types.Asset): ()
    local owner = asset.Owner
    if owner == "Bank" then
        return
    end
    assert(typeof(owner) ~= "string", "The bank cannot sell all developments")

    local totalSellPrice = getSellAllValue(asset)
    for _, v in owner.Assets do
        if v.AssetDescription.Colour ~= asset.AssetDescription.Colour then
            continue
        end

        for i = 1, v.Houses do
            tryRemoveDevelopmentModel(v, "House", i, true, false)
        end

        for i = 1, v.Hotels do
            tryRemoveDevelopmentModel(v, "Hotel", i, true, false)
        end

        v.Houses = 0
        v.Hotels = 0
    end

    if totalSellPrice > 0 then
        SendNotification(`[PLAYER] sold all developments on {asset.AssetDescription.Colour} for {GetCurrencySymbol()}{totalSellPrice}.`, {owner.Player})
    end

    owner:GiveMoney(totalSellPrice)
    updateAssetsInParticipantColourGroup(owner, asset.AssetDescription.Colour, owner.Round)
end

local function TryMortgage(asset: Types.Asset): ()
    assert(asset.Owner ~= "Bank", "The bank cannot mortgage")

    if asset.IsMortgaged then
        return
    end

    for _, v in asset.Owner.Assets do
        if v.AssetDescription.Colour == asset.AssetDescription.Colour and v:HasAnyDevelopments() then
            return
        end
    end

    asset.IsMortgaged = true

    local tile = asset.Owner.Round.Board:TryFindTileByName(asset.AssetDescription.Name)
    assert(tile, "Asset is not on a tile");

    (tile.Model :: Types.EdgeTile).Title.TitleUI.TextLabel.Text = `{asset.AssetDescription.Name}\n(MORTGAGED)`

    local value = GetMortgageValue(asset)
    asset.Owner:GiveMoney(value)
    SendNotification(`[PLAYER] mortgaged {asset.AssetDescription.Name} for {GetCurrencySymbol()}{value}.`, {asset.Owner.Player})
    updateAssetsInParticipantColourGroup(asset.Owner, asset.AssetDescription.Colour, asset.Owner.Round)
end

local function TryUnMortgage(asset: Types.Asset): ()
    assert(asset.Owner ~= "Bank", "The bank cannot unmortgage")

    if not asset.IsMortgaged then
        return
    end

    asset.IsMortgaged = false

    local tile = asset.Owner.Round.Board:TryFindTileByName(asset.AssetDescription.Name)
    assert(tile, "Asset is not on a tile");

    (tile.Model :: Types.EdgeTile).Title.TitleUI.TextLabel.Text = `{asset.AssetDescription.Name}`

    local value = GetUnMortgageCost(asset)
    asset.Owner:TransferMoneyTo("Bank", value, true)
    SendNotification(`[PLAYER] unmortgaged {asset.AssetDescription.Name} for {GetCurrencySymbol()}{value}.`, {asset.Owner.Player})
    updateAssetsInParticipantColourGroup(asset.Owner, asset.AssetDescription.Colour, asset.Owner.Round)
end

local function HasAnyDevelopments(asset: Types.Asset): boolean
    return asset.Houses > 0 or asset.Hotels > 0
end

local function GetRentCost(asset: Types.Asset, participant: Types.Participant): number
    if asset.IsMortgaged then
        return 0
    end
    
    if typeof(asset.AssetDescription.Rent) == "function" then
        return asset.AssetDescription.Rent(asset, participant)
    end

    local rentTable = asset.AssetDescription.Rent
    local rent = rentTable.Hotels[asset.Hotels] or rentTable.Houses[asset.Houses] or rentTable.Default

    if asset.Owner ~= "Bank" and asset.Owner:HasMonopoly(asset.AssetDescription.Colour) and not asset:HasAnyDevelopments() then
        rent *= 2
    end

    return rent
end

local function StartAuction(asset: Types.Asset, round: Types.Round, transferToBankIfNoWinner: boolean?): ()
    print("starting auction server")
    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("StartAuction"):FireAllClients(asset.AssetDescription)

    local auctionDuration = round.GameConfiguration.AuctionTime
    SetWaitingText("Auction in progress...", auctionDuration)

    local highestBid = 0
    local highestBidder: Types.Participant?

    local endTime = GetTime() + auctionDuration

    local con: RBXScriptConnection
    con = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ClientServer"):WaitForChild("MakeBid").OnServerEvent:Connect(function(plr, property: unknown, amount: unknown)
        if property ~= asset.AssetDescription.Name then
            return
        end
        
        if typeof(amount) ~= "number" or amount <= highestBid then
            return
        end

        local participant = round:TryGetParticipant(plr)
        if not participant or not participant:CanAfford(amount) then
            return
        end

        if highestBidder == participant then
            return
        end

        assert(participant ~= asset.Owner, `Player {participant.Player.Name} tried to bid on their own property?`)

        ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("UpdateAuction"):FireAllClients(participant.Player, amount)

        highestBidder = participant
        highestBid = amount

        endTime = GetTime() + auctionDuration
        SetWaitingText("Auction in progress...", auctionDuration)
    end)

    while GetTime() < endTime do
        task.wait()
    end
    
    print("stopping auction server")
    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("StartAuction"):FireAllClients(nil)
    con:Disconnect()

    if not highestBidder or not highestBidder.IsInGame then
        if transferToBankIfNoWinner then
            asset:TransferTo("Bank")
        end
        return
    end

    assert(highestBidder ~= asset.Owner, `Player {highestBidder.Player.Name} somehow bid on their own property?`)

    SendNotification(`[PLAYER] won the auction for {asset.AssetDescription.Name} at {GetCurrencySymbol()}{highestBid}.`, {highestBidder.Player})

    highestBidder:TransferMoneyTo("Bank", highestBid, true)
    asset:TransferTo(highestBidder)
end

local function GetClientAssetView(asset: Types.Asset, round: Types.Round): Types.ClientAssetView
    local tile = round.Board:TryFindTileByName(asset.AssetDescription.Name)
    assert(tile, "Asset is not on a tile")

    local view = {
        Name = asset.AssetDescription.Name,
        Colour = TileUtils.GetColor3(tile.TileDescription, round),
        Position = tile.Position,
    }

    if asset.IsMortgaged then
        view.UnMortgageCost = GetUnMortgageCost(asset)
    else
        view.MortgageValue = GetMortgageValue(asset)
    end

    local canMakeHotel, hotelCost = CanMakeDevelopment(asset, "Hotel", true)
    local canMakeHouse, houseCost = CanMakeDevelopment(asset, "House", true)
    if canMakeHotel then
        view.HotelPrice = hotelCost
    elseif canMakeHouse then
        view.HousePrice = houseCost
    end

    if asset.Hotels > 0 and CanUnmakeDevelopment(asset, "Hotel") then
        view.SellHotelValue = TryGetDevelopmentSellValue(asset, "Hotel", round.BoardConfiguration)
    elseif asset.Houses > 0 and CanUnmakeDevelopment(asset, "House") then
        view.SellHouseValue = TryGetDevelopmentSellValue(asset, "House", round.BoardConfiguration)
    end

    local sellAllValue = getSellAllValue(asset)

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

    asset.CanMakeDevelopment = CanMakeDevelopment
    asset.CanUnmakeDevelopment = CanUnmakeDevelopment

    asset.HasAnyDevelopments = HasAnyDevelopments

    return asset
end

return module