local SetTimeMilestone = require(script.Parent.Parent.SetTimeMilestone)
local TileMath = require(script.Parent.Parent.TileMath)
local TileUtils = require(script.Parent.TileUtils)
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

local function PurchaseProperty(participant: Types.Participant, asset: Types.Asset): ()
    assert(asset.Owner == "Bank", "Asset must be owned by bank")

    participant:TransferMoneyTo("Bank", asset.AssetDescription.Price)
    participant:GiveAsset(asset)
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

local function DrawCard(participant: Types.Participant, card: Types.CardDescription): ()
    card.Effect(participant)
end

local function MoveTo(participant: Types.Participant, position: number, moveDirectly: boolean?, intialMove: boolean?): ()
    assert(participant.Position ~= position, `Participant {participant.Player} already at position {position}`)
    assert(position <= #participant.Board.Tiles and position > 0, `Participant {participant.Player} failed to move to position {position} as this exceeds the board limits`)

    participant.PreviousPosition = participant.Position
    local passGo = (participant.Position == 1) or ((participant.Position > position) and (position ~= 1))
    if passGo and not moveDirectly and participant.LastMovedAt ~= 0 then
        GiveMoney(participant, participant.Round.BoardConfiguration.PassGoMoney)
    end

    if not intialMove then
        participant.LastMovedAt = workspace:GetServerTimeNow()
    end
    participant.Position = position

    local tile = participant.Board.Tiles[position]

    print(`Moved to {TileUtils.GetName(tile.TileDescription)}`)

    if not moveDirectly then
        local allTiles = participant.Board.Tiles
        local targetRow = TileMath.GetRowFromPosition(position, #allTiles)
        local currentPosition = participant.PreviousPosition

        local startTime = os.time()
        local currentRow = TileMath.GetRowFromPosition(currentPosition, #allTiles)
        while currentRow ~= targetRow do
            local nextCornerPosition = TileMath.GetWrapAround(TileMath.GetNextCornerPosition(currentPosition, #allTiles), #allTiles)
            local nextCorner = participant.Board.Tiles[nextCornerPosition]

            currentPosition = nextCornerPosition
            currentRow = TileMath.GetRowFromPosition(currentPosition, #allTiles)

            moveCharacter(participant.Player.Character, nextCorner, false, os.time() - startTime)
        end
        moveCharacter(participant.Player.Character, tile)
    else
        moveCharacter(participant.Player.Character, tile, moveDirectly)
    end

    local asset = tile.Asset
    if asset then
        local owner = asset.Owner

        if owner ~= participant then
            if owner == "Bank" then
                PurchaseProperty(participant, asset)
            else
                participant:TryPayRent(tile)
            end
        end
    end

    if tile.TileDescription.OnEnter then
        tile.TileDescription.OnEnter(tile.TileDescription, participant)
    end
end

local function MoveBy(participant: Types.Participant, amount: number): ()
    local position = TileMath.GetWrapAround(participant.Position + amount, #participant.Board.Tiles)
    MoveTo(participant, position)
end

local function MoveToTileByName(participant: Types.Participant, name: string, moveDirectly: boolean?): ()
    MoveTo(participant, participant.Board:FindTileByName(name), moveDirectly)
end

local function FindClosestForwardPositionByColour(participant: Types.Participant, colour: string): number?
    local validPositions: {number} = {}
    for i, v in participant.Board.Tiles do
        if v.TileDescription.AssetDescription and v.TileDescription.AssetDescription.Colour == colour then
            table.insert(validPositions, i)
        end
    end

    local closest: {Position: number?, Distance: number} = {Position = nil, Distance = math.huge}
    for _, position in validPositions do
        local distance = position - participant.Position
        if distance < 0 then
            distance += #participant.Board.Tiles
        end
        
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
        if participant.JailedOn <= participant.Round.Turn - participant.Round.BoardConfiguration.JailLength then
            LeaveJail(participant)
        elseif participant.Round.BoardConfiguration.CanLeaveJailByRollingDoubles and RollDice(participant).IsDoubles then
            LeaveJail(participant)
        end
    else
        local roll = RollDice(participant)
        if roll.IsDoubles then
            participant.DoublesStreak += 1

            if participant.DoublesStreak >= participant.Round.BoardConfiguration.DoublesConsecutiveJailAmount then
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

local function TryPayRent(participant: Types.Participant, tile: Types.Tile): ()
    local asset = tile.Asset
    if not asset then
        return
    end

    if asset.Owner == participant or asset.Owner == "Bank" then
        return
    end

    participant:TransferMoneyTo(asset.Owner, asset:GetRentCost(participant))
end

function module.new(player: Player, round: Types.Round): Types.Participant
    local participant = {}

    participant.Player = player
    participant.Round = round
    participant.Board = round.Board

    participant.JailCards = round.BoardConfiguration.StartingJailCards
    participant.Money = round.BoardConfiguration.StartingMoney
    participant.Assets = {}

    participant.LastMovedAt = 0
    participant.DoublesStreak = 0
    participant.PreviousPosition = 0
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
    participant.FindClosestForwardPositionByColour = FindClosestForwardPositionByColour
    participant.GiveJailCard = GiveJailCard
    participant.TransferJailCard = TransferJailCard
    participant.LeaveJail = LeaveJail
    participant.TryPayRent = TryPayRent
    participant.DrawCard = DrawCard

    participant.PurchaseProperty = PurchaseProperty

    player:SetAttribute("Money", participant.Money)

    return participant
end

return module