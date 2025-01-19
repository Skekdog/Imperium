local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPlayerName = require(ReplicatedStorage.Shared.GetPlayerName)
local ScreenMessage = require(ReplicatedStorage.Shared.ScreenMessage)
local ClientTypes = require(script.Parent.ClientTypes)
local CreateAssetButton = require(script.Parent.CreateAssetButton)
local UIAnimation = require(ReplicatedStorage.Shared.UIAnimation)
local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local IsTradeValid = require(script.Parent.IsTradeValid)
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
    elseif response == "JailCardsBelowZero" then
        ScreenMessage("Error", "Cannot offer a negative amount of jail cards.")
    elseif response == "MoneyBelowZero" then
        ScreenMessage("Error", "Cannot offer a negative amount of money.")
    elseif response == "Success" then
        return true
    else
        ScreenMessage("Error", "An unknown error occurred.")
    end

    return false
end

local function notifyOfferAcceptResponse(response: ClientTypes.TradeOfferAcceptInvokeResult): boolean
    if response == "Expired" then
        ScreenMessage("Error", "Trade has expired.")
    elseif response == "OtherJailCardsBelowZero" then
        ScreenMessage("Error", "Target offer has a negative amount of jail cards.")
    elseif response == "OtherMoneyBelowZero" then
        ScreenMessage("Error", "Target offer has a negative amount of money.")
    elseif response == "SelfJailCardsBelowZero" then
        ScreenMessage("Error", "Your offer has a negative amount of jail cards.")
    elseif response == "SelfMoneyBelowZero" then
        ScreenMessage("Error", "Your offer has a negative amount of money.")
    elseif response == "OtherNotEnoughJailCards" then
        ScreenMessage("Error", "Target no longer has enough jail cards.")
    elseif response == "OtherNotEnoughMoney" then
        ScreenMessage("Error", "Target no longer has enough money.")
    elseif response == "SelfNotEnoughJailCards" then
        ScreenMessage("Error", "You no longer have enough jail cards.")
    elseif response == "SelfNotEnoughMoney" then
        ScreenMessage("Error", "You no longer have enough money.")
    elseif response == "OtherUnownedAsset" then
        ScreenMessage("Error", "Target no longer owns some of the assets in their offer.")
    elseif response == "SelfUnownedAsset" then
        ScreenMessage("Error", "You no longer own some of the assets in your offer.")
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

local currentDraftTrader: string?
local currentTrader: string?

local ourItems = object.YourItems.Items
local theirItems = object.TheirItems.Items
local ourOffer = object.YourOffer.Items
local theirOffer = object.TheirOffer.Items

local ourMoneyOffer = 0
local ourJailCardsOffer = 0

local theirMoneyOffer = 0
local theirJailCardsOffer = 0

local weAccepted = false
local theyAccepted = false

local acceptButton = object.Choices.Accept
local function updateAcceptance(isOwn: boolean, accepted: boolean): ()
    if isOwn then
        weAccepted = accepted
    else
        theyAccepted = accepted
    end

    local countAccepted = 0
    if weAccepted then
        countAccepted += 1
    end
    if theyAccepted then
        countAccepted += 1
    end

    acceptButton.Text = `{if weAccepted then "Unaccept" else "Accept"} ({countAccepted}/2)`
end

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

    if currentTrader then
        local success = notifyOfferUpdateResponse(tradeRemotes:WaitForChild("UpdateTradeOffer"):InvokeServer(currentTrader, offer))
        if not success then
            if assetData.Owner == lclPlayer.Name then
                assetData.Button.Parent = ourItems :: any
            elseif assetData.Owner == currentTrader then
                assetData.Button.Parent = theirItems :: any
            end
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

    if currentTrader then
        local success = notifyOfferUpdateResponse(tradeRemotes:WaitForChild("UpdateTradeOffer"):InvokeServer(currentTrader, offer))
        if not success then
            if assetData.Owner == lclPlayer.Name then
                assetData.Button.Parent = ourOffer :: any
            elseif assetData.Owner == currentTrader then
                assetData.Button.Parent = theirOffer :: any
            end
        end
    end
end

