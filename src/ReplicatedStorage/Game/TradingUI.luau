local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScreenMessage = require(ReplicatedStorage.Shared.ScreenMessage)
local ClientTypes = require(script.Parent.ClientTypes)
local CreateAssetButton = require(script.Parent.CreateAssetButton)
local UIAnimation = require(ReplicatedStorage.Shared.UIAnimation)
local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

type AssetData = {
    Button: CreateAssetButton.Button,
    Owner: string
}
local assets: {[string]: AssetData?} = {}

local ui = UIManager.WaitForUI("Trading") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.Trading)}
local object = ui.Object

local function notifyOfferUpdateResponse(response: ClientTypes.TradeOfferUpdateInvokeResult): boolean
    if response == "AssetAlreadyAdded" then
        ScreenMessage("Error", "Asset already added to offer.")
    elseif response == "AssetAlreadyRemoved" then
        ScreenMessage("Error", "Asset already removed from offer.")
    elseif response == "UnownedAsset" then
        ScreenMessage("Error", "You don't own this asset.")
    elseif response == "NotEnoughJailCards" then
        ScreenMessage("Error", "You don't have enough jail cards.")
    elseif response == "NotEnoughMoney" then
        ScreenMessage("Error", "You don't have enough money.")
    elseif response == "Expired" then
        ScreenMessage("Error", "Trade has expired.")
    elseif response == "Success" then
        return true
    else
        ScreenMessage("Error", "An unknown error occurred.")
    end

    return false
end

local function getPlayerMoney(playerName: string?): number
    local player = if playerName then Players:FindFirstChild(playerName) else Players.LocalPlayer
    assert(player and (player:IsA("Player") or player:IsA("Configuration")), "Player not found")
    return player:GetAttribute("Money") :: number or 0
end

local function getPlayerJailCards(playerName: string?): number
    local player = if playerName then Players:FindFirstChild(playerName) else Players.LocalPlayer
    assert(player and (player:IsA("Player") or player:IsA("Configuration")), "Player not found")
    return player:GetAttribute("JailCards") :: number or 0
end

local currentTrader: string?

local ourItems = object.YourItems.Items
local theirItems = object.TheirItems.Items
local ourOffer = object.YourOffer.Items
local theirOffer = object.TheirOffer.Items

local ourMoneyOffer = 0
local ourJailCardsOffer = 0

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

local function processAssetButtonClick(assetData: AssetData): ()
    
end

serverClient:WaitForChild("UpdateAsset").OnClientEvent:Connect(function(plr: string, asset: ClientTypes.ClientAssetView): ()
    local assetData = assets[asset.Name]
    if assetData then
        assetData.Owner = plr
        
        if plr == currentTrader then
            assetData.Button.Parent = theirItems :: any
        elseif plr == Players.LocalPlayer.Name then
            assetData.Button.Parent = ourItems :: any
        else
            assetData.Button.Parent = nil :: any
        end
    else
        local button = CreateAssetButton(UDim2.new(1, 0, 0.15, 0), asset)
        assets[asset.Name] = {
            Button = button,
            Owner = plr,
        }

        bindToClick(button, function()
            processAssetButtonClick(assert(assets[asset.Name]))
        end)
    end
end)

local moneyOfferTemplate = ourItems.MoneyOffers.Template

local ourMoneyOfferButtons: {[typeof(moneyOfferTemplate)]: number} = {}
local theirMoneyOfferButtons: {[typeof(moneyOfferTemplate)]: number} = {}

local function makeMoneyOfferButtons(parent: typeof(ourItems.MoneyOffers) | typeof(theirItems.MoneyOffers), isOwn: boolean): ()
    for _, v in {1, 10, 100, -100, -10, -1} do
        local clone = moneyOfferTemplate:Clone()
        clone.Name = tostring(v)
        clone.Text = `{if v > 0 then "+" else ""}{GetCurrencySymbol()}{v}`
        clone.Visible = true
        clone.Parent = parent :: any

        bindToClick(clone, function()
            if ourMoneyOffer + v > getPlayerMoney(if isOwn then nil else currentTrader) then
                return ScreenMessage("Error", "You don't have enough money.")
            end

            ourMoneyOffer += v

            local offer: ClientTypes.TradeOfferMoneyUpdate = {
                Kind = "Money",
                Amount = v
            }
            
            local success = notifyOfferUpdateResponse(tradeRemotes:WaitForChild("UpdateTradeOffer"):InvokeServer(currentTrader, offer))
            if not success then
                ourMoneyOffer -= v
            end
        end)

        if parent == ourItems.MoneyOffers then
            ourMoneyOfferButtons[clone] = v
        else
            theirMoneyOfferButtons[clone] = v
        end
    end
end
makeMoneyOfferButtons(ourItems.MoneyOffers, true)
makeMoneyOfferButtons(theirItems.MoneyOffers, false)

local jailCardOfferTemplate = ourItems.JailCardOffers.Template

local ourJailCardOfferButtons: {[typeof(jailCardOfferTemplate)]: number} = {}
local theirJailCardOfferButtons: {[typeof(jailCardOfferTemplate)]: number} = {}

local function makeJailCardOfferButtons(parent: typeof(ourItems.JailCardOffers) | typeof(theirItems.JailCardOffers), isOwn: boolean): ()
    for _, v in {1, -1} do
        local clone = jailCardOfferTemplate:Clone()
        clone.Name = tostring(v)
        clone.Text = `{if v > 0 then "+" else ""}{v} Jail Card`
        clone.Visible = true
        clone.Parent = parent :: any

        bindToClick(clone, function()
            if ourJailCardsOffer + v > getPlayerJailCards(if isOwn then nil else currentTrader) then
                return ScreenMessage("Error", "You don't have enough jail cards.")
            end

            ourJailCardsOffer += v

            local offer: ClientTypes.TradeOfferJailCardsUpdate = {
                Kind = "JailCards",
                Amount = v
            }
            
            local success = notifyOfferUpdateResponse(tradeRemotes:WaitForChild("UpdateTradeOffer"):InvokeServer(currentTrader, offer))
            if not success then
                ourJailCardsOffer -= v
            end
        end)

        if parent == ourItems.JailCardOffers then
            ourJailCardOfferButtons[clone] = v
        else
            theirJailCardOfferButtons[clone] = v
        end
    end
end
makeJailCardOfferButtons(ourItems.JailCardOffers, true)
makeJailCardOfferButtons(theirItems.JailCardOffers, false)

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

local function reset(): ()
    setHidden(false)

    for _, v in clickCons do
        assert(v):Disconnect()
    end

    for _, v in assets do
        assert(v).Button.Parent = nil :: any
    end

    ourMoneyOffer = 0

    updateDisplayedMoneyOffer(ourOffer.OfferedMoney, 0)
    updateDisplayedMoneyOffer(theirOffer.OfferedMoney, 0)

    updateDisplayJailCardsOffer(ourOffer.OfferedJailCards, 0)
    updateDisplayJailCardsOffer(theirOffer.OfferedJailCards, 0)
end

reset()

return function(): ()

end
