local Players = game:GetService("Players")
local UIManager = require(script.Parent.UIManager)

local unregisteredUIs = UIManager.UnregisteredUIs
local plr = Players.LocalPlayer

local start = os.clock()
local found = false
task.spawn(function()
    UIManager.WaitForUI("Playerlist", true)
    found = true
end)

local special = plr.PlayerGui:WaitForChild("Special")

while not found do
    if (os.clock() - start > 5) and unregisteredUIs:FindFirstChild("LoadWarning") then
        unregisteredUIs.LoadWarning.Parent = special :: any
    end
    task.wait()
end

local warning = special:FindFirstChild("LoadWarning")
if warning then
    warning:Destroy()
end