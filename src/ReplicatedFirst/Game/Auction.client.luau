local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local HasMoneyFor = require(script.Parent.HasMoneyFor)
local IsSpectating = require(script.Parent.IsSpectating)
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local PlayClickSound = require(script.Parent.Parent.Shared.PlayClickSound)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local auctionPropertyUI = UIManager.WaitForUI("AuctionProperty") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.AuctionProperty)}
local object = auctionPropertyUI.Object

local function resetAuction(description: {Name: string}?): ()
    print("received auction event, ", if description then description.Name else "no description")
    local currency = GetCurrencySymbol()
    print("got currency symbol: ", currency)
    object.CurrentBid.Text = `{currency}0`
    object.CurrentWinner.Text = ""
    
    print("IsSpectating: ", IsSpectating())
    if not description or IsSpectating() then
        print("hiding auction")
        return auctionPropertyUI:ToggleVisible(false)
    end

    auctionPropertyUI:ToggleVisible(true)
    object.PropertyName.Text = description.Name
    print("showing auction")
end
resetAuction()

print("after reset auction")
local gameServerClient = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient")
print("connecting to startauction event client")
gameServerClient:WaitForChild("StartAuction").OnClientEvent:Connect(resetAuction)
print("connected to start auction event client")

gameServerClient:WaitForChild("UpdateAuction").OnClientEvent:Connect(function(highestBidder: Player, highestBid: number)
    local currency = GetCurrencySymbol()
    object.CurrentBid.Text = currency .. highestBid

    object.CurrentWinner:SetAttribute("Player_1", GetPlayerName(highestBidder))
    object.CurrentWinner:SetAttribute("Format", "[PLAYER]")
    object.CurrentWinner:AddTag("DynamicNames")
end)

local function parseValue(text: string): number
    return tonumber(text:sub(1 + #GetCurrencySymbol())) or error("Invalid text: " .. text)
end

local function makeBid(text: string)
    local property = object.PropertyName.Text
    local amount = parseValue(text)

    local highestBid = parseValue(object.CurrentBid.Text)

    local price = highestBid + amount
    if not HasMoneyFor(price) then
        return
    end

    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ClientServer"):WaitForChild("MakeBid"):FireServer(property, price)
end

local bidButtons: {TextButton} = {}
for _, v in object.Increments:GetChildren() do
    if not v:IsA("TextButton") then
        continue
    end

    table.insert(bidButtons, v)
    
    v.Text = GetCurrencySymbol() .. v.Name
    v.Activated:Connect(function()
        PlayClickSound()
        makeBid(v.Text)
    end)
end

local function updateButtons(): ()
    local money = Players.LocalPlayer:GetAttribute("Money") :: number?

    for _, v in bidButtons do
        local price = parseValue(object.CurrentBid.Text) + parseValue(v.Text)
        v.Visible = if money then price <= money else false
    end
end
Players.LocalPlayer:GetAttributeChangedSignal("Money"):Connect(updateButtons)
object.CurrentBid:GetPropertyChangedSignal("Text"):Connect(updateButtons)
updateButtons()