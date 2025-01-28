local SoundService = game:GetService("SoundService")
local tracksFolder = SoundService.BackgroundMusic

local PAUSE_TIME = 10

local random = Random.new(workspace:GetServerTimeNow())

local tracks: {Sound} = {}

local function tryAddTrack(track: Instance): ()
	if not track:IsA("Sound") then
		return
	end

	track.SoundGroup = SoundService.BackgroundMusic
	table.insert(tracks, track)
end

tracksFolder.ChildAdded:Connect(function(child)
	tryAddTrack(child)
	random:Shuffle(tracks)
end)

for _, v in tracksFolder:GetChildren() do
	tryAddTrack(v)
end

random:Shuffle(tracks)

local index = 0

while true do
	index += 1
	if index > #tracks then
		index = 1
	end

	local track = tracks[index]
	assert(track, "Index out of bounds")
	track:Play()

	track.Ended:Wait()

	task.wait(PAUSE_TIME)
end
