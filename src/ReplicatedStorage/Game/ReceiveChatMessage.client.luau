local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatMessage = require(ReplicatedStorage.Shared.ChatMessage)
ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("SendChatMessage").OnClientEvent:Connect(ChatMessage)