local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local tracksFolder = SoundService.BackgroundMusic

local FADE_OUT_TIME = 5
local PAUSE_TIME = 1

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

	task.delay(track.TimeLength - FADE_OUT_TIME, function() -- normally wouldn't do this but some of the tracks end REALLY abruptly
		TweenService:Create(track, TweenInfo.new(FADE_OUT_TIME), {Volume = 0}):Play()
	end)

	track.Ended:Wait()

	task.wait(PAUSE_TIME)
end
