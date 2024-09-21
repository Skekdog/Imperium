local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HasMoneyFor = require(script.Parent.HasMoneyFor)
local IsSpectating = require(script.Parent.IsSpectating)
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local PlayClickSound = require(script.Parent.Parent.Shared.PlayClickSound)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local auctionPropertyUI = UIManager.WaitForUI("AuctionProperty") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.AuctionProperty)}
local object = auctionPropertyUI.Object

local gameServerClient = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient")
gameServerClient:WaitForChild("StartAuction").OnClientEvent:Connect(function(description: {Name: string}?)
    if not description or IsSpectating() then
        return auctionPropertyUI:ToggleVisible(false)
    end
    object.PropertyName.Text = description.Name
    object.CurrentBid.Text = "£0"
    object.CurrentWinner.Text = ""
    auctionPropertyUI:ToggleVisible(true)
end)

gameServerClient:WaitForChild("UpdateAuction").OnClientEvent:Connect(function(highestBidder: Player, highestBid: number)
    object.CurrentBid.Text = "£" .. highestBid
    object.CurrentWinner.Text = GetPlayerName(highestBidder)
end)

local function parseValue(text: string): number
    return tonumber(text:sub(3)) or error("Invalid text: " .. text)
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