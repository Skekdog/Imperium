local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Tile = require(script.Parent.Imperium.Tile)
local Types = require(script.Parent.Imperium.Types)
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
        Players = if RunService:IsStudio() then 1 else 8,
        TurnDuration = 15,
        AuctionTime = 15,
        BankruptcyTime = 10,
    }
    info = temp
end
assert(info)

local MAX_PLAYER_LOAD_WAIT_TIME = 120
local INTERMISSION_DURATION = 5

local turnTime = info.TurnDuration or 15
local auctionTime = info.AuctionTime or 15
local bankruptcyTime = info.BankruptcyTime or 60

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
    PlayerTurnTime = turnTime,
    AuctionTime = auctionTime,
    BankruptcyTime = bankruptcyTime,
})

SetWaitingText("Starting soon...", INTERMISSION_DURATION)
task.wait(INTERMISSION_DURATION)

SetWaitingText(nil, 0)
round:StartRound()

local gameClientServer = ReplicatedStorage:WaitForChild("Game").ClientServer

local function canPlayMove(plr: Player): Types.Participant?
    local participant = round:GetParticipant(plr)

    if round.CurrentParticipant == participant and not participant.IsMoving then
        return participant
    else
        return nil
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