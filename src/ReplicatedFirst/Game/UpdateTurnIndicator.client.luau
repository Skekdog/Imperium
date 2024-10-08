local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetCurrencySymbol = require(script.Parent.GetCurrencySymbol)
local UIAnimation = require(script.Parent.Parent.Shared.UIAnimation)
local GetPlayerName = require(ReplicatedFirst.Shared.GetPlayerName)
local UIManager = require(ReplicatedFirst.Shared.UIManager)

local ui = UIManager.WaitForUI("CurrentTurnIndicator")
local object = ui.Object :: typeof(UIManager.UnregisteredUIs.CurrentTurnIndicator)

local function setPlayerText(): ()
    local name = ReplicatedStorage:GetAttribute("CurrentPlayer") :: string?
    if not name then
        return
    end

    local player = Players:FindFirstChild(name)
    if not player or not player:IsA("Player") then
        object.Frame.Turn.Text = "Unknown Player's Turn"
        return
    end

    object.Frame.Turn.Text = `{GetPlayerName(player)}'s Turn`
end

local function setWaitingText(): ()
    local text = ReplicatedStorage:GetAttribute("WaitingText") :: string?
    if not text then
        return setPlayerText()
    end

    object.Frame.Turn.Text = text
end
ReplicatedStorage:GetAttributeChangedSignal("WaitingText"):Connect(setWaitingText)
setWaitingText()

ReplicatedStorage:GetAttributeChangedSignal("CurrentPlayer"):Connect(setPlayerText)

ReplicatedStorage:GetAttributeChangedSignal("NeededMoneyBankruptcy"):Connect(function()
    local neededMoney = ReplicatedStorage:GetAttribute("NeededMoneyBankruptcy") :: number
    UIAnimation.Animate(object.Bankruptcy, TweenInfo.new(0.1), {
        Position = UDim2.fromScale(0.5, if neededMoney > 0 then 1 else 0.7)
    })

    object.Bankruptcy.Text = `GOING BANKRUPT (NEED ANOTHER {GetCurrencySymbol()}{neededMoney})`
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