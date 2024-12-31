local Types = require(script.Parent.Types)
local function FireRemote(remote: RemoteEvent, participant: Types.Participant, ...: any): ()
    if participant.Player:IsA("Player") then
        remote:FireClient(participant.Player, ...)
    end
end

return FireRemote
