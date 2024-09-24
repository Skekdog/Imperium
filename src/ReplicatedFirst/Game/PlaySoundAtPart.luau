local SoundService = game:GetService("SoundService")
export type SoundName = "Construction"

return function(name: SoundName, part: BasePart): ()
    local sound = SoundService:FindFirstChild(name, true)
    if not sound or not sound:IsA("Sound") then
        error("Sound not found: " .. name)
    end

    sound = sound:Clone()
    sound.PlayOnRemove = true
    sound.Parent = part
    sound:Destroy()
end
