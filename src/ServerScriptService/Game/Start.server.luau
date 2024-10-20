local MemoryStoreService = game:GetService("MemoryStoreService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Tile = require(script.Parent.Imperium.Tile)
local Types = require(script.Parent.Imperium.Types)
local ClientTypes = require(script.Parent.Parent.Parent.ReplicatedFirst.Game.ClientTypes)
local GameConfiguration = require(script.Parent.Parent.Parent.ReplicatedFirst.Shared.GameConfiguration)
local GetTime = require(script.Parent.Parent.Parent.ReplicatedFirst.Shared.GetTime)
local SendNotification = require(script.Parent.Parent.Shared.SendNotification)
local Teleport = require(script.Parent.Parent.Shared.Teleport)
local Round = require(ServerScriptService.Game.Imperium.Round)
local SetWaitingText = require(script.Parent.SetWaitingText)

local info = (MemoryStoreService:GetHashMap("GameInfo"):GetAsync(if game.PrivateServerId ~= "" then game.PrivateServerId else "NONE") or {}) :: Teleport.GameInfo?

if not info then
    info = {} :: Teleport.GameInfo
end
assert(info)

-- Lobby and game setting definitions may be out-of-sync with each other, so apply defaults on each setting
info.AuctionTime = info.AuctionTime or GameConfiguration.AuctionTime.Default :: number
info.BankruptcyTime = info.BankruptcyTime or GameConfiguration.BankruptcyTime.Default :: number
info.TurnTime = info.TurnTime or GameConfiguration.TurnTime.Default :: number
info.StartingMoney = info.StartingMoney or GameConfiguration.StartingMoney.Default :: number
info.Map = info.Map or GameConfiguration.Map.Default :: string
info.Board = info.Board or GameConfiguration.Board.Default :: string
info.FreeParkingBonusEnabled = info.FreeParkingBonusEnabled or GameConfiguration.FreeParkingBonusEnabled.Default :: string
info.Players = info.Players or (if RunService:IsStudio() then 3 else 8)

local map = ServerStorage.Game.Maps:FindFirstChild(info.Map)
assert(map, `Map {info.Map} not found`)
map:Clone().Parent = workspace

local boardFolder = ServerScriptService.Game.GameDefinitions:FindFirstChild(info.Board)
assert(boardFolder, `Board {info.Board} not found`)

local board = (require)(boardFolder:FindFirstChild("BoardTheme")) :: Types.BoardConfiguration

ReplicatedStorage:SetAttribute("CurrencySymbol", board.CurrencySymbol)
ReplicatedStorage:SetAttribute("BoardTheme", info.Board)
ReplicatedStorage:SetAttribute("Map", info.Map)

if info.FreeParkingBonusEnabled == "Enabled" then
    ReplicatedStorage:SetAttribute("FreeParkingMoney", 0)
end

local tiles = {}
for i, description in board.Tiles do
    table.insert(tiles, Tile.new(board, i, description))
end

local MAX_PLAYER_LOAD_WAIT_TIME = 120
local INTERMISSION_DURATION = 5

PhysicsService:RegisterCollisionGroup("Characters")
PhysicsService:RegisterCollisionGroup("Dice")
PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)
PhysicsService:CollisionGroupSetCollidable("Dice", "Characters", false)
local function disableCollision(part: Instance): ()
    if part:IsA("BasePart") then
        part.CollisionGroup = "Characters"
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr:SetAttribute("Status", "Spectating")
    plr.CharacterAdded:Connect(function(char)
        for _, v in char:GetDescendants() do
            disableCollision(v)
        end

        char.DescendantAdded:Connect(disableCollision)
    end)
    plr:LoadCharacter()
end)

local players = #Players:GetPlayers()

SetWaitingText("Waiting for players...", math.huge)
while players < 1 do
    task.wait()
    players = #Players:GetPlayers()
end

local startWait = GetTime()

