local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local AnimateDrawCard = require(script.Parent.AnimateDrawCard)
local LerpModelCFrame = require(script.Parent.LerpModelCFrame)
local ControlManager = require(script.Parent.Parent.Shared.ControlManager)
local Notification = require(script.Parent.Parent.Shared.Notification)
local UIManager = require(script.Parent.Parent.Shared.UIManager)
local PayFine = require(script.Parent.PayFine)
local RollDice = require(script.Parent.RollDice)
local ToggleMovementEnabled = require(script.Parent.ToggleMovementEnabled)
local UseGetOutOfJailFreeCard = require(script.Parent.UseGetOutOfJailFreeCard)
local ViewDeed = require(script.Parent.ViewDeed)

local gameServerClient = ReplicatedStorage:WaitForChild("Game").ServerClient
local gameClientServer = ReplicatedStorage:WaitForChild("Game").ClientServer
gameServerClient.SetMovementEnabled.OnClientEvent:Connect(ToggleMovementEnabled)

local player = Players.LocalPlayer

local rollDice = UIManager.WaitForUI("RollDice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.RollDice)}
local payFine = UIManager.WaitForUI("PayFine") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.PayFine)}
local useCard = UIManager.WaitForUI("UseGetOutOfJailFreeCard") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.UseGetOutOfJailFreeCard)}
gameServerClient.BeginTurn.OnClientEvent:Connect(function(name: string)
    local plr = Players:FindFirstChild(name)

    local isPlayer = plr == player

    if plr and plr:IsA("Player") then
        local char = plr.Character
        if char then
            workspace.CurrentCamera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
        end
    end

    local isJailed = player:GetAttribute("IsJailed") :: boolean
    rollDice:ToggleVisible(isPlayer)
    payFine:ToggleVisible(isPlayer and isJailed and player:GetAttribute("Money") :: number >= ReplicatedStorage:GetAttribute("FineAmount") :: number)
    useCard:ToggleVisible(isPlayer and isJailed and player:GetAttribute("GetOutOfJailFreeCards") :: number > 0)
end)

ReplicatedStorage:GetAttributeChangedSignal("FineAmount"):Connect(function()
    payFine.Object.Text = `Pay Fine (£{ReplicatedStorage:GetAttribute("FineAmount") :: number})`
end)
player:GetAttributeChangedSignal("GetOutOfJailFreeCards"):Connect(function()
    useCard.Object.Text = `Use Card ({player:GetAttribute("GetOutOfJailFreeCards") :: number})`
end)
payFine.Object.Text = `Pay Fine (£{ReplicatedStorage:GetAttribute("FineAmount") :: number})`
useCard.Object.Text = `Use Card ({player:GetAttribute("GetOutOfJailFreeCards") :: number})`

rollDice.Object.Activated:Connect(RollDice)
payFine.Object.Activated:Connect(PayFine)
useCard.Object.Activated:Connect(UseGetOutOfJailFreeCard)

ControlManager.Register("Roll Dice", false, function()
    RollDice()
    return Enum.ContextActionResult.Sink
end)

ControlManager.Register("Pay Fine", false, function()
    PayFine()
    return Enum.ContextActionResult.Sink
end)

ControlManager.Register("Use Jail Card", false, function()
    UseGetOutOfJailFreeCard()
    return Enum.ContextActionResult.Sink
end)

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
        ControlManager.Unregister("Confirm Purchase")
        buyPropertyUI:ToggleVisible(false)

        assert(acceptBuyCon and declineBuyCon)
        acceptBuyCon:Disconnect()
        declineBuyCon:Disconnect()

        gameClientServer.RespondPropertyPurchase:FireServer(accepted, description.Name)
    end

    ControlManager.Register("Confirm Purchase", false, function()
        makeChoice(true)
        return Enum.ContextActionResult.Sink
    end)
    
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

gameServerClient:WaitForChild("AnimateCard").OnClientEvent:Connect(AnimateDrawCard)

gameServerClient:WaitForChild("AnimateJailBars").OnClientEvent:Connect(function(bars: Model, targetCFrame: CFrame)
    LerpModelCFrame(bars, targetCFrame, 1)
end)
gameServerClient:WaitForChild("AnimateDevelopmentModel").OnClientEvent:Connect(function(model: Model, targetCFrame: CFrame)
    LerpModelCFrame(model, targetCFrame, 1)
end)

ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("SendNotification").OnClientEvent:Connect(Notification)

local castParams = RaycastParams.new()
castParams.FilterDescendantsInstances = {workspace:WaitForChild("Board")}
castParams.FilterType = Enum.RaycastFilterType.Include

ControlManager.Register("View Board Property", false, function()
    local mousePos = UserInputService:GetMouseLocation()

    local ray = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, castParams)

    if not result then
        ViewDeed()
        return Enum.ContextActionResult.Pass
    end

    local model = result.Instance:FindFirstAncestorOfClass("Model")
    if model then
        ViewDeed(model)
        return Enum.ContextActionResult.Sink
    end

    ViewDeed()
    return Enum.ContextActionResult.Pass
end)
