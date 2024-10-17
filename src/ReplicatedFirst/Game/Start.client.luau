local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local AnimateDrawCard = require(script.Parent.AnimateDrawCard)
local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local LerpModelCFrame = require(script.Parent.LerpModelCFrame)
local ControlManager = require(script.Parent.Parent.Shared.ControlManager)
local Notification = require(script.Parent.Parent.Shared.Notification)
local UIManager = require(script.Parent.Parent.Shared.UIManager)
local PayFine = require(script.Parent.PayFine)
local RollDice = require(script.Parent.RollDice)
local ToggleMovementEnabled = require(script.Parent.ToggleMovementEnabled)
local TradingUI = require(script.Parent.TradingUI)
local UseGetOutOfJailFreeCard = require(script.Parent.UseGetOutOfJailFreeCard)
local ViewDeed = require(script.Parent.ViewDeed)

local gameServerClient = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient")
local gameClientServer = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ClientServer")
local gameBidirectional = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Bidirectional")
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
    payFine.Object.Text = `Pay Fine ({GetCurrencySymbol()}{ReplicatedStorage:GetAttribute("FineAmount") :: number})`
end)
player:GetAttributeChangedSignal("GetOutOfJailFreeCards"):Connect(function()
    useCard.Object.Text = `Use Card ({player:GetAttribute("GetOutOfJailFreeCards") :: number})`
end)
payFine.Object.Text = `Pay Fine ({GetCurrencySymbol()}{ReplicatedStorage:GetAttribute("FineAmount") :: number})`
useCard.Object.Text = `Use Card ({player:GetAttribute("GetOutOfJailFreeCards") :: number})`

rollDice.Object.Activated:Connect(RollDice)
payFine.Object.Activated:Connect(PayFine)
useCard.Object.Activated:Connect(UseGetOutOfJailFreeCard)

ControlManager.Register("Roll Dice", false, function()
    if not rollDice.Object.Visible then
        return Enum.ContextActionResult.Pass
    end
    RollDice()
    return Enum.ContextActionResult.Sink
end)

ControlManager.Register("Pay Fine", false, function()
    if not payFine.Object.Visible then
        return Enum.ContextActionResult.Pass
    end
    PayFine()
    return Enum.ContextActionResult.Sink
end)

ControlManager.Register("Use Jail Card", false, function()
    if not useCard.Object.Visible then
        return Enum.ContextActionResult.Pass
    end
    UseGetOutOfJailFreeCard()
    return Enum.ContextActionResult.Sink
end)

local buyPropertyUI = UIManager.WaitForUI("BuyProperty") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.BuyProperty)}
local acceptBuyCon: RBXScriptConnection?
local declineBuyCon: RBXScriptConnection?
local closeBuyCon: RBXScriptConnection?
gameServerClient.PromptPropertyPurchase.OnClientEvent:Connect(function(description: {Name: string, Price: number}?)
    if acceptBuyCon then
        acceptBuyCon:Disconnect()
    end
    if declineBuyCon then
        declineBuyCon:Disconnect()
    end
    if closeBuyCon then
        closeBuyCon:Disconnect()
    end

    if not description then
        return buyPropertyUI:ToggleVisible(false)
    end

    local currency = GetCurrencySymbol()

    buyPropertyUI:ToggleVisible(true)
    
    local object = buyPropertyUI.Object
    object.PropertyName.Text = description.Name
    object.Price.Text = currency .. description.Price
    object.TextLabel.Text = `Would you like to purchase {description.Name} for {currency}{description.Price}?`

    local function makeChoice(accepted: boolean)
        ControlManager.Unregister("Confirm Purchase")
        buyPropertyUI:ToggleVisible(false)

        assert(acceptBuyCon and declineBuyCon and closeBuyCon)
        acceptBuyCon:Disconnect()
        declineBuyCon:Disconnect()
        closeBuyCon:Disconnect()

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

    closeBuyCon = object:GetPropertyChangedSignal("Visible"):Connect(function()
        if not object.Visible then
            makeChoice(false)
        end
    end)
end)

local moneyDisplay = UIManager.WaitForUI("MoneyDisplay") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.MoneyDisplay)}
local function updateMoney()
    local currency = GetCurrencySymbol()
    moneyDisplay.Object.Text = currency .. (player:GetAttribute("Money") :: number? or 0)
end
player:GetAttributeChangedSignal("Money"):Connect(updateMoney)
updateMoney()

gameServerClient:WaitForChild("AnimateCard").OnClientEvent:Connect(AnimateDrawCard)

gameServerClient:WaitForChild("AnimateJailBars").OnClientEvent:Connect(function(bars: Model, targetCFrame: CFrame)
    LerpModelCFrame(bars, targetCFrame, 1)
end)
gameServerClient:WaitForChild("AnimateDevelopmentModel").OnClientEvent:Connect(function(model: Model, targetCFrame: CFrame)
    LerpModelCFrame(model, targetCFrame, 1)
end)

gameBidirectional:WaitForChild("BeginTrading").OnClientEvent:Connect(function(plr: Player)
    TradingUI(plr)
end)

ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("SendNotification").OnClientEvent:Connect(Notification)

local castParams = RaycastParams.new()
castParams.FilterDescendantsInstances = {workspace:WaitForChild("Board")}
castParams.FilterType = Enum.RaycastFilterType.Include

ContextActionService:BindAction("View Board Property", function(_, state, input)
    if state ~= Enum.UserInputState.End then
        return Enum.ContextActionResult.Pass
    end

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
end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
