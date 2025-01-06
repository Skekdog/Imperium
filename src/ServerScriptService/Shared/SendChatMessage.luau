local ReplicatedStorage = game:GetService("ReplicatedStorage")
local function SendChatMessage(msg: string): ()
    ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerClient"):WaitForChild("SendChatMessage"):FireAllClients(msg)
end

return SendChatMessage