local function processAssetButtonClick(isOwn: boolean, assetData: AssetData): ()
    if currentTrader and not isOwn then
        return
    end

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
    else
        local button = CreateAssetButton(UDim2.new(1, 0, 0.15, 0), asset)
        assets[asset.Name] = {
            Button = button,
            Owner = plr,
            Name = asset.Name,
        }

        bindToClick(button, function()
            processAssetButtonClick(plr == lclPlayer.Name, assert(assets[asset.Name]))
        end)
    end

    local button = assert(assets[asset.Name]).Button
    if plr == currentTrader or plr == currentDraftTrader then
        button.Parent = theirItems :: any
    elseif plr == Players.LocalPlayer.Name then
        button.Parent = ourItems :: any
    else
        button.Parent = nil :: any
    end
end)

serverClient:WaitForChild("RemoveAsset").OnClientEvent:Connect(function(plr: string, asset: string): ()
    local assetData = assets[asset]
    if assetData and assetData.Owner == plr then
        assetData.Button:Destroy()
        assets[asset] = nil
    end
end)

local function updateMoneyOffer(isOwn: boolean, value: number): ()
    if isOwn then
        ourMoneyOffer = value
    else
        theirMoneyOffer = value
    end

    local label = (if isOwn then ourOffer.OfferedMoney else theirOffer.OfferedMoney) :: TextLabel
    if value == 0 then
        label.Visible = false
        return
    end
    assert(value > 0, "Value must be greater than 0")

    label.Text = `{GetCurrencySymbol()}{value} Cash`
    label.Visible = true
end

local function updateJailCardsOffer(isOwn: boolean, value: number): ()
    if isOwn then
        ourJailCardsOffer = value
    else
        theirJailCardsOffer = value
    end

    local label = (if isOwn then ourOffer.OfferedJailCards else theirOffer.OfferedJailCards) :: TextLabel
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

