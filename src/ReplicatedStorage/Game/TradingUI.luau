local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPlayerName = require(ReplicatedStorage.Shared.GetPlayerName)
local ScreenMessage = require(ReplicatedStorage.Shared.ScreenMessage)
local ClientTypes = require(script.Parent.ClientTypes)
local CreateAssetButton = require(script.Parent.CreateAssetButton)
local UIAnimation = require(ReplicatedStorage.Shared.UIAnimation)
local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local lclPlayer = Players.LocalPlayer

type AssetData = {
    Button: CreateAssetButton.Button,
    Owner: string,
    Name: string,
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

local theirMoneyOffer = 0
local theirJailCardsOffer = 0

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

local function offerAsset(assetData: AssetData): ()
    local offer: ClientTypes.TradeOfferAssetUpdate = {
        Kind = "Asset",
        Name = assetData.Name,
        Mode = "Add",
    }

    assetData.Button.Parent = if assetData.Owner == lclPlayer.Name then ourOffer :: any else theirOffer :: any

    local success = notifyOfferUpdateResponse(tradeRemotes:WaitForChild("UpdateTradeOffer"):InvokeServer(currentTrader, offer))
    if not success then
        if assetData.Owner == lclPlayer.Name then
            assetData.Button.Parent = ourItems :: any
        elseif assetData.Owner == currentTrader then
            assetData.Button.Parent = theirItems :: any
        end
    end
end

local function retractAsset(assetData: AssetData): ()
    local offer: ClientTypes.TradeOfferAssetUpdate = {
        Kind = "Asset",
        Name = assetData.Name,
        Mode = "Remove",
    }

    assetData.Button.Parent = if assetData.Owner == lclPlayer.Name then ourItems :: any else theirItems :: any

    local success = notifyOfferUpdateResponse(tradeRemotes:WaitForChild("UpdateTradeOffer"):InvokeServer(currentTrader, offer))
    if not success then
        if assetData.Owner == lclPlayer.Name then
            assetData.Button.Parent = ourOffer :: any
        elseif assetData.Owner == currentTrader then
            assetData.Button.Parent = theirOffer :: any
        end
    end
end

local function processAssetButtonClick(assetData: AssetData): ()
    if assetData.Button.Parent == ourItems :: any or assetData.Button.Parent == theirItems :: any then
        offerAsset(assetData)
    elseif assetData.Button.Parent == ourOffer :: any or assetData.Button.Parent == theirOffer :: any then
        retractAsset(assetData)
    end
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
            Name = asset.Name,
        }

        bindToClick(button, function()
            processAssetButtonClick(assert(assets[asset.Name]))
        end)
    end
end)

