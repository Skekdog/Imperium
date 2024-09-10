local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetPlayerName = require(ReplicatedFirst.Shared.GetPlayerName)
local UIManager = require(ReplicatedFirst.Shared.UIManager)

local ui = UIManager.WaitForUI("CurrentTurnIndicator")
local object = ui.Object :: typeof(UIManager.UnregisteredUIs.CurrentTurnIndicator)

local function setWaitingText(): ()
    local text = ReplicatedStorage:GetAttribute("WaitingText") :: string?
    if not text then
        return
    end

    object.Turn.Text = text
end
ReplicatedStorage:GetAttributeChangedSignal("WaitingText"):Connect(setWaitingText)
setWaitingText()

ReplicatedStorage:GetAttributeChangedSignal("CurrentPlayer"):Connect(function()
    local player = Players:FindFirstChild(ReplicatedStorage:GetAttribute("CurrentPlayer") :: string)
    if not player or not player:IsA("Player") then
        object.Turn.Text = "Unknown Player's Turn"
        return
    end

    object.Turn.Text = `{GetPlayerName(player)}'s Turn`
end)

task.spawn(function()
    while true do
        task.wait()

        local milestone = ReplicatedStorage:GetAttribute("TimeMilestone") :: number?
        if not milestone then
            object.Timer.Visible = false
            continue
        end

        object.Timer.Visible = true

        local diff = math.round(milestone - workspace:GetServerTimeNow())

        if diff <= 0 then -- We specifically want to check for == 0, because of negative 0. (I love IEEE 754)
            diff = 0
        end

        object.Timer.Text = `{diff}s`
    end
end)