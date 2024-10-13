local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientTypes = require(script.Parent.ClientTypes)
local CreateAssetButton = require(script.Parent.CreateAssetButton)
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

local serverClient = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient")
local bidirectional = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Bidirectional")

local clickCons: {[TextButton]: RBXScriptConnection?} = {}

local function bindToClick(button: TextButton, callback: () -> ())
    local old = clickCons[button]
    if old then
        old:Disconnect()
    end

    clickCons[button] = button.Activated:Connect(callback)
end

local function offerAsset(button: CreateAssetButton.Button, asset: ClientTypes.ClientAssetView): ()
    button.Parent = yourOffer :: any
    bidirectional:WaitForChild("UpdateOffer"):FireServer(asset.Name, "Add")
end

local function retractAsset(button: CreateAssetButton.Button, asset: ClientTypes.ClientAssetView): ()
    button.Parent = yourItems :: any
    bidirectional:WaitForChild("UpdateOffer"):FireServer(asset.Name, "Remove")
end

serverClient:WaitForChild("UpdateAsset").OnClientEvent:Connect(function(plr: Player, asset: ClientTypes.ClientAssetView)
    local inventory = inventories[plr] or {}
    inventories[plr] = inventory
    
    local button = (inventory[asset.Name] or CreateAssetButton(UDim2.new(1, 0, 0.15, 0), asset)) :: CreateAssetButton.Button
    inventory[asset.Name] = button

    if currentTrader == plr and false then
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

serverClient:WaitForChild("RemoveAsset").OnClientEvent:Connect(function(plr: Player, assetName: string)
    local inventory = inventories[plr]
    assert(inventory, "No inventory found for player: " .. plr.Name)

    local button = inventory[assetName]
    inventory[assetName] = nil

    assert(button, "No button found for asset: " .. assetName)
    button:Destroy()
end)

bidirectional:WaitForChild("UpdateOffer").OnClientEvent:Connect(function(plr: Player, assetName: string, mode: "Add" | "Remove")
    local inventory = inventories[plr]
    assert(inventory, "No inventory found for player: " .. plr.Name)

    local button = inventory[assetName]
    assert(button, "No button found for asset: " .. assetName)
    if mode == "Add" then
        button.Parent = theirOffer :: any
    elseif mode == "Remove" then
        button.Parent = theirItems :: any
    end
end)

local function updateAcceptance(): ()
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

bidirectional:WaitForChild("AnswerTradeOffer").OnClientEvent:Connect(function(plr: Player, accepted: boolean)
    if plr == Players.LocalPlayer then
        youAccepted = accepted
    elseif plr == currentTrader then
        theyAccepted = accepted
    end

    updateAcceptance()
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

    object.ThemTitle:SetAttribute("Player_1", GetPlayerName(target))
    object.ThemTitle:SetAttribute("Format", "[PLAYER]")
    object.ThemTitle:AddTag("DynamicNames")

    bindToClick(confirmButton, function()
        bidirectional:WaitForChild("AnswerTradeOffer"):FireServer(not youAccepted)
    end)

    bindToClick(rejectButton, function()
        bidirectional:WaitForChild("AnswerTradeOffer"):FireServer(nil)
    end)

    ui:ToggleVisible(true)
end
