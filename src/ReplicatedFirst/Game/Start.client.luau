local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Notification = require(script.Parent.Notification)
local UIManager = require(script.Parent.Parent.Shared.UIManager)
local RollDice = require(script.Parent.RollDice)
local ToggleMovementEnabled = require(script.Parent.ToggleMovementEnabled)

local gameServerClient = ReplicatedStorage:WaitForChild("Game").ServerClient
local gameClientServer = ReplicatedStorage:WaitForChild("Game").ClientServer
gameServerClient.SetMovementEnabled.OnClientEvent:Connect(ToggleMovementEnabled)

local player = Players.LocalPlayer

local rollDice = UIManager.WaitForUI("RollDice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.RollDice)}
local payFine = UIManager.WaitForUI("PayFine") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.PayFine)}
local useCard = UIManager.WaitForUI("UseGetOutOfJailFreeCard") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.UseGetOutOfJailFreeCard)}
gameServerClient.BeginTurn.OnClientEvent:Connect(function(name: string)
    local isPlayer = name == player.Name
    local isJailed = player:GetAttribute("IsJailed") :: boolean
    rollDice:ToggleVisible(isPlayer)
    payFine:ToggleVisible(isPlayer and isJailed and player:GetAttribute("Money") :: number >= ReplicatedStorage:GetAttribute("FineAmount") :: number)
    useCard:ToggleVisible(isPlayer and isJailed and player:GetAttribute("GetOutOfJailFreeCards") :: number > 0)
end)

ReplicatedStorage:GetAttributeChangedSignal("FineAmount"):Connect(function()
    payFine.Object.Text = `Pay Fine (£{ReplicatedStorage:GetAttribute("FineAmount") :: number})`
end)

rollDice.Object.Activated:Connect(RollDice)

local buyPropertyUI = UIManager.WaitForUI("BuyProperty") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.BuyProperty)}
local acceptBuyCon: RBXScriptConnection?
local declineBuyCon: RBXScriptConnection?
gameServerClient.PromptPropertyPurchase.OnClientEvent:Connect(function(description: {Name: string, Price: number}?)
    if acceptBuyCon then
        acceptBuyCon:Disconnect()
    end
    if declineBuyCon then
        declineBuyCon:Disconnect()
    end

    if not description then
        return buyPropertyUI:ToggleVisible(false)
    end

    buyPropertyUI:ToggleVisible(true)
    
    local object = buyPropertyUI.Object
    object.PropertyName.Text = description.Name
    object.Price.Text = "£" .. description.Price
    object.TextLabel.Text = `Would you like to purchase {description.Name} for £{description.Price}?`

    local function makeChoice(accepted: boolean)
        buyPropertyUI:ToggleVisible(false)

        assert(acceptBuyCon and declineBuyCon)
        acceptBuyCon:Disconnect()
        declineBuyCon:Disconnect()

        gameClientServer.RespondPropertyPurchase:FireServer(accepted, description.Name)
    end
    
    acceptBuyCon = object.Yes.Activated:Connect(function()
        makeChoice(true)
    end)

    declineBuyCon = object.No.Activated:Connect(function()
        makeChoice(false)
    end)
end)

local moneyDisplay = UIManager.WaitForUI("MoneyDisplay") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.MoneyDisplay)}
local function updateMoney()
    moneyDisplay.Object.Text = "£" .. (player:GetAttribute("Money") :: number? or 0)
end
moneyDisplay.Object.Size = UDim2.fromOffset(0, GuiService:GetGuiInset().Y)
player:GetAttributeChangedSignal("Money"):Connect(updateMoney)
updateMoney()

gameServerClient.SendNotification.OnClientEvent:Connect(Notification)