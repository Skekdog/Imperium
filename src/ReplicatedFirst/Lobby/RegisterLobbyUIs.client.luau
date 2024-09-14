local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UIManager = require(script.Parent.Parent.Shared.UIManager)

if not ReplicatedFirst:GetAttribute("UICanRegister") then
    ReplicatedFirst:GetAttributeChangedSignal("UICanRegister"):Wait()
end

UIManager.RegisterUI(UIManager.UnregisteredUIs.Playerlist)
UIManager.RegisterUI(UIManager.UnregisteredUIs.LobbyUI)
UIManager.RegisterUI(UIManager.UnregisteredUIs.Notification)