local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ProfileManager = require(script.Parent.ProfileManager)

Players.PlayerAdded:Connect(function(plr): ()
	if ServerStorage:GetAttribute("ServerLocked") then
		return plr:Kick("This server is shutting down.")
	end
	
    local profile = ProfileManager.LoadProfile(plr)
	if profile then
        ReplicatedStorage.ServerClient.LoadSavedData:FireClient(plr, profile.Data.Settings)

		plr:SetAttribute("Wins", profile.Data.Wins)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
	ProfileManager.ReleaseProfile(plr)
end)

ReplicatedStorage.ClientServer.SaveSettings.OnServerEvent:Connect(function(plr, options: unknown)
	if typeof(options) ~= "string" then
		return
	end
	if options:len() > ProfileManager.ProfileTemplate.Settings:len()*1.2 then
		return warn("Settings length exceeds maximum "..tostring(ProfileManager.ProfileTemplate.Settings:len()*1.2).." characters!")
	end

    ProfileManager.UpdateProfile(plr, "Settings", options)
end)