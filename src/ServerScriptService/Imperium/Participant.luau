local ReplicatedFirst = game:GetService("ReplicatedFirst")
local SetTimeMilestone = require(script.Parent.Parent.SetTimeMilestone)
local Types = require(ReplicatedFirst.Types)

local module = {}

local function SendToJail(participant: Types.Participant): ()
    participant:MoveToTileByName("Jail")
    participant.DoublesStreak = 0
    participant.JailedOn = participant.Round.Turn
end

local function GiveAsset(participant: Types.Participant, asset: Types.Asset): ()
    table.insert(participant.Assets, asset)
end

local function RemoveAsset(participant: Types.Participant, asset: Types.Asset): ()
    local index = table.find(participant.Assets, asset)
    if index then
        table.remove(participant.Assets, index)
    end
end

local function GiveMoney(participant: Types.Participant, amount: number): ()
    participant.Money += amount
    participant.Player:SetAttribute("Money", participant.Money)
end

local function TransferAssetTo(participant: Types.Participant, to: Types.AssetOwner, asset: Types.Asset): ()
    RemoveAsset(participant, asset)

    if to ~= "Bank" then
        GiveAsset(to, asset)
    end
end

local function TransferMoneyTo(participant: Types.Participant, to: Types.AssetOwner, amount: number): ()
    GiveMoney(participant, -amount)
    if to ~= "Bank" then
        GiveMoney(to, amount)
    end
end

local function MoveTo(participant: Types.Participant, position: number, moveDirectly: boolean?): ()
    assert(participant.Position ~= position, `Participant {participant.Player} already at position {position}`)
    assert(position <= #participant.Round.Tiles and position > 0, `Participant {participant.Player} failed to move to position {position} as this exceeds the board limits`)

    if participant.Position == 1 and not moveDirectly and participant.LastMovedAt ~= 0 then
        GiveMoney(participant, participant.Round.Board.PassGoMoney)
    end

    participant.LastMovedAt = workspace:GetServerTimeNow()
    participant.Position = position

    local tile = participant.Round.Tiles[position]

    print(`Moved to {if tile.TileDescription.Asset then tile.TileDescription.Asset.Name else tile.TileDescription.Name}`)

    local char = participant.Player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:MoveTo(tile.Model:GetPivot().Position)
            hum.MoveToFinished:Wait() -- todo: implement a timeout and moveDirectly
            --todo: on an unrelated note, findnearesttilebycolour should only move forward
        end
    end

    if tile.TileDescription.OnEnter then
        tile.TileDescription.OnEnter(tile.TileDescription, participant)
    end
end

local function MoveBy(participant: Types.Participant, amount: number): ()
    local position = (participant.Position + amount) % #participant.Round.Tiles
    if position == 0 then
        position = 1
    end
    MoveTo(participant, position)
end

local function MoveToTileByName(participant: Types.Participant, name: string): ()
    MoveTo(participant, participant.Round:FindTileByName(name))
end

local function FindClosestPositionByColour(participant: Types.Participant, colour: string): number?
    local validPositions: {number} = {}
    for i, v in participant.Round.Tiles do
        if v.TileDescription.Asset and v.TileDescription.Asset.Colour == colour then
            table.insert(validPositions, i)
        end
    end

    local closest: {Position: number?, Distance: number} = {Position = nil, Distance = math.huge}
    for _, position in validPositions do
        local distance = math.abs(position - participant.Position)
        if distance < closest.Distance then
            closest = {Position = position, Distance = distance}
        end
    end

    return closest.Position
end

local function RollDice(participant: Types.Participant): Types.DiceRollResult
    local roll1 = math.random(1, 6)
    local roll2 = math.random(1, 6)

    print("Roll 1: ", roll1, " Roll 2: ", roll2, " Total: ", roll1 + roll2, " Doubles: ", roll1 == roll2)

    return {
        Result = roll1 + roll2,
        IsDoubles = roll1 == roll2,
    }
end

local function LeaveJail(participant: Types.Participant, skipTurn: boolean?): ()
    participant.JailedOn = 0
    if not skipTurn then
        participant:TryPlayMove()
    end
end

local function TryPlayMove(participant: Types.Participant): ()
    SetTimeMilestone(nil)
    if participant.JailedOn ~= 0 then
        if participant.JailedOn <= participant.Round.Turn - participant.Round.Board.JailLength then
            LeaveJail(participant)
        elseif participant.Round.Board.CanLeaveJailByRollingDoubles and RollDice(participant).IsDoubles then
            LeaveJail(participant)
        end
    else
        local roll = RollDice(participant)
        if roll.IsDoubles then
            participant.DoublesStreak += 1

            if participant.DoublesStreak >= participant.Round.Board.DoublesConsecutiveJailAmount then
                return SendToJail(participant)
            end
        else
            participant.DoublesStreak = 0
        end

        MoveBy(participant, roll.Result)
    end

    participant.Round:StartNextParticipantTurn()
end

local function GiveJailCard(participant: Types.Participant): ()
    participant.JailCards += 1
end

local function TransferJailCard(participant: Types.Participant, to: Types.AssetOwner): ()
    participant.JailCards -= 1

    if to ~= "Bank" then
        to:GiveJailCard()
    end
end

function module.new(player: Player, round: Types.Round): Types.Participant
    local participant = {}

    participant.Player = player
    participant.Round = round

    participant.JailCards = round.Board.StartingJailCards
    participant.Money = round.Board.StartingMoney
    participant.Assets = {}

    participant.LastMovedAt = 0
    participant.DoublesStreak = 0
    participant.Position = 0
    participant.JailedOn = 0

    participant.SendToJail = SendToJail
    participant.GiveAsset = GiveAsset
    participant.RemoveAsset = RemoveAsset
    participant.GiveMoney = GiveMoney
    participant.TransferAssetTo = TransferAssetTo
    participant.TransferMoneyTo = TransferMoneyTo
    participant.MoveTo = MoveTo
    participant.MoveBy = MoveBy
    participant.RollDice = RollDice
    participant.TryPlayMove = TryPlayMove
    participant.MoveToTileByName = MoveToTileByName
    participant.FindClosestPositionByColour = FindClosestPositionByColour
    participant.GiveJailCard = GiveJailCard
    participant.TransferJailCard = TransferJailCard
    participant.LeaveJail = LeaveJail

    player:SetAttribute("Money", participant.Money)

    return participant
end

return module