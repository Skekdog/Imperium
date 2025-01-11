local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySound = require(script.Parent.PlaySound)
ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("PlaySound").OnClientEvent:Connect(PlaySound)