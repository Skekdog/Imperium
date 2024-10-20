local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientTypes = require(script.Parent.ClientTypes)
local CreateAssetButton = require(script.Parent.CreateAssetButton)
local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

type Inventory = {[string]: typeof(CreateAssetButton(nil :: any, nil :: any))?}
local inventories: {[Player]: Inventory?} = {}

local ui = UIManager.WaitForUI("Trading") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Trading)}
local object = ui.Object

local yourItems = object.YourItems.ScrollingFrame
local theirItems = object.TheirItems.ScrollingFrame
local yourOffer = object.YourOffer.ScrollingFrame
local theirOffer = object.TheirOffer.ScrollingFrame

local confirmButton = object.Responses.Confirm
local rejectButton = object.Responses.Reject

local currentTrader: Player?
local youAccepted = false
local theyAccepted = false

local offeredMoney = 0
local offeredJailCards = 0

local serverClient = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient")
local tradeRemotes = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Trading")

local clickCons: {[TextButton]: RBXScriptConnection?} = {}

local function bindToClick(button: TextButton, callback: () -> ())
    local old = clickCons[button]
    if old then
        old:Disconnect()
    end

    clickCons[button] = button.Activated:Connect(callback)
end

local function offerAsset(button: CreateAssetButton.Button, asset: ClientTypes.ClientAssetView): ()
    local offer: ClientTypes.TradeOfferUpdate = {
        Kind = "Asset",
        Name = asset.Name,
        Mode = "Add",
    }
    tradeRemotes:WaitForChild("UpdateOffer"):FireServer(offer)
end

local function retractAsset(button: CreateAssetButton.Button, asset: ClientTypes.ClientAssetView): ()
    local offer: ClientTypes.TradeOfferUpdate = {
        Kind = "Asset",
        Name = asset.Name,
        Mode = "Remove",
    }
    tradeRemotes:WaitForChild("UpdateOffer"):FireServer(offer)
end

serverClient:WaitForChild("UpdateAsset").OnClientEvent:Connect(function(plr: Player, asset: ClientTypes.ClientAssetView)
    local inventory = inventories[plr] or {}
    inventories[plr] = inventory
    
    local button = (inventory[asset.Name] or CreateAssetButton(UDim2.new(1, 0, 0.15, 0), asset)) :: CreateAssetButton.Button
    inventory[asset.Name] = button

    if currentTrader == plr then
        button.Parent = theirItems :: any
    end

    if plr == Players.LocalPlayer and not button.Parent then
        button.Parent = yourItems :: any

        bindToClick(button, function()
            if button.Parent == yourItems :: any then
                offerAsset(button, asset)
            else
                retractAsset(button, asset)
            end
        end)
    elseif plr == currentTrader and not button.Parent then
        button.Parent = theirItems :: any
    end
end)

local moneyAmounts = {-100, -10, 10, 100}
local jailCardAmounts = {-1, 1}

local offerMoneyButtons: {[TextButton]: number} = {}
local offerJailCardButtons: {[TextButton]: number} = {}

local function updateOfferMoneyButtons(): ()
    local money = Players.LocalPlayer:GetAttribute("Money") :: number? or 0

    local makeFrameVisible = false
    for i, v in offerMoneyButtons do
        print(v, offeredMoney)
        if v > 0 then
            i.Visible = offeredMoney + v <= money
        else
            i.Visible = offeredMoney >= math.abs(v)
        end

        if not makeFrameVisible then
            makeFrameVisible = i.Visible
        end
    end

    yourItems.MoneyOffers.Visible = makeFrameVisible
end

local function updateOfferJailCardButtons(): ()
    local jailCards = Players.LocalPlayer:GetAttribute("GetOutOfJailFreeCards") :: number? or 0

    local makeFrameVisible = false
    for i, v in offerJailCardButtons do
        if v > 0 then
            i.Visible = offeredJailCards + v <= jailCards
        else
            i.Visible = offeredJailCards >= math.abs(v)
        end

        if not makeFrameVisible then
            makeFrameVisible = i.Visible
        end
    end

    yourItems.JailCardOffers.Visible = makeFrameVisible
end

for i, v in moneyAmounts do
    local button = yourItems.MoneyOffers.Template:Clone()

    button.Visible = true
    button.LayoutOrder = i
    button.Text = `{if v < 0 then "-" else "+"}{GetCurrencySymbol()}{math.abs(v)}`

    bindToClick(button, function()
        offeredMoney += v
        local offer: ClientTypes.TradeOfferUpdate = {
            Kind = "Money",
            Amount = offeredMoney,
        }
        tradeRemotes:WaitForChild("UpdateOffer"):FireServer(offer)

        updateOfferMoneyButtons()
    end)

    button.Parent = yourItems.MoneyOffers

    offerMoneyButtons[button] = v
