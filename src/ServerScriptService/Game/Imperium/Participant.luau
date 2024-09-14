local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetTime = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Shared.GetTime)
local SendNotification = require(script.Parent.Parent.SendNotification)
local SetTimeMilestone = require(script.Parent.Parent.SetTimeMilestone)
local TileMath = require(script.Parent.Parent.TileMath)
local Types = require(script.Parent.Types)

local module = {}

local function SendToJail(participant: Types.Participant): ()
    participant.DoublesStreak = 0
    participant.JailedOn = participant.Round.Turn
    participant.Player:SetAttribute("IsJailed", true)
    participant:MoveToTileByName("Jail", true)
end

local function PurchaseProperty(participant: Types.Participant, asset: Types.Asset): ()
    assert(asset.Owner == "Bank", "Asset must be owned by bank")

    SendNotification(`[PLAYER] purchased {asset.AssetDescription.Name}.`, {participant.Player})
    participant:TransferMoneyTo("Bank", asset.AssetDescription.Price, true)
    asset:TransferTo(participant)
end

local function PromptPurchaseProperty(participant: Types.Participant, asset: Types.Asset): ()
    assert(asset.Owner == "Bank", "Asset must be owned by bank")

    ReplicatedStorage.Game.ServerClient.PromptPropertyPurchase:FireClient(participant.Player, asset.AssetDescription)

    local startTime = GetTime()
    local response: boolean?

    local con: RBXScriptConnection
    con = ReplicatedStorage.Game.ClientServer.RespondPropertyPurchase.OnServerEvent:Once(function(plr, accepted: unknown, propertyName: unknown)
        if plr ~= participant.Player then
            return
        end
        if typeof(accepted) ~= "boolean" or typeof(propertyName) ~= "string" then
            return
        end
    
        local tile = participant.Board:TryFindTileByName(propertyName)
        if not tile or not tile.Asset or tile.Position ~= participant.Position then
            return
        end

        response = accepted
    end)

    local duration = participant.Round.GameConfiguration.PlayerTurnTime
    SetTimeMilestone(duration)
    while typeof(response) == "nil" and GetTime() - startTime < duration do
        task.wait()
    end

    if response == true then
        if asset.Owner ~= "Bank" then
            return
        end

        participant:PurchaseProperty(asset)
    elseif response == false then
        asset:StartAuction(participant.Round)
    else
        ReplicatedStorage.Game.ServerClient.PromptPropertyPurchase:FireClient(participant.Player, nil)
    end

    con:Disconnect()
end

local function GiveMoney(participant: Types.Participant, amount: number): ()
    participant.Money += amount
    participant.Player:SetAttribute("Money", participant.Money)
end

local function TransferMoneyTo(participant: Types.Participant, to: Types.AssetOwner, amount: number, noNotification: boolean?): ()
    assert(to ~= participant, "Can't transfer money to same participant")
    if not noNotification then
        local players = {participant.Player}
        if to ~= "Bank" then
            table.insert(players, to.Player)
        end

        local lt = amount < 0
        SendNotification(`[PLAYER] {if lt then "received" else "paid"} £{math.abs(amount)} {if lt then "from" else "to"} {if to == "Bank" then "the bank" else "[PLAYER]"}.`, players)
    end

    GiveMoney(participant, -amount)
    if to ~= "Bank" then
        GiveMoney(to, amount)
    end
end

