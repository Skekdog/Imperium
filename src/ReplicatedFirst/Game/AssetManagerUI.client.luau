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

local function bindToClick(button: TextButton, callback: () -> ())
    local old = clickCons[button]
    if old then
        old:Disconnect()
    end

    clickCons[button] = button.Activated:Connect(callback)
end

local function closeActions(): ()
    currentAsset = nil
    actions.Visible = false
end

local function updateView(asset: ClientTypes.ClientAssetView): ()
    local name = asset.Name
    if currentAsset ~= name then
        return
    end

    for _, v in actions:GetChildren() do
        if v:IsA("TextButton") and v.Name ~= "Close" then
            v.Visible = false
        end
    end

    if asset.SellAllValue then
        actions.SellAll.Text = `Sell All (£{asset.SellAllValue})`
        actions.SellAll.Visible = true
        bindToClick(actions.SellAll, function() AssetManagement.SellAll(name) end)
    end

    if asset.SellHotelValue then
        actions.SellDevelopment.Text = `Sell Hotel (£{asset.SellHotelValue})`
        actions.SellDevelopment.Visible = true
        bindToClick(actions.SellDevelopment, function() AssetManagement.SellHotel(name) end)
    elseif asset.SellHouseValue then
        actions.SellDevelopment.Text = `Sell House (£{asset.SellHouseValue})`
        actions.SellDevelopment.Visible = true
        bindToClick(actions.SellDevelopment, function() AssetManagement.SellHouse(name) end)
    end

    if asset.HousePrice then
        actions.BuyDevelopment.Text = `Buy House (£{asset.HousePrice})`
        actions.BuyDevelopment.Visible = true
        bindToClick(actions.BuyDevelopment, function() AssetManagement.BuyHouse(name, asset.HousePrice) end)
    elseif asset.HotelPrice then
        actions.BuyDevelopment.Text = `Buy Hotel (£{asset.HotelPrice})`
        actions.BuyDevelopment.Visible = true
        bindToClick(actions.BuyDevelopment, function() AssetManagement.BuyHotel(name, asset.HotelPrice) end)
    end

    if asset.UnMortgageCost then
        actions.Mortgage.Text = `Unmortgage (£{asset.UnMortgageCost})`
        actions.Mortgage.Visible = true
        bindToClick(actions.Mortgage, function() AssetManagement.Unmortgage(name, asset.UnMortgageCost) end)
    elseif asset.MortgageValue then
        actions.Mortgage.Text = `Mortgage (£{asset.MortgageValue})`
        actions.Mortgage.Visible = true
        bindToClick(actions.Mortgage, function() AssetManagement.Mortgage(name) end)
    end
end

bindToClick(actions.Close, closeActions)

local function selectAsset(button: typeof(assetList.ButtonTemplate), name: string, asset: ClientTypes.ClientAssetView): ()
    if currentAsset == name then
        button.UIStroke.Enabled = false
        return closeActions()
    end

    for _, v in assetList:GetChildren() do
        if v:IsA("TextButton") then
            local vButton = v :: typeof(assetList.ButtonTemplate)
            vButton.UIStroke.Enabled = vButton == button
        end
    end

    actions.Visible = true
    currentAsset = name

    updateView(asset)
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

    updateView(asset)

    bindToClick(button, function()
        selectAsset(button, name, asset)
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

ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("GoBankrupt").OnClientEvent:Connect(function()
    ui:ToggleVisible(false)
end)