end
yourItems.MoneyOffers.UIGridLayout.CellSize = UDim2.new(1 / #moneyAmounts, -5, 1, 0)

for i, v in jailCardAmounts do
    local button = yourItems.JailCardOffers.Template:Clone()

    button.Visible = true
    button.LayoutOrder = i
    button.Text = `{if v < 0 then "-" else "+"}{v} Jail Card{if v == 1 then "" else "s"}`

    bindToClick(button, function()
        offeredJailCards += v
        local offer: ClientTypes.TradeOfferUpdate = {
            Kind = "JailCards",
            Amount = offeredJailCards,
        }
        tradeRemotes:WaitForChild("UpdateOffer"):FireServer(offer)

        updateOfferJailCardButtons()
    end)

    button.Parent = yourItems.JailCardOffers

    offerJailCardButtons[button] = v
end
yourItems.JailCardOffers.UIGridLayout.CellSize = UDim2.new(1 / #jailCardAmounts, -5, 1, 0)

serverClient:WaitForChild("RemoveAsset").OnClientEvent:Connect(function(plr: Player, assetName: string)
    local inventory = inventories[plr]
    assert(inventory, "No inventory found for player: " .. plr.Name)

    local button = inventory[assetName]
    inventory[assetName] = nil

    assert(button, "No button found for asset: " .. assetName)
    button:Destroy()
end)

tradeRemotes:WaitForChild("UpdateOffer").OnClientEvent:Connect(function(plr: Player, offer: ClientTypes.TradeOfferUpdate)
    if offer.Kind == "Asset" then
        local inventory = inventories[plr]
        assert(inventory, "No inventory found for player: " .. plr.Name)

        local button = inventory[offer.Name]
        assert(button, "No button found for asset: " .. offer.Name)
        if offer.Mode == "Add" then
            button.Parent = if plr == Players.LocalPlayer then yourOffer :: any else theirOffer :: any
        elseif offer.Mode == "Remove" then
            button.Parent = if plr == Players.LocalPlayer then yourItems :: any else theirItems :: any
        end
    elseif offer.Kind == "Money" then
        local label = (if plr == Players.LocalPlayer then yourOffer.OfferedMoney else theirOffer.OfferedMoney) :: TextLabel
        if offer.Amount <= 0 then
            label.Visible = false
            return
        end
        label.Text = `{GetCurrencySymbol()}{offer.Amount}`
        label.Visible = true
    elseif offer.Kind == "JailCards" then
        local label = (if plr == Players.LocalPlayer then yourOffer.OfferedJailCards else theirOffer.OfferedJailCards) :: TextLabel
        if offer.Amount <= 0 then
            label.Visible = false
            return
        end
        label.Text = `{offer.Amount} Jail Card{if offer.Amount == 1 then "" else "s"}`
        label.Visible = true
    else
        error("Unknown offer kind: " .. offer.Kind)
    end
end)

local function updatedAcceptance(): ()
    local num = 0
    if theyAccepted then
        num += 1
    end
    if youAccepted then
        num += 1
        confirmButton.Text = `Unconfirm ({num}/2)`
    else
        confirmButton.Text = `Confirm ({num}/2)`
    end
end

tradeRemotes:WaitForChild("TradeAcceptance").OnClientEvent:Connect(function(plr: Player, accepted: boolean)
    if plr == Players.LocalPlayer then
        youAccepted = accepted
    elseif plr == currentTrader then
        theyAccepted = accepted
    end

    updatedAcceptance()
end)

tradeRemotes:WaitForChild("TradeEnded").OnClientEvent:Connect(function()
    ui:ToggleVisible(false)
end)

local function clearObject(object: ScrollingFrame): ()
    for _, button in object:GetChildren() do
        if button:IsA("TextButton") then
            button.Parent = nil
        end
    end
end

local function moveButtons(from: Inventory, to: ScrollingFrame): ()
    for _, button in from do
        assert(button)
        button.Parent = to :: any
    end
end

Players.LocalPlayer:GetAttributeChangedSignal("Money"):Connect(updateOfferMoneyButtons)
Players.LocalPlayer:GetAttributeChangedSignal("GetOutOfJailFreeCards"):Connect(updateOfferJailCardButtons)

return function(target: Player): ()
    local yourInventory = inventories[Players.LocalPlayer]
    clearObject(yourItems)

    if yourInventory then
        moveButtons(yourInventory, yourItems)
    end

    local theirInventory = inventories[target]
    clearObject(theirItems)

    if theirInventory then
        moveButtons(theirInventory, theirItems)
    end

    currentTrader = target
    youAccepted = false
    theyAccepted = false

    offeredMoney = 0
    offeredJailCards = 0

    updateOfferJailCardButtons()
    updateOfferMoneyButtons()

    updatedAcceptance()

    object.ThemTitle:SetAttribute("Player_1", GetPlayerName(target))
    object.ThemTitle:SetAttribute("Format", "[PLAYER]")
    object.ThemTitle:AddTag("DynamicNames")

    bindToClick(confirmButton, function()
        tradeRemotes:WaitForChild("TradeAcceptance"):FireServer(not youAccepted)
    end)

    bindToClick(rejectButton, function()
        tradeRemotes:WaitForChild("TradeAcceptance"):FireServer(nil)
    end)

    ui:ToggleVisible(true)
end
