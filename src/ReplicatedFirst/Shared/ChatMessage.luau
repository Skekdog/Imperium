local TextChatService = game:GetService("TextChatService")
local chatChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral") :: TextChannel

local function ChatMessage(msg: string): ()
    chatChannel:DisplaySystemMessage(msg)
end

return ChatMessage