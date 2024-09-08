local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetPlayerName = require(script.Parent.GetPlayerName)
local UIManager = require(script.Parent.UIManager)

local ui = UIManager.WaitForUI("CurrentTurnIndicator")
local object = ui.Object :: typeof(UIManager.UnregisteredUIs.CurrentTurnIndicator)

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
        local milestone = ReplicatedStorage:GetAttribute("TimeMilestone") :: number
        local diff = math.round(milestone - workspace:GetServerTimeNow())

        if diff < 0 then
            diff = 0
        end

        object.Timer.Text = `{diff}s`
        task.wait()
    end
end)