local SoundService = game:GetService("SoundService")
local tracksFolder = SoundService.BackgroundMusic

local PAUSE_TIME = 10

local tracks = {}
for _, v in tracksFolder:GetChildren() do
	if not v:IsA("Sound") then
		continue
	end

	v.SoundGroup = SoundService.BackgroundMusic
	table.insert(tracks, v)
end

local lastTrack: Sound?

while true do
	local chosenTrack: Sound?
	repeat
		chosenTrack = tracks[math.random(#tracks)]
	until chosenTrack ~= lastTrack

	lastTrack = chosenTrack

	assert(chosenTrack)
	chosenTrack:Play()

	chosenTrack.Ended:Wait()

	task.wait(PAUSE_TIME)
end
