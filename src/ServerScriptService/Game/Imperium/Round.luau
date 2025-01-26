local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetTime = require(ReplicatedStorage.Shared.GetTime)
local WaitForever = require(ReplicatedStorage.Shared.WaitForever)
local Board = require(script.Parent.Board)
local BotPlayer = require(script.Parent.BotPlayer)
local FireRemote = require(script.Parent.Util.FireRemote)
local SetTimeMilestone = require(script.Parent.Parent.SetTimeMilestone)
local SetWaitingText = require(script.Parent.Parent.SetWaitingText)
local Participant = require(script.Parent.Participant)
local TileUtils = require(script.Parent.TileUtils)
local Types = require(script.Parent.Types)

local module = {}

local function getMinIndex(tbl: {[number]: any}): number
    -- note: the order of non-sequential table keys is undefined
    local lowest = table.maxn(tbl :: {any})
    for i in tbl do
        if i < lowest then
            lowest = i :: number
        end
    end

    return lowest
end

local function GetParticipantCount(round: Types.Round): number
    local count = 0
    for _ in round.Participants do
        count += 1
    end

    return count
end

local function GetHighestParticipantIndex(round: Types.Round): number
    return table.maxn(round.Participants)
end

local function GetNextParticipant(round: Types.Round): Types.GetNextParticipantResult
    local minIndex = getMinIndex(round.Participants)

    if #Players:GetChildren() < 1 or round:GetParticipantCount() < 1 then
        WaitForever()
    end

    if not round.CurrentParticipant then
        return {
            Participant = round.Participants[minIndex],
            IncrementTurn = false,
        }
    end

    if round.CurrentParticipant.Index >= round:GetHighestParticipantIndex() then
        return {
            Participant = round.Participants[minIndex],
            IncrementTurn = true,
        }
    end
    
    for i, v in round.Participants do
        assert(i)
        if i > round.CurrentParticipant.Index then
            return {
                Participant = v,
                IncrementTurn = false,
            }
        end
    end

    error("Failed to get next participant")
end

local function StartNextParticipantTurn(round: Types.Round): ()
    local result = round:GetNextParticipant()
    local nextParticipant = result.Participant
    
    if result.IncrementTurn then
        round.Turn += 1
    end

    round.CurrentParticipant = nextParticipant

    if round.IsPaused then
        ReplicatedStorage:SetAttribute("CurrentPlayer", nextParticipant.Player.Name)
        SetTimeMilestone(nil)
        ReplicatedStorage:SetAttribute("IsPaused", true)
        while round.IsPaused do
            task.wait()
        end
        ReplicatedStorage:SetAttribute("IsPaused", false)
    end

    if nextParticipant.HasDisconnected then
        nextParticipant:RemoveParticipant()
        return task.defer(round.StartNextParticipantTurn, round)
    end

    ReplicatedStorage:SetAttribute("CurrentPlayer", nextParticipant.Player.Name)
    SetWaitingText(nil, -1)
    SetTimeMilestone(round.GameConfiguration.PlayerTurnTime)

    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("BeginTurn"):FireAllClients(nextParticipant.Player.Name)

    local playedMove: "Dice" | "JailCard" | "Fine" | "Skip"?

    local botPlayer = round:GetBotPlayer(nextParticipant)
    if botPlayer then
        playedMove = botPlayer:DecideMove()
    else
        local gameClientServer = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ClientServer")

        local cons: {RBXScriptConnection} = {}
        local function clearCons(): ()
            for _, v in cons do
                v:Disconnect()
            end
        end

        table.insert(cons, gameClientServer:WaitForChild("RollDice").OnServerEvent:Connect(function(plr)
            if nextParticipant:CanPlayMove("Dice") and plr == (nextParticipant.Player :: Player) then
                clearCons()
                playedMove = "Dice"
            end
        end))

        table.insert(cons, gameClientServer:WaitForChild("UseGetOutOfJailFreeCard").OnServerEvent:Connect(function(plr)
            if nextParticipant:CanPlayMove("JailCard") and plr == (nextParticipant.Player :: Player) then
                clearCons()
                playedMove = "JailCard"
            end
        end))

        table.insert(cons, gameClientServer:WaitForChild("PayFine").OnServerEvent:Connect(function(plr)
            if nextParticipant:CanPlayMove("Fine") and plr == (nextParticipant.Player :: Player) then
                clearCons()
                playedMove = "Fine"
            end
        end))

        local start = GetTime()

        while not playedMove and GetTime() < start + round.GameConfiguration.PlayerTurnTime and not nextParticipant.HasDisconnected do
            task.wait()
        end

        clearCons()

        if not playedMove then
            playedMove = if nextParticipant.HasDisconnected then "Skip" else "Dice"
        end
        assert(playedMove)
    end

    FireRemote(ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("BeginTurn"), nextParticipant, "")
    if playedMove == "Dice" then
        nextParticipant:TryPlayMove()
    elseif playedMove == "JailCard" then
        nextParticipant:TryUseJailCard()
    elseif playedMove == "Fine" then
        nextParticipant:TryPayFine()
    elseif playedMove == "Skip" then
        return StartNextParticipantTurn(round)
    end

    if botPlayer then
        botPlayer:FinishTurn()
    end

    task.defer(round.StartNextParticipantTurn, round)
