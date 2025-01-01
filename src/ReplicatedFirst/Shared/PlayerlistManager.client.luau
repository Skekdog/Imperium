local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetPlayerName = require(script.Parent.GetPlayerName)
local GetUserId = require(script.Parent.GetUserId)
local IsLobby = require(script.Parent.IsLobby)
local AwaitReplicatedAttribute = require(script.Parent.Parent.Shared.AwaitReplicatedAttribute)
local UIManager = require(script.Parent.Parent.Shared.UIManager)

local ui = UIManager.WaitForUI("Playerlist").Object :: typeof(UIManager.UnregisteredUIs.Playerlist)
local list = ui.List

local layoutOrders = {
	["Playing"] = 0,
	["Spectating"] = 1000,
}

type PlayerElement = typeof(ui.PlayerFrame)
local players: {[string]: PlayerElement?} = {}
local function findPlr(plrName: string)
	return players[plrName]
end

function updatePlr(plr: Player | Configuration, clone: PlayerElement?)
	if not clone then
		return
	end

	local status = plr:GetAttribute("Status") or "Spectating"
	clone.Money.Text = tostring(plr:GetAttribute("Money") or 0)
	clone.Wins.Text = tostring(plr:GetAttribute("Wins") or 0)
	clone.JailCards.Text = tostring(plr:GetAttribute("GetOutOfJailFreeCards") or 0)

	if IsLobby() then
		clone.Trade.Visible = false
	else
		local IsSpectating = require(script.Parent.Parent.Game.IsSpectating)
		clone.Trade.Visible = status ~= "Spectating" and plr ~= Players.LocalPlayer and not IsSpectating()
	end
	
	movePlr(plr, status :: any)
end

local function createPlr(plr: Player | Configuration)
	local clone = ui.PlayerFrame:Clone()
	players[plr.Name] = clone

	clone.Username.Text = GetPlayerName(plr, "Both")

	pcall(function()
		clone.Avatar.Image = Players:GetUserThumbnailAsync(GetUserId(plr), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)

	clone.Visible = true
	clone.Name = "Player-"..plr.Name
	clone.Parent = list :: any

	local function update(): ()
		updatePlr(plr, clone)
	end

	plr:GetAttributeChangedSignal("Money"):Connect(update)
	plr:GetAttributeChangedSignal("Wins"):Connect(update)
	plr:GetAttributeChangedSignal("GetOutOfJailFreeCards"):Connect(update)
	plr:GetAttributeChangedSignal("Status"):Connect(update)

	clone.Trade.Activated:Connect(function()
		require(script.Parent.Parent.Game.SendTradeRequest)(plr)
	end)

	updatePlr(plr, clone)

	return clone :: PlayerElement
end

type Status = "Playing" | "Spectating"
local function recalculateCount(status: Status)
	local count = -1 -- Because this also counts the header
	for _, v in list:GetChildren() do
		if not v:IsA("GuiObject") then
			continue
		end

		if v.LayoutOrder // 1000 == (layoutOrders[status] / 1000) then
			count += 1
		end
	end

	local label = list:FindFirstChild(status) :: TextLabel
	label.Visible = count > 0

	label.Text = `{status} ({count})`
end

local function getStatus(order: number): Status
	order = (order // 1000) * 1000
	for _, v in list:GetChildren() do
		if not v:IsA("TextLabel") then
			continue
		end
		if v.LayoutOrder == order then
			local status = v.Text:split(" ")[1]
			return status :: Status
		end
	end
	error("Failed to get status for order: "..order)
end

function movePlr(plr: Player | Configuration, status: Status)
	local clone = findPlr(plr.Name) or createPlr(plr)
	local oldOrder = clone.LayoutOrder
	clone.LayoutOrder = layoutOrders[status] + 1

	recalculateCount(getStatus(oldOrder))

	recalculateCount(status)
end

local function removePlr(plr: Player | Configuration)
	local f = findPlr(plr.Name)
	players[plr.Name] = nil
	if f then
		f:Destroy()
		recalculateCount(getStatus(f.LayoutOrder))
	end
end

if false then -- This looks stupid but that's because it is. This doesn't do anything at runtime instead it silences the error about undefined global
	(movePlr :: any)()
end

Players.ChildRemoved:Connect(function(child)
	if child:IsA("Player") or child:IsA("Configuration") then
		removePlr(child)
	end
end)
Players.ChildAdded:Connect(function(child)
	if child:IsA("Player") or child:IsA("Configuration") then
		createPlr(child)
	end
end)

for _, v in Players:GetChildren() do
	assert(v:IsA("Player") or v:IsA("Configuration"))
	createPlr(v)
end

Players.LocalPlayer:GetAttributeChangedSignal("Status"):Connect(function()
	for _, v in Players:GetChildren() do
		assert(v:IsA("Player") or v:IsA("Configuration"))
		updatePlr(v)
	end
end)

game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

local roundInfo = ui.Info.RoundInfo.Info

if IsLobby() then
	roundInfo.Gamemode.Text = "Board Theme: Lobby"
	roundInfo.Map.Text = "Map: Lobby"
	roundInfo.FreeParkingMoney.Text = "Free Parking Money: Disabled"
else
	local GetCurrencySymbol = require(script.Parent.Parent.Game.GetCurrencySymbol)
	
	roundInfo.Gamemode.Text = "Board Theme: " .. AwaitReplicatedAttribute("BoardTheme")
	roundInfo.Map.Text = "Map: " .. AwaitReplicatedAttribute("Map")

	local freeParkingEnabled = not not AwaitReplicatedAttribute("FreeParkingMoney")
	roundInfo.FreeParkingMoney.Text = "Free Parking Money: " .. if freeParkingEnabled then GetCurrencySymbol() .. AwaitReplicatedAttribute("FreeParkingMoney") else "Disabled"

	ReplicatedStorage:GetAttributeChangedSignal("FreeParkingMoney"):Connect(function()
		roundInfo.FreeParkingMoney.Text = "Free Parking Money: " .. GetCurrencySymbol() .. AwaitReplicatedAttribute("FreeParkingMoney")
	end)
end