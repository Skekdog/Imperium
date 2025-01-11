local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingsManager = require(ReplicatedStorage.Shared.SettingsManager)
local ProfileService = require(script.Parent.ProfileService)

local module = {}

module.ProfileTemplate = {
	Settings = SettingsManager.JSONEncode(),
	Wins = 0,
}

type PlayerData = typeof(module.ProfileTemplate)
type Profile = ProfileService.Profile & {Data: PlayerData}

local profiles: {[Player]: Profile} = {}
local ProfileStore = ProfileService.GetProfileStore("PlayerData_v2", module.ProfileTemplate)

function module.LoadProfile(plr: Player): Profile?
    local profile: Profile = ProfileStore:LoadProfileAsync("Player"..plr.UserId)
	if profile then
		profile:AddUserId(plr.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			profiles[plr] = nil
		end)
		
		if plr:IsDescendantOf(Players) then
			profiles[plr] = profile
			return profile
		else
			-- Player left before the profile loaded
			profile:Release()
		end
	else
		plr:Kick("You have been kicked to maintain data integrity. Try again later.")
	end
	return
end

function module.ReleaseProfile(plr: Player): ()
    local profile = profiles[plr]
	if profile then
		profile:Release()
	end
end

function module.GetProfile(plr: Player | Configuration): PlayerData?
	if plr:IsA("Configuration") then
		return
	end
	
	if not profiles[plr] then
		return warn(plr.Name.." profile not found!")
	end
	return profiles[plr].Data
end

type UpdateProfile =
	((Player, "Settings", string) -> ()) &
	((Player, "Wins", number) -> ())

module.UpdateProfile = function(plr: Player, key, value): ()
	if not profiles[plr] then
		return warn(plr.Name.." profile not found!")
	end
	profiles[plr].Data[key] = value
end :: UpdateProfile

function module.ReleaseAllProfiles(): ()
    for _, v in profiles do
		v:Save()
		v:Release()
	end
end

return module