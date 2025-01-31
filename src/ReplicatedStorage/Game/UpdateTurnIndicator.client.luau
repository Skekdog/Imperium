local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIManager = require(ReplicatedStorage.Shared.UIManager)
local GetPlayerName = require(script.Parent.Parent.Shared.GetPlayerName)
local UIAnimation = require(script.Parent.Parent.Shared.UIAnimation)

local ui = UIManager.WaitForUI("CurrentTurnIndicator")
local object = ui.Object :: typeof(UIManager.UnregisteredUIs.CurrentTurnIndicator)

local function setPlayerText(): ()
    local name = ReplicatedStorage:GetAttribute("CurrentPlayer") :: string?
    if not name then
        return
    end

    local turnLabel = object.Frame.Turn

    local player = Players:FindFirstChild(name)
    if not player or (not player:IsA("Player") and not player:IsA("Configuration")) then
        turnLabel:SetAttribute("Format", "Unknown Player's Turn")
        return
    end

    turnLabel:SetAttribute("Player_1", GetPlayerName(player :: Player | Configuration))
    turnLabel:SetAttribute("Format", "[PLAYER]'s Turn")
    turnLabel:AddTag("DynamicNames")
end

local function setWaitingText(): ()
    local text = ReplicatedStorage:GetAttribute("WaitingText") :: string?
    if not text then
        return setPlayerText()
    end

    object.Frame.Turn:SetAttribute("Format", text)
    object.Frame.Turn:AddTag("DynamicNames")
end
ReplicatedStorage:GetAttributeChangedSignal("WaitingText"):Connect(setWaitingText)
setWaitingText()

ReplicatedStorage:GetAttributeChangedSignal("CurrentPlayer"):Connect(setPlayerText)

local function tryOnPlayerAdded(plr: Instance): ()
    if not plr:IsA("Player") or not plr:IsA("Configuration") then
        return
    end
end

for _, plr in Players:GetChildren() do
    tryOnPlayerAdded(plr)
end
Players.ChildAdded:Connect(tryOnPlayerAdded)

ReplicatedStorage:GetAttributeChangedSignal("IsPaused"):Connect(function()
    local isPaused = ReplicatedStorage:GetAttribute("IsPaused") :: boolean
    UIAnimation.Animate(object.Bankruptcy, TweenInfo.new(0.1), {
        Position = UDim2.fromScale(0.5, if isPaused then 1 else 0.7)
    })

    if isPaused then
        object.Bankruptcy.Text = "PAUSED"
    end
end)

task.spawn(function()
    while true do
        task.wait()

        local milestone = ReplicatedStorage:GetAttribute("TimeMilestone") :: number?
        if not milestone then
            object.Frame.Timer.Visible = false
            continue
        end

        object.Frame.Timer.Visible = true

        local diff = math.round(milestone - workspace:GetServerTimeNow())

        if diff <= 0 then -- We specifically want to check for == 0, because of negative 0. (I love IEEE 754)
            diff = 0
        end

        object.Frame.Timer.Text = `{diff}s`
    end
end)