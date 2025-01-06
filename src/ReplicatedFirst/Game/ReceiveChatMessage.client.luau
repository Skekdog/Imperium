local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatMessage = require(ReplicatedFirst.Shared.ChatMessage)
ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("SendChatMessage").OnClientEvent:Connect(ChatMessage)