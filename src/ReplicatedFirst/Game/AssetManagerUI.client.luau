local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetManagement = require(script.Parent.AssetManagement)
local ClientTypes = require(script.Parent.ClientTypes)
local UIAnimation = require(script.Parent.Parent.Shared.UIAnimation)
local UIManager = require(script.Parent.Parent.Shared.UIManager)
local ui = UIManager.WaitForUI("AssetManager") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.AssetManager)}

local object = ui.Object
local assetList = object.AssetList
local actions = object.Actions

local revealed = false
object.Reveal.Activated:Connect(function()
    revealed = not revealed

    UIAnimation.Animate(object, TweenInfo.new(0.25), { AnchorPoint = Vector2.new(if revealed then 0 else 1, 1) })
end)

local currentAsset: string?
local clickCons: {[TextButton]: RBXScriptConnection?} = {}

local function bindToClick(button: typeof(assetList.ButtonTemplate), callback: () -> ())
    local old = clickCons[button]
    if old then
        old:Disconnect()
    end

    clickCons[button] = button.Activated:Connect(callback)
end

ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("UpdateAsset").OnClientEvent:Connect(function(asset: ClientTypes.ClientAssetView)
    local name = asset.Name

    local button = assetList:FindFirstChild("Asset_" .. name) :: typeof(assetList.ButtonTemplate)?
    if not button then
        button = assetList.ButtonTemplate:Clone()
    end
    assert(button)

    button.Text = name
    button.BackgroundColor3 = asset.Colour

    button.Name = "Asset_" .. name
    button.Visible = true
    button.Parent = assetList

    local oldCon = clickCons[button]
    if oldCon then
        oldCon:Disconnect()
    end

    clickCons[button] = button.Activated:Connect(function()
        currentAsset = name
        actions.SellAll.Text = `Sell All (£{asset.SellAllValue})`
        actions.SellAll.Visible = not not asset.SellAllValue
        bindToClick(button, function() AssetManagement.SellAll(name) end)

        if asset.HousePrice then
            actions.SellDevelopment.Text = `Sell House (£{asset.SellHouseValue})`
            actions.SellDevelopment.Visible = true
            bindToClick(button, function() AssetManagement.SellHouse(name) end)
        elseif asset.HotelPrice then
            actions.SellDevelopment.Text = `Sell Hotel (£{asset.SellHotelValue})`
            actions.SellDevelopment.Visible = true
            bindToClick(button, function() AssetManagement.SellHotel(name) end)
        end

        if asset.UnMortgageCost then
            actions.Mortgage.Text = `Unmortgage (£{asset.UnMortgageCost})`
            actions.Mortgage.Visible = true
            bindToClick(button, function() AssetManagement.Unmortgage(name) end)
        elseif asset.MortgageValue then
            actions.Mortgage.Text = `Mortgage (£{asset.MortgageValue})`
            actions.Mortgage.Visible = true
            bindToClick(button, function() AssetManagement.Mortgage(name) end)
        end
    end)
end)

ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("RemoveAsset").OnClientEvent:Connect(function(name: string)
    local button = assetList:FindFirstChild("Asset_" .. name) :: typeof(assetList.ButtonTemplate)?
    if button then
        button:Destroy()
    end

    if currentAsset == name then
        currentAsset = nil
        actions.Visible = false
    end
end)
