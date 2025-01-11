local DynamicNames = require(script.Parent.Parent.DynamicNames)
local SettingCallback = require(script.Parent.Parent.SettingCallback)

SettingCallback.Listen(function(name, value)
    if name == "Player Names" then
        DynamicNames.UpdateAll(value)
    end
end)