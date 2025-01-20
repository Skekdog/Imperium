local SoundService = game:GetService("SoundService")
local SettingCallback = require(script.Parent.Parent.Shared.SettingCallback)
local SettingsManager = require(script.Parent.Parent.Shared.SettingsManager)

local alert = SoundService:WaitForChild("BankruptcyAlert")
alert:Play()

SettingCallback.Listen(function(name, value)
    if name ~= "Bankruptcy Alert" then
        return
    end

    if value then
        if not alert.IsPlaying then
            alert:Play()
        end
    else
        alert:Stop()
    end
end)

local module = {}

function module.Start(): ()
    if not alert.IsPlaying and SettingsManager.GetSetting("Bankruptcy Alert") then
        alert:Play()
    end
    alert.Volume = 0.1
end

function module.Stop(): ()
    alert.Volume = 0
end

return module