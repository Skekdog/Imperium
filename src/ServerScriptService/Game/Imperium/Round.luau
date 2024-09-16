local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Board = require(script.Parent.Board)
local SetTimeMilestone = require(script.Parent.Parent.SetTimeMilestone)
local SetWaitingText = require(script.Parent.Parent.SetWaitingText)
local Participant = require(script.Parent.Participant)
local Types = require(script.Parent.Types)

local module = {}

local function StartNextParticipantTurn(round: Types.Round): ()
    local lastIndex: number? = 0
    if round.CurrentParticipant then
        lastIndex = table.find(round.Participants, round.CurrentParticipant)
        assert(lastIndex, "Round has no current participant")
    end
    assert(lastIndex)

    if lastIndex >= #round.Participants then
        round.Turn += 1
        lastIndex = 0
    end

    lastIndex += 1

    local nextParticipant = round.Participants[lastIndex]    
    round.CurrentParticipant = nextParticipant

    local lastMovedAt = nextParticipant.LastMovedAt

    ReplicatedStorage:SetAttribute("CurrentPlayer", nextParticipant.Player.Name)
    SetTimeMilestone(round.GameConfiguration.PlayerTurnTime)

    ReplicatedStorage.Game.ServerClient.BeginTurn:FireAllClients(nextParticipant.Player.Name)

    task.delay(round.GameConfiguration.PlayerTurnTime, function()
        if lastMovedAt ~= nextParticipant.LastMovedAt then
            return
        end
        nextParticipant:TryPlayMove()
    end)
end

local function GetParticipant(round: Types.Round, player: Player): Types.Participant
    for _, participant in round.Participants do
        if participant.Player == player then
            return participant
        end
    end
    error(`Participant {player} not found`)
end

local function StartRound(round: Types.Round): ()
    if round.Started then
        error("Round already started")
    end

    round.Started = true

    ReplicatedStorage.Game.ServerClient.SetMovementEnabled:FireAllClients(false)

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

local function RemoveParticipant(round: Types.Round, participant: Types.Participant): ()
    table.remove(round.Participants, table.find(round.Participants, participant))
    if #round.Participants == 1 then
        round.Participants[1]:GetTheDub()
    elseif round.CurrentParticipant == participant and #round.Participants > 1 then
        StartNextParticipantTurn(round)
    end
end

function module.new(boardConfiguration: Types.BoardConfiguration, tiles: {Types.Tile}, gameConfiguration: Types.GameConfiguration): Types.Round
    local round = {}

    round.Board = Board.new(tiles)
    round.BoardConfiguration = boardConfiguration
    round.GameConfiguration = gameConfiguration

    round.Started = false
    round.Turn = 0

    round.Tiles = tiles
    
    round.Participants = {}

    round.StartNextParticipantTurn = StartNextParticipantTurn
    round.GetParticipant = GetParticipant
    round.StartRound = StartRound
    round.RemoveParticipant = RemoveParticipant

    for _, player in Players:GetPlayers() do
        table.insert(round.Participants, Participant.new(player, round))
    end

    Random.new():Shuffle(round.Participants)

    ReplicatedStorage:SetAttribute("FineAmount", boardConfiguration.JailFine)

    round.CurrentParticipant = round.Participants[#round.Participants]

    return round
end

return module