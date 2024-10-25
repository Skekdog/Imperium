local Lighting = game:GetService("Lighting")
local IsLobby = require(script.Parent.Parent.IsLobby)
local SettingCallback = require(script.Parent.Parent.SettingCallback)

SettingCallback.Listen(function(name, value)
    if name ~= "Night Sky" or IsLobby() then
        return
    end

    Lighting.ClockTime = if value then 0 else 14
end)