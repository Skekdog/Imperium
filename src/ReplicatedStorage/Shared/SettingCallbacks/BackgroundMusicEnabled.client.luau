local SoundService = game:GetService("SoundService")
local SettingCallback = require(script.Parent.Parent.SettingCallback)
SettingCallback.Listen(function(name, value)
    if name ~= "Background Music" then
        return
    end

    SoundService.BackgroundMusic.Volume = if value then 0.25 else 0
end)