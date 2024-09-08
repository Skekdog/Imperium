local Players = game:GetService("Players")
local Classic = require(script.Parent.GameDefinitions.Classic.Classic)
local Round = require(script.Parent.Imperium.Round)

Players.PlayerAdded:Wait()
Round.new(Classic)