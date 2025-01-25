local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local AnimateDrawCard = require(script.Parent.AnimateDrawCard)
local BankruptcyAlert = require(script.Parent.BankruptcyAlert)
local GetCharacter = require(script.Parent.GetCharacter)
local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local LerpModelCFrame = require(script.Parent.LerpModelCFrame)
local ControlManager = require(script.Parent.Parent.Shared.ControlManager)
local KeybindHintManager = require(script.Parent.Parent.Shared.KeybindHintManager)
local Notification = require(script.Parent.Parent.Shared.Notification)
local PlaySound = require(script.Parent.Parent.Shared.PlaySound)
local SettingsManager = require(script.Parent.Parent.Shared.SettingsManager)
local UIManager = require(script.Parent.Parent.Shared.UIManager)
local PayFine = require(script.Parent.PayFine)
local RollDice = require(script.Parent.RollDice)
local ToggleMovementEnabled = require(script.Parent.ToggleMovementEnabled)
local UseGetOutOfJailFreeCard = require(script.Parent.UseGetOutOfJailFreeCard)
local ViewDeed = require(script.Parent.ViewDeed)

require(script.Parent.TradingUI)

KeybindHintManager()

local gameServerClient = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient")
local gameClientServer = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ClientServer")
gameServerClient.SetMovementEnabled.OnClientEvent:Connect(ToggleMovementEnabled)

local localPlayer = Players.LocalPlayer

localPlayer:GetAttributeChangedSignal("GoingBankrupt"):Connect(function()
    if localPlayer:GetAttribute("GoingBankrupt") then
        BankruptcyAlert.Start()
    else
        BankruptcyAlert.Stop()
    end
end)

local function highlightCharacter(model: Model?, enabled: boolean?)
    if not model then
        return
    end

    local highlight = model:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")

    if not highlight.Parent then
        if model == localPlayer.Character then
            highlight.Name = "SelfHighlight"
            highlight.OutlineColor = Color3.new(0.23, 0.68, 1)
        else
            highlight.Name = "OtherHighlight"
            highlight.OutlineColor = Color3.new(1, 1, 1)
        end

        highlight.FillTransparency = 1
        highlight.Adornee = model
        
        highlight.Parent = model
    end
    
    if model == localPlayer.Character then
        highlight.Enabled = true
    else
        highlight.Enabled = if enabled == nil then true else enabled
    end
end

if localPlayer.Character then
    highlightCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(highlightCharacter)

local rollDice = UIManager.WaitForUI("RollDice") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.RollDice)}
local payFine = UIManager.WaitForUI("PayFine") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.PayFine)}
local useCard = UIManager.WaitForUI("UseGetOutOfJailFreeCard") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.UseGetOutOfJailFreeCard)}
gameServerClient.BeginTurn.OnClientEvent:Connect(function(name: string)
    local plr = Players:FindFirstChild(name)

    local isLocalPlayer = plr == localPlayer

    if plr then
        assert(plr:IsA("Player") or plr:IsA("Configuration"))
        for _, v in Players:GetChildren() do -- Inside the if block because we don't want to unhighlight everyone when beginTurn is fired with empty string
            assert(v:IsA("Player") or v:IsA("Configuration"))
            highlightCharacter(GetCharacter(v), v == plr and v ~= localPlayer)
        end

        local char = GetCharacter(plr)
        if char then
            workspace.CurrentCamera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
        end
    end

    local isJailed = localPlayer:GetAttribute("IsJailed") :: boolean
    rollDice:ToggleVisible(isLocalPlayer)
    payFine:ToggleVisible(isLocalPlayer and isJailed and localPlayer:GetAttribute("Money") :: number >= ReplicatedStorage:GetAttribute("FineAmount") :: number)
    useCard:ToggleVisible(isLocalPlayer and isJailed and localPlayer:GetAttribute("GetOutOfJailFreeCards") :: number > 0)

    if isLocalPlayer and SettingsManager.GetSetting("Your Turn Alert") then
        PlaySound("TurnBeginAlert")
    end
end)

ReplicatedStorage:GetAttributeChangedSignal("FineAmount"):Connect(function()
    payFine.Object.Text = `Pay Fine ({GetCurrencySymbol()}{ReplicatedStorage:GetAttribute("FineAmount") :: number})`
end)
localPlayer:GetAttributeChangedSignal("GetOutOfJailFreeCards"):Connect(function()
    useCard.Object.Text = `Use Card ({localPlayer:GetAttribute("GetOutOfJailFreeCards") :: number})`
end)
payFine.Object.Text = `Pay Fine ({GetCurrencySymbol()}{ReplicatedStorage:GetAttribute("FineAmount") :: number})`
useCard.Object.Text = `Use Card ({localPlayer:GetAttribute("GetOutOfJailFreeCards") :: number})`

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
    moneyDisplay.Object.Text = currency .. (localPlayer:GetAttribute("Money") :: number? or 0)
end
localPlayer:GetAttributeChangedSignal("Money"):Connect(updateMoney)
updateMoney()

gameServerClient:WaitForChild("AnimateCard").OnClientEvent:Connect(AnimateDrawCard)

gameServerClient:WaitForChild("AnimateJailBars").OnClientEvent:Connect(function(bars: MeshPart, targetCFrame: CFrame)
    LerpModelCFrame(bars, targetCFrame, 1)
end)
gameServerClient:WaitForChild("AnimateDevelopmentModel").OnClientEvent:Connect(function(model: MeshPart, targetCFrame: CFrame)
    LerpModelCFrame(model, targetCFrame, 1)
end)

ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("SendNotification").OnClientEvent:Connect(Notification)

local castParams = RaycastParams.new()
castParams.FilterDescendantsInstances = {workspace:WaitForChild("Board")}
castParams.FilterType = Enum.RaycastFilterType.Include

local function viewDeed(_, proc: boolean): ()
    if proc then
        return
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
end

UserInputService.TouchTapInWorld:Connect(viewDeed)
UserInputService.InputEnded:Connect(function(input, proc)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 or input.Delta.Magnitude > 1 then
        return
    end

    viewDeed(nil, proc)
end)