serverClient:WaitForChild("RemoveAsset").OnClientEvent:Connect(function(plr: string, asset: string): ()
    local assetData = assets[asset]
    if assetData and assetData.Owner == plr then
        assetData.Button:Destroy()
        assets[asset] = nil
    end
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
            if (if isOwn then ourMoneyOffer else theirMoneyOffer) + v > getPlayerMoney(if isOwn then nil else currentTrader) then
                return ScreenMessage("Error", `{if isOwn then "You don't" else "Target doesn't"} have enough money.`)
            end

            local actualDiff: number
            if isOwn then
                actualDiff = math.max(ourMoneyOffer + v, 0) - ourMoneyOffer
                ourMoneyOffer = math.max(ourMoneyOffer + v, 0)
                updateDisplayedMoneyOffer(ourOffer.OfferedMoney, ourMoneyOffer)
            else
                actualDiff = math.max(theirMoneyOffer + v, 0) - theirMoneyOffer
                theirMoneyOffer = math.max(theirMoneyOffer + v, 0)
                updateDisplayedMoneyOffer(theirOffer.OfferedMoney, theirMoneyOffer)
            end

            local offer: ClientTypes.TradeOfferMoneyUpdate = {
                Kind = "Money",
                Amount = v
            }
            
            local success = notifyOfferUpdateResponse(tradeRemotes:WaitForChild("UpdateTradeOffer"):InvokeServer(currentTrader, offer))
            if not success then
                if isOwn then
                    ourMoneyOffer -= actualDiff
                    updateDisplayedMoneyOffer(ourOffer.OfferedMoney, ourMoneyOffer)
                else
                    theirMoneyOffer -= actualDiff
                    updateDisplayedMoneyOffer(theirOffer.OfferedMoney, theirMoneyOffer)
                end
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
            if (if isOwn then ourJailCardsOffer else theirJailCardsOffer) + v > getPlayerJailCards(if isOwn then nil else currentTrader) then
                return ScreenMessage("Error", `{if isOwn then "You don't" else "Target doesn't"} have enough jail cards.`)
            end

            local actualDiff: number
            if isOwn then
                actualDiff = math.max(ourJailCardsOffer + v, 0) - ourMoneyOffer
                ourJailCardsOffer += v
                updateDisplayJailCardsOffer(ourOffer.OfferedJailCards, ourJailCardsOffer)
            else
                actualDiff = math.max(theirJailCardsOffer + v, 0) - theirJailCardsOffer
                theirJailCardsOffer += v
                updateDisplayJailCardsOffer(theirOffer.OfferedJailCards, theirJailCardsOffer)
            end

            local offer: ClientTypes.TradeOfferJailCardsUpdate = {
                Kind = "JailCards",
                Amount = v
            }
            
            local success = notifyOfferUpdateResponse(tradeRemotes:WaitForChild("UpdateTradeOffer"):InvokeServer(currentTrader, offer))
            if not success then
                if isOwn then
                    ourJailCardsOffer -= actualDiff
                    updateDisplayJailCardsOffer(ourOffer.OfferedJailCards, ourJailCardsOffer)
                else
                    theirJailCardsOffer -= actualDiff
                    updateDisplayJailCardsOffer(theirOffer.OfferedJailCards, theirJailCardsOffer)
                end
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

local function reset(): ()
    setHidden(false)

    for _, v in assets do
        assert(v).Button.Parent = nil :: any
    end

    currentTrader = nil

    ourMoneyOffer = 0
    ourJailCardsOffer = 0

    theirMoneyOffer = 0
    theirJailCardsOffer = 0

    updateDisplayedMoneyOffer(ourOffer.OfferedMoney, 0)
    updateDisplayedMoneyOffer(theirOffer.OfferedMoney, 0)

    updateDisplayJailCardsOffer(ourOffer.OfferedJailCards, 0)
    updateDisplayJailCardsOffer(theirOffer.OfferedJailCards, 0)
end

reset()

local module = {}

function module.DraftTrade(player: Player | Configuration): ClientTypes.InitialTradeOffer?
    reset()

    currentTrader = player.Name

    for _, v in assets do
        assert(v)
        if v.Owner == lclPlayer.Name then
            v.Button.Parent = ourItems :: any
        elseif v.Owner == player.Name then
            v.Button.Parent = theirItems :: any
        end
    end

    object.Title:SetAttribute("Player_1", GetPlayerName(player))
    object.Title:SetAttribute("Format", `Drafting Trade with [PLAYER]`)
    object.Title:AddTag("DynamicNames")

    object.Choices.Reject.Visible = false
    object.Choices.Accept.Visible = false

    object.Choices.Propose.Visible = true
    object.Choices.Cancel.Visible = true

    ui:ToggleVisible(true)

    local success: boolean?
    repeat
        success = nil
        local proposed: boolean?
        bindToClick(object.Choices.Propose, function()
            proposed = true
        end)

        bindToClick(object.Choices.Cancel, function()
            proposed = false
        end)

        while proposed == nil do
            task.wait()
        end

        assert(currentTrader, "No current trader")

        if proposed then
            local ourOfferedAssets: {string} = {}
            for _, v in ourItems:GetChildren() do
                local asset = assets[v.Name]
                if asset then
                    if asset.Owner ~= lclPlayer.Name then
                        ScreenMessage("Error", `Failed to offer trade as you no longer own {asset.Name}.`)
                        success = false
                        break
                    end
                    table.insert(ourOfferedAssets, v.Name)
                end
            end

            local theirOfferedAssets: {string} = {}
            for _, v in theirItems:GetChildren() do
                local asset = assets[v.Name]
                if asset then
                    if asset.Owner ~= currentTrader then
                        ScreenMessage("Error", `Failed to offer trade as target no longer owns {asset.Name}.`)
                        success = false
                        break
                    end
                    table.insert(theirOfferedAssets, v.Name)
                end
            end

            if theirMoneyOffer > getPlayerMoney(currentTrader) then
                ScreenMessage("Error", `Failed to offer trade as target doesn't have enough money.`)
                success = false
                return
            end

            if ourMoneyOffer > getPlayerMoney() then
                ScreenMessage("Error", `Failed to offer trade as you don't have enough money.`)
                success = false
                return
            end

            if ourJailCardsOffer > getPlayerJailCards() then
                ScreenMessage("Error", `Failed to offer trade as you don't have enough jail cards.`)
                success = false
                return
            end

            if theirJailCardsOffer > getPlayerJailCards(currentTrader) then
                ScreenMessage("Error", `Failed to offer trade as target doesn't have enough jail cards.`)
                success = false
                return
            end

            return {
                OurOffer = {
                    Money = ourMoneyOffer,
                    JailCards = ourJailCardsOffer,
                    Assets = ourOfferedAssets,
                },
                TheirOffer = {
                    Money = theirMoneyOffer,
                    JailCards = theirJailCardsOffer,
                    Assets = theirOfferedAssets,
                }
            }
        end

        if success == nil then
            success = true
        end
    until success

    return nil
end

function module.Trading(player: Player | Configuration, offer: ClientTypes.InitialTradeOffer): ()
    reset()

    currentTrader = player.Name

    updateDisplayJailCardsOffer(ourOffer.OfferedJailCards, offer.OurOffer.JailCards)
    updateDisplayedMoneyOffer(ourOffer.OfferedMoney, offer.OurOffer.Money)

    updateDisplayJailCardsOffer(theirOffer.OfferedJailCards, offer.TheirOffer.JailCards)
    updateDisplayedMoneyOffer(theirOffer.OfferedMoney, offer.TheirOffer.Money)

    for _, v in offer.OurOffer.Assets do
        local asset = assets[v]
        if asset then
            asset.Button.Parent = ourOffer :: any
        end
    end

    for _, v in offer.TheirOffer.Assets do
        local asset = assets[v]
        if asset then
            asset.Button.Parent = theirOffer :: any
        end
    end

    object.Choices.Propose.Visible = true
    object.Choices.Cancel.Visible = true

    object.Choices.Reject.Visible = true
    object.Choices.Accept.Visible = true

    object.Title:SetAttribute("Player_1", GetPlayerName(player))
    object.Title:SetAttribute("Format", `Trading with [PLAYER]`)
    object.Title:AddTag("DynamicNames")

    ui:ToggleVisible(true)
end

module.UI = ui

return module