local MAX_MOVE_DURATION = 15
local MAX_DIRECT_MOVE_DURATION = 8
local MOVEMENT_EPSILON = 2.5
local JAIL_EPSILON = 1.5
local CHAR_HEIGHT = 3
local function moveCharacter(char: Model?, tile: Types.Tile, direct: boolean?, elapsedTime: number?, isJailed: boolean?): ()
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

    local targetPart = tile.Model.PrimaryPart :: BasePart

    local startTime = GetTime() - (elapsedTime or 0)
    local reached = false

    local epsilon = MOVEMENT_EPSILON
    local isJail = tile.Model.Name == "Jail"
    if isJail then
        epsilon = JAIL_EPSILON
        if isJailed then
            targetPart = (tile.Model :: Types.JailTile).Cell
        else
            targetPart = (tile.Model :: Types.JailTile).JustVisiting
        end
    end

    local targetPosition = targetPart.Position + Vector3.new(0, CHAR_HEIGHT + targetPart.Size.Y / 2, 0)

    repeat
        if (root.Position - targetPosition).Magnitude < epsilon then
            reached = true
            break
        end
        hum:MoveTo(targetPosition) -- MoveTo timesout after 8 seconds by default - but we want a longer timeout, so we set it every iteration
        task.wait() -- We don't need to wait really because MoveTo is blocking, but why not
    until GetTime() - startTime > if direct then MAX_DIRECT_MOVE_DURATION else MAX_MOVE_DURATION
    
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

    participant.IsMoving = true

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

    local isJailed = participant.JailedOn ~= 0

    if not moveDirectly then
        local allTiles = participant.Board.Tiles
        local targetRow = TileMath.GetRowFromPosition(position, #allTiles)
        local currentPosition = participant.PreviousPosition

        local startTime = GetTime()
        local currentRow = TileMath.GetRowFromPosition(currentPosition, #allTiles)
        while currentRow ~= targetRow do
            local nextCornerPosition = TileMath.GetWrapAround(TileMath.GetNextCornerPosition(currentPosition, #allTiles), #allTiles)
            local nextCorner = participant.Board.Tiles[nextCornerPosition]

            currentPosition = nextCornerPosition
            currentRow = TileMath.GetRowFromPosition(currentPosition, #allTiles)

            moveCharacter(participant.Player.Character, nextCorner, false, GetTime() - startTime, isJailed)
        end
        moveCharacter(participant.Player.Character, tile, nil, nil, isJailed)
    else
        moveCharacter(participant.Player.Character, tile, moveDirectly, nil, isJailed)
    end

    local asset = tile.Asset
    if asset then
        local owner = asset.Owner

        if owner ~= participant then
            if owner == "Bank" then
                participant.ValidPropertyPurchaseTurn = participant.Round.Turn
                PromptPurchaseProperty(participant, asset)
            else
                participant:TryPayRent(tile)
            end
        end
    end

    if tile.TileDescription.OnEnter then
        tile.TileDescription.OnEnter(tile.TileDescription, participant)
    end

    participant.IsMoving = false
end

local function MoveBy(participant: Types.Participant, amount: number): ()
    local position = TileMath.GetWrapAround(participant.Position + amount, #participant.Board.Tiles)
    MoveTo(participant, position)
end

local function MoveToTileByName(participant: Types.Participant, name: string, moveDirectly: boolean?): ()
    MoveTo(participant, participant.Board:FindTileByName(name).Position, moveDirectly)
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

    SendNotification(`[PLAYER] rolled a {roll1 + roll2}.` .. if roll1 == roll2 then " Doubles!" else "", {participant.Player})

    return {
        Result = roll1 + roll2,
        IsDoubles = true--roll1 == roll2,
    }
end

local function LeaveJail(participant: Types.Participant, skipTurn: boolean?): ()
    participant.JailedOn = 0
    participant.Player:SetAttribute("IsJailed", false)
    if not skipTurn then
        participant:TryPlayMove()
    end
end

local function TryPlayMove(participant: Types.Participant): ()
    SetTimeMilestone(nil)
    ReplicatedStorage:SetAttribute("CurrentPlayer", nil)
    if participant.JailedOn ~= 0 then
        if participant.JailedOn < participant.Round.Turn - participant.Round.BoardConfiguration.JailLength then
            SendNotification(`[PLAYER] is leaving jail after waiting for {participant.Round.BoardConfiguration.JailLength} turns.`, {participant.Player})
            LeaveJail(participant)
        elseif false then --participant.Round.BoardConfiguration.CanLeaveJailByRollingDoubles and RollDice(participant).IsDoubles then
            SendNotification(`[PLAYER] rolled doubles and is leaving jail.`, {participant.Player})
            LeaveJail(participant)
        end
    else
        local roll = RollDice(participant)
        if roll.IsDoubles then
            participant.DoublesStreak += 1

            local neededDoubles = participant.Round.BoardConfiguration.DoublesConsecutiveJailAmount
            if participant.DoublesStreak >= neededDoubles then
                SendNotification(`[PLAYER] rolled doubles {neededDoubles} times in a row and was sent to jail.`, {participant.Player})
                SendToJail(participant)
                return participant.Round:StartNextParticipantTurn()
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
    participant.Player:SetAttribute("GetOutOfJailFreeCards", participant.JailCards)
end

local function TransferJailCard(participant: Types.Participant, to: Types.AssetOwner): ()
    participant.JailCards -= 1
    participant.Player:SetAttribute("GetOutOfJailFreeCards", participant.JailCards)

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

    participant.IsMoving = false
    participant.LastMovedAt = 0
    participant.DoublesStreak = 0
    participant.PreviousPosition = 0
    participant.Position = 0
    participant.JailedOn = 0

    participant.SendToJail = SendToJail
    participant.GiveMoney = GiveMoney
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
    participant.PromptPurchaseProperty = PromptPurchaseProperty

    player:SetAttribute("Money", participant.Money)
    player:SetAttribute("GetOutOfJailFreeCards", participant.JailCards)
    player:SetAttribute("IsJailed", participant.JailedOn ~= 0)

    return participant
end

return module