local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetManagement = require(script.Parent.AssetManagement)
local ClientTypes = require(script.Parent.ClientTypes)
local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local ControlManager = require(script.Parent.Parent.Shared.ControlManager)
local UIAnimation = require(script.Parent.Parent.Shared.UIAnimation)
local UIManager = require(script.Parent.Parent.Shared.UIManager)
local ui = UIManager.WaitForUI("AssetManager") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.AssetManager)}

local object = ui.Object
local assetList = object.AssetList.ScrollingFrame
local actions = object.Actions

type AssetListButton = typeof(assetList.ButtonTemplate)

local currentAsset: string?
local clickCons: {[TextButton]: RBXScriptConnection?} = {}

local function bindToClick(button: TextButton, callback: () -> ())
    local old = clickCons[button]
    if old then
        old:Disconnect()
    end

    clickCons[button] = button.Activated:Connect(callback)
end

local function setHighlightedAsset(button: AssetListButton?): ()
    for _, v in assetList:GetChildren() do
        if v:IsA("TextButton") then
            local vButton = v :: AssetListButton
            vButton.UIStroke.Enabled = vButton == button
        end
    end
end

local function setActionsVisible(visible: boolean): ()
    if not visible then
        currentAsset = nil
        setHighlightedAsset()
    end

    -- I love hardcoding!
    UIAnimation.Animate(object.Reveal, TweenInfo.new(0.25), {Position = UDim2.new(if visible then 1 else 0.5, 0, 0, 0)})
    UIAnimation.Animate(object.Title, TweenInfo.new(0.25), {Size = UDim2.new(if visible then 1 else 0.5, 0, 0.1, 9)})
    UIAnimation.Animate(actions, TweenInfo.new(0.25), {Position = if visible then UDim2.new(0.5, 5, 0.1, 0) else UDim2.new(0, 0, 0.1, 0)})
end

local function closeActions(): ()
    setActionsVisible(false)
end

local revealed = false
local function reveal(): ()
    revealed = not revealed

    UIAnimation.Animate(object, TweenInfo.new(0.25), { Position = UDim2.new(if revealed then UDim.new(0, 10) else UDim.new(-0.15, 0), UDim.new(1, -10)) })
    if not revealed then
        closeActions()
    end
end
object.Reveal.Activated:Connect(reveal)

local function updateView(asset: ClientTypes.ClientAssetView): ()
    local name = asset.Name
    if currentAsset ~= name then
        return
    end

    local currency = GetCurrencySymbol()

    local scaleUp: {TextButton} = {}
    local scaleDown: {TextButton} = {}

    if asset.SellAllValue then
        actions.SellAll.Text = `Sell All ({currency}{asset.SellAllValue})`
        actions.SellAll.Visible = true
        bindToClick(actions.SellAll, function() AssetManagement.SellAll(name) end)
        table.insert(scaleUp, actions.SellAll)
    else
        table.insert(scaleDown, actions.SellAll)
    end

    if asset.SellHotelValue then
        actions.SellDevelopment.Text = `Sell Hotel ({currency}{asset.SellHotelValue})`
        actions.SellDevelopment.Visible = true
        bindToClick(actions.SellDevelopment, function() AssetManagement.SellHotel(name) end)
        table.insert(scaleUp, actions.SellDevelopment)
    elseif asset.SellHouseValue then
        actions.SellDevelopment.Text = `Sell House ({currency}{asset.SellHouseValue})`
        actions.SellDevelopment.Visible = true
        bindToClick(actions.SellDevelopment, function() AssetManagement.SellHouse(name) end)
        table.insert(scaleUp, actions.SellDevelopment)
    else
        table.insert(scaleDown, actions.SellDevelopment)
    end

    if asset.HousePrice then
        actions.BuyDevelopment.Text = `Buy House ({currency}{asset.HousePrice})`
        actions.BuyDevelopment.Visible = true
        bindToClick(actions.BuyDevelopment, function() AssetManagement.BuyHouse(name, asset.HousePrice) end)
        table.insert(scaleUp, actions.BuyDevelopment)
    elseif asset.HotelPrice then
        actions.BuyDevelopment.Text = `Buy Hotel ({currency}{asset.HotelPrice})`
        actions.BuyDevelopment.Visible = true
        bindToClick(actions.BuyDevelopment, function() AssetManagement.BuyHotel(name, asset.HotelPrice) end)
        table.insert(scaleUp, actions.BuyDevelopment)
    else
        table.insert(scaleDown, actions.BuyDevelopment)
    end

    if asset.UnMortgageCost then
        actions.Mortgage.Text = `Unmortgage ({currency}{asset.UnMortgageCost})`
        actions.Mortgage.Visible = true
        bindToClick(actions.Mortgage, function() AssetManagement.Unmortgage(name, asset.UnMortgageCost) end)
        table.insert(scaleUp, actions.Mortgage)
    elseif asset.MortgageValue then
        actions.Mortgage.Text = `Mortgage ({currency}{asset.MortgageValue})`
        actions.Mortgage.Visible = true
        bindToClick(actions.Mortgage, function() AssetManagement.Mortgage(name) end)
        table.insert(scaleUp, actions.Mortgage)
    else
        table.insert(scaleDown, actions.Mortgage)
    end

    for _, v in scaleUp do
        UIAnimation.Animate(v, TweenInfo.new(0.25), {Size = UDim2.new(1, 0, 0.15, 0)})
    end
    for _, v in scaleDown do
        UIAnimation.Animate(v, TweenInfo.new(0.25), {Size = UDim2.new(0, 0, 0, 0)})
    end
end

bindToClick(actions.Close, closeActions)

local function selectAsset(button: AssetListButton, name: string, asset: ClientTypes.ClientAssetView): ()
    if currentAsset == name then
        button.UIStroke.Enabled = false
        return closeActions()
    end

    setHighlightedAsset(button)

    setActionsVisible(true)
    currentAsset = name

    updateView(asset)
end

ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("UpdateAsset").OnClientEvent:Connect(function(asset: ClientTypes.ClientAssetView)
    local name = asset.Name

    local button = assetList:FindFirstChild("Asset_" .. name) :: AssetListButton?
    if not button then
        button = assetList.ButtonTemplate:Clone()
    end
    assert(button)

    button.Text = name
    button.BackgroundColor3 = asset.Colour

    if not button.Parent then
        local targetSize = button.Size
        button.Size = UDim2.new(targetSize.X, UDim.new())
        UIAnimation.Animate(button, TweenInfo.new(0.25), {Size = targetSize})
    end

    -- todo: this can cause problems if there are two similar colours. woo.
    button.LayoutOrder = (tonumber(asset.Colour:ToHex(), 16) or error("Failed to convert colour to hex")) + asset.Position

    button.Name = "Asset_" .. name
    button.Visible = true
    button.Parent = assetList

    updateView(asset)

    bindToClick(button, function()
        selectAsset(button, name, asset)
    end)
end)

ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("RemoveAsset").OnClientEvent:Connect(function(name: string)
    local button = assetList:FindFirstChild("Asset_" .. name) :: AssetListButton?
    if button then
        UIAnimation.Animate(button, TweenInfo.new(0.25), {Size = UDim2.new()})
        task.delay(0.25, button.Destroy, button)
    end

    if currentAsset == name then
        closeActions()
    end
end)

ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("GoBankrupt").OnClientEvent:Connect(function()
    ui:ToggleVisible(false)
end)

ControlManager.Register("Asset Manager", false, function()
    reveal()
    return Enum.ContextActionResult.Sink
end)
