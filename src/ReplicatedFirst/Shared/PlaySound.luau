local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

type SoundName = "Click" | "Siren" | "DiceRoll" | "MoneyGained" | "LockingUp" | "DrawCard"
return function(soundName: SoundName, to: Player?): Sound?
    if to then
        return ReplicatedStorage.Shared.ServerClient.PlaySound:FireClient(to, soundName)
    end

    local sound = SoundService:FindFirstChild(soundName, true)
    if not sound or not sound:IsA("Sound") then
        error("Sound not found: " .. soundName)
    end

    sound:Play()
    return sound
end
