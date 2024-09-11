local Types = require(script.Parent.Types)

local module = {}

local function TransferTo(asset: Types.Asset, to: Types.AssetOwner): ()
    asset.Owner = to
    -- auto sell()
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
    owner:TransferMoneyTo("Bank", cost)

    if development == "House" then
        asset.Houses += 1
    elseif development == "Hotel" then
        asset.Hotels += 1
    end
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

    local sellPrice = GetDevelopmentCost(asset, development) / 2
    owner:GiveMoney(sellPrice)
end

local function SellAllDevelopments(asset: Types.Asset): ()
    local owner = asset.Owner
    assert(typeof(owner) ~= "string", "The bank cannot sell developments")

    local sellPrice = (GetDevelopmentCost(asset, "House") * asset.Houses) + (GetDevelopmentCost(asset, "Hotel") * asset.Hotels)
    asset.Houses = 0
    asset.Hotels = 0

    owner:GiveMoney(sellPrice)
end

local function Mortgage(asset: Types.Asset): ()
    assert(not asset.IsMortgaged, "Asset is already mortgaged")
    assert(asset.Owner ~= "Bank", "The bank cannot mortgage")

    asset.IsMortgaged = true
    asset.Owner:GiveMoney(GetMortgageValue(asset))
end

local function UnMortgage(asset: Types.Asset): ()
    assert(asset.IsMortgaged, "Asset is not mortgaged")
    assert(asset.Owner ~= "Bank", "The bank cannot unmortgage")

    asset.IsMortgaged = false
    asset.Owner:TransferMoneyTo("Bank", GetUnMortgageCost(asset))
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
    asset.SellAllDevelopments = SellAllDevelopments

    return asset
end

return module