local moneyOfferIntervals = {1, 10, 100, -100, -10, -1}
local function makeMoneyOfferButtons(parent: typeof(ourItems.MoneyOffers) | typeof(theirItems.MoneyOffers), isOwn: boolean): ()
    for _, v in moneyOfferIntervals do
        local clone = moneyOfferTemplate:Clone()
        clone.Name = tostring(v)
        clone.Text = `{if v > 0 then "+" else ""}{GetCurrencySymbol()}{v}`
        clone.Visible = true
        clone.Parent = parent :: any

        bindToClick(clone, function()
            if currentTrader and not isOwn then
                return
            end

            if v > 0 and (if isOwn then ourMoneyOffer else theirMoneyOffer) + v > getPlayerMoney(if isOwn then nil else currentDraftTrader) then
                return ScreenMessage("Error", `{if isOwn then "You don't" else "Target doesn't"} have enough money.`)
            end

            local value = if isOwn then ourMoneyOffer else theirMoneyOffer
            local actualDiff = math.max(value + v, 0) - value

            updateMoneyOffer(isOwn, value + actualDiff)

            local offer: ClientTypes.TradeOfferMoneyUpdate = {
                Kind = "Money",
                Amount = if isOwn then ourMoneyOffer else theirMoneyOffer
            }
            
            if currentTrader then
                local success = notifyOfferUpdateResponse(tradeRemotes:WaitForChild("UpdateTradeOffer"):InvokeServer(currentTrader, offer))
                if not success then
                    updateMoneyOffer(isOwn, (if isOwn then ourMoneyOffer else theirMoneyOffer) - actualDiff)
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

local moneyCellSize = UDim2.new(1 / #moneyOfferIntervals, -ourItems.MoneyOffers.UIGridLayout.CellPadding.X.Offset, 1, 0)
ourItems.MoneyOffers.UIGridLayout.CellSize = moneyCellSize
theirItems.MoneyOffers.UIGridLayout.CellSize = moneyCellSize

local jailCardOfferTemplate = ourItems.JailCardOffers.Template

local ourJailCardOfferButtons: {[typeof(jailCardOfferTemplate)]: number} = {}
local theirJailCardOfferButtons: {[typeof(jailCardOfferTemplate)]: number} = {}

local jailCardOfferIntervals = {1, -1}
local function makeJailCardOfferButtons(parent: typeof(ourItems.JailCardOffers) | typeof(theirItems.JailCardOffers), isOwn: boolean): ()
    for _, v in jailCardOfferIntervals do
        local clone = jailCardOfferTemplate:Clone()
        clone.Name = tostring(v)
        clone.Text = `{if v > 0 then "+" else ""}{v} Jail Card`
        clone.Visible = true
        clone.Parent = parent :: any

        bindToClick(clone, function()
            if currentTrader and not isOwn then
                return
            end

            if v > 0 and (if isOwn then ourJailCardsOffer else theirJailCardsOffer) + v > getPlayerJailCards(if isOwn then nil else currentDraftTrader) then
                return ScreenMessage("Error", `{if isOwn then "You don't" else "Target doesn't"} have enough jail cards.`)
            end

            local value = if isOwn then ourJailCardsOffer else theirJailCardsOffer
            local actualDiff = math.max(value + v, 0) - value

            updateJailCardsOffer(isOwn, value + actualDiff)

            local offer: ClientTypes.TradeOfferJailCardsUpdate = {
                Kind = "JailCards",
                Amount = if isOwn then ourJailCardsOffer else theirJailCardsOffer
            }
            
            if currentTrader then
                local success = notifyOfferUpdateResponse(tradeRemotes:WaitForChild("UpdateTradeOffer"):InvokeServer(currentTrader, offer))
                if not success then
                    updateJailCardsOffer(isOwn, (if isOwn then ourJailCardsOffer else theirJailCardsOffer) - actualDiff)
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

local jailCardCellSize = UDim2.new(1 / #jailCardOfferIntervals, -ourItems.JailCardOffers.UIGridLayout.CellPadding.X.Offset, 1, 0)
ourItems.JailCardOffers.UIGridLayout.CellSize = jailCardCellSize
theirItems.JailCardOffers.UIGridLayout.CellSize = jailCardCellSize

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

    currentDraftTrader = nil
    currentTrader = nil

    updateAcceptance(true, false)
    updateAcceptance(false, false)

    updateMoneyOffer(true, 0)
    updateMoneyOffer(false, 0)

    updateJailCardsOffer(true, 0)
    updateJailCardsOffer(false, 0)
end

reset()

local module = {}

local function tryCreateOfferFromUI(): {Success: true, Offer: ClientTypes.InitialTradeOffer} | {Success: false, Reason: string}
    local ourOfferedAssets: {string} = {}
    for _, v in ourOffer:GetChildren() do
        local splitName = v.Name:split("Asset_")[2]
        local asset = assets[splitName]
        if asset then
            if asset.Owner ~= lclPlayer.Name then
                return {Success = false, Reason = `Failed to offer trade as you no longer own {asset.Name}.`}
            end
            table.insert(ourOfferedAssets, splitName)
        end
    end

    local theirOfferedAssets: {string} = {}
    for _, v in theirOffer:GetChildren() do
        local splitName = v.Name:split("Asset_")[2]
        local asset = assets[splitName]
        if asset then
            if asset.Owner ~= currentDraftTrader then
                return {Success = false, Reason = `Failed to offer trade as target no longer owns {asset.Name}.`}
            end
            table.insert(theirOfferedAssets, splitName)
        end
    end

    local tradeOffer = {
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

    return {
        Success = true,
        Offer = tradeOffer,
    }
end

local function validateOfferFromUI(): {Success: false, Reason: string?} | {Success: true, Offer: ClientTypes.InitialTradeOffer}
    local offer = tryCreateOfferFromUI()
    if not offer.Success then
        ScreenMessage("Error", offer.Reason)
        return {
            Success = false,
            Reason = offer.Reason,
        }
    end

    local ourAssets: {string} = {}
    local theirAssets: {string} = {}
    for _, v in assets do
        assert(v)
        if v.Owner == lclPlayer.Name then
            table.insert(ourAssets, v.Name)
        elseif v.Owner == currentDraftTrader then
            table.insert(theirAssets, v.Name)
        end
    end

    local ourView = {
        Money = getPlayerMoney(),
        JailCards = getPlayerJailCards(),
        Assets = ourAssets,
    }

    local theirView = {
        Money = getPlayerMoney(currentDraftTrader),
        JailCards = getPlayerJailCards(currentDraftTrader),
        Assets = theirAssets,
    }

    local success = notifyOfferAcceptResponse(IsTradeValid.IsTradeValid(offer.Offer, ourView, theirView))

    if not success then
        return {Success = false}
    end

    return {
        Success = true,
        Offer = offer.Offer,
    }
end

function module.DraftTrade(player: Player | Configuration): ClientTypes.InitialTradeOffer?
    reset()

    currentDraftTrader = player.Name

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

        assert(currentDraftTrader, "No current trader")

        if proposed then
            local tradeOffer = validateOfferFromUI()
            if not tradeOffer.Success then
                success = false
                continue
            end

            return tradeOffer.Offer
        end

        if success == nil then
            success = true
        end

        proposed = nil
    until success

    return nil
end

function module.Trading(player: Player | Configuration, offer: ClientTypes.InitialTradeOffer): ()
    reset()

    currentTrader = player.Name

    updateMoneyOffer(true, offer.OurOffer.Money)
    updateMoneyOffer(false, offer.TheirOffer.Money)

    updateJailCardsOffer(true, offer.OurOffer.JailCards)
    updateJailCardsOffer(false, offer.TheirOffer.JailCards)

    for _, v in assets do
        assert(v)
        if v.Owner == lclPlayer.Name then
            v.Button.Parent = ourItems :: any
        elseif v.Owner == player.Name then
            v.Button.Parent = theirItems :: any
        end
    end

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

    object.Choices.Propose.Visible = false
    object.Choices.Cancel.Visible = false

    object.Choices.Reject.Visible = true
    acceptButton.Visible = true

    bindToClick(acceptButton, function()
        assert(currentTrader, "No current trader")
        
        local pass = validateOfferFromUI().Success
        if not pass then
            return
        end

        updateAcceptance(true, not weAccepted)
        local success = notifyOfferAcceptResponse(tradeRemotes.SendTradeAcceptance:InvokeServer(currentTrader, weAccepted) :: ClientTypes.TradeOfferAcceptInvokeResult)
        if not success then
            updateAcceptance(true, false)
        end
    end)

    bindToClick(object.Choices.Reject, function()
        assert(currentTrader, "No current trader")
        notifyOfferAcceptResponse(tradeRemotes.RejectTradeOffer:InvokeServer(currentTrader) :: ClientTypes.TradeOfferRejectInvokeResult)
        ui:ToggleVisible(false)
    end)

    object.Title:SetAttribute("Player_1", GetPlayerName(player))
    object.Title:SetAttribute("Format", `Trading with [PLAYER]`)
    object.Title:AddTag("DynamicNames")

    ui:ToggleVisible(true)
end

tradeRemotes.ReceiveUpdatedTradeOffer.OnClientEvent:Connect(function(trader: string, offer: ClientTypes.TradeOfferUpdate): ()
    if currentTrader ~= trader then
        return
    end

    if offer.Kind == "Money" then
        theirMoneyOffer = offer.Amount
        updateMoneyOffer(false, theirMoneyOffer)
    elseif offer.Kind == "JailCards" then
        theirJailCardsOffer = offer.Amount
        updateJailCardsOffer(false, theirJailCardsOffer)
    elseif offer.Kind == "Asset" then
        local asset = assets[offer.Name]
        if asset then
            if offer.Mode == "Add" then
                asset.Button.Parent = theirOffer :: any
            elseif offer.Mode == "Remove" then
                asset.Button.Parent = theirItems :: any
            end
        end
    end
end)

tradeRemotes.ReceiveUpdatedTradeAcceptance.OnClientEvent:Connect(function(trader: string, accepted: boolean): ()
    if currentTrader ~= trader then
        return
    end

    updateAcceptance(false, accepted)
end)

tradeRemotes.TradeEnded.OnClientEvent:Connect(function(trader: string, reason: ClientTypes.TradeResetReason)
    if currentTrader ~= trader then
        return
    end

    ui:ToggleVisible(false)

    if reason == "Disconnected" then
        ScreenMessage("Error", "Trade ended because target disconnected.")
    elseif reason == "GoingBankrupt" then
        ScreenMessage("Error", "Trade ended because someone is going bankrupt.")
    elseif reason == "TradeAccepted" then
        ScreenMessage("Success", `Trade accepted with {GetPlayerName(trader)}!`)
    elseif reason == "TradeRejected" then
        ScreenMessage("Error", "Trade was rejected.")
    else
        ScreenMessage("Error", "Trade ended for an unknown reason.")
    end
end)

module.UI = ui

return module