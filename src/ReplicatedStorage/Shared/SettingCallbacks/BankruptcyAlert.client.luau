local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local PlaySound = require(script.Parent.Parent.PlaySound)
local SettingCallback = require(script.Parent.Parent.SettingCallback)

SettingCallback.Listen(function(name, value)
    local neededMoney = ReplicatedStorage:GetAttribute("NeededMoneyBankruptcy") or 0
    if not value then
        SoundService:FindFirstChild("BankruptcyAlert"):Stop()
    elseif neededMoney > 0 and ReplicatedStorage:GetAttribute("CurrentPlayer") == Players.LocalPlayer.Name then
        PlaySound("BankruptcyAlert")
    end
end)