end

local function TryGetParticipant(round: Types.Round, player: Player | Configuration): Types.Participant?
    for _, participant in round.Participants do
        if participant.Player == player then
            return participant
        end
    end
    return
end

local function StartRound(round: Types.Round): ()
    if round.Started then
        error("Round already started")
    end

    round.Started = true

    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("SetMovementEnabled"):FireAllClients(false)

    SetWaitingText("Starting soon...", 8)
    local threads = {}
    for _, v in round.Participants do
        v.Player:SetAttribute("Status", "Playing")
        table.insert(threads, task.spawn(v.MoveTo, v, 1, true, true))
    end

    while true do
        task.wait()

        local shouldBreak = true
        for _, v in threads do
            if coroutine.status(v) ~= "dead" then
                shouldBreak = false
                break
            end
        end

        if shouldBreak then
            break
        end
    end

    StartNextParticipantTurn(round)
end

local function SetFreeParkingMoney(round: Types.Round, amount: number): ()
    if not round.GameConfiguration.FreeParkingBonusEnabled then
        return
    end
    round._freeParkingMoney = amount
    ReplicatedStorage:SetAttribute("FreeParkingMoney", amount)
end

local function GetFreeParkingMoney(round: Types.Round): number
    return round._freeParkingMoney
end

local function GetBotPlayer(round: Types.Round, participant: Types.Participant): Types.BotPlayer?
    return round.BotPlayers[participant]
end

function module.new(boardConfiguration: Types.BoardConfiguration, tiles: {Types.Tile}, gameConfiguration: Types.GameConfiguration): Types.Round
    local round = {}

    round.Board = Board.new(tiles)
    round.BoardConfiguration = boardConfiguration
    round.GameConfiguration = gameConfiguration

    round.BotPlayers = {}

    round._freeParkingMoney = 0
    round.Started = false
    round.Turn = 0

    round.Tiles = tiles
    
    round.Participants = {}

    round.IsPaused = false
    round.StartNextParticipantTurn = StartNextParticipantTurn
    round.TryGetParticipant = TryGetParticipant
    round.StartRound = StartRound
    round.GetNextParticipant = GetNextParticipant

    round.GetParticipantCount = GetParticipantCount
    round.GetHighestParticipantIndex = GetHighestParticipantIndex

    round.SetFreeParkingMoney = SetFreeParkingMoney
    round.GetFreeParkingMoney = GetFreeParkingMoney

    round.GetBotPlayer = GetBotPlayer

    for _, player in Players:GetPlayers() do
        table.insert(round.Participants, Participant.new(player, round))
    end

    for _, v in gameConfiguration.BotPlayers do
        local botPlayer = BotPlayer.new(round, v)
        table.insert(round.Participants, botPlayer.Participant)
        round.BotPlayers[botPlayer.Participant] = botPlayer
    end

    local participants = round.Participants
    Random.new():Shuffle(participants)
    local left = 1
    for i = 1, #participants do
        if not round:GetBotPlayer(participants[i]) then
            participants[left], participants[i] = participants[i], participants[left]
            left = left + 1
        end
    end

    for i, v in participants do
        v.Index = i
    end

    ReplicatedStorage:SetAttribute("FineAmount", boardConfiguration.JailFine)

    local colourOrders = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ColourOrders")
    for i, tile in tiles do
        local color = TileUtils.GetColor3(tile.TileDescription, round):ToHex()
        if not colourOrders:GetAttribute(color) then
            colourOrders:SetAttribute(color, i)
        end
    end

    return round
end

return module