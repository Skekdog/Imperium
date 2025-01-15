local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CreateAssetButton = require(script.Parent.CreateAssetButton)
local UIAnimation = require(ReplicatedStorage.Shared.UIAnimation)
local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local assetButtons: {[string]: CreateAssetButton.Button?} = {}

local ui = UIManager.WaitForUI("Trading") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Trading)}
local object = ui.Object

local ourItems = object.YourItems.Items
local theirItems = object.TheirItems.Items
local ourOffer = object.YourOffer.Items
local theirOffer = object.TheirOffer.Items

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

local moneyOfferTemplate = ourItems.MoneyOffers.Template

local ourMoneyOfferButtons: {[typeof(moneyOfferTemplate)]: number} = {}
local theirMoneyOfferButtons: {[typeof(moneyOfferTemplate)]: number} = {}

local function makeMoneyOfferButtons(parent: typeof(ourItems.MoneyOffers) | typeof(theirItems.MoneyOffers)): ()
    for _, v in {1, 10, 100, -100, -10, -1} do
        local clone = moneyOfferTemplate:Clone()
        clone.Name = tostring(v)
        clone.Text = `{if v > 0 then "+" else ""}{GetCurrencySymbol()}{v}`
        clone.Parent = parent :: any

        if parent == ourItems.MoneyOffers then
            ourMoneyOfferButtons[clone] = v
        else
            theirMoneyOfferButtons[clone] = v
        end
    end
end
makeMoneyOfferButtons(ourItems.MoneyOffers)
makeMoneyOfferButtons(theirItems.MoneyOffers)

local isHidden = false
local function setHidden(hidden: boolean): ()
    isHidden = hidden
    UIAnimation.Animate(object, TweenInfo.new(0.25), {
        Position = UDim2.fromScale(if isHidden then 1 else 0.5, 0.5),
        AnchorPoint = Vector2.new(if isHidden then 0 else 0.5, 0.5),
    })
end

object.Hide.Activated:Connect(function()
    setHidden(not isHidden)
end)

local function updateDisplayedMoneyOffer(label: TextLabel, value: number): ()
    if value == 0 then
        label.Visible = false
        return
    end

    label.Text = `{GetCurrencySymbol()}{value} Cash`
    label.Visible = true
end

local function updateDisplayJailCardsOffer(label: TextLabel, value: number): ()
    if value == 0 then
        label.Visible = false
        return
    end

    label.Text = `{value} Jail Cards`
    label.Visible = true
end

local function resetUI(): ()
    setHidden(false)

    for _, v in clickCons do
        assert(v):Disconnect()
    end

    for _, v in assetButtons do
        assert(v).Parent = nil :: any
    end

    updateDisplayedMoneyOffer(ourOffer.OfferedMoney, 0)
    updateDisplayedMoneyOffer(theirOffer.OfferedMoney, 0)

    updateDisplayJailCardsOffer(ourOffer.OfferedJailCards, 0)
    updateDisplayJailCardsOffer(theirOffer.OfferedJailCards, 0)
end

resetUI()

return function(): ()

end
