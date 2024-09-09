local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Tile = require(script.Parent.Imperium.Tile)
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
    }
    info = temp
end
assert(info)

local MAX_PLAYER_LOAD_WAIT_TIME = 120
local INTERMISSION_DURATION = 10

local turnTime = info.TurnDuration
local auctionTime = info.AuctionTime

Players.PlayerAdded:Connect(function(plr)
    plr:SetAttribute("Status", "Spectating")
end)

local startWait = os.time()
local players = #Players:GetPlayers()

SetWaitingText("Waiting for players...", MAX_PLAYER_LOAD_WAIT_TIME)

-- Note: we can't use Players.PlayerAdded because then we don't check for max time
while (players < info.Players) and (os.time() - startWait < MAX_PLAYER_LOAD_WAIT_TIME) do
    task.wait()
    players = math.max(players, #Players:GetPlayers()) -- If a player disconnects after joining we don't want to stall the game
end

local round = Round.new(Classic, tiles, {
    PlayerTurnTime = turnTime,
    AuctionTime = auctionTime,
})

ReplicatedStorage.Game.ClientServer.RollDice.OnServerEvent:Connect(function(plr)
    local participant = round:GetParticipant(plr)

    if round.CurrentParticipant == participant then
        participant:TryPlayMove()
    end
end)

SetWaitingText("Starting soon...", INTERMISSION_DURATION)
task.wait(INTERMISSION_DURATION)

SetWaitingText(nil, 0)
round:StartRound()