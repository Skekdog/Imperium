local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local PlayClickSound = require(script.Parent.Parent.Shared.PlayClickSound)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local auctionPropertyUI = UIManager.WaitForUI("AuctionProperty") :: UIManager.UI & {Object: typeof(UIManager.UnregisteredUIs.AuctionProperty)}
local object = auctionPropertyUI.Object

ReplicatedStorage.Game.ServerClient.StartAuction.OnClientEvent:Connect(function(description: {Name: string}?)
    if not description then
        return auctionPropertyUI:ToggleVisible(false)
    end
    object.PropertyName.Text = description.Name
    object.CurrentBid.Text = "£0"
    object.CurrentWinner.Text = ""
    auctionPropertyUI:ToggleVisible(true)
end)

ReplicatedStorage.Game.ServerClient.UpdateAuction.OnClientEvent:Connect(function(highestBidder: Player, highestBid: number)
    object.CurrentBid.Text = "£" .. highestBid
    object.CurrentWinner.Text = GetPlayerName(highestBidder)
end)

local function makeBid(text: string)
    local property = object.PropertyName.Text
    local amount = tonumber(text:sub(3)) -- 3, not 2, because of character encoding
    assert(amount, "Invalid text: " .. text)

    local highestBid = tonumber(object.CurrentBid.Text:sub(3))
    assert(highestBid, "Invalid highest bid: " .. object.CurrentBid.Text)

    ReplicatedStorage.Game.ClientServer.MakeBid:FireServer(property, highestBid + amount)
end

for _, v in object.Increments:GetChildren() do
    if not v:IsA("TextButton") then
        continue
    end

    v.Activated:Connect(function()
        PlayClickSound()
        makeBid(v.Text)
    end)
end