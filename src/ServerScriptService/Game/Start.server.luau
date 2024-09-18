local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Tile = require(script.Parent.Imperium.Tile)
local Types = require(script.Parent.Imperium.Types)
local GameConfiguration = require(script.Parent.Parent.Parent.ReplicatedFirst.Shared.GameConfiguration)
local GetTime = require(script.Parent.Parent.Parent.ReplicatedFirst.Shared.GetTime)
local Teleport = require(script.Parent.Parent.Shared.Teleport)
local Classic = require(ServerScriptService.Game.GameDefinitions.Classic.Classic)
local Round = require(ServerScriptService.Game.Imperium.Round)
local SetWaitingText = require(script.Parent.SetWaitingText)

local board = Classic

ServerStorage.Game.Maps:FindFirstChild("Happy Home"):Clone().Parent = workspace :: any

local tiles = {}
for i, description in board.Tiles do
    table.insert(tiles, Tile.new(board, i, description))
end

local info = MemoryStoreService:GetHashMap("GameInfo"):GetAsync(if game.PrivateServerId ~= "" then game.PrivateServerId else "NONE") :: Teleport.GameInfo?

if not info then
    local temp = {
        Players = if RunService:IsStudio() then 2 else 8,
        TurnTime = GameConfiguration.TurnTime.Default,
        AuctionTime = GameConfiguration.AuctionTime.Default,
        BankruptcyTime = GameConfiguration.BankruptcyTime.Default,
        Map = "Happy Home",
        Board = "Classic (UK)",
    } :: Teleport.GameInfo
    info = temp
end
assert(info)

local MAX_PLAYER_LOAD_WAIT_TIME = 120
local INTERMISSION_DURATION = 5

Players.PlayerAdded:Connect(function(plr)
    plr:SetAttribute("Status", "Spectating")
end)

local startWait = GetTime()
local players = #Players:GetPlayers()

SetWaitingText("Waiting for players...", MAX_PLAYER_LOAD_WAIT_TIME)

-- Note: we can't use Players.PlayerAdded because then we don't check for max time
while (players < info.Players) and (GetTime() - startWait < MAX_PLAYER_LOAD_WAIT_TIME) do
    task.wait()
    players = math.max(players, #Players:GetPlayers()) -- If a player disconnects after joining we don't want to stall the game
end

local round = Round.new(Classic, tiles, {
    PlayerTurnTime = info.TurnTime,
    AuctionTime = info.AuctionTime,
    BankruptcyTime = info.BankruptcyTime,
})

SetWaitingText("Starting soon...", INTERMISSION_DURATION)
task.wait(INTERMISSION_DURATION)

SetWaitingText(nil, 0)
round:StartRound()

local gameClientServer = ReplicatedStorage:WaitForChild("Game").ClientServer

local function canPlayMove(plr: Player): Types.Participant?
    local participant = round:TryGetParticipant(plr)

    if not participant then
        return
    end

    if round.CurrentParticipant == participant and not participant.IsMoving then
        return participant
    else
        return
    end
end

gameClientServer.RollDice.OnServerEvent:Connect(function(plr)
    local participant = canPlayMove(plr)
    if participant then
        participant:TryPlayMove()
    end
end)

gameClientServer.UseGetOutOfJailFreeCard.OnServerEvent:Connect(function(plr)
    local participant = canPlayMove(plr)
    if participant then
        participant:TryUseJailCard()
    end
end)

gameClientServer.PayFine.OnServerEvent:Connect(function(plr)
    local participant = canPlayMove(plr)
    if participant then
        participant:TryPayFine()
    end
end)

local function getAsset(plr: Player, name: string): Types.Asset?
    local participant = round:TryGetParticipant(plr)
    if not participant then
        return
    end
    
    for _, v in participant.Assets do
        if v.AssetDescription.Name == name then
            return v
        end
    end
    return
end

gameClientServer.BuyDevelopment.OnServerEvent:Connect(function(plr, property: unknown, development: unknown)
    if typeof(property) ~= "string" or (development ~= "House" and development ~= "Hotel") then
        return
    end

    local asset = getAsset(plr, property)
    if not asset then
        return
    end

    asset:TryDevelopProperty(development)
end)

gameClientServer.SellDevelopment.OnServerEvent:Connect(function(plr, property: unknown)
    if typeof(property) ~= "string" then
        return
    end

    local asset = getAsset(plr, property)
    if not asset then
        return
    end

    asset:TrySellDevelopment()
end)

gameClientServer.SellAllDevelopments.OnServerEvent:Connect(function(plr, property: unknown)
    if typeof(property) ~= "string" then
        return
    end

    local asset = getAsset(plr, property)
    if not asset then
        return
    end

    asset:TrySellAllDevelopments()
end)

gameClientServer.MortgageProperty.OnServerEvent:Connect(function(plr, property: unknown)
    if typeof(property) ~= "string" then
        return
    end

    local asset = getAsset(plr, property)
    if not asset then
        return
    end

    asset:TryMortgage()
end)

gameClientServer.UnmortgageProperty.OnServerEvent:Connect(function(plr, property: unknown)
    if typeof(property) ~= "string" then
        return
    end

    local asset = getAsset(plr, property)
    if not asset then
        return
    end

    asset:TryUnMortgage()
end)
