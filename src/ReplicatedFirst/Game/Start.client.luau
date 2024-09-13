local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIManager = require(script.Parent.Parent.Shared.UIManager)
local RollDice = require(script.Parent.RollDice)
local ToggleMovementEnabled = require(script.Parent.ToggleMovementEnabled)

local gameServerClient = ReplicatedStorage:WaitForChild("Game").ServerClient
local gameClientServer = ReplicatedStorage:WaitForChild("Game").ClientServer
gameServerClient.SetMovementEnabled.OnClientEvent:Connect(ToggleMovementEnabled)

local rollDice = UIManager.WaitForUI("RollDice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.RollDice)}
gameServerClient.BeginTurn.OnClientEvent:Connect(function(name: string)
    rollDice:ToggleVisible(name == Players.LocalPlayer.Name)
end)

rollDice.Object.Activated:Connect(RollDice)

local buyPropertyUI = UIManager.WaitForUI("BuyProperty") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.BuyProperty)}
local acceptBuyCon: RBXScriptConnection?
local declineBuyCon: RBXScriptConnection?
gameServerClient.PromptPropertyPurchase.OnClientEvent:Connect(function(description: {Name: string, Price: number})
    if acceptBuyCon then
        acceptBuyCon:Disconnect()
    end
    if declineBuyCon then
        declineBuyCon:Disconnect()
    end
    
    local object = buyPropertyUI.Object
    object.PropertyName.Text = description.Name
    object.Price.Text = "£" .. description.Price
    object.TextLabel.Text = `Would you like to purchase {description.Name} for £{description.Price}?`

    buyPropertyUI:ToggleVisible(true)

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
