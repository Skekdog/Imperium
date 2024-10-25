local SettingCallback = require(script.Parent.Parent.SettingCallback)
local ThemesManager = require(script.Parent.Parent.ThemesManager)

SettingCallback.Listen(function(name, value)
    if name == "UI Theme" then
        ThemesManager.UpdateTheme(value)
    end
end)