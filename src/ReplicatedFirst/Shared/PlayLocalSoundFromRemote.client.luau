local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlaySound = require(script.Parent.PlaySound)
ReplicatedStorage:WaitForChild("Shared").ServerClient.PlaySound.OnClientEvent:Connect(PlaySound)