SetWaitingText("Waiting for players...", MAX_PLAYER_LOAD_WAIT_TIME)

-- Note: we can't use Players.PlayerAdded because then we don't check for max time
while (players < info.Players) and (GetTime() - startWait < MAX_PLAYER_LOAD_WAIT_TIME) do
    task.wait()
    players = math.max(players, #Players:GetPlayers()) -- If a player disconnects after joining we don't want to stall the game
end

local round = Round.new(board, tiles, {
    PlayerTurnTime = info.TurnTime,
    AuctionTime = info.AuctionTime,
    BankruptcyTime = info.BankruptcyTime,
    StartingMoney = info.StartingMoney,
    FreeParkingBonusEnabled = if info.FreeParkingBonusEnabled == "Enabled" then true else false,
})

SetWaitingText("Starting soon...", INTERMISSION_DURATION)
task.wait(INTERMISSION_DURATION)

SetWaitingText(nil, 0)

Players.PlayerRemoving:Connect(function(plr)
    local participant = round:TryGetParticipant(plr)
    if participant then
        SendNotification(`{plr.Name} has left the game. Their assets will be auctioned off when their turn starts.`) -- todo: Format names correctly as per client settings. Can't just pass the player instance because they're gone
        participant.HasDisconnected = true
    end
end)

local gameClientServer = ReplicatedStorage:WaitForChild("Game").ClientServer

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

local tradeRemotes = ReplicatedStorage:WaitForChild("Game"):WaitForChild("Trading")
tradeRemotes:WaitForChild("RequestTrade").OnServerEvent:Connect(function(plr, to: unknown)
    if typeof(to) ~= "Instance" or not to:IsA("Player") or to == plr then
        return
    end

    local requestingParticipant = round:TryGetParticipant(plr)
    if not requestingParticipant then
        return
    end

    local targetParticipant = round:TryGetParticipant(to)
    if not targetParticipant then
        return
    end

    requestingParticipant.TradeManager:RequestTradeWith(targetParticipant)
end)

tradeRemotes:WaitForChild("AnswerTradeRequest").OnServerEvent:Connect(function(plr, target: unknown, accepted: unknown)
    if typeof(accepted) ~= "boolean" or typeof(target) ~= "Instance" or not target:IsA("Player") then
        return
    end

    local responder = round:TryGetParticipant(plr)
    if not responder then
        return
    end

    local trader = round:TryGetParticipant(target)
    if not trader then
        return
    end

    if trader.TradeManager.SentOfferTo ~= responder then
        return
    end

    responder.TradeManager:RespondRequest(accepted)
end)

tradeRemotes:WaitForChild("TradeAcceptance").OnServerEvent:Connect(function(plr, accepted: unknown)
    if typeof(accepted) ~= "boolean" and typeof(accepted) ~= "nil" then
        return
    end

    local participant = round:TryGetParticipant(plr)
    if not participant then
        return
    end

    participant.TradeManager:SetProposalAccepted(accepted)
end)

local function isTradeOfferUpdate(value: ClientTypes.TradeOfferUpdate): boolean
    if typeof(value) ~= "table" then
        return false
    end

    if typeof(value.Kind) ~= "string" then
        return false
    end

    if value.Kind == "JailCards" then
        return typeof(value.Amount) == "number"
    elseif value.Kind == "Money" then
        return typeof(value.Amount) == "number"
    elseif value.Kind == "Asset" then
        return typeof(value.Name) == "string" and (value.Mode == "Add" or value.Mode == "Remove")
    else
        return false
    end
end

tradeRemotes:WaitForChild("UpdateOffer").OnServerEvent:Connect(function(plr, offer: ClientTypes.TradeOfferUpdate)
    if not isTradeOfferUpdate(offer) then
        return
    end

    local participant = round:TryGetParticipant(plr)
    if not participant then
        return
    end

    participant.TradeManager:UpdateOffer(offer)
end)

round:StartRound()