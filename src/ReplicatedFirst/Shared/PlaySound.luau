local SoundService = game:GetService("SoundService")
return function(soundName: "Click"): ()
    local sound = SoundService:FindFirstChild(soundName, true)
    if not sound or not sound:IsA("Sound") then
        error("Sound not found: " .. soundName)
    end

    sound:Play()
end
