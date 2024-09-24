local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local GetTime = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Shared.GetTime)
local PlaySound = require(script.Parent.Parent.Parent.Parent.ReplicatedFirst.Shared.PlaySound)
local ProfileManager = require(script.Parent.Parent.Parent.Shared.ProfileManager)
local SendNotification = require(script.Parent.Parent.Parent.Shared.SendNotification)
local Teleport = require(script.Parent.Parent.Parent.Shared.Teleport)
local SetTimeMilestone = require(script.Parent.Parent.SetTimeMilestone)
local SetWaitingText = require(script.Parent.Parent.SetWaitingText)
local TileMath = require(script.Parent.Parent.TileMath)
local Types = require(script.Parent.Types)

local module = {}

local function animateJailBars(round: Types.Round, locked: boolean): ()
    local jailTile = round.Board:FindTileByName("Jail") :: Types.Tile & {Model: Types.JailTile}
    local model = jailTile.Model
    local bars = model.Bars
    local base = model.Base

    ReplicatedStorage.Game.ServerClient.AnimateJailBars:FireAllClients(bars, if locked then base.BarsLocked.WorldCFrame else base.BarsUnlocked.WorldCFrame)
end

local function SendToJail(participant: Types.Participant): ()
    local sound = PlaySound("Siren")
    if sound then
        task.delay(sound.TimeLength, PlaySound, "Siren" :: "Siren")
    end

    participant.DoublesStreak = 0
    participant.JailedOn = participant.Round.Turn
    participant.Player:SetAttribute("IsJailed", true)

    animateJailBars(participant.Round, false)
    participant:MoveToTileByName("Jail", true)
    animateJailBars(participant.Round, true)

    PlaySound("LockingUp")
end

local function PurchaseProperty(participant: Types.Participant, asset: Types.Asset): ()
    assert(asset.Owner == "Bank", "Asset must be owned by bank")

    SendNotification(`[PLAYER] purchased {asset.AssetDescription.Name}.`, {participant.Player})
    participant:TransferMoneyTo("Bank", asset.AssetDescription.Price, true)
    asset:TransferTo(participant)
end

