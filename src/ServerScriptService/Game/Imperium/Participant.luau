local SetTimeMilestone = require(script.Parent.Parent.SetTimeMilestone)
local TileUtils = require(script.Parent.Parent.TileUtils)
local Types = require(script.Parent.Types)

local module = {}

local function SendToJail(participant: Types.Participant): ()
    participant:MoveToTileByName("Jail", true)
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

local MAX_MOVE_DURATION = 45
local MAX_DIRECT_MOVE_DURATION = 10
local function moveCharacter(char: Model?, tile: Types.Tile, direct: boolean?, elapsedTime: number?): ()
    if not char then
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        return
    end

    local root = hum.RootPart
    if not root then
        return
    end

    local targetPosition = tile.Model:GetPivot().Position + Vector3.new(0, 3, 0)

    local startTime = os.time() - (elapsedTime or 0)
    local reached = false

    repeat
        if (root.Position - targetPosition).Magnitude < 2.5 then
            reached = true
            break
        end
        hum:MoveTo(targetPosition) -- MoveTo timesout after 8 seconds by default - but we want a longer timeout, so we set it every iteration
        task.wait(0.1) -- We don't need to wait really because MoveTo is blocking, but why not
    until os.time() - startTime > if direct then MAX_DIRECT_MOVE_DURATION else MAX_MOVE_DURATION
    
    if not reached then
        root.Position = targetPosition
    end
end

local function MoveTo(participant: Types.Participant, position: number, moveDirectly: boolean?, intialMove: boolean?): ()
    assert(participant.Position ~= position, `Participant {participant.Player} already at position {position}`)
    assert(position <= #participant.Round.Tiles and position > 0, `Participant {participant.Player} failed to move to position {position} as this exceeds the board limits`)

    local lastPosition = participant.Position
    if participant.Position == 1 and not moveDirectly and participant.LastMovedAt ~= 0 then
        GiveMoney(participant, participant.Round.Board.PassGoMoney)
    end

    if not intialMove then
        participant.LastMovedAt = workspace:GetServerTimeNow()
    end
    participant.Position = position

    local tile = participant.Round.Tiles[position]

    print(`Moved to {if tile.TileDescription.Asset then tile.TileDescription.Asset.Name else tile.TileDescription.Name}`)

    if not moveDirectly then
        local allTiles = participant.Round.Tiles
        local targetRow = TileUtils.GetRowFromPosition(position, #allTiles)
        local currentPosition = lastPosition

        local startTime = os.time()
        local currentRow = TileUtils.GetRowFromPosition(currentPosition, #allTiles)
        while currentRow ~= targetRow do
            local nextCornerPosition = TileUtils.GetWrapAround(TileUtils.GetNextCornerPosition(currentPosition, #allTiles), #allTiles)
            local nextCorner = participant.Round.Tiles[nextCornerPosition]

            currentPosition = nextCornerPosition
            currentRow = TileUtils.GetRowFromPosition(currentPosition, #allTiles)

            moveCharacter(participant.Player.Character, nextCorner, false, os.time() - startTime)
        end
        moveCharacter(participant.Player.Character, tile)
    else
        moveCharacter(participant.Player.Character, tile, moveDirectly)
    end

    if tile.TileDescription.OnEnter then
        tile.TileDescription.OnEnter(tile.TileDescription, participant)
    end
end

local function MoveBy(participant: Types.Participant, amount: number): ()
    local position = TileUtils.GetWrapAround(participant.Position + amount, #participant.Round.Tiles)
    MoveTo(participant, position)
end

local function MoveToTileByName(participant: Types.Participant, name: string, moveDirectly: boolean?): ()
    MoveTo(participant, participant.Round:FindTileByName(name), moveDirectly)
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