local function PromptPurchaseProperty(participant: Types.Participant, asset: Types.Asset): ()
    assert(asset.Owner == "Bank", "Asset must be owned by bank")
    if not participant:CanAfford(asset.AssetDescription.Price) then
        return asset:StartAuction(participant.Round)
    end

    ReplicatedStorage.Game.ServerClient.PromptPropertyPurchase:FireClient(participant.Player, asset.AssetDescription)

    local startTime = GetTime()
    local response: boolean?

    local con: RBXScriptConnection
    con = ReplicatedStorage.Game.ClientServer.RespondPropertyPurchase.OnServerEvent:Once(function(plr, accepted: unknown, propertyName: unknown)
        if plr ~= participant.Player then
            return
        end

        if not participant:CanAfford(asset.AssetDescription.Price) then
            response = false -- If they do something async and they can no longer afford we want to start an auction
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

    if amount > 0 then
        PlaySound("MoneyGained", participant.Player)
    end
end

local function GoBankrupt(participant: Types.Participant, to: Types.AssetOwner): ()
    SendNotification(`[PLAYER] went bankrupt. All their money and assets were transferred to {if to == "Bank" then "the bank" else "[PLAYER]"}.`, {participant.Player})
    participant:TransferMoneyTo(to, participant.Money, true)
    participant:TransferJailCards(to, participant.JailCards)
    for _, asset in participant.Assets do
        asset:TransferTo(to)
    end

    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("GoBankrupt"):FireClient(participant.Player)
    participant:RemoveParticipant()
end

local function BankruptcyWarning(participant: Types.Participant, targetAmount: number, to: Types.AssetOwner): boolean
    local players = {participant.Player}
    if to ~= "Bank" then
        table.insert(players, to.Player)
    end
    SendNotification(`[PLAYER] needs another £{targetAmount - participant.Money} to pay {if to == "Bank" then "the bank" else "[PLAYER]"}, or else they go bankrupt.`, players)
    
    ReplicatedStorage:SetAttribute("GoingBankrupt", true)
    local start = GetTime()
    local maxTime = start + participant.Round.GameConfiguration.BankruptcyTime
    SetTimeMilestone(participant.Round.GameConfiguration.BankruptcyTime)
    while true and GetTime() < maxTime and participant.Money < targetAmount do
        task.wait()
    end
    ReplicatedStorage:SetAttribute("GoingBankrupt", false)

    if participant.Money < targetAmount then
        GoBankrupt(participant, to)
        return false
    end

    return true
end

local function TransferMoneyTo(participant: Types.Participant, to: Types.AssetOwner, amount: number, noNotification: boolean?): ()
    assert(to ~= participant, "Can't transfer money to same participant")
    if not participant:CanAfford(amount) then
        local survived = BankruptcyWarning(participant, amount, to)
        if not survived then
            return
        end
    end
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

local function DrawCard(participant: Types.Participant, card: Types.CardDescription, cardType: Types.CardType): ()
    local position = participant.Board.Tiles[participant.Position].Model:GetPivot()

    local model = (ServerStorage.Game:FindFirstChild(cardType .. " Card") :: Types.CardModel):Clone()
    model.Size = Vector3.new()
    model:PivotTo(position + Vector3.new(0, 10, 0))

    model.Gui.Description.Text = card.Title

    local gui2 = model.Gui:Clone()
    gui2.Face = Enum.NormalId.Back
    gui2.Parent = model

    model.Parent = workspace:FindFirstChild("Cards") or Instance.new("Folder", workspace) :: any
    model.Parent.Name = "Cards"

    PlaySound("DrawCard")
    SendNotification(`[PLAYER] drew a {cardType} card: {card.Title}`, {participant.Player})
    ReplicatedStorage:WaitForChild("Game"):WaitForChild("ServerClient"):WaitForChild("AnimateCard"):FireAllClients(model)

    task.wait(6)
    model:Destroy()
    
    card.Effect(participant)
end

local function MoveTo(participant: Types.Participant, position: number, moveDirectly: boolean?, intialMove: boolean?): ()
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
end

local function MoveBy(participant: Types.Participant, amount: number, moveDirectly: boolean?): ()
    local position = TileMath.GetWrapAround(participant.Position + amount, #participant.Board.Tiles)
    MoveTo(participant, position, moveDirectly)
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
    PlaySound("DiceRoll")
    local roll1 = math.random(1, 6)
    local roll2 = math.random(1, 6)

    SendNotification(`[PLAYER] rolled a {roll1 + roll2}.` .. if roll1 == roll2 then " Doubles!" else "", {participant.Player})

    return {
        Result = roll1 + roll2,
        IsDoubles = roll1 == roll2,
    }
end

local function LeaveJail(participant: Types.Participant, skipTurn: boolean?): ()
    participant.JailedOn = 0
    participant.Player:SetAttribute("IsJailed", false)

    animateJailBars(participant.Round, false)
    task.wait(1)

    for _, v in participant.Round.Participants do
        if v.JailedOn ~= 0 then
            animateJailBars(participant.Round, true)
        end
    end

    if not skipTurn then
        participant:TryPlayMove()
    end
end

local function TryPlayMove(participant: Types.Participant): ()
    participant.IsMoving = true
    SetTimeMilestone(nil)
    ReplicatedStorage:SetAttribute("CurrentPlayer", nil)
    if participant.JailedOn ~= 0 then
        if participant.JailedOn <= participant.Round.Turn - participant.Round.BoardConfiguration.JailLength then
            SendNotification(`[PLAYER] is leaving jail after waiting for {participant.Round.BoardConfiguration.JailLength} turns.`, {participant.Player})
            LeaveJail(participant)
        elseif participant.Round.BoardConfiguration.CanLeaveJailByRollingDoubles and RollDice(participant).IsDoubles then
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

    if participant.IsInGame then
        participant.Round:StartNextParticipantTurn()
    end
    participant.IsMoving = false
end

local function GiveJailCards(participant: Types.Participant, amount: number): ()
    participant.JailCards += amount
    participant.Player:SetAttribute("GetOutOfJailFreeCards", participant.JailCards)
end

local function TransferJailCards(participant: Types.Participant, to: Types.AssetOwner, amount: number): ()
    assert(participant.JailCards >= amount, "Not enough jail cards")
    participant.JailCards -= amount
    participant.Player:SetAttribute("GetOutOfJailFreeCards", participant.JailCards)

    if to ~= "Bank" then
        to:GiveJailCards(amount)
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

local function TryUseJailCard(participant: Types.Participant): ()
    if participant.JailCards > 0 and participant.JailedOn ~= 0 then
        participant:TransferJailCards("Bank", 1)

        SendNotification(`[PLAYER] used a Get Out of Jail Free card.`, {participant.Player})
        LeaveJail(participant)
    end
end

local function TryPayFine(participant: Types.Participant): ()
    if participant.JailedOn ~= 0 and participant.Money >= participant.Round.BoardConfiguration.JailFine then
        participant:TransferMoneyTo("Bank", participant.Round.BoardConfiguration.JailFine, true)

        SendNotification(`[PLAYER] paid a fine of £{participant.Round.BoardConfiguration.JailFine} to leave jail.`, {participant.Player})
        LeaveJail(participant)
    end
end

local function GetTheDub(participant: Types.Participant): ()
    SendNotification(`[PLAYER] won the game!`, {participant.Player})
    SetWaitingText("Returning to lobby...", 15)

    local plr = participant.Player
    local profile = ProfileManager.GetProfile(plr)

    if profile then
        plr:SetAttribute("Wins", profile.Wins + 1)
        ProfileManager.UpdateProfile(participant.Player, "Wins", profile.Wins + 1)
    end

    task.wait(15)
    Teleport(Players:GetPlayers(), "Lobby")
end

local function HasMonopoly(participant: Types.Participant, colour: string): boolean
    for _, asset in participant.Board:GetAllAssetsInColourGroup(colour) do
        if asset.Owner ~= participant then
            return false
        end
    end

    return true
end

local function CanAfford(participant: Types.Participant, amount: number): boolean
    return participant.Money >= amount
end

local function RemoveParticipant(participant: Types.Participant): ()
    local round = participant.Round

    local nextParticipant: Types.Participant?
    if round.CurrentParticipant == participant then
        nextParticipant = round:SetNextParticipant()
    end

    table.remove(round.Participants, table.find(round.Participants, participant))
    participant.IsInGame = false
    participant.Player:SetAttribute("Status", "Spectating")
    participant.Player:SetAttribute("IsJailed", false)

    local plr = participant.Player
    local char = plr.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
        end
    end

    local isGameOver = #round.Participants == 1
    if isGameOver then
        return round.Participants[1]:GetTheDub()
    end

    for i = #participant.Assets, 1, -1 do
        local asset = participant.Assets[i]
        assert(asset, "Invalid index for asset (" .. i .. ")")
        asset:StartAuction(round, true)
    end

    if nextParticipant and #round.Participants > 1 then
        round:StartNextParticipantTurn(nextParticipant)
    end
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
    participant.GiveJailCards = GiveJailCards
    participant.TransferJailCards = TransferJailCards
    participant.LeaveJail = LeaveJail
    participant.TryPayRent = TryPayRent
    participant.DrawCard = DrawCard
    participant.TryUseJailCard = TryUseJailCard
    participant.TryPayFine = TryPayFine

    participant.PurchaseProperty = PurchaseProperty
    participant.PromptPurchaseProperty = PromptPurchaseProperty

    participant.BankruptcyWarning = BankruptcyWarning
    participant.GoBankrupt = GoBankrupt
    participant.GetTheDub = GetTheDub

    participant.HasMonopoly = HasMonopoly
    participant.CanAfford = CanAfford

    participant.IsInGame = true
    participant.HasDisconnected = false

    participant.RemoveParticipant = RemoveParticipant

    player:SetAttribute("Money", participant.Money)
    player:SetAttribute("GetOutOfJailFreeCards", participant.JailCards)
    player:SetAttribute("IsJailed", participant.JailedOn ~= 0)

    return participant
end

return module